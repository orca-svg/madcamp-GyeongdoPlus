import { Controller, Post, Body, UseGuards, Req, HttpCode, Get, Param, Patch } from '@nestjs/common';
import { GameService } from './game.service';
import { 
  MoveDto, MoveResponseDto, 
  ArrestDto, ArrestResponseDto, 
  RescueDto, RescueResponseDto, RescueRangeErrorDto, 
  SelectAbilityDto, SelectAbilityResponseDto, SelectAbilityErrorDto,
  UseAbilityDto, UseAbilityResponseDto, AbilityGaugeErrorDto, 
  SelectItemDto, SelectItemResponseDto, ItemTimeErrorDto, ItemConflictErrorDto, 
  UseItemDto, UseItemResponseDto, 
  SyncGameResponseDto,
  EndGameDto, EndGameResponseDto,
  RematchResponseDto,
  DelegateHostDto, DelegateHostResponseDto,
  LeaveGameResponseDto 
} from './game.dto';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

@ApiTags('Game Action')
@Controller('game')
@UseGuards(AuthGuard('jwt'))
export class GameController {
  constructor(private readonly gameService: GameService) {}

  @Post('move')
  @HttpCode(200)
  @ApiOperation({ 
    summary: '위치 이동 및 자동 체포 판정', 
    description: '1. 위치/심박수 업데이트 <br> 2. (경찰) 1m 내 도둑 자동 체포 진행 <br> 3. 주변 50m 플레이어/미끼 목록 반환 (투명 유저 제외)' 
  })
  @ApiResponse({ 
    status: 200, 
    description: '위치 업데이트 및 주변 정보 조회 성공', 
    type: MoveResponseDto 
  })
  async move(@Req() req, @Body() dto: MoveDto) {
    return this.gameService.updatePosition(req.user.id, dto);
  }

  @Post('action/arrest')
  @HttpCode(200)
  @ApiOperation({ 
    summary: '도둑 자수(항복)', 
    description: '도둑이 스스로 게임을 포기하고 체포 상태가 됩니다. (경찰의 체포는 /move에서 자동 처리됨)' 
  })
  @ApiResponse({ 
    status: 200, 
    description: '자수 성공', 
    type: ArrestResponseDto 
  })
  async arrest(@Req() req, @Body() dto: ArrestDto) {
    return this.gameService.surrender(req.user.id, dto);
  }

@Post('action/rescue')
  @HttpCode(200)
  @ApiOperation({ summary: '감옥 해방 시도 (구조)', description: '감옥 영역 내에서 호출 시 규칙에 따라 수감자를 구출합니다.' })
  
  // ✅ [추가] 성공 응답 (200)
  @ApiResponse({ 
    status: 200, 
    description: '구출 성공', 
    type: RescueResponseDto 
  })
  // ✅ [추가] 실패 - 거리 (400)
  @ApiResponse({ 
    status: 400, 
    description: '감옥 영역 밖임', 
    type: RescueRangeErrorDto 
  })
  async rescue(@Req() req, @Body() dto: RescueDto) {
    return this.gameService.rescuePlayer(req.user.id, dto);
  }

  // 1. 능력(직업) 선택
  @Post('ability/select')
  @HttpCode(200)
  @ApiOperation({ 
    summary: '능력(직업) 선택', 
    description: '준비 시간(PREPARE)에 자신의 역할에 맞는 직업을 선택합니다.' 
  })
  // ✅ [성공] 200 OK
  @ApiResponse({ 
    status: 200, 
    description: '직업 선택 성공', 
    type: SelectAbilityResponseDto 
  })
  // ❌ [실패] 400 Bad Request (역할 불일치 등)
  @ApiResponse({ 
    status: 400, 
    description: '역할에 맞지 않는 직업 선택 또는 준비 시간이 아님', 
    type: SelectAbilityErrorDto 
  })
  async selectAbility(@Req() req, @Body() dto: SelectAbilityDto) {
    return this.gameService.selectAbility(req.user.id, dto);
  }

  // 2. 능력(액티브) 사용
  @Post('ability/use')
  @HttpCode(200)
  @ApiOperation({ 
    summary: '능력(액티브) 사용', 
    description: '선택한 직업의 고유 액티브 능력을 사용합니다.' 
  })
  // ✅ [성공] 200 OK
  @ApiResponse({ 
    status: 200, 
    description: '능력 사용 성공', 
    type: UseAbilityResponseDto 
  })
  // ❌ [실패] 400 Bad Request (직업 미선택, 쿨타임 등)
  @ApiResponse({ 
    status: 400, 
    description: '직업이 선택되지 않았거나 사용할 수 없는 상태', 
    // 필요 시 UseAbilityErrorDto도 만들어서 연결 가능
  })
  async useAbility(@Req() req, @Body() dto: UseAbilityDto) {
    return this.gameService.useAbility(req.user.id, dto);
  }

  // 🎁 아이템 선택 (시간 보상)
  @Post('item/select')
  @HttpCode(200)
  @ApiOperation({ 
    summary: '아이템 선택 (시간 경과 보상)', 
    description: '게임 시작 후 10분/20분이 경과했을 때 아이템을 선택하여 획득합니다.' 
  })
  
  // ✅ [성공] 200 OK
  @ApiResponse({ 
    status: 200, 
    description: '아이템 획득 성공', 
    type: SelectItemResponseDto 
  })
  // ❌ [실패] 400 Bad Request (시간 미달)
  @ApiResponse({ 
    status: 400, 
    description: '아직 선택 가능한 시간이 아님', 
    type: ItemTimeErrorDto 
  })
  // ❌ [실패] 409 Conflict (이미 수령함)
  @ApiResponse({ 
    status: 409, 
    description: '이미 해당 구간 보상을 수령함', 
    type: ItemConflictErrorDto 
  })
  async selectItem(@Req() req, @Body() dto: SelectItemDto) {
    return this.gameService.selectItem(req.user.id, dto);
  }

@Post('item/use')
  @HttpCode(200)
  @ApiOperation({ 
    summary: '아이템 사용 (8종 전체 구현)', 
    description: `
      다음 아이템을 사용하여 효과를 발동합니다.
      
      **[경찰 아이템]**
      - RADAR: 7초간 모든 도둑 위치 노출
      - RESCUE_BLOCK: 15초간 감옥 구출 차단
      - THIEF_DETECTOR: 이동 시 5m 내 도둑 있으면 진동 (1회)
      - AREA_SIREN: 반경 30m 도둑에게 경보 (팀 1회)

      **[도둑 아이템]**
      - DECOY: 현재 위치에 미끼 설치 (밟으면 경찰 위치 노출)
      - RESCUE_BOOST: 10초간 구출 능력 강화 (인원 증가)
      - EMP: 15초간 경찰 아이템 무력화
      - REMOTE_RESCUE: 감옥 10m 내에서 원격으로 3명 구출 (팀 1회)
    ` 
  })
  @ApiResponse({ status: 200, type: UseItemResponseDto })
  async useItem(@Req() req, @Body() dto: UseItemDto) {
    return this.gameService.useItem(req.user.id, dto);
  }

// 🔄 게임 상태 동기화 (재접속)
  @Get('sync/:matchId')
  @ApiOperation({ summary: '게임 상태 동기화 (재접속)', description: '앱을 껐다 켰거나 재접속 시 현재 게임 상태(점수, 위치, 아이템 등)를 복구합니다.' })
  
  // ✅ [추가] 성공 응답 (200)
  @ApiResponse({ 
    status: 200, 
    description: '동기화 데이터 반환', 
    type: SyncGameResponseDto 
  })
  @ApiResponse({ status: 404, description: '참여 중인 게임 아님' })
  async syncGame(@Req() req, @Param('matchId') matchId: string) {
    return this.gameService.syncGameState(req.user.id, matchId);
  }

// 🏁 게임 종료
  @Post(':matchId/end')
  @HttpCode(201)
  @ApiOperation({ 
    summary: '게임 종료 및 결과 저장', 
    description: '방장이 게임을 종료시킵니다. Redis 데이터를 RDB로 이관하고, MVP 및 승리 팀을 산정하여 결과를 반환합니다.' 
  })
  
  // ✅ [추가] 성공 응답 (201 Created) - 명세서 image_84870e.png 반영
  @ApiResponse({ 
    status: 201, 
    description: '게임 종료 성공 및 결과 데이터 반환', 
    type: EndGameResponseDto 
  })
  async endGame(@Req() req, @Param('matchId') matchId: string, @Body() dto: EndGameDto) {
    return this.gameService.endGame(req.user.id, matchId, dto);
  }

  // 🔄 게임 다시 하기 (Rematch)
  @Post(':matchId/rematch')
  @HttpCode(201)
  @ApiOperation({ 
    summary: '게임 다시 하기 (새 방 생성)', 
    description: '이전 게임의 설정(맵, 규칙 등)을 그대로 가져와서 새로운 대기실을 만듭니다. 요청자가 새 방장이 됩니다.' 
  })
  
  // ✅ [추가] 성공 응답 (201 Created)
  @ApiResponse({ 
    status: 201, 
    description: '새로운 대기실 생성 성공', 
    type: RematchResponseDto 
  })
  async rematch(@Req() req, @Param('matchId') matchId: string) {
    return this.gameService.rematch(req.user.id, matchId);
  }

// 👑 방장 위임
  @Patch(':matchId/host')
  @HttpCode(200) // 201 Created 보다는 200 OK가 적절 (수정이므로)
  @ApiOperation({ 
    summary: '방장 권한 위임', 
    description: '현재 방장이 다른 플레이어에게 방장 권한을 넘깁니다.' 
  })
  
  // ✅ [추가] 성공 응답 (200 OK)
  @ApiResponse({ 
    status: 200, 
    description: '방장 변경 성공', 
    type: DelegateHostResponseDto 
  })
  @ApiResponse({ status: 403, description: '권한 없음 (방장 아님)' })
  @ApiResponse({ status: 404, description: '대상 유저 없음' })
  async delegateHost(
    @Req() req, 
    @Param('matchId') matchId: string, 
    @Body() dto: DelegateHostDto
  ) {
    return this.gameService.delegateHost(req.user.id, matchId, dto);
  }

// 🚪 방 퇴장
  @Post(':matchId/leave')
  @HttpCode(200)
  @ApiOperation({ 
    summary: '방 퇴장 (탈주 처리)', 
    description: '대기 중일 때는 단순히 나가고, 게임 중일 때는 탈주(LEFT) 처리됩니다. 방장일 경우 자동으로 다른 사람에게 권한이 위임됩니다.' 
  })
  
  // ✅ [추가] 성공 응답 (200 OK)
  @ApiResponse({ 
    status: 200, 
    description: '퇴장 성공', 
    type: LeaveGameResponseDto 
  })
  async leaveGame(@Req() req, @Param('matchId') matchId: string) {
    return this.gameService.leaveGame(req.user.id, matchId);
  }
}