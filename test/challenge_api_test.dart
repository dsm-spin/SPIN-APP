import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spin_app/api/api_client.dart';
import 'package:spin_app/api/challenge_api.dart';

void main() {
  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
  });

  test('체크인 성공 시 qrCode를 그대로 보내고 결과를 파싱한다', () async {
    Map<String, dynamic>? sentBody;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          sentBody = options.data as Map<String, dynamic>;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'challengeId': 1,
                'routeId': 2,
                'status': 'IN_PROGRESS',
                'totalStops': 3,
                'checkedInCount': 2,
                'pointsEarned': 50,
                'totalPoints': 120,
              },
            ),
          );
        },
      ),
    );

    final outcome = await checkIn(qrCode: 'STORE-QR-CODE-123');

    expect(sentBody, {'qrCode': 'STORE-QR-CODE-123'});
    expect(outcome.error, isNull);
    expect(outcome.data!.checkedInCount, 2);
    expect(outcome.data!.pointsEarned, 50);
    expect(outcome.data!.totalPoints, 120);
    expect(outcome.data!.isCompleted, isFalse);
  });

  test('전체 스탑을 다 찍으면 status가 COMPLETED로 내려온다', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'challengeId': 1,
                'routeId': 2,
                'status': 'COMPLETED',
                'totalStops': 3,
                'checkedInCount': 3,
                'pointsEarned': 50,
                'totalPoints': 300,
              },
            ),
          );
        },
      ),
    );

    final outcome = await checkIn(qrCode: 'STORE-QR-CODE-999');

    expect(outcome.data!.isCompleted, isTrue);
    expect(outcome.data!.checkedInCount, outcome.data!.totalStops);
  });

  test('400이면 진행 중인 루트에 없는 가게 에러를 반환한다', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 400),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );

    final outcome = await checkIn(qrCode: 'OTHER-ROUTE-QR');

    expect(outcome.data, isNull);
    expect(outcome.error, CheckInError.storeNotInChallenge);
  });

  test('409면 이미 체크인한 가게 에러를 반환한다', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 409),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );

    final outcome = await checkIn(qrCode: 'ALREADY-DONE-QR');

    expect(outcome.data, isNull);
    expect(outcome.error, CheckInError.alreadyCheckedIn);
  });

  test('404면 존재하지 않는 QR 코드 에러를 반환한다', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 404),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );

    final outcome = await checkIn(qrCode: 'UNKNOWN-QR');

    expect(outcome.data, isNull);
    expect(outcome.error, CheckInError.unknownCode);
  });

  group('normalizeQrCheckInCode', () {
    test('가게 QR 원문에서 code 값만 뽑아낸다', () {
      expect(
        normalizeQrCheckInCode(
          'spin://checkin?code=3ad0af6c-786d-498a-99a4-2aab116d5818',
        ),
        '3ad0af6c-786d-498a-99a4-2aab116d5818',
      );
    });

    test('코드값만 담긴 QR은 그대로 둔다', () {
      expect(normalizeQrCheckInCode('PLAIN-CODE-123'), 'PLAIN-CODE-123');
    });

    test('앞뒤 공백을 제거한다', () {
      expect(normalizeQrCheckInCode('  PLAIN-CODE-123 '), 'PLAIN-CODE-123');
    });
  });

  test('스캔한 QR 원문을 보내면 code 값만 서버로 전송한다', () async {
    Map<String, dynamic>? sentBody;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          sentBody = options.data as Map<String, dynamic>;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'challengeId': 20,
                'routeId': 66,
                'status': 'IN_PROGRESS',
                'totalStops': 3,
                'checkedInCount': 1,
                'pointsEarned': 10,
                'totalPoints': 10,
              },
            ),
          );
        },
      ),
    );

    final outcome = await checkIn(
      qrCode: 'spin://checkin?code=3ad0af6c-786d-498a-99a4-2aab116d5818',
    );

    expect(sentBody, {'qrCode': '3ad0af6c-786d-498a-99a4-2aab116d5818'});
    expect(outcome.error, isNull);
    expect(outcome.data!.pointsEarned, 10);
  });
}
