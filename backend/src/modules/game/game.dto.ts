import { IsString, IsNumber, IsOptional, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

// 1. 위치 이동 DTO
export class MoveDto {
  @ApiProperty({ description: '매치 ID' })
  @IsString()
  matchId: string;

  @ApiProperty({ description: '위도 (Latitude)', example: 37.123 })
  @IsNumber()
  lat: number;

  @ApiProperty({ description: '경도 (Longitude)', example: 127.123 })
  @IsNumber()
  lng: number;

  @ApiProperty({ description: '심박수 (선택)', required: false })
  @IsOptional()
  @IsNumber()
  heartRate?: number;
}

// 2. 체포 요청 DTO
export class ArrestDto {
  @ApiProperty({ description: '매치 ID' })
  @IsString()
  matchId: string;

  @ApiProperty({ description: '체포할 도둑 ID' })
  @IsString()
  targetUserId: string;
}

// 3. 구조 요청 DTO
export class RescueDto {
  @ApiProperty({ description: '매치 ID' })
  @IsString()
  matchId: string;
}

// 1. 능력 사용 DTO
export class UseAbilityDto {
  @ApiProperty({ description: '매치 ID' })
  @IsString()
  matchId: string;

  @ApiProperty({ description: '스킬 타입', example: 'DASH' })
  @IsEnum(['DASH', 'STEALTH', 'SCAN'])
  skillType: 'DASH' | 'STEALTH' | 'SCAN';
}

// 2. 아이템 사용 DTO
export class UseItemDto {
  @ApiProperty({ description: '매치 ID' })
  @IsString()
  matchId: string;

  @ApiProperty({ description: '아이템 ID (Type)', example: 'DECOY' })
  @IsEnum(['EMP', 'RADAR', 'DECOY', 'INVISIBLE'])
  itemId: 'EMP' | 'RADAR' | 'DECOY' | 'INVISIBLE';
}

// 1. 게임 종료 DTO
export class EndGameDto {
  @ApiProperty({ description: '종료 사유 (선택)', example: 'HOST_FORCE_END', required: false })
  @IsOptional()
  @IsString()
  reason?: string;
}

// 2. 게임 다시 하기 (Rematch) DTO
// Body가 비어있을 수도 있지만, 추후 설정 변경 가능성을 위해 클래스는 만들어둡니다.
export class RematchDto {
  // 현재는 명세상 Body가 비어있으므로 필드 없음
}

// 3. 방장 위임 DTO
export class DelegateHostDto {
  @ApiProperty({ description: '방장을 넘겨줄 대상의 ID' })
  @IsString()
  targetUserId: string;
}