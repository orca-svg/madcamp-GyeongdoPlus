import { Body, Controller, Post, HttpCode, HttpStatus } from '@nestjs/common';
import { AuthService } from './auth.service';
import { LocalSignupDto } from './dto/signup.dto';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('signup')
  @ApiOperation({ summary: '로컬 회원가입', description: '이메일, 비밀번호, 닉네임을 사용하여 회원가입을 진행합니다.' })
  @ApiResponse({
    status: 201,
    description: '회원가입 성공',
    schema: {
      example: {
        success: true,
        message: '회원가입 성공',
        data: {
          accessToken: 'eyJh...',
          refreshToken: 'dGhp...',
          user: {
            id: 'uuid-string',
            email: 'thief123@example.com',
            nickname: 'lupin',
            profileImage: null,
          },
        },
        error: null,
      },
    },
  })
  @ApiResponse({
    status: 409,
    description: '이메일 또는 닉네임 중복',
    schema: {
      example: {
        success: false,
        error: {
            code: "CONFLICT",
            message: "이미 존재하는 이메일 또는 닉네임입니다."
        }
      },
    },
  })
  @HttpCode(HttpStatus.CREATED)
  async signup(@Body() dto: LocalSignupDto) {
    return this.authService.signup(dto);
  }
}