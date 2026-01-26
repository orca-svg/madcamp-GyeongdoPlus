import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsString, Matches, MinLength } from 'class-validator';

// ==========================================
// 1. 공통 내부 DTO (응답 구조용)
// ==========================================

class UserDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000', description: '사용자 고유 ID' })
  id: string;

  @ApiProperty({ example: 'thief123@example.com', description: '이메일' })
  email: string;

  @ApiProperty({ example: 'lupin_the_third', description: '닉네임' })
  nickname: string;

  @ApiProperty({ example: null, nullable: true, description: '프로필 이미지 URL' })
  profileImage: string | null;
}

class AuthDataDto {
  @ApiProperty({ example: 'eyJhbGciOiJIUzI1Ni...', description: 'JWT Access Token' })
  accessToken: string;

  @ApiProperty({ example: 'dGhwY3ByBcyBhIHJl...', description: 'JWT Refresh Token' })
  refreshToken: string;

  @ApiProperty({ example: 1800, description: '토큰 만료 시간 (초)' })
  expiresIn: number;

  @ApiProperty({ type: UserDto, description: '사용자 정보' })
  user: UserDto;
}

class ErrorDetailDto {
  @ApiProperty({ example: 'CONFLICT', description: '에러 코드' })
  code: string;

  @ApiProperty({ example: '이미 존재하는 이메일 또는 닉네임입니다.', description: '에러 메시지' })
  message: string;
}

// ==========================================
// 2. 회원가입 (Signup) 관련
// ==========================================

export class LocalSignupDto {
  @ApiProperty({ example: 'thief123@example.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'strongPassword123!' })
  @IsString()
  @MinLength(8)
  @Matches(/^(?=.*[a-zA-Z])(?=.*[!@#$%^*+=-])(?=.*[0-9]).{8,25}$/)
  password: string;

  @ApiProperty({ example: 'lupin_the_third' })
  @IsNotEmpty()
  @IsString()
  nickname: string;
}

export class SignupResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '회원가입 성공' })
  message: string;

  @ApiProperty({ type: AuthDataDto })
  data: AuthDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

export class SignupConflictErrorDto {
  @ApiProperty({ example: false })
  success: boolean;

  @ApiProperty({ type: ErrorDetailDto })
  error: ErrorDetailDto;
}

// ==========================================
// 3. 로그인 (Login) 관련
// ==========================================

export class LocalLoginDto {
  @ApiProperty({ example: 'thief123@example.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'strongPassword123!' })
  @IsNotEmpty()
  @IsString()
  password: string;
}

export class KakaoLoginDto {
  @ApiProperty({ example: 'access_token_from_kakao_sdk...', description: '카카오 SDK에서 받은 토큰' })
  @IsNotEmpty()
  @IsString()
  kakaoAccessToken: string;
}

export class LoginResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '로그인 성공' })
  message: string;

  @ApiProperty({ type: AuthDataDto })
  data: AuthDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

// ==========================================
// 4. 토큰 재발급 (Refresh)
// ==========================================

export class RefreshRequestDto {
  @ApiProperty({ example: 'dGhwY3ByBcyBhIHJl...', description: 'Refresh Token' })
  @IsNotEmpty()
  @IsString()
  refreshToken: string;
}

export class RefreshResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '토큰 재발급 성공' })
  message: string;

  @ApiProperty({ 
    example: { 
      accessToken: 'new_access_token...', 
      refreshToken: 'new_refresh_token...' 
    } 
  })
  data: {
    accessToken: string;
    refreshToken: string;
  };
}

// ==========================================
// 5. 로그아웃 (Logout)
// ==========================================

export class LogoutResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '로그아웃 성공' })
  message: string;
}

// ==========================================
// 6. 닉네임 중복 확인 (Check Nickname)
// ==========================================

export class CheckNicknameResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '확인 완료' })
  message: string;

  @ApiProperty({ example: { isAvailable: true }, description: 'true면 사용 가능, false면 중복' })
  data: {
    isAvailable: boolean;
  };
}