import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spin_app/core/config/env.dart';

/// 앱 전체에서 공유하는 Dio 인스턴스.
///
/// 세션 인증: 로그인 성공 시 서버가 내려주는 세션 쿠키(Set-Cookie)를
/// CookieManager가 기기에 저장하고, 이후 모든 요청에 자동으로 실어 보낸다.
/// 앱을 껐다 켜도 쿠키가 유지된다(PersistCookieJar).
///
/// 사용 전 main()에서 [initApiClient]가 먼저 호출되어야 한다.
/// (테스트에서는 가짜 응답을 주는 Dio로 교체할 수 있도록 final이 아니다.)
late Dio dio;

/// 로그인 세션 쿠키가 저장되는 곳. 로그아웃 시 이 쿠키를 지워서
/// 서버에 별도 로그아웃 API가 없어도 기기에서 세션을 끊을 수 있게 한다.
late PersistCookieJar cookieJar;

Future<void> initApiClient() async {
  final dir = await getApplicationDocumentsDirectory();
  cookieJar = PersistCookieJar(
    storage: FileStorage('${dir.path}/.cookies/'),
  );

  dio = Dio(BaseOptions(baseUrl: Env.baseUrl))
    ..interceptors.add(CookieManager(cookieJar))
    // CSRF: 로그인 시 서버가 내려주는 XSRF-TOKEN 쿠키 값을
    // POST/PUT/DELETE 요청의 X-XSRF-TOKEN 헤더에 자동으로 실어 보낸다.
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          const mutating = {'POST', 'PUT', 'DELETE', 'PATCH'};
          if (mutating.contains(options.method.toUpperCase())) {
            final cookies = await cookieJar.loadForRequest(options.uri);
            for (final cookie in cookies) {
              if (cookie.name == 'XSRF-TOKEN') {
                options.headers['X-XSRF-TOKEN'] = cookie.value;
                break;
              }
            }
          }
          handler.next(options);
        },
      ),
    );

  // 디버그 빌드에서만: 모든 요청/응답을 콘솔에 출력해서
  // 어떤 API가 몇 번 상태 코드로 실패했는지 바로 볼 수 있게 한다.
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
}
