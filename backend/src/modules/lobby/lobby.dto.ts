import { IsString, IsNumber, IsEnum, IsObject, IsOptional } from 'class-validator';
import { ApiProperty, PartialType } from '@nestjs/swagger';

// ==========================================
// 1. 방 생성 (Create)
// ==========================================

export class CreateRoomDto {
  @ApiProperty({ description: '게임 모드', example: 'NORMAL' })
  @IsEnum(['NORMAL', 'ITEM', 'ABILITY'])
  mode: 'NORMAL' | 'ITEM' | 'ABILITY';

  @ApiProperty({ description: '최대 인원', example: 8 })
  @IsNumber()
  maxPlayers: number;

  @ApiProperty({ description: '제한 시간(초)', example: 600 })
  @IsNumber()
  timeLimit: number;

  @ApiProperty({ 
    description: '맵 설정 (JSON)', 
    example: { 
      polygon: [
        { lat: 37.123, lng: 127.123 },
        { lat: 37.124, lng: 127.124 }
      ],
      jail: { lat: 37.1235, lng: 127.1235, radiusM: 12 }
    } 
  })
  @IsObject()
  mapConfig: any;

  @ApiProperty({ 
    description: '게임 규칙 (JSON)', 
    example: {
      contactMode: "NON_CONTACT",
      captureRule: { ruleType: "THREE_OF_THREE" },
      jailRule: { jailEnabled: true }
    } 
  })
  @IsObject()
  rules: any;
}

// 방 생성 응답 DTO
class CreateRoomDataDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  matchId: string;

  @ApiProperty({ example: '392A1', description: '친구 초대용 짧은 코드' })
  roomCode: string;
}

export class CreateRoomResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '방이 생성되었습니다.' })
  message: string;

  @ApiProperty({ type: CreateRoomDataDto })
  data: CreateRoomDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}


// ==========================================
// 2. 방 입장 (Join)
// ==========================================

// ✅ [복구] 이게 바로 사라졌던 JoinRoomDto 입니다!
export class JoinRoomDto {
  @ApiProperty({ description: '참여 코드', example: '392A1' })
  @IsString()
  roomCode: string;
}

// 입장 성공 데이터
class JoinRoomDataDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  matchId: string;

  @ApiProperty({ example: 'POLICE', description: '초기 역할' })
  myRole: string;

  @ApiProperty({ example: 'host-uuid-1234' })
  hostId: string;

  @ApiProperty({ example: { polygon: [] }, description: '대기실 지도 미리보기용' })
  mapConfig: any;
}

// 입장 성공 응답 (200)
export class JoinRoomResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '방에 입장했습니다.' })
  message: string;

  @ApiProperty({ type: JoinRoomDataDto })
  data: JoinRoomDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

// 입장 실패 (409) - 방 꽉 참 / 이미 시작됨
export class JoinRoomConflictErrorDto {
  @ApiProperty({ example: false })
  success: boolean;

  @ApiProperty({ example: '방이 가득 찼습니다.' })
  message: string;

  @ApiProperty({ example: null, nullable: true })
  data: any;

  @ApiProperty({ example: { code: 'ROOM_FULL' } })
  error: { code: string };
}

// 입장 실패 (404) - 방 없음
export class JoinRoomNotFoundErrorDto {
  @ApiProperty({ example: false })
  success: boolean;

  @ApiProperty({ example: '존재하지 않는 참여 코드입니다.' })
  message: string;

  @ApiProperty({ example: null, nullable: true })
  data: any;

  @ApiProperty({ example: { code: 'ROOM_NOT_FOUND' } })
  error: { code: string };
}


// ==========================================
// [수정] 유저 강퇴 Request DTO
// ==========================================
export class KickUserDto {
  @ApiProperty({ description: '게임 매치 ID', example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsString()
  matchId: string;

  @ApiProperty({ description: '강퇴할 유저 ID', example: 'troll-user-uuid-9999' })
  @IsString()
  targetUserId: string;
}

// ==========================================
// [신규] 유저 강퇴 응답용 DTO
// ==========================================

// 1. 강퇴 성공 데이터
class KickUserDataDto {
  @ApiProperty({ example: 'troll-user-uuid-9999' })
  kickedUserId: string;

  @ApiProperty({ example: 3, description: '강퇴 후 남은 인원' })
  remainingPlayerCount: number;
}

// 2. 성공 응답 (200)
export class KickUserResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '해당 유저를 강퇴했습니다.' })
  message: string;

  @ApiProperty({ type: KickUserDataDto })
  data: KickUserDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

// 3. 실패 응답 - 권한 없음 (403)
export class KickUserForbiddenErrorDto {
  @ApiProperty({ example: false })
  success: boolean;

  @ApiProperty({ example: '방장만 유저를 강퇴할 수 있습니다.' })
  message: string;

  @ApiProperty({ example: null, nullable: true })
  data: any;

  @ApiProperty({ 
    example: { code: 'NOT_HOST' },
    description: '에러 코드 (NOT_HOST)'
  })
  error: { code: string };
}

// ==========================================
// [신규] 방 상세 정보 조회 응답용 DTO
// ==========================================

// 1. 방 설정 정보 (Settings)
class RoomSettingsDto {
  @ApiProperty({ example: 'ABILITY' })
  mode: string;

  @ApiProperty({ example: 600 })
  timeLimit: number;

  @ApiProperty({ example: 10 })
  maxPlayers: number;

  @ApiProperty({ 
    example: { 
      polygon: [{ lat: 37.123, lng: 127.123 }],
      jail: { lat: 37.1235, lng: 127.1235, radiusM: 12 } 
    } 
  })
  mapConfig: any;
}

// 2. 플레이어 정보 (Players Array Item)
class RoomPlayerDto {
  @ApiProperty({ example: 'host-uuid-1234' })
  userId: string;

  @ApiProperty({ example: 'PoliceKing' })
  nickname: string;

  @ApiProperty({ example: true, description: '준비 완료 여부' })
  ready: boolean;

  @ApiProperty({ example: 'POLICE', nullable: true, description: '팀 정보 (없으면 null)' })
  team: string | null;
}

// 3. 상세 정보 데이터 (Data Wrapper)
class RoomDetailsDataDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  matchId: string;

  @ApiProperty({ example: 'WAITING' })
  status: string;

  @ApiProperty({ example: 'host-uuid-1234' })
  hostId: string;

  @ApiProperty({ type: RoomSettingsDto })
  settings: RoomSettingsDto;

  @ApiProperty({ type: [RoomPlayerDto] }) // 배열 타입 명시
  players: RoomPlayerDto[];
}

// 4. 최종 성공 응답 (200)
export class GetRoomDetailsResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '방 정보를 조회했습니다.' })
  message: string;

  @ApiProperty({ type: RoomDetailsDataDto })
  data: RoomDetailsDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

// ==========================================
// [수정] 방 설정 변경 Request DTO
// ==========================================
export class UpdateRoomDto extends PartialType(CreateRoomDto) {
  @ApiProperty({ description: '변경할 게임 모드', example: 'ITEM', required: false })
  @IsOptional()
  @IsEnum(['NORMAL', 'ITEM', 'ABILITY'])
  mode?: 'NORMAL' | 'ITEM' | 'ABILITY';

  @ApiProperty({ description: '변경할 시간 제한(초)', example: 1200, required: false })
  @IsOptional()
  @IsNumber()
  timeLimit?: number;

  // PartialType이 mapConfig, rules 등도 자동으로 Optional로 가져오지만,
  // Swagger 예시를 명확히 하려면 아래처럼 오버라이딩해도 됩니다.
  @ApiProperty({ 
    description: '변경할 맵 설정', 
    example: { 
      polygon: [{ lat: 37.123, lng: 127.123 }],
      jail: { lat: 37.1235, lng: 127.1235, radiusM: 12 } 
    }, 
    required: false 
  })
  @IsOptional()
  mapConfig?: any;
}

// ==========================================
// [신규] 방 설정 변경 응답용 DTO
// ==========================================

// 1. 변경된 설정 정보
class UpdatedSettingsDto {
  @ApiProperty({ example: 'ITEM' })
  mode: string;

  @ApiProperty({ example: 1200 })
  timeLimit: number;

  @ApiProperty({ example: { polygon: [] } })
  mapConfig: any;
  
  @ApiProperty({ example: {}, nullable: true })
  rules: any;
}

// 2. 데이터 Wrapper
class UpdateRoomDataDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  matchId: string;

  @ApiProperty({ type: UpdatedSettingsDto })
  updatedSettings: UpdatedSettingsDto;
}

// 3. 최종 성공 응답 (200)
export class UpdateRoomResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '방 설정이 변경되었습니다.' })
  message: string;

  @ApiProperty({ type: UpdateRoomDataDto })
  data: UpdateRoomDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

// ==========================================
// [수정] 게임 시작 Request DTO
// ==========================================
export class StartGameDto {
  @ApiProperty({ description: '시작할 게임 매치 ID', example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsString()
  matchId: string;
}

// ==========================================
// [신규] 게임 시작 응답용 DTO
// ==========================================

class StartGameDataDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  matchId: string;

  @ApiProperty({ example: '2026-01-24T15:30:00Z', description: '서버 기준 시작 시간' })
  startTime: Date;

  @ApiProperty({ example: 600, description: '게임 제한 시간 (초)' })
  gameDuration: number;
}

// 최종 성공 응답 (200)
export class StartGameResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '게임이 시작되었습니다!' })
  message: string;

  @ApiProperty({ type: StartGameDataDto })
  data: StartGameDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}