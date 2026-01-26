import { 
  Injectable, 
  BadRequestException, 
  NotFoundException,
  ForbiddenException
} from '@nestjs/common';
import { RedisService } from '../redis/redis.service';
import { PrismaService } from '../../database/prisma.service';
import { MoveDto, ArrestDto, RescueDto, UseAbilityDto, UseItemDto, EndGameDto, DelegateHostDto } from './game.dto';
import { generateRoomCode } from '../../common/utils/room-code.util';
import { Prisma } from '@prisma/client';

@Injectable()
export class GameService {
  constructor(
    private redisService: RedisService,
    private prisma: PrismaService,
  ) {}

  // 🏃 1. 위치 이동 (Response 보강)
  async updatePosition(userId: string, dto: MoveDto) {
    const { matchId, lat, lng, heartRate } = dto;

    // 1. Redis GEO & Hash 업데이트
    await this.redisService.geoadd(`game:${matchId}:geo`, lng, lat, userId);
    
    const updateData: Record<string, string | number> = {};
    if (heartRate) updateData.heart_rate = heartRate;
    await this.redisService.hset(`game:${matchId}:player:${userId}`, updateData);

    // [Response] 주변 이벤트나 아이템 정보를 계산해서 줄 수 있음 (지금은 빈 배열)
    return { 
      success: true, 
      message: '위치 업데이트 완료', 
      data: {
        nearbyEvents: [], 
      } 
    };
  }

  // 👮 2. 체포 요청 (Response 보강)
  async arrestPlayer(copId: string, dto: ArrestDto) {
    const { matchId, targetUserId } = dto;

    // 1. 거리 검증
    const distance = await this.redisService.geodist(
      `game:${matchId}:geo`, 
      copId, 
      targetUserId
    ); // (단위 생략 = m)

    if (distance === null) throw new NotFoundException('위치 정보를 찾을 수 없습니다.');
    if (distance > 1.5) {
      throw new BadRequestException({
        message: '거리가 너무 멉니다.',
        code: 'OUT_OF_RANGE',
        distance,
      });
    }

    // 2. 상태 변경 및 감옥 이동
    await this.redisService.hset(`game:${matchId}:player:${targetUserId}`, { status: 'ARRESTED' });
    await this.redisService.rpush(`game:${matchId}:prison_queue`, targetUserId);

    // 3. 현재 점수 계산 (Redis에서 가져오거나 계산)
    // const currentScore = await this.redisService.incr(`game:${matchId}:score:police`);
    const currentScore = 10; // (예시 값)

    return {
      success: true,
      message: '체포 성공!',
      data: {
        arrestedUser: targetUserId,
        distance: distance,
        currentScore: currentScore, // 현재 팀 점수 반환
      },
    };
  }

  // 🤝 3. 감옥 해방 요청 (FIFO / LIFO 로직 적용)
  async rescuePlayer(rescuerId: string, dto: RescueDto) {
    const { matchId } = dto;

    // 1. 게임 규칙(Rules) 조회
    const match = await this.prisma.gameMatch.findUnique({
      where: { id: matchId },
      select: { rules: true } // 규칙만 가져옴
    });

    if (!match) throw new NotFoundException('게임을 찾을 수 없습니다.');

    // 2. 정책 확인 (FIFO vs LIFO)
    const rules = match.rules as any; // JSON 타입 캐스팅
    const queuePolicy = rules?.jailRule?.rescue?.queuePolicy || 'FIFO'; // 기본값 FIFO

    // 3. 정책에 따라 감옥에서 꺼내기
    let rescuedUserId: string | null = null;
    const queueKey = `game:${matchId}:prison_queue`;

    if (queuePolicy === 'LIFO') {
      // LIFO: 나중에 들어온 사람부터 (Stack 구조) -> RPOP
      rescuedUserId = await this.redisService.rpop(queueKey);
    } else {
      // FIFO: 먼저 들어온 사람부터 (Queue 구조) -> LPOP
      rescuedUserId = await this.redisService.lpop(queueKey);
    }

    if (!rescuedUserId) {
      throw new BadRequestException('감옥이 비어있습니다.');
    }

    // 4. 상태 변경
    await this.redisService.hset(`game:${matchId}:player:${rescuedUserId}`, { status: 'ALIVE' });

    // 5. 남은 수감자 수
    const remainingPrisoners = await this.redisService.llen(queueKey);

    return {
      success: true,
      message: `동료를 구출했습니다! (${queuePolicy} 방식)`,
      data: {
        rescuedUserId,
        remainingPrisoners,
        policy: queuePolicy
      },
    };
  }

  // ⚡ 4. 능력 사용 (POST /game/action/ability)
  async useAbility(userId: string, dto:     UseAbilityDto) {
    const { matchId, skillType } = dto;

    // 1. 게임 모드 검증
    const mode = await this.redisService.hget(`game:${matchId}:state`, 'game_mode');
    if (mode !== 'ABILITY') {
      throw new BadRequestException('능력전 모드가 아닙니다.');
    }

    // 2. 스킬별 비용 및 쿨타임 정의 (상수로 관리 추천)
    const SKILL_COST = { DASH: 30, STEALTH: 50, SCAN: 40 };
    const cost = SKILL_COST[skillType];

    // 3. 게이지 확인 (Redis Hash)
    const playerKey = `game:${matchId}:player:${userId}`;
    const currentGaugeStr = await this.redisService.hget(playerKey, 'ability_gauge');
    const currentGauge = parseFloat(currentGaugeStr || '0');

    if (currentGauge < cost) {
      throw new BadRequestException({
        message: '게이지가 부족합니다.',
        code: 'NOT_ENOUGH_GAUGE',
        current: currentGauge,
        required: cost
      }); //
    }

    // 4. 게이지 차감 & 효과 적용
    const remainingGauge = await this.redisService.hincrby(playerKey, 'ability_gauge', -cost);
    
    // 효과 활성화 (예: 투명화)
    if (skillType === 'STEALTH') {
      // active_effects라는 JSON 필드를 업데이트하거나 별도 키 사용
      // 여기선 간단히 예시
      await this.redisService.hset(playerKey, { stealth_active: 'true' });
    }

    // 5. Socket Broadcast (Gateway에서 처리: "AbilityUsed")

    return {
      success: true,
      message: '스킬을 사용했습니다.',
      data: {
        skillType,
        remainingGauge,
        duration: 3, // 지속시간 (예시)
        cooldown: 10 // 쿨타임 (예시)
      }
    }; //
  }

  // 🎒 5. 아이템 사용 (POST /game/item/use)
  async useItem(userId: string, dto: UseItemDto) {
    const { matchId, itemId } = dto;
    const itemKey = `game:${matchId}:player:${userId}:items`; // 아이템은 별도 List로 관리 가정

    // 1. 보유 확인 및 차감
    // LREM: 리스트에서 해당 아이템 1개 삭제. 삭제된 개수가 반환됨.
    const removedCount = await this.redisService.lrem(itemKey, 1, itemId);
    
    if (removedCount === 0) {
      throw new BadRequestException('해당 아이템을 보유하고 있지 않습니다.');
    }

    // 2. 효과 적용 (Switch Case)
    switch (itemId) {
      case 'DECOY':
        // 현재 위치 가져오기
        const pos = await this.redisService.geopos(`game:${matchId}:geo`, userId);
        if (pos && pos[0]) {
          // 미끼 생성 (GEOADD)
          await this.redisService.geoadd(`game:${matchId}:geo`, parseFloat(pos[0][0]), parseFloat(pos[0][1]), `decoy:${userId}`);
        }
        break;
      case 'INVISIBLE':
        await this.redisService.hset(`game:${matchId}:player:${userId}`, { invisible: 'true' });
        break;
      case 'EMP':
        // Global State에 EMP 효과 등록
        await this.redisService.hset(`game:${matchId}:state`, { emp_active: 'true' });
        break;
      // ...
    }

    // 남은 아이템 목록 조회
    const remainingItems = await this.redisService.lrange(itemKey, 0, -1);

    return {
      success: true,
      message: '아이템을 사용했습니다.', //
      data: {
        remainingItems,
        effectDuration: 60
      }
    };
  }

  // 🔄 6. 게임 상태 동기화/재접속 (GET /game/sync/:matchId)
  async syncGameState(userId: string, matchId: string) {
    // 1. 유효성 검증
    const playerKey = `game:${matchId}:player:${userId}`;
    const exists = await this.redisService.exists(playerKey);
    if (!exists) throw new NotFoundException('참여 중인 게임이 아닙니다.');

    // 2. Redis 조회 (Global, Player, Queue)
    const globalState = await this.redisService.hgetall(`game:${matchId}:state`);
    const playerState = await this.redisService.hgetall(playerKey);
    const prisonQueue = await this.redisService.lrange(`game:${matchId}:prison_queue`, 0, -1);
    
    // 아이템 리스트 별도 조회
    const items = await this.redisService.lrange(`game:${matchId}:player:${userId}:items`, 0, -1);

    // 3. 응답 데이터 구성
    return {
      success: true,
      message: '게임 상태를 동기화했습니다.',
      data: {
        gameStatus: globalState.game_status || 'PLAYING',
        serverTime: new Date().toISOString(),
        startTime: globalState.start_time,
        timeLimit: parseInt(globalState.total_time || '600'),
        policeScore: parseInt(globalState.score_police || '0'),
        totalThiefCount: parseInt(globalState.total_thief_count || '0'),
        
        myState: {
          role: playerState.role,
          status: playerState.status,
          items: items,
          abilityGauge: parseFloat(playerState.ability_gauge || '0'),
          activeEffects: { 
            invisible: playerState.invisible === 'true',
            stealth: playerState.stealth_active === 'true' 
          }
        },
        
        prisonQueue: prisonQueue,
        shrinkingRadius: parseFloat(globalState.shrinking_radius || '1000')
      }
    };
  }

  // 🏁 1. 게임 종료 (POST /game/:matchId/end)
  async endGame(hostId: string, matchId: string, dto: EndGameDto) {
    // 1. 권한 확인
    const match = await this.prisma.gameMatch.findUnique({ where: { id: matchId } });
    if (!match) throw new NotFoundException('게임을 찾을 수 없습니다.');
    if (match.hostUserId !== hostId) {
      throw new ForbiddenException('방장만 게임을 종료할 수 있습니다.');
    }

    // 2. 데이터 이관 (Redis -> DB) 및 승패 판정
    // (간소화를 위해 MVP 로직 등은 예시로 작성합니다)
    const playerKeys = await this.redisService.keys(`game:${matchId}:player:*`);
    const records : any[] = [];

    let mvpUserId: string | null = null;
    let maxScore = -1;

    for (const key of playerKeys) {
      const userId = key.split(':').pop()!;
      const userData = await this.redisService.hgetall(key);
      const score = parseInt(userData.score || '0'); // 점수 기록 가정

      // MVP 선정 로직 (단순 점수 비교)
      if (score > maxScore) {
        maxScore = score;
        mvpUserId = userId;
      }

      records.push({
        userId,
        matchId,
        role: userData.role === 'POLICE' ? 'POLICE' : 'THIEF',
        result: 'WIN', // (실제론 팀 승패 로직 필요)
        catchCount: parseInt(userData.catchCount || '0'),
        contribution: score,
      });
    }

    // 2-1. MatchRecord 일괄 저장 (Transaction 권장)
    // await this.prisma.matchRecord.createMany({ data: records }); 
    // (Prisma createMany는 일부 DB에서 제한될 수 있으니 loop나 transaction 사용)
    for (const r of records) {
        await this.prisma.matchRecord.create({ data: r as any });
    }

    // 2-2. GameMatch 업데이트
    const endTime = new Date();
    const startTime = match.startedAt || match.createdAt;
    const playTime = Math.floor((endTime.getTime() - startTime.getTime()) / 1000);

    const updatedMatch = await this.prisma.gameMatch.update({
      where: { id: matchId },
      data: {
        status: 'ENDED',
        endedAt: endTime,
        winnerTeam: 'POLICE', // (예시)
        mvpUserId: mvpUserId
      }
    });

    // 3. 청소: Redis 만료 처리
    // 관련된 모든 키에 TTL 설정 (바로 삭제하기보다 1시간 뒤 만료 추천)
    const allKeys = await this.redisService.keys(`game:${matchId}:*`);
    for (const key of allKeys) {
      await this.redisService.expire(key, 3600); 
    }

    // 4. 알림: Socket Broadcast (Gateway에서 "game_over" 전송)

    return {
      success: true,
      message: '게임이 종료되고 기록이 저장되었습니다.',
      data: {
        matchId,
        playTime: playTime,
        winnerTeam: updatedMatch.winnerTeam,
        mvpUser: { userId: mvpUserId }, // 상세 정보는 User 테이블 조회 필요
        resultReport: { totalCatch: 5, totalDistance: 12.5 } //
      }
    };
  }

  // 🔄 2. 게임 다시 하기 (POST /game/:matchId/rematch)
  async rematch(userId: string, oldMatchId: string) {
    // 1. 이전 설정 조회
    const oldMatch = await this.prisma.gameMatch.findUnique({ where: { id: oldMatchId } });
    if (!oldMatch) throw new NotFoundException('이전 게임 기록이 없습니다.');

    // 2. 방 코드 생성 (중복 체크)
    let roomCode = generateRoomCode();
    // (실제론 while loop로 중복 체크 필요)

    // 3. 새 게임 생성
    const newMatch = await this.prisma.gameMatch.create({
      data: {
        hostUserId: userId, // 요청한 사람이 새 방장
        roomCode: roomCode,
        status: 'WAITING',
        mode: oldMatch.mode,
        mapConfig: oldMatch.mapConfig as Prisma.InputJsonValue,
        rules: oldMatch.rules as Prisma.InputJsonValue,
        maxPlayers: oldMatch.maxPlayers,
        timeLimit: oldMatch.timeLimit
      }
    });

    // 4. 응답
    return {
      success: true,
      message: '새로운 대기실이 생성되었습니다.',
      data: {
        newMatchId: newMatch.id,
        roomCode: newMatch.roomCode,
        hostUserId: newMatch.hostUserId,
        mode: newMatch.mode,
        status: newMatch.status
      }
    };
  }

  // 👑 3. 방장 위임 (PATCH /game/:matchId/host)
  async delegateHost(currentHostId: string, matchId: string, dto: DelegateHostDto) {
    // 1. 권한 검증
    const match = await this.prisma.gameMatch.findUnique({ where: { id: matchId } });
    if (!match) throw new NotFoundException('게임을 찾을 수 없습니다.');
    if (match.hostUserId !== currentHostId) {
      throw new ForbiddenException('방장만 권한을 위임할 수 있습니다.');
    }

    // 2. 대상 검증 (Redis에 존재하는 유저인지)
    const targetKey = `game:${matchId}:player:${dto.targetUserId}`;
    const targetExists = await this.redisService.exists(targetKey);
    if (!targetExists) {
      throw new BadRequestException('해당 유저가 방에 존재하지 않습니다.');
    }

    // 3. DB 업데이트
    await this.prisma.gameMatch.update({
      where: { id: matchId },
      data: { hostUserId: dto.targetUserId }
    });

    // 4. Redis 업데이트 (선택 사항: is_host 필드 관리 시 필요)
    await this.redisService.hset(`game:${matchId}:player:${currentHostId}`, { is_host: 'false' });
    await this.redisService.hset(targetKey, { is_host: 'true' });

    // 5. 알림: Socket Broadcast ("host_changed")

    return {
      success: true,
      message: '방장이 변경되었습니다.',
      data: {
        matchId,
        previousHostId: currentHostId,
        newHostId: dto.targetUserId
      }
    }; //
  }

  // 🚪 4. 방 퇴장 (POST /game/:matchId/leave)
  async leaveGame(userId: string, matchId: string) {
    // 1. 공통 처리: Redis 삭제
    const playerKey = `game:${matchId}:player:${userId}`;
    const exists = await this.redisService.exists(playerKey);
    // (이미 나간 경우도 성공 처리하거나 에러 처리, 여기선 진행)
    
    await this.redisService.del(playerKey);
    // GEO 정보 삭제 (만약 ZSET 사용 중이라면)
    await this.redisService.zrem(`game:${matchId}:geo`, userId);

    // 2. 상태별 분기
    const match = await this.prisma.gameMatch.findUnique({ where: { id: matchId } });
    if (!match) throw new NotFoundException('방이 존재하지 않습니다.');

    let penaltyApplied = false;
    if (match.status === 'PLAYING') {
      // 탈주 패널티 로직 (MMR 차감 등)
      penaltyApplied = true; 
    }

    // 3. 방장 자동 위임 (통합 로직)
    let newHostId: string | null = null;
    
    if (match.hostUserId === userId) {
      // 남은 유저 찾기
      const remainingKeys = await this.redisService.keys(`game:${matchId}:player:*`);
      
      if (remainingKeys.length > 0) {
        // 가장 먼저 들어온 사람(혹은 랜덤)에게 위임. 
        // keys 순서는 보장 안 되지만 임의로 첫 번째 선택
        const nextUserKey = remainingKeys[0]; 
        newHostId = nextUserKey.split(':').pop()!;

        await this.prisma.gameMatch.update({
          where: { id: matchId },
          data: { hostUserId: newHostId }
        });
        
        await this.redisService.hset(nextUserKey, { is_host: 'true' });
        // Socket: "host_changed" 알림
      } else {
        // 남은 사람 없으면 방 삭제(대기중) 또는 종료(게임중)
        if (match.status === 'WAITING') {
          await this.prisma.gameMatch.delete({ where: { id: matchId } });
          await this.redisService.del(`game:${matchId}:state`);
        } else {
           await this.prisma.gameMatch.update({
             where: { id: matchId }, 
             data: { status: 'ENDED', endedAt: new Date() }
           });
        }
      }
    }

    // 4. 응답
    return {
      success: true,
      message: '방에서 퇴장했습니다.',
      data: {
        matchId,
        leftUserId: userId,
        newHostId, // 위임 발생 시 ID, 없으면 null
        penaltyApplied
      }
    };
  }
}