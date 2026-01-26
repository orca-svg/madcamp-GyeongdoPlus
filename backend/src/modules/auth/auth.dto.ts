import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsString, Matches, MinLength } from 'class-validator';

// ==========================================
// 1. 공통 내부 DTO (User, AuthData 등)
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

  @ApiProperty({ example: 1800, description: 'Access Token 만료 시간 (초)' })
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

// ✅ [수정] 명세서와 일치하도록 Response DTO 수정
export class SignupResponseDto {
  @ApiProperty({ example: true, description: '성공 여부' })
  success: boolean;

  @ApiProperty({ example: '회원가입 성공', description: '응답 메시지' })
  message: string;

  @ApiProperty({ type: AuthDataDto, description: '인증 데이터' })
  data: AuthDataDto;

  @ApiProperty({ example: null, nullable: true, description: '에러 정보 (성공 시 null)' })
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

// ✅ [수정] 명세서와 일치하도록 Response DTO 수정
export class LoginResponseDto {
  @ApiProperty({ example: true, description: '성공 여부' })
  success: boolean;

  @ApiProperty({ example: '로그인 성공', description: '응답 메시지' })
  message: string;

  @ApiProperty({ type: AuthDataDto, description: '인증 데이터' })
  data: AuthDataDto;

  @ApiProperty({ example: null, nullable: true, description: '에러 정보 (성공 시 null)' })
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

// ✅ [수정] 명세서와 일치하도록 Response DTO 수정
export class RefreshResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '토큰 재발급 성공' })
  message: string;

  @ApiProperty({ 
    example: { 
      accessToken: 'new_access_token...', 
      refreshToken: 'new_refresh_token...' 
    },
    description: '재발급된 토큰 정보'
  })
  data: {
    accessToken: string;
    refreshToken: string;
  };

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

// ==========================================
// 5. 로그아웃 (Logout)
// ==========================================

// ✅ [수정] 명세서와 일치하도록 Response DTO 수정
export class LogoutResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '로그아웃 성공' })
  message: string;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

// ==========================================
// 6. 닉네임 중복 확인 (Check Nickname)
// ==========================================

// ✅ [수정] 명세서와 일치하도록 Response DTO 수정
export class CheckNicknameResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '확인 완료' })
  message: string;

  @ApiProperty({ example: { isAvailable: true }, description: 'true면 사용 가능, false면 중복' })
  data: {
    isAvailable: boolean;
  };

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

// 1. 카카오용 Data DTO (isNewUser 추가됨)
export class KakaoAuthDataDto extends AuthDataDto { // 기존 AuthDataDto 상속
  @ApiProperty({ 
    example: false, 
    description: '신규 가입 유저 여부 (true: 신규, false: 기존)' 
  })
  isNewUser: boolean;
}

// 2. 카카오 로그인 성공 응답 (200 OK)
export class KakaoLoginResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '카카오 로그인 성공' })
  message: string;

  @ApiProperty({ type: KakaoAuthDataDto }) // 위에서 만든 전용 Data DTO 사용
  data: KakaoAuthDataDto;

  @ApiProperty({ example: null, nullable: true })
  error: any;
}

// 3. 카카오 로그인 실패 응답 (401 Unauthorized)
export class KakaoUnauthorizedErrorDto {
  @ApiProperty({ example: false })
  success: boolean;

  @ApiProperty({ example: '유효하지 않은 카카오 토큰입니다.' })
  message: string;

  @ApiProperty({ example: null, nullable: true })
  data: any;

  @ApiProperty({ 
    example: { code: 'INVALID_KAKAO_TOKEN' },
    description: '에러 상세 정보'
  })
  error: {
    code: string;
  };
}

// ==========================================
// [신규] 토큰 재발급 실패 DTO (401)
// ==========================================
export class RefreshUnauthorizedErrorDto {
  @ApiProperty({ example: false })
  success: boolean;

  @ApiProperty({ 
    type: ErrorDetailDto, 
    description: '에러 상세 정보' 
  })
  @ApiProperty({ 
    example: { 
      code: 'UNAUTHORIZED', 
      message: '유효하지 않거나 만료된 리프레시 토큰입니다. 다시 로그인해주세요.' 
    } 
  })
  error: ErrorDetailDto;
}