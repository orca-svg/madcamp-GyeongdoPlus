import { 
  Injectable, 
  NotFoundException, 
  ConflictException, 
  ForbiddenException,
  BadRequestException,
  HttpException,
  HttpStatus
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { RedisService } from '../redis/redis.service';
import { EventsGateway } from '../events/events.gateway';
import { CreateRoomDto, JoinRoomDto, KickUserDto, UpdateRoomDto, StartGameDto } from './lobby.dto';
import { generateRoomCode } from '../../common/utils/room-code.util';
import { join } from 'path';

@Injectable()
export class LobbyService {
  constructor(
    private prisma: PrismaService,
    private redisService: RedisService,
    private eventsGateway: EventsGateway,
  ) {}

  // 1. 방 생성 (POST /lobby/create)
  async createRoom(hostUserId: string, dto: CreateRoomDto) {
    let roomCode = generateRoomCode();
    // findUnique는 null을 반환할 수 있으므로, while 조건에서 true/false로 변환되어 사용됨 (문제 없음)
    while (await this.prisma.gameMatch.findUnique({ where: { roomCode } })) {
      roomCode = generateRoomCode();
    }

    const match = await this.prisma.gameMatch.create({
      data: {
        hostUserId,
        roomCode,
        mode: dto.mode,
        status: 'WAITING',
        mapConfig: dto.mapConfig,
        rules: dto.rules,         
        maxPlayers: dto.maxPlayers,
        timeLimit: dto.timeLimit,
      },
    });

    await this.redisService.hset(`game:${match.id}:state`, {
      game_status: 'WAITING',
      game_mode: dto.mode, // mode 추가
      total_time: dto.timeLimit.toString(),
      max_players: dto.maxPlayers.toString(),
      created_at: new Date().toISOString(),
      host_id: hostUserId,
      room_code: match.roomCode,
      // JSON 객체는 문자열로 변환하여 저장
      map_config: JSON.stringify(dto.mapConfig), 
      rules: JSON.stringify(dto.rules),
    });
    
    await this.redisService.set(`room:${roomCode}`, match.id, 3600 * 24);

    const user = await this.prisma.user.findUnique({ where: { id: hostUserId } });
    await this.redisService.hset(`game:${match.id}:player:${hostUserId}`, {
      role: 'NONE',
      status: 'ALIVE',
      is_host: 'true',
      nickname: user?.nickname || 'HostUser',
      ready: 'true',
    });

    return {
      success: true,
      message: '방이 생성되었습니다.',
      data: { matchId: match.id, roomCode: match.roomCode },
      error: null
    };
  }

  // 2. 방 입장 (POST /lobby/join)
  async joinRoom(userId: string, dto: JoinRoomDto) {
    let matchId = await this.redisService.get(`room:${dto.roomCode}`);
    
    if (!matchId) {
        const match = await this.prisma.gameMatch.findUnique({
            where: { roomCode: dto.roomCode },
        });
        
        // 🚨 [필수 수정] match가 null인지 먼저 확인해야 합니다!
        if (!match) {
            throw new HttpException({
                success: false, message: '존재하지 않는 참여 코드입니다.', data: null, error: { code: 'ROOM_NOT_FOUND' },
            }, HttpStatus.NOT_FOUND);
        }
        
        // 위에서 에러를 던졌으므로, 여기서는 match가 null이 아님을 확신할 수 있습니다.
        matchId = match.id;
    }

    const globalState = await this.redisService.hgetall(`game:${matchId}:state`);
    
    if (globalState.game_status !== 'WAITING') {
      throw new HttpException({
        success: false, message: '이미 게임이 시작되었습니다.', data: null, error: { code: 'GAME_STARTED' },
      }, HttpStatus.CONFLICT);
    }

    const currentPlayers = await this.redisService.keys(`game:${matchId}:player:*`);
    const playerKeys = currentPlayers.filter(k => k.split(':').length === 4); 

    if (playerKeys.length >= parseInt(globalState.max_players || '8')) {
      throw new HttpException({
        success: false, message: '방이 가득 찼습니다.', data: null, error: { code: 'ROOM_FULL' },
      }, HttpStatus.CONFLICT);
    }
    
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    const nickname = user?.nickname || `Guest_${userId.substring(0,4)}`;

    await this.redisService.hset(`game:${matchId}:player:${userId}`, {
      role: 'NONE',
      status: 'ALIVE',
      is_host: 'false',
      nickname: nickname,
      ready: 'false',
      joined_at: Date.now().toString(),
    });

    if (matchId) {
      this.eventsGateway.server.to(matchId).emit('user_joined', {
        userId,
        nickname,
        isHost: false,
        ready: false
      });
    }

    return {
      success: true,
      message: '방에 입장했습니다.',
      data: {
        matchId: matchId,
        myRole: 'NONE',
        hostId: globalState.host_id,
      },
      error: null
    };
  }

  // 3. 유저 강퇴 (POST /lobby/kick)
  async kickUser(requesterId: string, dto: KickUserDto) {
    const match = await this.prisma.gameMatch.findUnique({
      where: { id: dto.matchId },
    });

    // 🚨 [필수 수정] match가 null인지 확인
    if (!match) throw new NotFoundException('게임을 찾을 수 없습니다.');
    
    // 위에서 확인했으므로 match.hostUserId 접근 가능
    if (match.hostUserId !== requesterId) {
      throw new HttpException(
        { success: false, message: '방장만 유저를 강퇴할 수 있습니다.', data: null, error: { code: 'NOT_HOST' } },
        HttpStatus.FORBIDDEN,
      );
    }

    if (dto.targetUserId === requesterId) {
      throw new ConflictException('자기 자신은 강퇴할 수 없습니다.');
    }

    const playerKey = `game:${dto.matchId}:player:${dto.targetUserId}`;
    await this.redisService.del(playerKey);

    const remainingKeys = await this.redisService.keys(`game:${dto.matchId}:player:*`);
    const remainingCount = remainingKeys.length;

    this.eventsGateway.server.to(dto.matchId).emit('user_kicked', {
        kickedUserId: dto.targetUserId,
        remainingPlayerCount: remainingCount
    });

    return {
      success: true,
      message: '해당 유저를 강퇴했습니다.',
      data: { kickedUserId: dto.targetUserId, remainingPlayerCount: remainingCount },
      error: null
    };
  }

  // 4. 방 상세 정보 조회 (GET /lobby/:matchId)
  async getRoomDetails(matchId: string) {

    // 1. Redis에서 실시간 상태를 먼저 조회 (성능 최적화)
  const redisState = await this.redisService.hgetall(`game:${matchId}:state`);
  
  if (redisState && redisState.game_status) {
    const playerKeys = await this.redisService.keys(`game:${matchId}:player:*`);
    const players = await Promise.all(
      playerKeys.map(async (key) => {
        if (key.split(':').length > 4) return null; // items 등 제외
        const data = await this.redisService.hgetall(key);
        return {
          userId: key.split(':').pop(), 
          nickname: data.nickname || 'Unknown',
          ready: data.ready === 'true', 
          team: data.role === 'NONE' ? null : data.role,
        };
      })
    );

    return {
      success: true,
      message: '방 정보를 조회했습니다.',
      data: {
        matchId,
        status: redisState.game_status,
        hostId: redisState.host_id,
        settings: {
          mode: redisState.game_mode,
          timeLimit: parseInt(redisState.total_time || '0'),
          maxPlayers: parseInt(redisState.max_players || '8'),
          mapConfig: redisState.map_config ? JSON.parse(redisState.map_config) : {},
          rules: redisState.rules ? JSON.parse(redisState.rules) : {},
        },
        players: players.filter(p => p !== null),
      }
    };
  }

  // 2. Redis에 없으면 DB에서 조회 (Fallback)
    const match = await this.prisma.gameMatch.findUnique({
      where: { id: matchId },
    });

    // 🚨 [필수 수정] match가 null인지 확인
    if (!match) throw new NotFoundException('방을 찾을 수 없습니다.');

    const playerKeys = await this.redisService.keys(`game:${matchId}:player:*`);
    const players = await Promise.all(
      playerKeys.map(async (key) => {
        const data = await this.redisService.hgetall(key);
        return {
          userId: key.split(':').pop(), 
          nickname: data.nickname || 'Unknown',
          ready: data.ready === 'true', 
          team: data.role === 'NONE' ? null : data.role,
        };
      })
    );

    return {
      success: true,
      message: '방 정보를 조회했습니다.',
      data: {
        matchId: match.id,
        status: match.status,
        hostId: match.hostUserId,
        settings: {
          mode: match.mode,
          timeLimit: match.timeLimit, 
          maxPlayers: match.maxPlayers, 
          mapConfig: match.mapConfig,
        },
        players: players,
      },
      error: null
    };
  }

  // 5. 방 설정 변경 (PATCH /lobby/:matchId)
  async updateRoomSettings(requesterId: string, matchId: string, dto: UpdateRoomDto) {
    const match = await this.prisma.gameMatch.findUnique({ where: { id: matchId } });
    
    // 🚨 [필수 수정] match가 null인지 확인
    if (!match) throw new NotFoundException('방을 찾을 수 없습니다.');
    
    if (match.hostUserId !== requesterId) {
      throw new HttpException(
        { success: false, message: '방장만 설정을 변경할 수 있습니다.', data: null, error: { code: 'NOT_HOST' } },
        HttpStatus.FORBIDDEN,
      );
    }
    
    if (match.status !== 'WAITING') {
      throw new ConflictException('게임이 이미 시작되었습니다.');
    }

    const updatedMatch = await this.prisma.gameMatch.update({
      where: { id: matchId },
      data: {
        ...(dto.mode && { mode: dto.mode }),
        ...(dto.mapConfig && { mapConfig: dto.mapConfig }),
        ...(dto.rules && { rules: dto.rules }),
        ...(dto.timeLimit && { timeLimit: dto.timeLimit }),
        ...(dto.maxPlayers && { maxPlayers: dto.maxPlayers }),
      },
    });

    const redisUpdateData: Record<string, string> = {};
    if (dto.mode) redisUpdateData.game_mode = dto.mode;
    if (dto.timeLimit) redisUpdateData.total_time = dto.timeLimit.toString();
    if (dto.maxPlayers) redisUpdateData.max_players = dto.maxPlayers.toString();
    if (dto.mapConfig) redisUpdateData.map_config = JSON.stringify(dto.mapConfig);
    if (dto.rules) redisUpdateData.rules = JSON.stringify(dto.rules);

    if (Object.keys(redisUpdateData).length > 0) {
      await this.redisService.hset(`game:${matchId}:state`, redisUpdateData);
    }

    this.eventsGateway.server.to(matchId).emit('settings_updated', {
      matchId,
      updatedSettings: {
        mode: updatedMatch.mode,
        timeLimit: updatedMatch.timeLimit,
        mapConfig: updatedMatch.mapConfig,
      }
    });

    return {
      success: true,
      message: '방 설정이 변경되었습니다.',
      data: {
        matchId: updatedMatch.id,
        updatedSettings: {
          mode: updatedMatch.mode,
          timeLimit: updatedMatch.timeLimit,
          mapConfig: updatedMatch.mapConfig,
          rules: updatedMatch.rules,
        },
      },
      error: null
    };
  }

  // 6. 게임 시작 (POST /lobby/start)
  async startGame(requesterId: string, dto: StartGameDto) {
    const { matchId } = dto;

    const match = await this.prisma.gameMatch.findUnique({ where: { id: matchId } });
    
    // 🚨 [필수 수정] match가 null인지 확인
    if (!match) throw new NotFoundException('방을 찾을 수 없습니다.');
    
    if (match.hostUserId !== requesterId) {
      throw new HttpException(
        { success: false, message: '방장만 게임을 시작할 수 있습니다.', data: null, error: { code: 'NOT_HOST' } },
        HttpStatus.FORBIDDEN,
      );
    }

    const playerKeys = await this.redisService.keys(`game:${matchId}:player:*`);
    const playerCount = playerKeys.length;
    
    if (playerCount < 2) { 
      throw new BadRequestException('게임 시작을 위해 최소 2명이 필요합니다.');
    }

    const startedMatch = await this.prisma.gameMatch.update({
      where: { id: matchId },
      data: {
        status: 'PLAYING',
        startedAt: new Date(),
      },
    });

    await this.redisService.hset(`game:${matchId}:state`, {
      game_status: 'PLAYING',
      start_time: new Date().toISOString(),
      total_thief_count: Math.floor(playerCount / 2).toString(), 
    });

    this.eventsGateway.server.to(matchId).emit('game_started', {
        matchId,
        startTime: startedMatch.startedAt,
        gameDuration: startedMatch.timeLimit 
    });

    return {
      success: true,
      message: '게임을 시작합니다!',
      data: {
        matchId: startedMatch.id,
        startTime: startedMatch.startedAt,
        gameDuration: startedMatch.timeLimit, 
      },
      error: null
    };
  }
}