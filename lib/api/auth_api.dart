import 'package:dio/dio.dart';
import 'package:spin_app/api/api_client.dart';

/// 회원가입. 성공하면 true를 반환한다.
Future<bool> signUpApi(String id, String password) async {
  try {
    final response = await dio.post(
      '/auth/signup',
      data: {'accountId': id, 'password': password},
    );
    return response.statusCode == 200 || response.statusCode == 201;
  } on DioException catch (e) {
    // 403: 이미 존재하는 아이디 (서버가 본문 없이 403만 내려줌)
    print('회원가입 실패 (status: ${e.response?.statusCode}): ${e.message}');
    return false;
  } catch (e) {
    print('회원가입 일반 에러: $e');
    return false;
  }
}

/// 기기에 저장된 세션 쿠키가 아직 서버에서 유효한지 확인한다.
///
/// 전용 "내 정보" API가 따로 없어서, 로그인 세션이 있어야만 접근 가능한
/// 가벼운 엔드포인트(GET /points)를 그대로 프로브로 사용한다.
/// 앱 시작 시 자동 로그인 여부를 판단하는 데 쓴다.
Future<bool> hasValidSession() async {
  try {
    final response = await dio.get('/points');
    return response.statusCode == 200;
  } on DioException {
    // 403 등 인증 실패: 세션이 없거나 만료됨
    return false;
  } catch (e) {
    print('세션 확인 일반 에러: $e');
    return false;
  }
}

/// 로그아웃. 서버에 별도 로그아웃 API가 없어서, 기기에 저장된 세션 쿠키를
/// 직접 지워서 로그인 상태를 끊는다. 이후 [hasValidSession]은 항상 false를 준다.
Future<void> logOutApi() async {
  await cookieJar.deleteAll();
}

/// 로그인. 성공하면 true를 반환한다.
///
/// 성공 시 서버가 내려주는 세션 쿠키는 api_client의 CookieManager가
/// 자동으로 저장하므로, 이후 API 호출은 별도 처리 없이 인증된 상태로 나간다.
Future<bool> logInApi(String id, String password) async {
  try {
    final response = await dio.post(
      '/auth/login',
      data: {'accountId': id, 'password': password},
    );
    return response.statusCode == 200 || response.statusCode == 201;
  } on DioException catch (e) {
    // 403: 아이디 또는 비밀번호 불일치 (서버가 본문 없이 403만 내려줌)
    print('로그인 실패 (status: ${e.response?.statusCode}): ${e.message}');
    return false;
  } catch (e) {
    print('로그인 일반 에러: $e');
    return false;
  }
}
