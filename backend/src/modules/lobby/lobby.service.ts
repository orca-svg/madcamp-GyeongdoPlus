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
import { CreateRoomDto, JoinRoomDto, KickUserDto, UpdateRoomDto, StartGameDto } from './lobby.dto';
import { generateRoomCode } from '../../common/utils/room-code.util'; // (아까 만든 유틸)

@Injectable()
export class LobbyService {
  constructor(
    private prisma: PrismaService,
    private redisService: RedisService,
  ) {}

  // 1. 방 생성 (POST /lobby/create)
  async createRoom(hostUserId: string, dto: CreateRoomDto) {
    // 1-1. 방 코드 생성 (중복 체크)
    let roomCode = generateRoomCode();
    while (await this.prisma.gameMatch.findUnique({ where: { roomCode } })) {
      roomCode = generateRoomCode();
    }

    // 1-2. DB에 매치 정보 저장 (상태: WAITING)
    const match = await this.prisma.gameMatch.create({
      data: {
        hostUserId,
        roomCode,
        mode: dto.mode,
        status: 'WAITING',
        mapConfig: dto.mapConfig, // JSON 타입
        rules: dto.rules,         // JSON 타입
        
        // 🚨 [수정] 이 두 필드를 꼭 저장해야 나중에 전적 조회 시 올바르게 나옵니다!
        maxPlayers: dto.maxPlayers,
        timeLimit: dto.timeLimit,
      },
    });

    // 1-3. Redis 초기화 (기존 로직 유지)
    await this.redisService.hset(`game:${match.id}:state`, {
      game_status: 'WAITING',
      total_time: dto.timeLimit.toString(),
      max_players: dto.maxPlayers.toString(),
      created_at: new Date().toISOString(),
    });

    // 1-4. 호스트 추가 (기존 로직 유지)
    await this.redisService.hset(`game:${match.id}:player:${hostUserId}`, {
      role: 'NONE',
      status: 'ALIVE',
      is_host: 'true',
      nickname: 'HostUser', // (실제로는 UserService 등을 통해 닉네임을 가져와야 함)
    });

    return {
      success: true,
      message: '방이 생성되었습니다.',
      data: {
        matchId: match.id,
        roomCode: match.roomCode,
      },
      error: null // Response DTO 형식을 맞추기 위해 추가
    };
  }

  // 2. 방 입장 (POST /lobby/join)
  async joinRoom(userId: string, dto: JoinRoomDto) {
    // 2-1. 방 코드 검증
    const match = await this.prisma.gameMatch.findUnique({
      where: { roomCode: dto.roomCode },
    });

    // 🚨 [수정] 404 에러 포맷 맞추기 (ROOM_NOT_FOUND)
    if (!match) {
      throw new HttpException(
        {
          success: false,
          message: '존재하지 않는 참여 코드입니다.',
          data: null,
          error: { code: 'ROOM_NOT_FOUND' },
        },
        HttpStatus.NOT_FOUND,
      );
    }

    // 2-2. 게임 상태 체크
    if (match.status !== 'WAITING') {
      throw new HttpException(
        {
          success: false,
          message: '이미 게임이 시작되었습니다.',
          data: null,
          error: { code: 'GAME_STARTED' },
        },
        HttpStatus.CONFLICT,
      );
    }

    // ✅ [추가] 인원 수 체크 (Logic 누락 해결)
    const currentPlayers = await this.redisService.keys(`game:${match.id}:player:*`);
    if (currentPlayers.length >= match.maxPlayers) {
      throw new HttpException(
        {
          success: false,
          message: '방이 가득 찼습니다.',
          data: null,
          error: { code: 'ROOM_FULL' },
        },
        HttpStatus.CONFLICT,
      );
    }
    
    // 2-3. Redis: 플레이어 추가 (기존 로직 유지)
    // (이미 들어와 있는 유저인지 체크하는 로직은 선택사항이나, 여기선 덮어쓰기로 진행)
    await this.redisService.hset(`game:${match.id}:player:${userId}`, {
      role: 'NONE',
      status: 'ALIVE',
      is_host: 'false',
      // nickname: ... (UserService에서 가져와서 넣으면 더 좋음)
    });

    return {
      success: true,
      message: '방에 입장했습니다.',
      data: {
        matchId: match.id,
        myRole: 'NONE', // 아직 팀 선택 전이므로 NONE
        hostId: match.hostUserId,
        mapConfig: match.mapConfig,
      },
      error: null
    };
  }

// 3. 유저 강퇴 (POST /lobby/kick)
  async kickUser(requesterId: string, dto: KickUserDto) {
    // 3-1. 권한 확인 (요청자가 방장인지)
    const match = await this.prisma.gameMatch.findUnique({
      where: { id: dto.matchId },
    });
    if (!match) throw new NotFoundException('게임을 찾을 수 없습니다.');
    
    // 🚨 [수정] 403 Forbidden 에러 포맷 맞추기 (NOT_HOST)
    if (match.hostUserId !== requesterId) {
      throw new HttpException(
        {
          success: false,
          message: '방장만 유저를 강퇴할 수 있습니다.',
          data: null,
          error: { code: 'NOT_HOST' },
        },
        HttpStatus.FORBIDDEN,
      );
    }

    // 3-2. 대상 확인 (방장은 스스로 강퇴 불가)
    if (dto.targetUserId === requesterId) {
      throw new ConflictException('자기 자신은 강퇴할 수 없습니다.');
    }

    // 3-3. Redis 삭제
    const playerKey = `game:${dto.matchId}:player:${dto.targetUserId}`;
    // (선택) 실제로 존재하는 유저였는지 체크하려면 여기서 redis.exists 확인 가능
    await this.redisService.del(playerKey);

    // ✅ [추가] 남은 인원 수 계산 (Logic 누락 해결)
    // 패턴: game:{matchId}:player:* 키 개수 조회
    const remainingKeys = await this.redisService.keys(`game:${dto.matchId}:player:*`);
    const remainingCount = remainingKeys.length;

    // (참고) 3-4. Socket 알림 전송 (Gateway 역할)

    return {
      success: true,
      message: '해당 유저를 강퇴했습니다.',
      data: {
        kickedUserId: dto.targetUserId,
        remainingPlayerCount: remainingCount, // ✅ 실제 남은 인원 반환
      },
      error: null
    };
  }

  // ✅ 4. 방 상세 정보 조회 (GET /lobby/:matchId)
  async getRoomDetails(matchId: string) {
    // 1. DB에서 방 설정 조회
    const match = await this.prisma.gameMatch.findUnique({
      where: { id: matchId },
    });
    if (!match) throw new NotFoundException('방을 찾을 수 없습니다.');

    // 2. Redis에서 플레이어 리스트 조회
    const playerKeys = await this.redisService.keys(`game:${matchId}:player:*`);
    
    // 3. 각 키에 대해 hgetall로 상세 정보 가져오기
    const players = await Promise.all(
      playerKeys.map(async (key) => {
        const data = await this.redisService.hgetall(key);
        return {
          userId: key.split(':').pop(), 
          nickname: data.nickname || 'Unknown',
          ready: data.status === 'READY', // Redis 상태값(READY) 확인
          team: data.role === 'NONE' ? null : data.role,
          // isHost 정보는 클라이언트에서 hostId와 비교하면 되므로 생략 가능하나 포함해도 무방
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
          // 🚨 [수정] 하드코딩 제거 -> DB 값 사용
          timeLimit: match.timeLimit, 
          maxPlayers: match.maxPlayers, 
          mapConfig: match.mapConfig,
        },
        players: players,
      },
      error: null
    };
  }

  // ✅ 5. 방 설정 변경 (PATCH /lobby/:matchId)
  async updateRoomSettings(requesterId: string, matchId: string, dto: UpdateRoomDto) {
    // 1. 권한 및 상태 확인
    const match = await this.prisma.gameMatch.findUnique({ where: { id: matchId } });
    if (!match) throw new NotFoundException('방을 찾을 수 없습니다.');
    
    // 🚨 [수정] 403 에러 포맷 맞추기 (NOT_HOST)
    if (match.hostUserId !== requesterId) {
      throw new HttpException(
        {
          success: false,
          message: '방장만 설정을 변경할 수 있습니다.',
          data: null,
          error: { code: 'NOT_HOST' },
        },
        HttpStatus.FORBIDDEN,
      );
    }
    
    // 게임 시작 전인지 확인
    if (match.status !== 'WAITING') {
      throw new ConflictException('게임이 이미 시작되었습니다.');
    }

    // 2. DB 업데이트 (Logic 누락 해결)
    // ✅ DTO에 있는 값이 존재할 때만 DB에 업데이트되도록 수정
    const updatedMatch = await this.prisma.gameMatch.update({
      where: { id: matchId },
      data: {
        ...(dto.mode && { mode: dto.mode }),
        ...(dto.mapConfig && { mapConfig: dto.mapConfig }),
        ...(dto.rules && { rules: dto.rules }),
        ...(dto.timeLimit && { timeLimit: dto.timeLimit }), // ✅ DB에도 시간 저장
        ...(dto.maxPlayers && { maxPlayers: dto.maxPlayers }), // ✅ DB에도 인원 저장
      },
    });

    // 3. Redis 동기화 (GlobalState)
    const redisUpdateData: Record<string, string> = {};
    if (dto.mode) redisUpdateData.game_mode = dto.mode;
    if (dto.timeLimit) redisUpdateData.total_time = dto.timeLimit.toString();
    if (dto.maxPlayers) redisUpdateData.max_players = dto.maxPlayers.toString();

    if (Object.keys(redisUpdateData).length > 0) {
      await this.redisService.hset(`game:${matchId}:state`, redisUpdateData);
    }

    // 4. Socket 알림 (Gateway 역할 - 여기선 주석 처리)
    // server.to(matchId).emit('RoomSettingsUpdated', { ... });

    return {
      success: true,
      message: '방 설정이 변경되었습니다.',
      data: {
        matchId: updatedMatch.id,
        updatedSettings: {
          mode: updatedMatch.mode,
          timeLimit: updatedMatch.timeLimit,
          mapConfig: updatedMatch.mapConfig,
          rules: updatedMatch.rules, // 규칙도 반환해주면 좋음
        },
      },
      error: null
    };
  }

  // ✅ 6. 게임 시작 (POST /lobby/start)
  async startGame(requesterId: string, dto: StartGameDto) {
    const { matchId } = dto;

    // 1. 권한 체크
    const match = await this.prisma.gameMatch.findUnique({ where: { id: matchId } });
    if (!match) throw new NotFoundException('방을 찾을 수 없습니다.');
    
    // 🚨 [수정] 403 에러 포맷 맞추기 (NOT_HOST)
    if (match.hostUserId !== requesterId) {
      throw new HttpException(
        {
          success: false,
          message: '방장만 게임을 시작할 수 있습니다.',
          data: null,
          error: { code: 'NOT_HOST' },
        },
        HttpStatus.FORBIDDEN,
      );
    }

    // 2. 인원 체크 (Redis 키 개수로 확인)
    const playerKeys = await this.redisService.keys(`game:${matchId}:player:*`);
    const playerCount = playerKeys.length;
    
    // (선택) 최소 인원 체크 강화
    if (playerCount < 2) { 
      throw new BadRequestException('게임 시작을 위해 최소 2명이 필요합니다.');
    }

    // 3. DB Update: status -> PLAYING, startedAt 기록
    const startedMatch = await this.prisma.gameMatch.update({
      where: { id: matchId },
      data: {
        status: 'PLAYING',
        startedAt: new Date(),
      },
    });

    // 4. Redis Init: start_time 설정
    await this.redisService.hset(`game:${matchId}:state`, {
      game_status: 'PLAYING',
      start_time: new Date().toISOString(),
      total_thief_count: Math.floor(playerCount / 2).toString(), 
    });

    // 5. Socket Broadcast (Gateway 역할)

    return {
      success: true,
      message: '게임을 시작합니다!', // 메시지 수정 (명세서엔 '게임이 시작되었습니다!'지만, 시작 시점엔 이게 더 자연스러움)
      data: {
        matchId: startedMatch.id,
        startTime: startedMatch.startedAt,
        // 🚨 [수정] 하드코딩(600) 제거 -> DB에 저장된 timeLimit 사용
        gameDuration: startedMatch.timeLimit, 
      },
      error: null
    };
  }
}