import { Controller, Post, Body, UseGuards, Req, Get, Param, Patch } from '@nestjs/common';
import { LobbyService } from './lobby.service';
import { CreateRoomDto, CreateRoomResponseDto, JoinRoomDto, JoinRoomConflictErrorDto, JoinRoomNotFoundErrorDto, JoinRoomResponseDto, KickUserDto, KickUserForbiddenErrorDto, KickUserResponseDto, GetRoomDetailsResponseDto, UpdateRoomDto, UpdateRoomResponseDto, UpdateRoleDto, UpdateRoleResponseDto, StartGameDto, StartGameResponseDto } from './lobby.dto';
import { AuthGuard } from '@nestjs/passport'; // (JwtAuthGuard)
import { ApiBearerAuth, ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

@ApiTags('Lobby')
@Controller('lobby')
@UseGuards(AuthGuard('jwt')) // 토큰 필수
@ApiBearerAuth()
export class LobbyController {
  constructor(private readonly lobbyService: LobbyService) {}

  @Post('create')
  @ApiOperation({ summary: '게임 방 생성', description: '새로운 게임 방을 생성하고 호스트로 입장합니다.' })
  
  // ✅ [추가] 성공 응답 명세 (201 Created)
  @ApiResponse({ 
    status: 201, 
    description: '방 생성 성공', 
    type: CreateRoomResponseDto 
  })
  async createRoom(@Req() req, @Body() dto: CreateRoomDto) {
    return this.lobbyService.createRoom(req.user.id, dto);
  }

  @Post('join')
  @ApiOperation({ summary: '게임 방 참가', description: '참여 코드(RoomCode)를 입력하여 방에 입장합니다.' })
  
  // ✅ [추가] 성공 (200)
  @ApiResponse({ 
    status: 200, 
    description: '입장 성공', 
    type: JoinRoomResponseDto 
  })
  // ✅ [추가] 실패 - 방 없음 (404)
  @ApiResponse({ 
    status: 404, 
    description: '방을 찾을 수 없음', 
    type: JoinRoomNotFoundErrorDto 
  })
  // ✅ [추가] 실패 - 꽉 참/시작됨 (409)
  @ApiResponse({ 
    status: 409, 
    description: '입장 불가 (만원/진행중)', 
    type: JoinRoomConflictErrorDto 
  })
  async joinRoom(@Req() req, @Body() dto: JoinRoomDto) {
    return this.lobbyService.joinRoom(req.user.id, dto);
  }

  @Post('kick')
  @ApiOperation({ summary: '유저 강퇴하기', description: '방장(Host) 권한으로 특정 유저를 대기실에서 내보냅니다.' })
  
  // ✅ [추가] 성공 (200)
  @ApiResponse({ 
    status: 200, 
    description: '강퇴 성공', 
    type: KickUserResponseDto 
  })
  // ✅ [추가] 실패 - 권한 없음 (403)
  @ApiResponse({ 
    status: 403, 
    description: '권한 없음 (방장 아님)', 
    type: KickUserForbiddenErrorDto 
  })
  // ✅ [추가] 실패 - 찾을 수 없음 (404)
  @ApiResponse({ 
    status: 404, 
    description: '방을 찾을 수 없음' 
  })
  async kickUser(@Req() req, @Body() dto: KickUserDto) {
    return this.lobbyService.kickUser(req.user.id, dto);
  }

  // 📜 방 상세 정보 조회
  @Get(':matchId')
  @ApiOperation({ summary: '방 상세 정보 조회', description: '방의 설정(Settings)과 현재 참여 중인 플레이어 목록(Players)을 조회합니다.' })
  
  // ✅ [추가] 성공 응답 명세 (200)
  @ApiResponse({ 
    status: 200, 
    description: '조회 성공', 
    type: GetRoomDetailsResponseDto 
  })
  @ApiResponse({ 
    status: 404, 
    description: '방을 찾을 수 없음' 
  })
  async getRoomDetails(@Param('matchId') matchId: string) {
    return this.lobbyService.getRoomDetails(matchId);
  }

// ⚙️ 방 설정 변경
  @Patch(':matchId')
  @ApiOperation({ summary: '방 설정 변경', description: '방장(Host) 권한으로 게임 모드, 시간, 맵 등을 변경합니다.' })
  
  // ✅ [추가] 성공 응답 (200)
  @ApiResponse({ 
    status: 200, 
    description: '변경 성공', 
    type: UpdateRoomResponseDto 
  })
  // ✅ [추가] 실패 - 권한 없음 (403)
  @ApiResponse({ 
    status: 403, 
    description: '권한 없음 (방장 아님)', 
    type: KickUserForbiddenErrorDto // 에러 포맷이 같아서 재사용
  })
  async updateRoomSettings(
    @Req() req,
    @Param('matchId') matchId: string,
    @Body() dto: UpdateRoomDto
  ) {
    return this.lobbyService.updateRoomSettings(req.user.id, matchId, dto);
  }

  // 🎭 역할 선택
  @Patch('role')
  @ApiOperation({ summary: '역할 선택', description: '대기실(Waiting) 상태에서 경찰/도둑 역할을 변경합니다.' })
  
  // ✅ 성공 응답 (200)
  @ApiResponse({ 
    status: 200, 
    description: '역할 변경 성공', 
    type: UpdateRoleResponseDto 
  })
  // ✅ 실패 - 게임 이미 시작됨 (409)
  @ApiResponse({ 
    status: 409, 
    description: '이미 게임이 시작됨', 
    type: JoinRoomConflictErrorDto // { code: 'GAME_ALREADY_STARTED' }
  })
  // ✅ 실패 - 방 없음 (404)
  @ApiResponse({ 
    status: 404, 
    description: '방을 찾을 수 없음' 
  })
  async updatePlayerRole(@Req() req, @Body() dto: UpdateRoleDto) {
    return this.lobbyService.updatePlayerRole(req.user.id, dto);
  }
  
  // 🚀 게임 시작
  @Post('start')
  @ApiOperation({ summary: '게임 시작', description: '방장(Host) 권한으로 게임을 시작 상태로 변경합니다.' })
  
  // ✅ [추가] 성공 응답 (200)
  @ApiResponse({ 
    status: 200, 
    description: '게임 시작 성공', 
    type: StartGameResponseDto 
  })
  // ✅ [추가] 실패 - 권한 없음 (403)
  @ApiResponse({ 
    status: 403, 
    description: '권한 없음 (방장 아님)', 
    type: KickUserForbiddenErrorDto 
  })
  // ✅ [추가] 실패 - 인원 부족 (400)
  @ApiResponse({ 
    status: 400, 
    description: '인원 부족 (최소 2명)' 
  })
  async startGame(@Req() req, @Body() dto: StartGameDto) {
    return this.lobbyService.startGame(req.user.id, dto);
  }
}