import { IsString, IsNumber, IsOptional, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

// ==========================================
// 1. 위치 이동 Request DTO
// ==========================================
export class MoveDto {
  @ApiProperty({ description: '매치 ID', example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsString()
  matchId: string;

  @ApiProperty({ description: '위도 (Latitude)', example: 37.566535 })
  @IsNumber()
  lat: number;

  @ApiProperty({ description: '경도 (Longitude)', example: 126.977969 })
  @IsNumber()
  lng: number;

  @ApiProperty({ description: '심박수 (선택)', example: 120, required: false })
  @IsOptional()
  @IsNumber()
  heartRate?: number;

  @ApiProperty({ description: '나침반 방향 (0~360)', example: 90.5, required: false })
  @IsOptional()
  @IsNumber()
  heading?: number;
}

// ==========================================
// [응답용] 주변 오브젝트 & 자동 체포 상태 DTO
// ==========================================

export class NearbyObjectDto {
  @ApiProperty({ example: 'PLAYER', description: '물체 타입 (PLAYER: 플레이어, DECOY: 미끼)' })
  type: 'PLAYER' | 'DECOY';

  @ApiProperty({ example: 'user-uuid-5678', description: '유저 ID (미끼라면 설치한 유저 ID)' })
  userId: string;

  @ApiProperty({ example: 12.5, description: '나와의 거리 (미터)' })
  distance: number;
}

export class AutoArrestStatusDto {
  @ApiProperty({ example: 'thief-uuid-1234' })
  targetId: string;

  @ApiProperty({ example: 'PROGRESSING', enum: ['PROGRESSING', 'COMPLETED'] })
  status: 'PROGRESSING' | 'COMPLETED';

  @ApiProperty({ example: 45.5, description: '진행률 (0~100)' })
  progress: number;
}

class MoveResponseDataDto {
  @ApiProperty({ type: [NearbyObjectDto], description: '주변(50m) 플레이어 및 미끼 목록 (투명 상태 제외)' })
  nearbyEvents: NearbyObjectDto[];

  @ApiProperty({ type: AutoArrestStatusDto, nullable: true, description: '현재 진행 중인 자동 체포 상태' })
  autoArrestStatus: AutoArrestStatusDto | null;
}

export class MoveResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '위치 업데이트 완료' })
  message: string;

  @ApiProperty({ type: MoveResponseDataDto })
  data: MoveResponseDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}


// ==========================================
// 2. 자수(항복) 요청 DTO
// ==========================================
export class ArrestDto {
  @ApiProperty({ description: '매치 ID' })
  @IsString()
  matchId: string;

  // ✅ [추가] 나를 잡은 경찰의 ID (선택 사항)
  // 물리적으로 잡혔는데 시스템이 인식 못 했을 때, 해당 경찰에게 점수를 주기 위해 입력
  @ApiProperty({ 
    description: '나를 체포한 경찰의 ID (선택). 입력 시 해당 경찰의 카운트가 증가함.',
    required: false 
  })
  @IsOptional()
  @IsString()
  copId?: string;
}

// 자수 성공 데이터
class ArrestDataDto {
  @ApiProperty({ example: 'my-uuid-1234', description: '체포된(자수한) 유저 ID' })
  arrestedUser: string;

  @ApiProperty({ example: 'ARRESTED' })
  status: string;

  @ApiProperty({ example: 3, description: '감옥 구출 대기열 순서 (1부터 시작)' })
  prisonQueueIndex: number;
}

export class ArrestResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '자수하여 체포되었습니다.' })
  message: string;

  @ApiProperty({ type: ArrestDataDto })
  data: ArrestDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

export class ArrestRangeErrorDto {
  // 자수에는 거리 에러가 없지만, 혹시 모를 확장을 위해 남겨둠
  @ApiProperty({ example: false })
  success: boolean;
  @ApiProperty({ example: '잘못된 요청입니다.' })
  message: string;
  @ApiProperty({ example: null })
  data: any;
  @ApiProperty({ example: { code: 'BAD_REQUEST' } })
  error: any;
}


// ==========================================
// [수정] 구조 요청 응답 DTO
// ==========================================

export class RescueDto {
  @ApiProperty({ description: '매치 ID' })
  @IsString()
  matchId: string;
}

// 구조 성공 데이터
class RescueDataDto {
  @ApiProperty({ 
    example: ['thief-uuid-1111', 'thief-uuid-2222'], 
    description: '구출된 유저 ID 목록 (배열)' 
  })
  rescuedUserIds: string[];

  @ApiProperty({ example: 'PARTIAL', enum: ['PARTIAL', 'FULL'] })
  rescueType: 'PARTIAL' | 'FULL';

  @ApiProperty({ example: 2, description: '구출 후 남은 수감자 수' })
  remainingPrisoners: number;
}

// 성공 응답 (200)
export class RescueResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '동료를 구출했습니다!' })
  message: string;

  @ApiProperty({ type: RescueDataDto })
  data: RescueDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

// 실패 응답 (400 - 감옥 밖임)
export class RescueRangeErrorDto {
  @ApiProperty({ example: false })
  success: boolean;
  @ApiProperty({ example: '감옥 영역 밖입니다.' })
  message: string;
  @ApiProperty({ example: null })
  data: any;
  @ApiProperty({ example: { code: 'OUT_OF_JAIL_RANGE' } })
  error: any;
}

// [신규] 직업 선택 DTO
export class SelectAbilityDto {
  @ApiProperty({ description: '매치 ID' })
  @IsString()
  matchId: string;

  @ApiProperty({ 
    description: '선택할 직업 코드', 
    enum: ['SEARCHER', 'JAILER', 'ENFORCER', 'CHASER', 'SHADOW', 'BROKER', 'HACKER', 'CLOWN'] 
  })
  @IsEnum(['SEARCHER', 'JAILER', 'ENFORCER', 'CHASER', 'SHADOW', 'BROKER', 'HACKER', 'CLOWN'])
  abilityClass: string;
}

class SelectAbilityDataDto {
  @ApiProperty({ example: 'user-uuid-1234', description: '유저 ID' })
  userId: string;

  @ApiProperty({ example: 'THIEF', description: '유저 역할 (POLICE | THIEF)' })
  role: string;

  @ApiProperty({ example: 'SHADOW', description: '선택된 직업 코드' })
  selectedClass: string;
}

export class SelectAbilityResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: 'SHADOW 직업을 선택했습니다.' })
  message: string;

  @ApiProperty({ type: SelectAbilityDataDto })
  data: SelectAbilityDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

// [신규] 능력 선택 실패 DTO (예시)
export class SelectAbilityErrorDto {
  @ApiProperty({ example: false })
  success: boolean;

  @ApiProperty({ example: '경찰 전용 직업이 아닙니다.' })
  message: string;

  @ApiProperty({ example: null })
  data: any;

  @ApiProperty({ 
    example: { code: 'INVALID_CLASS_FOR_ROLE', myRole: 'POLICE', requestedClass: 'SHADOW' },
    description: '에러 상세 정보'
  })
  error: any;
}

// [수정] 능력 사용 DTO (skillType 삭제)
export class UseAbilityDto {
  @ApiProperty({ description: '매치 ID' })
  @IsString()
  matchId: string;
  
  // skillType은 필요 없습니다. (이미 선택한 직업의 스킬이 나가므로)
}

// ==========================================
// [신규] 능력 사용 응답 DTO (Response)
// ==========================================

// 1. 성공 데이터
class UseAbilityDataDto {
  @ApiProperty({ example: 'DASH' })
  skillType: string;

  @ApiProperty({ example: 45.0, description: '사용 후 남은 게이지' })
  remainingGauge: number;

  @ApiProperty({ example: 3, description: '지속 시간 (초)' })
  duration: number;

  @ApiProperty({ example: 10, description: '쿨타임 (초)' })
  cooldown: number;
}

// 2. 성공 응답 (200)
export class UseAbilityResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '스킬을 사용했습니다.' })
  message: string;

  @ApiProperty({ type: UseAbilityDataDto })
  data: UseAbilityDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

// 3. 실패 응답 - 게이지 부족 (400)
export class AbilityGaugeErrorDto {
  @ApiProperty({ example: false })
  success: boolean;

  @ApiProperty({ example: '게이지가 부족합니다.' })
  message: string;

  @ApiProperty({ example: null, nullable: true })
  data: any;

  @ApiProperty({ 
    example: { code: 'NOT_ENOUGH_GAUGE', current: 10, required: 30 },
    description: '에러 상세 정보 (필요 게이지량 등)'
  })
  error: { 
    code: string;
    current: number;
    required: number;
  };
}

// ==========================================
// [신규] 아이템 선택 Request DTO
// ==========================================
export class SelectItemDto {
  @ApiProperty({ description: '매치 ID' })
  @IsString()
  matchId: string;

  @ApiProperty({ description: '선택할 아이템 ID', example: 'RADAR' })
  @IsEnum(['EMP', 'RADAR', 'DECOY', 'INVISIBLE', 'TRAP', 'SCANNER']) // 예시 아이템 목록
  itemId: string;
}

// ==========================================
// [신규] 아이템 선택 응답 DTOs
// ==========================================

// 1. 성공 데이터
class SelectItemDataDto {
  @ApiProperty({ example: 'RADAR', description: '획득한 아이템' })
  obtainedItem: string;

  @ApiProperty({ example: ['EMP', 'RADAR'], description: '현재 보유 중인 전체 아이템 리스트' })
  currentInventory: string[];
}

// 2. 성공 응답 (200)
export class SelectItemResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: 'RADAR 아이템을 획득했습니다.' })
  message: string;

  @ApiProperty({ type: SelectItemDataDto })
  data: SelectItemDataDto;

  @ApiProperty({ example: null })
  error: any;
}

// 3. 실패 응답 - 시간 미달 (400)
export class ItemTimeErrorDto {
  @ApiProperty({ example: false })
  success: boolean;

  @ApiProperty({ example: '아직 아이템을 선택할 수 있는 시간이 아닙니다.' })
  message: string;

  @ApiProperty({ example: null })
  data: any;

  @ApiProperty({ 
    example: { 
      code: 'TOO_EARLY_TO_SELECT', 
      elapsedMinutes: 5.5, 
      requiredMinutes: 10 
    },
    description: '에러 상세: 현재 경과 시간 및 필요 시간'
  })
  error: {
    code: string;
    elapsedMinutes: number;
    requiredMinutes: number;
  };
}

// 4. 실패 응답 - 이미 수령함 (409)
export class ItemConflictErrorDto {
  @ApiProperty({ example: false })
  success: boolean;

  @ApiProperty({ example: '이미 해당 구간의 아이템을 선택했습니다.' })
  message: string;

  @ApiProperty({ example: null })
  data: any;

  @ApiProperty({ 
    example: { 
      code: 'ALREADY_CLAIMED', 
      nextAvailableTime: '20분 경과 후' 
    },
    description: '에러 상세: 중복 수령 경고'
  })
  error: {
    code: string;
    nextAvailableTime?: string;
  };
}

// ==========================================
// [수정] 아이템 사용 Request DTO (8종 반영)
// ==========================================
export class UseItemDto {
  @ApiProperty({ description: '매치 ID' })
  @IsString()
  matchId: string;

  @ApiProperty({ 
    description: '아이템 ID (Type)', 
    example: 'RADAR',
    enum: [
      'RADAR',          // 경찰: 레이더 (7초간 도둑 위치 표시)
      'RESCUE_BLOCK',   // 경찰: 구출 차단 (감옥 잠금)
      'THIEF_DETECTOR', // 경찰: 도둑 탐지기 (5m 내 진동)
      'AREA_SIREN',     // 경찰: 광역 사이렌 (30m 내 도둑 알림, 팀 1회)
      'DECOY',          // 도둑: 미끼 (밟으면 경찰 위치 노출)
      'RESCUE_BOOST',   // 도둑: 구출 촉진 (구출 속도/인원 증가)
      'EMP',            // 도둑: EMP (경찰 아이템 무력화)
      'REMOTE_RESCUE'   // 도둑: 원격 구출 (팀 1회, 3명 구출)
    ]
  })
  @IsEnum([
    'RADAR', 'RESCUE_BLOCK', 'THIEF_DETECTOR', 'AREA_SIREN',
    'DECOY', 'RESCUE_BOOST', 'EMP', 'REMOTE_RESCUE'
  ])
  itemId: string;
}

// ==========================================
// [수정] 아이템 사용 응답 DTO
// ==========================================

class UseItemDataDto {
  @ApiProperty({ example: ['EMP', 'DECOY'], description: '사용 후 남은 아이템 목록' })
  remainingItems: string[];

  @ApiProperty({ example: 60, description: '효과 지속 시간 (초)' })
  effectDuration: number;

  @ApiProperty({ example: 3, description: '영향을 받은 유저 수 (사이렌/구출 등)', required: false })
  affectedCount?: number;
}

export class UseItemResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '레이더가 활성화되었습니다.' })
  message: string;

  @ApiProperty({ type: UseItemDataDto })
  data: UseItemDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

// ==========================================
// [신규] 게임 동기화(Sync) 응답 DTO
// ==========================================

// 1. 활성 효과 정보 (Active Effects)
class ActiveEffectsDto {
  @ApiProperty({ example: false, description: '투명 상태 여부' })
  invisible: boolean;

  @ApiProperty({ example: true, description: '은신 상태 여부 (능력전)' })
  stealth: boolean;

  // 필요시 추가 (예: detector_active, rescue_boost 등)
  @ApiProperty({ example: false, description: '구출 촉진 버프 여부' })
  rescueBoost: boolean;
}

// 2. 내 상태 정보 (My State)
class MyStateDto {
  @ApiProperty({ example: 'THIEF', enum: ['POLICE', 'THIEF', 'NONE'] })
  role: string;

  @ApiProperty({ example: 'ALIVE', enum: ['ALIVE', 'ARRESTED', 'ESCAPED', 'SPECTATOR'] })
  status: string;

  @ApiProperty({ example: ['EMP', 'DECOY'], description: '보유 아이템 (능력전일 경우 빈 배열)' })
  items: string[];

  @ApiProperty({ example: 80.5, description: '능력 게이지 (아이템전일 경우 0)' })
  abilityGauge: number;

  @ApiProperty({ type: ActiveEffectsDto })
  activeEffects: ActiveEffectsDto;
}

// 3. 동기화 데이터 (Data Wrapper)
class SyncGameDataDto {
  @ApiProperty({ example: 'PLAYING' })
  gameStatus: string;

  @ApiProperty({ example: '2026-01-24T16:45:30Z', description: '현재 서버 시간' })
  serverTime: string;

  @ApiProperty({ example: '2026-01-24T16:40:00Z', description: '게임 시작 시간' })
  startTime: string;

  @ApiProperty({ example: 600, description: '제한 시간 (초)' })
  timeLimit: number;

  @ApiProperty({ example: 3, description: '현재 경찰 팀 점수' })
  policeScore: number;

  @ApiProperty({ example: 8, description: '전체 도둑 수 (UI 표시용)' })
  totalThiefCount: number;

  @ApiProperty({ type: MyStateDto })
  myState: MyStateDto;

  @ApiProperty({ example: ['user-uuid-1', 'user-uuid-2'], description: '감옥 수감자 목록' })
  prisonQueue: string[];

  @ApiProperty({ example: 350.5, description: '현재 자기장 반경 (미터)' })
  shrinkingRadius: number;
}

// 4. 최종 성공 응답 (200)
export class SyncGameResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '게임 상태를 동기화했습니다.' })
  message: string;

  @ApiProperty({ type: SyncGameDataDto })
  data: SyncGameDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

// ==========================================
// [수정] 게임 종료 Request DTO
// ==========================================
export class EndGameDto {
  @ApiProperty({ 
    description: '종료 사유', 
    example: 'ALL_THIEVES_CAUGHT', 
    enum: ['HOST_FORCE_END', 'ALL_THIEVES_CAUGHT', 'TIME_OVER']
  })
  @IsOptional()
  @IsString()
  reason?: string;
}

// ==========================================
// [신규] 게임 종료 응답 DTOs
// ==========================================

class MvpUserDto {
  @ApiProperty({ example: 'user-uuid-1111', description: 'MVP 유저 ID' })
  userId: string;

  @ApiProperty({ example: 'Sherlock', description: 'MVP 유저 닉네임' })
  nickname: string;

  @ApiProperty({ example: 'http://image-url.com/profile.jpg', description: 'MVP 유저 프로필 이미지 URL' })
  profileImage: string;
}

class ResultReportDto {
  @ApiProperty({ example: 5, description: '게임 전체 총 체포 횟수' })
  totalCatch: number;

  @ApiProperty({ example: 12.5, description: '게임 전체 총 이동 거리 (km)' })
  totalDistance: number;
}

class EndGameDataDto {
  @ApiProperty({ example: 'uuid-1234-match-id', description: '종료된 매치 ID' })
  matchId: string;

  @ApiProperty({ example: 540, description: '총 플레이 타임 (초)' })
  playTime: number;

  @ApiProperty({ example: 'POLICE', description: '승리 팀 (POLICE | THIEF)' })
  winnerTeam: string;

  @ApiProperty({ type: MvpUserDto, description: 'MVP 플레이어 정보' })
  mvpUser: MvpUserDto;

  @ApiProperty({ type: ResultReportDto, description: '게임 결과 요약 리포트' })
  resultReport: ResultReportDto;
}

export class EndGameResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '게임이 종료되고 기록이 저장되었습니다.' })
  message: string;

  @ApiProperty({ type: EndGameDataDto })
  data: EndGameDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}


// ==========================================
// [신규] 게임 다시 하기 응답 DTOs
// ==========================================

class RematchDataDto {
  @ApiProperty({ example: 'uuid-9999-new-match-id', description: '새로 생성된 매치 ID' })
  newMatchId: string;

  @ApiProperty({ example: '7A9Z2', description: '새로운 5자리 방 코드' })
  roomCode: string;

  @ApiProperty({ example: 'user-uuid-req-user', description: '새 방의 방장 ID (요청자)' })
  hostUserId: string;

  @ApiProperty({ example: 'ITEM', description: '이전 게임 설정을 승계한 모드' })
  mode: string;

  @ApiProperty({ example: 'WAITING' })
  status: string;
}

export class RematchResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '새로운 대기실이 생성되었습니다.' })
  message: string;

  @ApiProperty({ type: RematchDataDto })
  data: RematchDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

// ==========================================
// 7. 방장 위임 DTO
// ==========================================
export class DelegateHostDto {
  @ApiProperty({ description: '방장을 넘겨줄 대상의 ID', example: 'user-uuid-new-host' })
  @IsString()
  targetUserId: string;
}

// [신규] 방장 위임 응답 DTO
class DelegateHostDataDto {
  @ApiProperty({ example: 'uuid-1234-match-id', description: '매치 ID' })
  matchId: string;

  @ApiProperty({ example: 'user-uuid-old-host', description: '이전 방장 ID' })
  previousHostId: string;

  @ApiProperty({ example: 'user-uuid-new-host', description: '새로운 방장 ID' })
  newHostId: string;
}

export class DelegateHostResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '방장이 변경되었습니다.' })
  message: string;

  @ApiProperty({ type: DelegateHostDataDto })
  data: DelegateHostDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

// ==========================================
// [신규] 방 퇴장 응답 DTOs
// ==========================================

class LeaveGameDataDto {
  @ApiProperty({ example: 'uuid-1234-match-id', description: '매치 ID' })
  matchId: string;

  @ApiProperty({ example: 'user-uuid-leaver', description: '퇴장한 유저 ID' })
  leftUserId: string;

  @ApiProperty({ example: 'user-uuid-new-host', description: '새로운 방장 ID (방장이 나갔을 경우 위임된 유저)', nullable: true })
  newHostId: string | null;

  @ApiProperty({ example: false, description: '패널티 적용 여부 (PLAYING 상태에서 퇴장 시 true)' })
  penaltyApplied: boolean;
}

export class LeaveGameResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '방에서 퇴장했습니다.' })
  message: string;

  @ApiProperty({ type: LeaveGameDataDto })
  data: LeaveGameDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}