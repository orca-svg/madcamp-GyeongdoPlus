import { 
  Body, 
  Controller, 
  Post, 
  Get,            
  Query,           
  HttpCode, 
  HttpStatus, 
  UseGuards,       
  Req,
  Headers as HttpHeaders,         
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthGuard } from '@nestjs/passport';
import { 
  LocalSignupDto, 
  SignupResponseDto, 
  SignupConflictErrorDto,
  LocalLoginDto,
  KakaoLoginDto,
  LoginResponseDto,
  RefreshRequestDto,
  RefreshResponseDto,
  LogoutResponseDto,
  CheckNicknameResponseDto,
  KakaoLoginResponseDto,
  KakaoUnauthorizedErrorDto,
  RefreshUnauthorizedErrorDto
} from './auth.dto';
import { ApiOperation, ApiResponse, ApiTags, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('signup')
  @ApiOperation({ summary: '로컬 회원가입' })
  @ApiResponse({ status: 201, type: SignupResponseDto })
  @ApiResponse({ status: 409, type: SignupConflictErrorDto })
  async signup(@Body() dto: LocalSignupDto) {
    return this.authService.signup(dto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '로컬 로그인' })
  @ApiResponse({ status: 200, type: LoginResponseDto })
  async login(@Body() dto: LocalLoginDto) {
    return this.authService.login(dto);
  }

@Post('login/kakao')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '카카오 로그인' })
  
  // ✅ [수정 1] 200 OK 응답 타입을 'LoginResponseDto' -> 'KakaoLoginResponseDto'로 변경
  @ApiResponse({ 
    status: 200, 
    type: KakaoLoginResponseDto, 
    description: '로그인 성공 (isNewUser 포함)' 
  })
  
  // ✅ [추가 2] 401 Unauthorized 에러 명세 추가
  @ApiResponse({ 
    status: 401, 
    type: KakaoUnauthorizedErrorDto, 
    description: '카카오 토큰 만료 또는 위조' 
  })
  async kakaoLogin(@Body() dto: KakaoLoginDto) {
    return this.authService.kakaoLogin(dto);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '토큰 재발급', description: 'Refresh Token을 이용해 AT/RT를 모두 재발급받습니다.' })
  @ApiResponse({ status: 200, type: RefreshResponseDto })
  @ApiResponse({ 
    status: 401, 
    type: RefreshUnauthorizedErrorDto, 
    description: '유효하지 않은 토큰' 
  })
  async refresh(@Body() dto: RefreshRequestDto) {
    return this.authService.refresh(dto);
  }

  @Post('logout')
  @UseGuards(AuthGuard('jwt')) // (*중요) 로그인한 사용자만 접근 가능
  @ApiBearerAuth() // Swagger에 자물쇠 아이콘 추가
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '로그아웃', description: 'Redis에서 Refresh Token을 삭제합니다.' })
  @ApiResponse({ status: 200, type: LogoutResponseDto })
  async logout(@Req() req, @HttpHeaders('Authorization') authHeader: string) {
    const accessToken = authHeader;
    // AuthGuard가 토큰을 해석해서 req.user에 { id, email }을 넣어줍니다.
    return this.authService.logout(req.user.id, accessToken);
  }

  @Get('check-nickname')
  @ApiOperation({ summary: '닉네임 중복 확인', description: '닉네임 사용 가능 여부를 반환합니다.' })
  @ApiQuery({ name: 'nickname', required: true, example: 'lupin' })
  @ApiResponse({ status: 200, type: CheckNicknameResponseDto })
  async checkNickname(@Query('nickname') nickname: string) {
    return this.authService.checkNickname(nickname);
  }
}