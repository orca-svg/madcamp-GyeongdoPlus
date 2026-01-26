import { 
  Controller, 
  Get, 
  Patch, 
  Body, 
  Param, 
  UseGuards, 
  Req,
  Query, 
  Delete
} from '@nestjs/common';
import { UserService } from './user.service';
import { MyProfileResponseDto, OtherProfileResponseDto, UpdateProfileDto, UpdateProfileResponseDto, MatchHistoryQueryDto, MatchHistoryResponseDto, DeleteAccountDto, DeleteAccountResponseDto } from './user.dto';
import { AuthGuard } from '@nestjs/passport'; // 또는 만드신 JwtAuthGuard
import { 
  ApiTags, 
  ApiOperation, 
  ApiResponse, 
  ApiBearerAuth,
  ApiParam
} from '@nestjs/swagger';

@ApiTags('User')
@Controller('user') // 기본 경로: /user
export class UserController {
  constructor(private readonly userService: UserService) {}

  // 1. 내 프로필 조회
  @Get('me')
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth() // 2. 자물쇠 아이콘 추가 (Header Authorization 필요함 표시)
  @ApiOperation({ summary: '내 프로필 조회', description: '자신의 상세 프로필 정보를 조회합니다.' })
  @ApiResponse({ 
    status: 200, 
    description: '조회 성공', 
    type: MyProfileResponseDto // 3. 응답 구조 연결
  })
  @ApiResponse({ status: 401, description: '인증 실패 (토큰 없음)' })
  @ApiResponse({ status: 404, description: '사용자 없음' })
  async getMyProfile(@Req() req) {
    const userId = req.user.id; 
    return this.userService.getMyProfile(userId);
  }

 // 2. 다른 유저 프로필 조회
  @Get('profile/:userId')
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: '다른 유저 프로필 조회', description: '특정 유저의 공개 프로필 정보를 조회합니다. (이메일 등 민감정보 제외)' })
  @ApiParam({ name: 'userId', example: 'target-uuid-5678', description: '조회할 유저의 ID' }) // URL 파라미터 설명 추가
  @ApiResponse({ 
    status: 200, 
    description: '조회 성공', 
    type: OtherProfileResponseDto // ✅ 방금 만든 DTO 연결
  })
  @ApiResponse({ status: 404, description: '사용자를 찾을 수 없음' })
  async getUserProfile(@Param('userId') targetId: string) {
    return this.userService.getUserProfile(targetId);
  }

 // 3. 내 프로필 수정
  @Patch('me')
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: '내 프로필 수정', description: '닉네임 또는 프로필 이미지를 수정합니다.' })
  
  // ✅ [추가] 성공 응답 명세 연결
  @ApiResponse({ 
    status: 200, 
    description: '수정 성공', 
    type: UpdateProfileResponseDto 
  })
  // ✅ [추가] 실패 응답 명세 (409 Conflict)
  @ApiResponse({ 
    status: 409, 
    description: '이미 존재하는 닉네임' 
  })
  async updateProfile(@Req() req, @Body() dto: UpdateProfileDto) {
    const userId = req.user.id;
    return this.userService.updateProfile(userId, dto);
  }

  // 📜 전적 조회 API
  @Get('me/history')
  @UseGuards(AuthGuard('jwt')) // ✅ 로그인 필수 (Req.user 사용하므로)
  @ApiBearerAuth()
  @ApiOperation({ summary: '전적 기록 조회', description: '나의 과거 게임 기록을 페이징하여 조회합니다.' })
  
  // ✅ [추가] 성공 응답 연결
  @ApiResponse({ 
    status: 200, 
    description: '조회 성공', 
    type: MatchHistoryResponseDto 
  })
  async getMatchHistory(@Req() req, @Query() query: MatchHistoryQueryDto) {
    const userId = req.user.id;
    return this.userService.getMatchHistory(userId, query);
  }
  
    // 👋 회원 탈퇴 API
  @Delete('me')
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: '회원 탈퇴', description: '서비스에서 탈퇴하고 모든 데이터를 삭제합니다.' })
  
  // ✅ [추가] 성공 응답 명세 연결
  @ApiResponse({ 
    status: 200, 
    description: '탈퇴 성공', 
    type: DeleteAccountResponseDto 
  })
  // ✅ [추가] 실패 응답 명세 (동의 안 함)
  @ApiResponse({ 
    status: 400, 
    description: '데이터 삭제 미동의' 
  })
  async deleteAccount(@Req() req, @Body() dto: DeleteAccountDto) {
    const userId = req.user.id;
    return this.userService.deleteAccount(userId, dto);
  }
}
