import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../dto/game_dto.dart';

part 'game_api.g.dart';

@RestApi()
abstract class GameApi {
  factory GameApi(Dio dio, {String baseUrl}) = _GameApi;

  @POST('/game/move')
  Future<MoveResponseDto> move(@Body() MoveDto dto);

  @POST('/game/action/arrest')
  Future<ArrestResponseDto> arrest(@Body() ArrestDto dto);

  @POST('/game/action/rescue')
  Future<RescueResponseDto> rescue(@Body() RescueDto dto);

  @POST('/game/ability/select')
  Future<SelectAbilityResponseDto> selectAbility(@Body() SelectAbilityDto dto);

  @POST('/game/ability/use')
  Future<UseAbilityResponseDto> useAbility(@Body() UseAbilityDto dto);

  @POST('/game/item/select')
  Future<SelectItemResponseDto> selectItem(@Body() SelectItemDto dto);

  @POST('/game/item/use')
  Future<UseItemResponseDto> useItem(@Body() UseItemDto dto);

  @GET('/game/sync/{matchId}')
  Future<SyncGameResponseDto> syncGame(@Path('matchId') String matchId);

  @POST('/game/{matchId}/end')
  Future<EndGameResponseDto> endGame(
    @Path('matchId') String matchId,
    @Body() EndGameDto dto,
  );

  @POST('/game/{matchId}/rematch')
  Future<RematchResponseDto> rematch(@Path('matchId') String matchId);

  @PATCH('/game/{matchId}/host')
  Future<DelegateHostResponseDto> delegateHost(
    @Path('matchId') String matchId,
    @Body() DelegateHostDto dto,
  );

  @POST('/game/{matchId}/leave')
  Future<LeaveGameResponseDto> leaveGame(@Path('matchId') String matchId);
}
