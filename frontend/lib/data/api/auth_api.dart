import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../dto/auth_dto.dart';

part 'auth_api.g.dart';

@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String baseUrl}) = _AuthApi;

  @POST('/auth/signup')
  Future<SignupResponseDto> signup(@Body() LocalSignupDto dto);

  @POST('/auth/login')
  Future<LoginResponseDto> login(@Body() LocalLoginDto dto);

  @POST('/auth/login/kakao')
  Future<KakaoLoginResponseDto> kakaoLogin(@Body() KakaoLoginDto dto);

  @POST('/auth/refresh')
  Future<RefreshResponseDto> refresh(@Body() RefreshRequestDto dto);

  @POST('/auth/logout')
  Future<LogoutResponseDto> logout();

  @GET('/auth/check-nickname')
  Future<CheckNicknameResponseDto> checkNickname(
    @Query('nickname') String nickname,
  );
}
