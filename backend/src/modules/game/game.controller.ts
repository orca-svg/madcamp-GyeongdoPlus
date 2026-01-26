import { Controller, Post, Body, UseGuards, Req, HttpCode, Get, Param, Patch } from '@nestjs/common';
import { GameService } from './game.service';
import { MoveDto, ArrestDto, RescueDto, UseAbilityDto, UseItemDto, EndGameDto, DelegateHostDto } from './game.dto';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

@ApiTags('Game Action')
@Controller('game')
@UseGuards(AuthGuard('jwt'))
export class GameController {
  constructor(private readonly gameService: GameService) {}

  @Post('move')
  @HttpCode(200) // 201 Created 대신 200 OK 사용
  @ApiOperation({ summary: '위치 이동 및 심박수 전송' })
  async move(@Req() req, @Body() dto: MoveDto) {
    return this.gameService.updatePosition(req.user.id, dto);
  }

  @Post('action/arrest')
  @HttpCode(200)
  @ApiOperation({ summary: '도둑 체포 시도' })
  async arrest(@Req() req, @Body() dto: ArrestDto) {
    return this.gameService.arrestPlayer(req.user.id, dto);
  }

  @Post('action/rescue')
  @HttpCode(200)
  @ApiOperation({ summary: '감옥 해방 시도 (구조)' })
  async rescue(@Req() req, @Body() dto: RescueDto) {
    return this.gameService.rescuePlayer(req.user.id, dto);
  }

  // ⚡ 능력 사용
  @Post('action/ability')
  @HttpCode(200)
  async useAbility(@Req() req, @Body() dto: UseAbilityDto) {
    return this.gameService.useAbility(req.user.id, dto);
  }

  // 🎒 아이템 사용
  @Post('item/use')
  @HttpCode(200)
  async useItem(@Req() req, @Body() dto: UseItemDto) {
    return this.gameService.useItem(req.user.id, dto);
  }

  // 🔄 게임 상태 동기화 (재접속)
  @Get('sync/:matchId')
  async syncGame(@Req() req, @Param('matchId') matchId: string) {
    return this.gameService.syncGameState(req.user.id, matchId);
  }

  // 🏁 게임 종료
  @Post(':matchId/end')
  @HttpCode(201) // 생성(기록 저장)의 의미가 포함되므로 201
  async endGame(@Req() req, @Param('matchId') matchId: string, @Body() dto: EndGameDto) {
    return this.gameService.endGame(req.user.id, matchId, dto);
  }

  // 🔄 게임 다시 하기 (Rematch)
  @Post(':matchId/rematch')
  @HttpCode(201) // 새 방 생성이므로 201
  async rematch(@Req() req, @Param('matchId') matchId: string) {
    // Body가 없어도 DTO를 인자로 받을 수 있음 (현재는 사용 안 함)
    return this.gameService.rematch(req.user.id, matchId);
  }

  // 👑 방장 위임
  @Patch(':matchId/host')
  @HttpCode(201) // 명세서 상 201 Created로 되어있음
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
  async leaveGame(@Req() req, @Param('matchId') matchId: string) {
    return this.gameService.leaveGame(req.user.id, matchId);
  }
}