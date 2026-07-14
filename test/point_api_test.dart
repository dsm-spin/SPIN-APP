import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spin_app/api/api_client.dart';
import 'package:spin_app/api/point_api.dart';

void main() {
  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
  });

  test('잔액을 파싱한다', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'balance': 30},
            ),
          );
        },
      ),
    );

    expect(await fetchPointBalance(), 30);
  });

  test('세션이 없으면(403) null을 반환한다', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 403),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );

    expect(await fetchPointBalance(), isNull);
  });
}
