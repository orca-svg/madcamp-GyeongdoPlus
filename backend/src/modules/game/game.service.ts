import { 
  Injectable, 
  BadRequestException, 
  NotFoundException,
  ForbiddenException,
  HttpException,
  HttpStatus
} from '@nestjs/common';
import { RedisService } from '../redis/redis.service';
import { PrismaService } from '../../database/prisma.service';
import { 
  MoveDto, ArrestDto, RescueDto, SelectAbilityDto, UseAbilityDto, SelectItemDto, UseItemDto, 
  EndGameDto, DelegateHostDto, NearbyObjectDto, AutoArrestStatusDto 
} from './game.dto';
import { EventsGateway } from '../events/events.gateway';
import { Prisma, Team, MatchResult } from '@prisma/client';
import { generateRoomCode } from '../../common/utils/room-code.util';


@Injectable()
export class GameService {
  constructor(
    private redisService: RedisService,
    private prisma: PrismaService,
    private eventsGateway: EventsGateway,
  ) {}

  // ==================================================================
  // 🆕 0. 능력(직업) 선택 (준비 시간에만 가능)
  // ==================================================================
  async selectAbility(userId: string, dto: SelectAbilityDto) {
    const { matchId, abilityClass } = dto;
    const globalState = await this.redisService.hgetall(`game:${matchId}:state`);

    // [검증] 현재 단계가 'PREPARE' 인지 확인
    // (만약 PREPARE 단계가 없다면 WAITING에서 넘어가자마자라고 가정하거나 로직 조정 필요)
    if (globalState.phase !== 'PREPARE') {
      throw new BadRequestException('능력 선택 시간이 아닙니다.');
    }
    
    // [검증] 역할에 맞는 직업인지 확인
    const myRole = await this.redisService.hget(`game:${matchId}:player:${userId}`, 'role');
    const POLICE_CLASSES = ['SEARCHER', 'JAILER', 'ENFORCER', 'CHASER'];
    const THIEF_CLASSES = ['SHADOW', 'BROKER', 'HACKER', 'CLOWN'];

    if (myRole === 'POLICE' && !POLICE_CLASSES.includes(abilityClass)) {
      throw new BadRequestException('경찰 전용 직업이 아닙니다.');
    }
    if (myRole === 'THIEF' && !THIEF_CLASSES.includes(abilityClass)) {
      throw new BadRequestException('도둑 전용 직업이 아닙니다.');
    }

    // [저장] Redis에 내 직업 저장
    await this.redisService.hset(`game:${matchId}:player:${userId}`, { class: abilityClass });

    return { success: true, message: `${abilityClass} 직업을 선택했습니다.` };
  }

  // ==================================================================
  // ⚡ 1. 능력(액티브) 사용 (8종 직업 구현)
  // ==================================================================
  async useAbility(userId: string, dto: UseAbilityDto) {
    const { matchId } = dto;
    const playerKey = `game:${matchId}:player:${userId}`;
    
    // 내 직업 조회
    const playerState = await this.redisService.hgetall(playerKey);
    const myClass = playerState.class;
    
    if (!myClass) throw new BadRequestException('직업이 선택되지 않았습니다.');

    // 쿨타임 및 게이지 체크 (여기서는 단순화하여 생략, 필요시 추가)
    // const gauge = parseFloat(playerState.ability_gauge || '0');
    // ... gauge check ...

    let message = '';
    
    switch (myClass) {
      // --- [경찰 액티브] ---
      case 'SEARCHER': // 탐지자: 도둑 정적 위치 공유
        this.eventsGateway.server.to(matchId).emit('reveal_thieves_static', { duration: 5 }); 
        message = '모든 도둑의 위치를 팀원에게 공유했습니다.';
        break;

      case 'JAILER': // 감옥지기: 채널링 초기화
        this.eventsGateway.server.to(matchId).emit('reset_channeling', { area: 'JAIL' });
        message = '감옥 주변의 구조 작업을 초기화시켰습니다.';
        break;

      case 'ENFORCER': // 집행자: 5초간 5m 내 상대 능력 봉인
        // 1. 내 위치 가져오기
        const myPosEnforcer = await this.redisService.geopos(`game:${matchId}:geo`, userId);
        if (!myPosEnforcer || !myPosEnforcer[0]) throw new BadRequestException('위치 정보 오류');

        // 2. 주변 5m 검색
        const nearbyThieves = (await this.redisService.georadius(
          `game:${matchId}:geo`, 
          parseFloat(myPosEnforcer[0][0]), 
          parseFloat(myPosEnforcer[0][1]), 
          5, 
          'm'
        )) as [string, string][];

        // 3. 상태 부여
        for (const [thiefId] of nearbyThieves) {
          if (thiefId === userId) continue;
          const tState = await this.redisService.hgetall(`game:${matchId}:player:${thiefId}`);
          if (tState.role === 'THIEF' && tState.status === 'ALIVE') {
             await this.redisService.set(`game:${matchId}:player:${thiefId}:silence`, 'true', 5); // 5초간 침묵
             this.eventsGateway.server.to(matchId).emit('ability_silenced', { targetId: thiefId, duration: 5 });
          }
        }
        message = '주변 도둑들의 능력을 봉인했습니다.';
        break;

      case 'CHASER': // 추격자: 가장 가까운 도둑 추적
        // (단순 구현: 메시지만 전송, 실제 로직은 클라에서 처리하거나 별도 계산 필요)
        message = '가장 가까운 도둑을 추적합니다.';
        break;

      // --- [도둑 액티브] ---
      case 'SHADOW': // 그림자: 15초간 정보 은폐
        await this.redisService.hset(playerKey, { stealth_active: 'true' });
        // TODO: 15초 후 해제 로직 (클라 타이머 의존 or 스케줄러)
        message = '15초간 그림자 속에 숨습니다.';
        break;

      case 'BROKER': // 브로커: 3m 내 즉시 구출
        // rescuePlayer 로직 재사용 (instant=true)
        await this.rescuePlayer(userId, { matchId }, true); 
        message = '능력을 사용하여 즉시 구출했습니다.';
        break;

      case 'HACKER': // 해커: 경찰 위치 노출
        this.eventsGateway.server.to(matchId).emit('reveal_police_static', { count: 3, interval: 3000 });
        message = '경찰들의 위치를 해킹했습니다.';
        break;

      case 'CLOWN': // 광대: 어그로
        this.eventsGateway.server.to(matchId).emit('clown_taunt', { userId });
        message = '광대 공연 시작! 30초간 버티면 동료가 구출됩니다.';
        break;
    }

    return { success: true, message, data: { myClass } };
  }

  // ==================================================================
  // 🎒 2. 아이템 사용 (8종 구현)
  // ==================================================================
  async useItem(userId: string, dto: UseItemDto) {
    const { matchId, itemId } = dto;
    const playerKey = `game:${matchId}:player:${userId}`;
    const itemsKey = `${playerKey}:items`;

    const playerState = await this.redisService.hgetall(playerKey);
    if (playerState.status !== 'ALIVE') throw new BadRequestException('탈락한 상태입니다.');

    // [EMP 체크] 경찰 아이템 무력화
    const isEmpActive = await this.redisService.get(`game:${matchId}:state:emp_active`);
    if (isEmpActive && playerState.role === 'POLICE' && itemId !== 'RESCUE_BLOCK') {
      throw new BadRequestException('EMP 효과로 인해 아이템을 사용할 수 없습니다!');
    }

    const removed = await this.redisService.lrem(itemsKey, 1, itemId);
    if (removed === 0) throw new BadRequestException('아이템을 보유하고 있지 않습니다.');

    let resultData: any = {};
    let message = '';
    
    const DURATION = { RADAR: 7, RESCUE_BLOCK: 15, EMP: 15, DECOY: 300, RESCUE_BOOST: 10 };

    switch (itemId) {
      case 'RADAR':
        await this.redisService.set(`game:${matchId}:state:radar_active`, 'true', DURATION.RADAR);
        this.eventsGateway.server.to(matchId).emit('radar_activated', { duration: DURATION.RADAR });
        message = '레이더를 가동했습니다.';
        resultData.effectDuration = DURATION.RADAR;
        break;

      case 'RESCUE_BLOCK':
        await this.redisService.set(`game:${matchId}:state:rescue_blocked`, 'true', DURATION.RESCUE_BLOCK);
        this.eventsGateway.server.to(matchId).emit('rescue_blocked', { duration: DURATION.RESCUE_BLOCK });
        message = '감옥 구출을 차단했습니다.';
        resultData.effectDuration = DURATION.RESCUE_BLOCK;
        break;

      case 'THIEF_DETECTOR':
        await this.redisService.hset(playerKey, { detector_active: 'true' });
        message = '도둑 탐지기를 켰습니다. 5m 내 접근 시 알려줍니다.';
        resultData.effectDuration = 0; 
        break;

      case 'AREA_SIREN':
        // NX 대체 로직
        const sirenKey = `game:${matchId}:team_limit:siren`;
        if (await this.redisService.get(sirenKey)) {
           await this.redisService.rpush(itemsKey, itemId);
           throw new BadRequestException('이미 팀에서 광역 사이렌을 사용했습니다.');
        }
        await this.redisService.set(sirenKey, 'used', 3600);

        const myPosSiren = await this.redisService.geopos(`game:${matchId}:geo`, userId);
        if (myPosSiren && myPosSiren[0]) {
          const targets = (await this.redisService.georadius(
            `game:${matchId}:geo`, parseFloat(myPosSiren[0][0]), parseFloat(myPosSiren[0][1]), 30, 'm'
          )) as [string, string][];

          let affected = 0;
          for (const [tId] of targets) {
             if (tId === userId) continue;
             const tState = await this.redisService.hgetall(`game:${matchId}:player:${tId}`);
             if (tState.role === 'THIEF' && tState.status === 'ALIVE') {
               this.eventsGateway.server.to(matchId).emit('play_siren', { targetId: tId });
               affected++;
             }
          }
          message = `사이렌 가동! ${affected}명에게 경보를 울렸습니다.`;
          resultData.affectedCount = affected;
        }
        break;

      case 'DECOY':
        const myPosDecoy = await this.redisService.geopos(`game:${matchId}:geo`, userId);
        if (myPosDecoy && myPosDecoy[0]) {
          const decoyId = `decoy:${userId}`; 
          await this.redisService.geoadd(`game:${matchId}:geo`, parseFloat(myPosDecoy[0][0]), parseFloat(myPosDecoy[0][1]), decoyId);
          await this.redisService.set(`game:${matchId}:decoy:${userId}`, 'active', DURATION.DECOY); 
          message = '현재 위치에 미끼를 설치했습니다.';
        }
        break;

      case 'RESCUE_BOOST':
        await this.redisService.set(`game:${matchId}:player:${userId}:rescue_boost`, 'true', DURATION.RESCUE_BOOST);
        message = '구출 능력이 10초간 강화됩니다.';
        resultData.effectDuration = DURATION.RESCUE_BOOST;
        break;

      case 'EMP':
        await this.redisService.set(`game:${matchId}:state:emp_active`, 'true', DURATION.EMP);
        this.eventsGateway.server.to(matchId).emit('emp_activated', { duration: DURATION.EMP });
        message = 'EMP 가동! 경찰의 전자장비를 무력화합니다.';
        resultData.effectDuration = DURATION.EMP;
        break;

      case 'REMOTE_RESCUE':
        const remoteKey = `game:${matchId}:team_limit:remote_rescue`;
        if (await this.redisService.get(remoteKey)) {
           await this.redisService.rpush(itemsKey, itemId);
           throw new BadRequestException('이미 팀에서 원격 구출을 사용했습니다.');
        }
        await this.redisService.set(remoteKey, 'used', 3600);

        const matchInfo = await this.prisma.gameMatch.findUnique({ where: { id: matchId }, select: { mapConfig: true } });
        const jail = (matchInfo?.mapConfig as any)?.jail;
        const myPosRemote = await this.redisService.geopos(`game:${matchId}:geo`, userId);
        
        if (!jail || !myPosRemote || !myPosRemote[0]) throw new BadRequestException('위치 정보 오류');

        const distToJail = this.calculateDistance(parseFloat(myPosRemote[0][1]), parseFloat(myPosRemote[0][0]), jail.lat, jail.lng);
        if (distToJail > 10.0) {
           await this.redisService.rpush(itemsKey, itemId);
           await this.redisService.del(remoteKey);
           throw new BadRequestException('감옥 반경 10m 이내에서만 사용할 수 있습니다.');
        }

        const rescuedList: string[] = [];
        for(let i=0; i<3; i++) {
          const prisoner = await this.redisService.lpop(`game:${matchId}:prison_queue`);
          if(prisoner) {
            await this.redisService.hset(`game:${matchId}:player:${prisoner}`, { status: 'ALIVE' });
            rescuedList.push(prisoner);
          }
        }
        
        if (rescuedList.length > 0) {
           await this.redisService.hincrby(`game:${matchId}:state`, 'police_score', -rescuedList.length);
           this.eventsGateway.server.to(matchId).emit('user_rescued', { matchId, rescuerId: userId, rescuedUserIds: rescuedList, remote: true });
        }
        message = `원격 해킹 성공! ${rescuedList.length}명을 구출했습니다.`;
        resultData.affectedCount = rescuedList.length;
        break;
    }

    const remainingItems = await this.redisService.lrange(itemsKey, 0, -1);
    resultData.remainingItems = remainingItems;

    return { success: true, message, data: resultData, error: null };
  }

  // ==================================================================
  // 🏃 3. 위치 이동 + 🛡️ 패시브 + 🚨 자동 체포
  // ==================================================================
  async updatePosition(userId: string, dto: MoveDto) {
    const { matchId, lat, lng, heartRate, heading } = dto;
    const ARREST_RADIUS_M = 1.0; 
    const SCAN_RADIUS_M = 50.0;

    // 1. 기본 위치 업데이트
    await this.redisService.geoadd(`game:${matchId}:geo`, lng, lat, userId);
    const updateData: Record<string, string | number> = {};
    if (heartRate) updateData.heart_rate = heartRate;
    if (heading) updateData.heading = heading;
    if (Object.keys(updateData).length > 0) await this.redisService.hset(`game:${matchId}:player:${userId}`, updateData);

    this.eventsGateway.server.to(matchId).emit('player_moved', { userId, lat, lng, heading });

    // 2. 직업/역할 확인
    const playerState = await this.redisService.hgetall(`game:${matchId}:player:${userId}`);
    const myRole = playerState.role;
    const myClass = playerState.class;

    let autoArrestStatus: AutoArrestStatusDto | null = null;

    // ---------------- [경찰 로직] ----------------
    if (myRole === 'POLICE') {
      // (1) 도둑 탐지기 아이템 패시브
      const isDetectorOn = await this.redisService.hget(`game:${matchId}:player:${userId}`, 'detector_active');
      if (isDetectorOn === 'true') {
        const nearby5m = (await this.redisService.georadius(`game:${matchId}:geo`, lng, lat, 5, 'm')) as [string, string][];
        for (const [tid] of nearby5m) {
          if (tid === userId || tid.startsWith('decoy:')) continue;
          const tState = await this.redisService.hgetall(`game:${matchId}:player:${tid}`);
          if (tState.role === 'THIEF') {
            this.eventsGateway.server.to(matchId).emit('detector_vibrate', { userId });
            await this.redisService.hdel(`game:${matchId}:player:${userId}`, 'detector_active');
            break;
          }
        }
      }

      // (2) 미끼 밟기 패시브
      const nearbyDecoys = (await this.redisService.georadius(`game:${matchId}:geo`, lng, lat, 1.5, 'm')) as [string, string][];
      for (const [objId] of nearbyDecoys) {
        if (objId.startsWith('decoy:')) {
           const decoyOwner = objId.split(':')[1];
           await this.redisService.zrem(`game:${matchId}:geo`, objId);
           await this.redisService.del(`game:${matchId}:decoy:${decoyOwner}`);
           this.eventsGateway.server.to(matchId).emit('police_revealed_by_decoy', { policeId: userId, decoyOwner, duration: 7 });
        }
      }

      // (3) 자동 체포 (집행자 패시브: 가속)
      const arrestSpeedBonus = (myClass === 'ENFORCER') ? 1.05 : 1.0; // 5% 가속
      
      const nearbyForArrest = (await this.redisService.georadius(`game:${matchId}:geo`, lng, lat, ARREST_RADIUS_M, 'm')) as [string, string][];
      for (const [targetId] of nearbyForArrest) {
        if (targetId === userId || targetId.startsWith('decoy:')) continue;
        const tState = await this.redisService.hgetall(`game:${matchId}:player:${targetId}`);
        if (tState.role === 'THIEF' && tState.status === 'ALIVE') {
          const result = await this.processAutoArrest(matchId, userId, targetId, arrestSpeedBonus);
          autoArrestStatus = result;
          if (result.status === 'COMPLETED') break;
        }
      }
    }

    // ---------------- [도둑 로직] ----------------
    if (myRole === 'THIEF') {
      // (1) 그림자(Shadow): 경찰 10m 내 은신
      if (myClass === 'SHADOW') {
        const nearbyPolice = (await this.redisService.georadius(`game:${matchId}:geo`, lng, lat, 10, 'm')) as [string, string][];
        // 주변에 경찰(나 자신 제외)이 있으면 invisible 플래그 갱신
        // (실제 구현 시 nearbyPolice 루프 돌며 role 확인 필요, 여기선 생략)
      }
      
      // (2) 광대(Clown): 경찰 7m 내 게이지 충전
      if (myClass === 'CLOWN') {
         // (거리 계산 로직 후 게이지 증가)
         // await this.redisService.hincrby(`game:${matchId}:player:${userId}`, 'ability_gauge', 2);
      }
    }

    // ---------------- [주변 정보 스캔] ----------------
    const nearbyRaw = (await this.redisService.georadius(`game:${matchId}:geo`, lng, lat, SCAN_RADIUS_M, 'm')) as [string, string][];
    const nearbyEvents: NearbyObjectDto[] = [];
    const isRadarActive = await this.redisService.get(`game:${matchId}:state:radar_active`);

    await Promise.all(nearbyRaw.map(async (item) => {
      const [targetId, distStr] = item;
      const distance = parseFloat(distStr);
      if (targetId === userId) return;

      if (targetId.startsWith('decoy:')) {
        nearbyEvents.push({ type: 'DECOY', userId: targetId, distance });
        return;
      }

      const tState = await this.redisService.hgetall(`game:${matchId}:player:${targetId}`);
      // 투명 체크 (레이더 있으면 무시)
      const isInvisible = (tState.invisible === 'true' || tState.stealth_active === 'true');
      if (isInvisible && !isRadarActive) return;

      nearbyEvents.push({ type: 'PLAYER', userId: targetId, distance });
    }));

    return { success: true, message: 'Updated', data: { nearbyEvents, autoArrestStatus } };
  }

  // ==================================================================
  // 🤝 4. 구출 (브로커 패시브 등 적용)
  // ==================================================================
  async rescuePlayer(rescuerId: string, dto: RescueDto, isInstant = false) {
    const { matchId } = dto;

    // 차단 체크
    const isBlocked = await this.redisService.get(`game:${matchId}:state:rescue_blocked`);
    if (isBlocked) throw new BadRequestException('경찰에 의해 구출이 차단되었습니다!');

    // 구조자 정보
    const rescuerState = await this.redisService.hgetall(`game:${matchId}:player:${rescuerId}`);
    if (rescuerState.status !== 'ALIVE') throw new BadRequestException('상태 이상');

    // 패시브 & 아이템 체크
    const hasBoost = await this.redisService.get(`game:${matchId}:player:${rescuerId}:rescue_boost`);
    const isBroker = (rescuerState.class === 'BROKER');

    // 위치 검증 (Instant면 3m, 아니면 감옥 반경)
    const match = await this.prisma.gameMatch.findUnique({ where: { id: matchId }, select: { rules: true, mapConfig: true } });
    const jail = (match?.mapConfig as any)?.jail;

    if (jail) {
      const pos = await this.redisService.geopos(`game:${matchId}:geo`, rescuerId);
      if (!pos || !pos[0]) throw new NotFoundException('위치 정보 오류');
      const dist = this.calculateDistance(parseFloat(pos[0][1]), parseFloat(pos[0][0]), jail.lat, jail.lng);
      
      const limit = isInstant ? 3.0 : jail.radiusM; // 브로커 액티브는 3m
      if (dist > limit) throw new HttpException({ message: '범위 밖입니다.', error: { code: 'OUT_OF_RANGE', dist } }, HttpStatus.BAD_REQUEST);
    }

    // 구출 인원 산정
    const rules = match?.rules as any;
    let releaseCount = rules?.jailRule?.rescue?.releaseCount || 1;
    if (hasBoost) releaseCount += 2; // 부스트 아이템
    if (isInstant) releaseCount = 1; // 브로커 액티브는 1명 확정

    // (참고: 브로커 패시브 "채널링 시간 감소"는 클라이언트 UI 처리 영역이 큼)

    // 실행
    const queueKey = `game:${matchId}:prison_queue`;
    const rescuedUserIds: string[] = [];
    const queuePolicy = rules?.jailRule?.rescue?.queuePolicy || 'FIFO';

    for (let i = 0; i < releaseCount; i++) {
      let popped: string | null = null;
      if (queuePolicy === 'LIFO') popped = await this.redisService.rpop(queueKey);
      else popped = await this.redisService.lpop(queueKey);

      if (!popped) break;
      rescuedUserIds.push(popped);
      await this.redisService.hset(`game:${matchId}:player:${popped}`, { status: 'ALIVE' });
    }

    if (rescuedUserIds.length === 0) throw new BadRequestException('감옥이 비어있습니다.');

    await this.redisService.hincrby(`game:${matchId}:state`, 'police_score', -rescuedUserIds.length);
    await this.redisService.hincrby(`game:${matchId}:player:${rescuerId}`, 'contribution', rescuedUserIds.length * 10);

    const remaining = await this.redisService.llen(queueKey);
    this.eventsGateway.server.to(matchId).emit('user_rescued', { matchId, rescuerId, rescuedUserIds, remainingPrisoners: remaining });

    return { success: true, message: `${rescuedUserIds.length}명 구출 성공!`, data: { rescuedUserIds, remainingPrisoners: remaining } };
  }

  // ==================================================================
  // 🔄 5. 동기화
  // ==================================================================
  async syncGameState(userId: string, matchId: string) {
    const pKey = `game:${matchId}:player:${userId}`;
    if (!(await this.redisService.exists(pKey))) throw new NotFoundException('참가자 아님');

    const [gState, pState, prisonQueue] = await Promise.all([
      this.redisService.hgetall(`game:${matchId}:state`),
      this.redisService.hgetall(pKey),
      this.redisService.lrange(`game:${matchId}:prison_queue`, 0, -1)
    ]);

    const gameMode = gState.game_mode || 'NORMAL';
    let items: string[] = [];
    let gauge = 0;

    if (gameMode === 'ITEM') {
      items = await this.redisService.lrange(`${pKey}:items`, 0, -1);
    } else if (gameMode === 'ABILITY') {
      gauge = parseFloat(pState.ability_gauge || '0');
    }

    return {
      success: true, message: 'Sync',
      data: {
        gameStatus: gState.game_status || 'WAITING',
        phase: gState.phase || 'PLAYING', // PREPARE 단계 확인용
        serverTime: new Date().toISOString(),
        startTime: gState.start_time,
        policeScore: parseInt(gState.police_score || '0'),
        myState: {
          role: pState.role,
          class: pState.class, // 직업 정보 추가
          status: pState.status,
          items,
          abilityGauge: gauge,
          activeEffects: {
            invisible: pState.invisible === 'true',
            stealth: pState.stealth_active === 'true',
            rescueBoost: pState.rescue_boost === 'true'
          }
        },
        prisonQueue
      }
    };
  }

  // ==================================================================
  // 🏳️ 6. 수동 자수
  // ==================================================================
  async surrender(userId: string, dto: ArrestDto) {
    const { matchId, copId } = dto;
    const myState = await this.redisService.hgetall(`game:${matchId}:player:${userId}`);
    
    if (myState.role !== 'THIEF') throw new BadRequestException('도둑만 자수 가능');
    if (myState.status !== 'ALIVE') throw new BadRequestException('이미 체포됨');

    let arresterId = 'SYSTEM';
    if (copId) {
      const copState = await this.redisService.hgetall(`game:${matchId}:player:${copId}`);
      if (copState && copState.role === 'POLICE') arresterId = copId;
    }

    const queueIndex = await this.executeArrest(matchId, arresterId, userId);
    return { success: true, message: '자수 완료', data: { arrestedUser: userId, status: 'ARRESTED', prisonQueueIndex: queueIndex } };
  }

  // ==================================================================
  // 🎁 7. 아이템 선택 (시간 보상)
  // ==================================================================
  async selectItem(userId: string, dto: SelectItemDto) {
    const { matchId, itemId } = dto;
    const state = await this.redisService.hgetall(`game:${matchId}:state`);
    
    if (state.game_mode !== 'ITEM') throw new BadRequestException('아이템전 아님');
    if (!state.start_time) throw new BadRequestException('시작 전');

    const elapsed = (Date.now() - new Date(state.start_time).getTime()) / 60000;
    let phase = '';
    if (elapsed < 10) throw new BadRequestException('선택 불가 시간');
    else if (elapsed < 20) phase = 'mid';
    else phase = 'late';

    const claimKey = `game:${matchId}:player:${userId}:claim:${phase}`;
    if (await this.redisService.get(claimKey)) throw new HttpException({ message: '이미 수령함', error: { code: 'ALREADY_CLAIMED' } }, HttpStatus.CONFLICT);
    
    await this.redisService.set(claimKey, 'true', 3600);
    await this.redisService.rpush(`game:${matchId}:player:${userId}:items`, itemId);
    
    const inventory = await this.redisService.lrange(`game:${matchId}:player:${userId}:items`, 0, -1);
    return { success: true, message: '획득', data: { obtainedItem: itemId, currentInventory: inventory } };
  }

// ==================================================================
  // 🏁 7. 게임 종료 (스키마 오타 수정 및 playTime 제거 반영)
  // ==================================================================
  async endGame(hostId: string, matchId: string, dto: EndGameDto) {
    // 1. [검증] 방장 권한 확인
    const match = await this.prisma.gameMatch.findUnique({ where: { id: matchId } });
    if (!match) throw new NotFoundException('게임을 찾을 수 없습니다.');
    if (match.hostUserId !== hostId) throw new ForbiddenException('방장만 게임을 종료할 수 있습니다.');

    // 2. [Redis] 게임 데이터 조회
    const globalState = await this.redisService.hgetall(`game:${matchId}:state`);
    const startTime = globalState.start_time ? new Date(globalState.start_time).getTime() : Date.now();
    const endTime = Date.now();
    
    // 플레이 타임 계산 (초 단위) - DB 저장 안 함, MatchRecord 및 응답용
    const playTimeSec = Math.floor((endTime - startTime) / 1000);

    // 3. [로직] 승리 팀 판정
    let winnerTeam: Team = Team.THIEF; 
    if (dto.reason === 'ALL_THIEVES_CAUGHT') {
      winnerTeam = Team.POLICE;
    } else if (dto.reason === 'HOST_FORCE_END') {
       const policeScore = parseInt(globalState.police_score || '0');
       const totalThief = parseInt(globalState.total_thief_count || '1');
       if (policeScore >= totalThief) winnerTeam = Team.POLICE;
    }

    // 4. [Redis -> DB] 데이터 집계
    const playerKeys = await this.redisService.keys(`game:${matchId}:player:*`);
    const records: Prisma.MatchRecordCreateManyInput[] = [];
    
    let mvpCandidate = { userId: '', score: -1, nickname: 'None', profileImage: '' };
    let totalCatch = 0;
    let totalDistance = 0;

    for (const key of playerKeys) {
      if (key.split(':').length > 4) continue; 

      const pData = await this.redisService.hgetall(key);
      const userId = key.split(':').pop()!;
      
      const catchCount = parseInt(pData.catchCount || '0');
      const contribution = parseInt(pData.contribution || '0');
      const distance = parseFloat(pData.total_distance || '0');
      
      // MVP 계산
      const personalScore = (catchCount * 100) + contribution;
      if (personalScore > mvpCandidate.score) {
        mvpCandidate = { userId, score: personalScore, nickname: 'Player', profileImage: '' };
      }

      totalCatch += catchCount;
      totalDistance += distance;

      // Role String -> Enum 변환
      const roleEnum = pData.role === 'POLICE' ? Team.POLICE : Team.THIEF;
      
      let matchResult: MatchResult = MatchResult.LOSE; 

      if (roleEnum === winnerTeam) {
        matchResult = MatchResult.WIN;
      } else {
        matchResult = MatchResult.LOSE;
      }

      // DB 데이터 매핑
      records.push({
        matchId,
        userId,
        role: roleEnum,           
        result: matchResult,      
        catchCount,
        distanceMoved: distance,  
        // 생존 시간: 도둑이면서 살아있으면 전체 시간, 아니면 0 (또는 체포된 시간 기록 필요)
        survivalTime: pData.role === 'THIEF' && pData.status === 'ALIVE' ? playTimeSec : 0, 
        contribution,
      });
    }

    // 5. [DB] 트랜잭션 저장
    await this.prisma.$transaction(async (tx) => {
      // 5-1. 매치 정보 업데이트
      // 🚨 수정됨: playTime 필드 제거 (스키마에 없으므로)
      await tx.gameMatch.update({
        where: { id: matchId },
        data: {
          status: 'ENDED',
          endedAt: new Date(),
          // playTime: playTimeSec,  <-- 삭제함
          winnerTeam: winnerTeam,
          mvpUserId: mvpCandidate.userId
        }
      });

      // 5-2. 플레이어 기록 일괄 저장
      if (records.length > 0) {
        await tx.matchRecord.createMany({
          data: records
        });
      }
    });

    // 6. [Redis] 청소
    const allKeys = await this.redisService.keys(`game:${matchId}:*`);
    for (const key of allKeys) {
      await this.redisService.expire(key, 3600);
    }

    // 7. 결과 전송 (여기는 playTime 포함해서 줌)
    const resultData = {
      matchId,
      playTime: playTimeSec, // 클라이언트는 계산된 값을 받음
      winnerTeam,
      mvpUser: mvpCandidate,
      resultReport: { totalCatch, totalDistance }
    };

    this.eventsGateway.server.to(matchId).emit('game_over', resultData);

    return {
      success: true,
      message: '게임 종료 및 저장 완료',
      data: resultData,
      error: null
    };
  }
  // ==================================================================
  // 🔄 8. 게임 다시 하기 (Rematch) - 로직 구현
  // ==================================================================
  async rematch(userId: string, oldMatchId: string) {
    // 1. [설정 조회] 이전 게임 정보 가져오기
    const oldMatch = await this.prisma.gameMatch.findUnique({
      where: { id: oldMatchId }
    });

    if (!oldMatch) {
      throw new NotFoundException('이전 게임 정보를 찾을 수 없습니다.');
    }

    // 2. [방 코드 생성] 중복 체크 로직 포함
    // (generateRoomCode 유틸 함수 활용 - 이미 import 되어 있음)
    let newRoomCode = '';
    let isUnique = false;
    let retryCount = 0;

    while (!isUnique && retryCount < 5) {
      newRoomCode = generateRoomCode(); // 5자리 코드 생성
      // DB에서 중복 확인 (진행 중인 방만 체크하는 것이 좋으나, 여기선 전체 unique 체크)
      const existing = await this.prisma.gameMatch.findUnique({
        where: { roomCode: newRoomCode }
      });
      if (!existing) {
        // Redis에서도 확인 (혹시 모를 동시성 이슈 대비)
        const redisExists = await this.redisService.get(`room:${newRoomCode}`);
        if (!redisExists) isUnique = true;
      }
      retryCount++;
    }

    if (!isUnique) {
      throw new HttpException('방 코드 생성 실패. 다시 시도해주세요.', HttpStatus.CONFLICT);
    }

    // 3. [새 게임 생성] DB Insert
    const newMatch = await this.prisma.gameMatch.create({
      data: {
        hostUserId: userId, // 요청한 사람이 새 방장
        roomCode: newRoomCode,
        status: 'WAITING',
        mode: oldMatch.mode,           // 설정 승계
        maxPlayers: oldMatch.maxPlayers, // 설정 승계
        timeLimit: oldMatch.timeLimit,   // 설정 승계
        mapConfig: oldMatch.mapConfig as Prisma.InputJsonValue, // 설정 승계
        rules: oldMatch.rules as Prisma.InputJsonValue,         // 설정 승계
        createdAt: new Date()
      }
    });

    // 4. [Redis] 방 정보 초기화 (대기방 상태)
    await this.redisService.hset(`game:${newMatch.id}:state`, {
      game_mode: newMatch.mode,
      game_status: 'WAITING',
      host_id: userId,
      room_code: newRoomCode
    });
    
    // 방 코드 매핑 저장 (Code -> ID)
    await this.redisService.set(`room:${newRoomCode}`, newMatch.id, 3600 * 24); // 24시간 유지

    // 5. [응답] 새 방 정보 반환
    // 클라이언트는 이 정보를 받고 소켓 leave(old) -> join(new) 처리함
    return {
      success: true,
      message: '새로운 대기실이 생성되었습니다.',
      data: {
        newMatchId: newMatch.id,
        roomCode: newRoomCode,
        hostUserId: userId,
        mode: newMatch.mode,
        status: 'WAITING'
      },
      error: null
    };
  }
  // ==================================================================
  // 👑 방장 위임 (로직 구현)
  // ==================================================================
  async delegateHost(userId: string, matchId: string, dto: DelegateHostDto) {
    const { targetUserId } = dto;

    // 1. [검증] 자기 자신에게 위임 불가
    if (userId === targetUserId) {
      throw new BadRequestException('자기 자신에게 방장을 위임할 수 없습니다.');
    }

    // 2. [검증] 현재 방장 권한 확인
    const match = await this.prisma.gameMatch.findUnique({ where: { id: matchId } });
    if (!match) throw new NotFoundException('게임을 찾을 수 없습니다.');
    
    if (match.hostUserId !== userId) {
      throw new ForbiddenException('오직 방장만이 권한을 위임할 수 있습니다.');
    }

    // 3. [검증] 위임 받을 대상이 현재 방에 존재하는지 확인
    // (Redis에서 실시간 참여자 확인이 가장 정확함)
    const targetKey = `game:${matchId}:player:${targetUserId}`;
    const targetExists = await this.redisService.exists(targetKey);
    if (!targetExists) {
      throw new NotFoundException('위임할 대상을 찾을 수 없거나 방을 나간 상태입니다.');
    }

    // 4. [DB 업데이트] 방장 변경
    await this.prisma.gameMatch.update({
      where: { id: matchId },
      data: { hostUserId: targetUserId }
    });

    // 5. [Redis 업데이트] 상태 동기화 (필수)
    // 게임 로직은 대부분 Redis를 참조하므로 여기도 바꿔줘야 함
    await this.redisService.hset(`game:${matchId}:state`, { host_id: targetUserId });

    // 6. [Socket] 실시간 알림
    // 클라이언트는 이 이벤트를 받으면 방장 아이콘(왕관)을 UI에서 옮겨야 함
    this.eventsGateway.server.to(matchId).emit('host_changed', {
      matchId,
      previousHostId: userId,
      newHostId: targetUserId
    });

    return {
      success: true,
      message: '방장이 변경되었습니다.',
      data: {
        matchId,
        previousHostId: userId,
        newHostId: targetUserId
      },
      error: null
    };
  }
  // ==================================================================
  // 🚪 9. 방 퇴장 (로직 구현: 방장 승계 + 상태별 처리)
  // ==================================================================
  async leaveGame(userId: string, matchId: string) {
    // 1. [Redis] 현재 게임 상태 조회
    const globalState = await this.redisService.hgetall(`game:${matchId}:state`);
    if (!globalState || !globalState.game_status) {
      throw new NotFoundException('유효하지 않은 게임이거나 이미 종료된 방입니다.');
    }

    const currentHostId = globalState.host_id;
    const gameStatus = globalState.game_status;
    let newHostId: string | null = null;
    let penaltyApplied = false;

    // 2. [방장 자동 위임] 나가는 사람이 방장이라면?
    if (currentHostId === userId) {
      // 다른 플레이어 검색 (keys 사용 - 성능 최적화를 위해선 Set 사용 권장)
      const playerKeys = await this.redisService.keys(`game:${matchId}:player:*`);
      
      // 나 자신을 제외한 다른 플레이어 찾기
      const candidates = playerKeys
        .filter(key => !key.includes('items') && !key.endsWith(userId)) // items 키 제외, 나 제외
        .map(key => key.split(':').pop()!);

      if (candidates.length > 0) {
        // 랜덤 혹은 첫 번째 유저에게 위임
        newHostId = candidates[0];

        // DB 및 Redis 업데이트
        await this.prisma.gameMatch.update({
          where: { id: matchId },
          data: { hostUserId: newHostId }
        });
        await this.redisService.hset(`game:${matchId}:state`, { host_id: newHostId });
        
        // 소켓 알림 (방장 변경)
        this.eventsGateway.server.to(matchId).emit('host_changed', {
          matchId,
          previousHostId: userId,
          newHostId
        });
      } else {
        // 남은 사람이 없으면 방 폭파 (옵션)
        // 여기선 별도 처리 없이 진행 (나중에 스케줄러가 정리)
      }
    }

    // 3. [상태별 처리] WAITING vs PLAYING
    if (gameStatus === 'PLAYING') {
      // 3-1. PLAYING: 탈주 처리 (기록 보존 필요)
      penaltyApplied = true;
      
      // 상태를 'LEFT'로 변경 (DB 저장을 위해 데이터는 남김)
      await this.redisService.hset(`game:${matchId}:player:${userId}`, { status: 'LEFT' });
      
      // 지도에서는 제거 (GEO REM)
      await this.redisService.zrem(`game:${matchId}:geo`, userId);
      
      // MMR 차감 등 패널티 로직 추가 가능
      // await this.decreaseMmr(userId);

    } else {
      // 3-2. WAITING: 완전 삭제
      const playerKey = `game:${matchId}:player:${userId}`;
      
      // Redis 데이터 삭제
      await this.redisService.del(playerKey);
      await this.redisService.del(`${playerKey}:items`); // 아이템 목록 삭제
      await this.redisService.zrem(`game:${matchId}:geo`, userId); // 위치 삭제
    }

    // 4. [Socket] 퇴장 알림
    this.eventsGateway.server.to(matchId).emit('user_left', {
      matchId,
      leftUserId: userId,
      newHostId
    });
    
    // 해당 유저의 소켓 Room 나가기 처리 (Gateway에서 처리하거나 클라가 끊음)
    // this.eventsGateway.server.in(socketId).socketsLeave(matchId); 

    return {
      success: true,
      message: '방에서 퇴장했습니다.',
      data: {
        matchId,
        leftUserId: userId,
        newHostId,
        penaltyApplied
      },
      error: null
    };
  }

  // ==================================================================
  // 🛠 Helpers
  // ==================================================================
  private async processAutoArrest(matchId: string, copId: string, thiefId: string, speedBonus = 1.0): Promise<AutoArrestStatusDto> {
    const REQUIRED_MS = 3000 / speedBonus; // 속도 보너스 적용
    const key = `game:${matchId}:arrest_timer:${copId}:${thiefId}`;
    
    const startStr = await this.redisService.get(key);
    let start = parseInt(startStr || '0');
    
    if (!start) {
      start = Date.now();
      await this.redisService.set(key, start.toString(), 1);
    } else {
      await this.redisService.expire(key, 1);
    }

    const elapsed = Date.now() - start;
    if (elapsed >= REQUIRED_MS) {
      await this.redisService.del(key);
      await this.executeArrest(matchId, copId, thiefId);
      return { targetId: thiefId, status: 'COMPLETED', progress: 100 };
    }
    return { targetId: thiefId, status: 'PROGRESSING', progress: Math.min((elapsed/REQUIRED_MS)*100, 100) };
  }

  private async executeArrest(matchId: string, copId: string, thiefId: string): Promise<number> {
    const status = await this.redisService.hget(`game:${matchId}:player:${thiefId}`, 'status');
    if (status === 'ARRESTED') return 0;

    await this.redisService.hset(`game:${matchId}:player:${thiefId}`, { status: 'ARRESTED' });
    const idx = await this.redisService.rpush(`game:${matchId}:prison_queue`, thiefId);

    let score = 0;
    if (copId !== 'SYSTEM') {
      await this.redisService.hincrby(`game:${matchId}:player:${copId}`, 'catchCount', 1);
      const s = await this.redisService.hincrby(`game:${matchId}:state`, 'police_score', 1);
      score = typeof s === 'number' ? s : parseInt(s);
      
      const mode = await this.redisService.hget(`game:${matchId}:state`, 'game_mode');
      if (mode === 'ABILITY') await this.redisService.hincrby(`game:${matchId}:player:${copId}`, 'ability_gauge', 20);
    } else {
      const s = await this.redisService.hget(`game:${matchId}:state`, 'police_score');
      score = parseInt(s || '0');
    }

    this.eventsGateway.server.to(matchId).emit('user_arrested', {
      matchId, copId, targetUserId: thiefId, currentScore: score, prisonQueueIndex: idx
    });
    return idx;
  }

  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371e3; 
    const φ1 = lat1 * Math.PI/180;
    const φ2 = lat2 * Math.PI/180;
    const Δφ = (lat2-lat1) * Math.PI/180;
    const Δλ = (lon2-lon1) * Math.PI/180;
    const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) + Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ/2) * Math.sin(Δλ/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
  }
}