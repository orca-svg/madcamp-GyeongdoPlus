import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../dto/user_dto.dart';

part 'user_api.g.dart';

@RestApi()
abstract class UserApi {
  factory UserApi(Dio dio, {String baseUrl}) = _UserApi;

  @GET('/user/me')
  Future<MyProfileResponseDto> getMyProfile();

  @GET('/user/profile/{userId}')
  Future<OtherProfileResponseDto> getUserProfile(@Path('userId') String userId);

  @PATCH('/user/me')
  Future<UpdateProfileResponseDto> updateProfile(@Body() UpdateProfileDto dto);

  @GET('/user/me/history')
  Future<MatchHistoryResponseDto> getMatchHistory(
    @Queries() MatchHistoryQueryDto query,
  );

  @DELETE('/user/me')
  Future<DeleteAccountResponseDto> deleteAccount(@Body() DeleteAccountDto dto);
}
