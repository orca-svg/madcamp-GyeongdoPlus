// src/modules/user/user.dto.ts
import { IsOptional, IsString, Length, IsNumber, IsBoolean } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';;

// ==========================================
// [신규] 내 프로필 조회 응답용 DTO
// ==========================================

// 1. User 정보 객체 (export 권장)
export class UserProfileDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: 'Lupin' })
  nickname: string;

  @ApiProperty({ example: 'lupin@gmail.com', description: '본인이므로 노출' })
  email: string;

  @ApiProperty({ example: 'https://s3.aws.com/profile/123.jpg', nullable: true })
  profileImage: string | null;

  @ApiProperty({ example: 'KAKAO' })
  provider: string;
}

// 2. Stat 정보 객체 (export 권장)
export class UserStatDto {
  @ApiProperty({ example: 1250 })
  policeMmr: number;

  @ApiProperty({ example: 1050 })
  thiefMmr: number;

  @ApiProperty({ example: 95 })
  integrityScore: number;

  @ApiProperty({ example: 15 })
  totalCatch: number;

  @ApiProperty({ example: 5 })
  totalRelease: number;

  @ApiProperty({ example: 3600, description: '초 단위' })
  totalSurvival: number;

  @ApiProperty({ example: 12.5, description: 'km 단위' })
  totalDistance: number;

  @ApiProperty({ example: 2 })
  totalMvpCount: number;
}

// 3. Achievement 정보 객체 (export 권장)
export class AchievementDto {
  @ApiProperty({ example: 'SPEED_DEMON_1' })
  achieveId: string;

  @ApiProperty({ example: '2026-01-20T10:00:00.000Z' })
  earnedAt: Date;
}

// ✅ [추가] Data 내부 구조를 정의하는 DTO 클래스
export class MyProfileDataDto {
  @ApiProperty({ type: UserProfileDto }) // $ref 대신 클래스 타입 사용
  user: UserProfileDto;

  @ApiProperty({ type: UserStatDto })
  stat: UserStatDto;

  @ApiProperty({ type: [AchievementDto] }) // 배열은 [Class] 형태로 지정
  achievements: AchievementDto[];
}

// 4. 최종 Response DTO (Wrapper)
export class MyProfileResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '내 프로필을 조회했습니다.' })
  message: string;

  // ✅ [수정] 복잡한 properties 설정 대신 type에 DTO 클래스 지정
  @ApiProperty({ type: MyProfileDataDto })
  data: MyProfileDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

// 1. 타인 User 정보 객체 (이메일 등 민감정보 제외)
export class OtherUserProfileDto {
  @ApiProperty({ example: 'target-uuid-5678' })
  id: string;

  @ApiProperty({ example: 'Sherlock' })
  nickname: string;

  @ApiProperty({ example: null, nullable: true })
  profileImage: string | null;

  @ApiProperty({ example: '2025-12-25T00:00:00Z', description: '가입일' })
  createdAt: Date;
}

// 2. Data 내부 구조 (Stat, Achievement는 기존 DTO 재사용 가능)
export class OtherUserProfileDataDto {
  @ApiProperty({ type: OtherUserProfileDto })
  user: OtherUserProfileDto;

  @ApiProperty({ type: UserStatDto }) // 기존에 만든 UserStatDto 재사용
  stat: UserStatDto;

  @ApiProperty({ type: [AchievementDto] }) // 기존 AchievementDto 재사용
  achievements: AchievementDto[];
}

// 3. 최종 Response DTO (Wrapper)
export class OtherProfileResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '유저 프로필을 조회했습니다.' })
  message: string;

  @ApiProperty({ type: OtherUserProfileDataDto })
  data: OtherUserProfileDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}
// ✅ [수정] Request DTO: example 추가
export class UpdateProfileDto {
  @ApiProperty({ 
    example: 'NewLupin', // "string" 대신 실제 예시 값 표시
    description: '변경할 닉네임', 
    required: false 
  })
  @IsOptional()
  @IsString()
  @Length(2, 12)
  nickname?: string;

  @ApiProperty({ 
    example: 'https://new-image-url.com/face.png', // 실제 예시 값 표시
    description: '변경할 프로필 이미지 URL', 
    required: false 
  })
  @IsOptional()
  @IsString()
  profileImage?: string;
}

// ==========================================
// [신규] 프로필 수정 응답용 DTO
// ==========================================

class UpdateProfileDataDto {
  @ApiProperty({ example: 'NewLupin' })
  nickname: string;

  @ApiProperty({ example: '2026-01-24T16:00:00Z' })
  updatedAt: Date;
}

export class UpdateProfileResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '프로필이 수정되었습니다.' })
  message: string;

  @ApiProperty({ type: UpdateProfileDataDto })
  data: UpdateProfileDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

// 1. 전적 조회 쿼리 DTO
export class MatchHistoryQueryDto {
  @ApiProperty({ description: '페이지 번호 (기본값: 1)', required: false })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  page?: number = 1;

  @ApiProperty({ description: '한 번에 가져올 개수 (기본값: 10)', required: false })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  limit?: number = 10;
}

// 1. 통계 정보
class MyStatDto {
  @ApiProperty({ example: 3 })
  catchCount: number;

  @ApiProperty({ example: 85 })
  contribution: number;
}

// 2. 맵 설정 정보 (JSON 구조 반영)
class MapConfigDto {
  @ApiProperty({ example: [{ lat: 37.123, lng: 127.123 }] })
  polygon: object[];

  @ApiProperty({ example: { lat: 37.1235, lng: 127.1235, radiusM: 12 } })
  jail: object;
}

// 3. 게임 규칙 정보 (복잡한 JSON 예시 반영)
class GameRulesDto {
  @ApiProperty({ example: 'NON_CONTACT' })
  contactMode: string;

  @ApiProperty({ 
    example: { 
      ruleType: 'THREE_OF_THREE', 
      nearThresholdM: 1.0, 
      speedMaxMps: 1.2 
    } 
  })
  captureRule: object;

  @ApiProperty({ 
    example: { 
      jailEnabled: true, 
      rescue: { type: 'CHANNELING', rangeM: 10 } 
    } 
  })
  jailRule: object;
}

// 4. 게임 상세 정보
class GameInfoDto {
  @ApiProperty({ example: 8 })
  maxPlayers: number;

  @ApiProperty({ example: 600, description: '제한 시간 (초)' })
  timeLimit: number;

  @ApiProperty({ type: MapConfigDto })
  mapConfig: MapConfigDto;

  @ApiProperty({ example: 540, description: '실제 진행 시간 (초)' })
  playTime: number;

  @ApiProperty({ example: '2026-01-25T14:00:00Z' })
  playedAt: Date;

  @ApiProperty({ type: GameRulesDto })
  rules: GameRulesDto;
}

// 5. 전적 아이템 (배열 내부 요소)
class MatchRecordDto {
  @ApiProperty({ example: 'uuid-1234' })
  matchId: string;

  @ApiProperty({ example: 'WIN' })
  result: string;

  @ApiProperty({ example: 'POLICE' })
  role: string;

  @ApiProperty({ type: MyStatDto })
  myStat: MyStatDto;

  @ApiProperty({ type: GameInfoDto })
  gameInfo: GameInfoDto;
}

// 6. 최종 Response DTO
export class MatchHistoryResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '전적 기록을 조회했습니다.' })
  message: string;

  @ApiProperty({ type: [MatchRecordDto] }) // 배열 형태 지정
  data: MatchRecordDto[];

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

// ==========================================
// [수정] 회원 탈퇴 요청 DTO (Request)
// ==========================================
export class DeleteAccountDto {
  @ApiProperty({ 
    example: '게임이 너무 어려워요', // ✅ "string" 대신 예시 값 표시
    description: '탈퇴 사유 (선택)', 
    required: false 
  })
  @IsOptional()
  @IsString()
  reason?: string;

  @ApiProperty({ 
    example: true, // ✅ 예시 값 표시
    description: '데이터 삭제 동의 여부 (true여야 탈퇴 가능)', 
    required: true 
  })
  @IsBoolean()
  agreedToLoseData: boolean;
}

// ==========================================
// [신규] 회원 탈퇴 응답용 DTO (Response)
// ==========================================
export class DeleteAccountResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '회원 탈퇴가 완료되었습니다. 이용해 주셔서 감사합니다.' })
  message: string;

  @ApiProperty({ example: null, nullable: true })
  data: any; // 데이터는 null

  @ApiProperty({ example: null, nullable: true })
  error: any;
}