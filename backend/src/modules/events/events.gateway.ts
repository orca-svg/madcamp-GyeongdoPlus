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
import { Logger, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt'; // AuthModule의 JwtService 활용

@WebSocketGateway({
  cors: {
    origin: '*', // 실제 배포 시엔 프론트엔드 도메인으로 제한 필요
  },
  namespace: 'game', // URL: ws://localhost:3000/game
})
export class EventsGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer() server: Server;
  private logger: Logger = new Logger('EventsGateway');

  constructor(private readonly jwtService: JwtService) {}

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
      this.logger.error(`Connection error: ${error.message}`);
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
}