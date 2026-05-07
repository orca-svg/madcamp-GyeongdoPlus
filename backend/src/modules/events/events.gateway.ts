// src/modules/events/events.gateway.ts
import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayInit,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import {
  BadRequestException,
  ForbiddenException,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt'; // AuthModule의 JwtService 활용
import { RedisService } from '../redis/redis.service';
import { PrismaService } from '../../database/prisma.service';
import {
  isCorsOriginAllowed,
  resolveWsCorsOrigins,
} from '../../common/utils/cors.util';

@WebSocketGateway({
  cors: {
    origin: (origin, callback) => {
      callback(null, isCorsOriginAllowed(resolveWsCorsOrigins(), origin));
    },
    credentials: true,
  },
  namespace: 'game', // URL: ws://localhost:3000/game
})
export class EventsGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer() server: Server;
  private logger: Logger = new Logger('EventsGateway');

  constructor(
    private readonly jwtService: JwtService,
    private readonly redisService: RedisService,
    private readonly prismaService: PrismaService,
  ) {}

  afterInit(server: Server) {
    this.logger.log('웹소켓 서버 초기화 완료');
  }

  // 🔌 1. 소켓 연결 시도 (인증 및 방 입장)
  async handleConnection(client: Socket) {
    try {
      // 1-1. 헤더나 쿼리에서 토큰 추출
      // 클라이언트는 { auth: { token: '...' } } 형태로 보낸다고 가정
      const token =
        client.handshake.auth.token ||
        client.handshake.headers.authorization?.split(' ')[1];

      if (!token) {
        throw new UnauthorizedException('토큰이 없습니다.');
      }

      // 1-2. 토큰 검증
      const payload = this.jwtService.verify(token, {
        secret: process.env.JWT_SECRET, // .env 확인
      });

      // 소켓 객체에 유저 정보 저장 (나중에 쓰기 위해)
      client.data.userId = payload.sub; // payload.sub는 userId
      client.data.email = payload.email;

      // 1-3. (선택) 클라이언트가 보내준 matchId가 있다면 바로 방에 조인
      const matchId = client.handshake.query.matchId as string;
      if (matchId) {
        await client.join(matchId);
        this.logger.log(`User ${payload.sub} connected and joined room ${matchId}`);

        // (선택) 방에 있는 다른 사람들에게 "새 유저 접속" 알림
        // client.to(matchId).emit('user_connected', { userId: payload.sub });
      } else {
        this.logger.log(`User ${payload.sub} connected (No matchId provided)`);
      }

    } catch (error) {
      const message = error instanceof Error ? error.message : 'unknown';
      this.logger.error(`Connection error: ${message}`);
      client.disconnect(); // 인증 실패 시 연결 끊기
    }
  }

  // 🔌 2. 소켓 연결 해제
  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
    // 필요 시 Redis에서 유저 상태(ONLINE/OFFLINE) 업데이트 로직 추가 가능
  }

  // 📢 3. (예시) 클라이언트가 방에 입장하겠다고 요청할 때
  @SubscribeMessage('join_room')
  handleJoinRoom(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string },
  ) {
    client.join(data.matchId);
    this.logger.log(`User ${client.data.userId} joined room ${data.matchId}`);
    return { event: 'joined_room', data: { matchId: data.matchId } };
  }

  @SubscribeMessage('change_ready')
  async handleChangeReady(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId?: string; isReady?: boolean; ready?: boolean },
  ) {
    return this.handleReadyUpdate(client, data);
  }

  @SubscribeMessage('ready')
  async handleReadyAlias(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId?: string; isReady?: boolean; ready?: boolean },
  ) {
    return this.handleReadyUpdate(client, data);
  }

  @SubscribeMessage('change_role')
  async handleChangeRole(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId?: string; role?: string; team?: string },
  ) {
    return this.handleRoleUpdate(client, data);
  }

  @SubscribeMessage('change_team')
  async handleChangeTeam(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId?: string; role?: string; team?: string },
  ) {
    return this.handleRoleUpdate(client, data);
  }

  @SubscribeMessage('update_settings')
  async handleUpdateSettings(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: {
      matchId?: string;
      mode?: string;
      maxPlayers?: number;
      timeLimit?: number;
      rules?: Record<string, unknown>;
      mapConfig?: Record<string, unknown>;
    },
  ) {
    const matchId = this.resolveMatchId(client, data.matchId);
    const requesterId = client.data.userId?.toString();
    if (!requesterId) {
      throw new UnauthorizedException('인증 정보가 없습니다.');
    }

    const globalState = await this.redisService.hgetall(`game:${matchId}:state`);
    if (!globalState || !globalState.game_status) {
      throw new BadRequestException('존재하지 않는 방입니다.');
    }
    if (globalState.host_id !== requesterId) {
      throw new ForbiddenException('방장만 설정을 변경할 수 있습니다.');
    }
    if (globalState.game_status !== 'WAITING') {
      throw new BadRequestException('게임 시작 후에는 설정을 변경할 수 없습니다.');
    }

    const updateData: Record<string, unknown> = {};
    if (data.mode != null) updateData.mode = data.mode;
    if (data.maxPlayers != null) updateData.maxPlayers = data.maxPlayers;
    if (data.timeLimit != null) updateData.timeLimit = data.timeLimit;
    if (data.rules != null) updateData.rules = data.rules;
    if (data.mapConfig != null) updateData.mapConfig = data.mapConfig;

    if (Object.keys(updateData).length === 0) {
      return { event: 'settings_updated', data: { matchId } };
    }

    const updatedMatch = await this.prismaService.gameMatch.update({
      where: { id: matchId },
      data: updateData as any,
    });

    const redisUpdateData: Record<string, string | number> = {};
    if (data.mode != null) redisUpdateData.game_mode = data.mode;
    if (data.maxPlayers != null) {
      redisUpdateData.max_players = data.maxPlayers;
    }
    if (data.timeLimit != null) redisUpdateData.total_time = data.timeLimit;
    if (data.rules != null) redisUpdateData.rules = JSON.stringify(data.rules);
    if (data.mapConfig != null) {
      redisUpdateData.map_config = JSON.stringify(data.mapConfig);
    }
    if (Object.keys(redisUpdateData).length > 0) {
      await this.redisService.hset(`game:${matchId}:state`, redisUpdateData);
    }

    const payload = {
      matchId,
      mode: updatedMatch.mode,
      maxPlayers: updatedMatch.maxPlayers,
      timeLimit: updatedMatch.timeLimit,
      rules: updatedMatch.rules,
      mapConfig: updatedMatch.mapConfig,
      updatedSettings: {
        mode: updatedMatch.mode,
        maxPlayers: updatedMatch.maxPlayers,
        timeLimit: updatedMatch.timeLimit,
        rules: updatedMatch.rules,
        mapConfig: updatedMatch.mapConfig,
      },
    };
    this.server.to(matchId).emit('settings_updated', payload);
    return { event: 'settings_updated', data: payload };
  }

  @SubscribeMessage('watch_ping')
  handleWatchPing(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId?: string; timestamp?: number },
  ) {
    const matchId = this.resolveMatchId(client, data.matchId);
    const userId = client.data.userId?.toString();
    const payload = {
      matchId,
      userId,
      timestamp: data.timestamp ?? Date.now(),
    };

    this.logger.log(`Watch ping received from ${userId} in room ${matchId}`);
    return { event: 'watch_ping', data: payload };
  }

  private async handleReadyUpdate(
    client: Socket,
    data: { matchId?: string; isReady?: boolean; ready?: boolean },
  ) {
    const matchId = this.resolveMatchId(client, data.matchId);
    const userId = client.data.userId?.toString();
    if (!userId) {
      throw new UnauthorizedException('인증 정보가 없습니다.');
    }

    const nextReady = data.isReady ?? data.ready ?? false;
    const playerKey = `game:${matchId}:player:${userId}`;
    if (!(await this.redisService.exists(playerKey))) {
      throw new BadRequestException('참가자를 찾을 수 없습니다.');
    }
    await this.redisService.hset(playerKey, {
      ready: nextReady ? 'true' : 'false',
    });

    const payload = {
      userId,
      ready: nextReady,
      isReady: nextReady,
    };
    this.server.to(matchId).emit('ready_changed', payload);
    return { event: 'ready_changed', data: payload };
  }

  private async handleRoleUpdate(
    client: Socket,
    data: { matchId?: string; role?: string; team?: string },
  ) {
    const matchId = this.resolveMatchId(client, data.matchId);
    const userId = client.data.userId?.toString();
    if (!userId) {
      throw new UnauthorizedException('인증 정보가 없습니다.');
    }

    const requestedRole = (data.role ?? data.team ?? '').toUpperCase();
    if (requestedRole != 'POLICE' && requestedRole != 'THIEF') {
      throw new BadRequestException('유효하지 않은 역할입니다.');
    }

    const globalState = await this.redisService.hgetall(`game:${matchId}:state`);
    if (!globalState || globalState.game_status !== 'WAITING') {
      throw new BadRequestException('대기실에서만 역할을 변경할 수 있습니다.');
    }

    const playerKey = `game:${matchId}:player:${userId}`;
    if (!(await this.redisService.exists(playerKey))) {
      throw new BadRequestException('참가자를 찾을 수 없습니다.');
    }

    await this.redisService.hset(playerKey, { role: requestedRole, class: '' });
    const payload = {
      userId,
      role: requestedRole,
      team: requestedRole,
      newRole: requestedRole,
    };
    this.server.to(matchId).emit('role_changed', payload);
    this.server.to(matchId).emit('user_role_changed', payload);
    return { event: 'role_changed', data: payload };
  }

  private resolveMatchId(client: Socket, matchId?: string): string {
    if (matchId != null && matchId.length > 0) {
      return matchId;
    }

    const queryMatchId = client.handshake.query.matchId?.toString();
    if (queryMatchId != null && queryMatchId.length > 0) {
      return queryMatchId;
    }

    const joinedRoom =
      Array.from(client.rooms).find((roomId) => roomId !== client.id) ?? '';
    if (joinedRoom.length === 0) {
      throw new BadRequestException('매치 정보가 없습니다.');
    }
    return joinedRoom;
  }
}
