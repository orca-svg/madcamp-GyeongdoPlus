import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../dto/lobby_dto.dart';

part 'lobby_api.g.dart';

@RestApi()
abstract class LobbyApi {
  factory LobbyApi(Dio dio, {String baseUrl}) = _LobbyApi;

  @POST('/lobby/create')
  Future<CreateRoomResponseDto> createRoom(@Body() CreateRoomDto dto);

  @POST('/lobby/join')
  Future<JoinRoomResponseDto> joinRoom(@Body() JoinRoomDto dto);

  @POST('/lobby/kick')
  Future<KickUserResponseDto> kickUser(@Body() KickUserDto dto);

  @GET('/lobby/{matchId}')
  Future<GetRoomDetailsResponseDto> getRoomDetails(
    @Path('matchId') String matchId,
  );

  @PATCH('/lobby/{matchId}')
  Future<UpdateRoomResponseDto> updateRoom(
    @Path('matchId') String matchId,
    @Body() UpdateRoomDto dto,
  );

  @POST('/lobby/start')
  Future<StartGameResponseDto> startGame(@Body() StartGameDto dto);
}
