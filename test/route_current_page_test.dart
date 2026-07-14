import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spin_app/api/api_client.dart';
import 'package:spin_app/pages/route/route_progress_page.dart';
import 'package:spin_app/route/route.dart';

Response<dynamic> Function(RequestOptions options)? _challengeRespond;
Response<dynamic> Function(RequestOptions options)? _routeDetailRespond;

const _challengeJson = {
  'challengeId': 1,
  'routeId': 2,
  'status': 'IN_PROGRESS',
  'totalStops': 3,
  'checkedInCount': 1,
  'stamps': [
    {'storeName': '볕들다', 'category': '카페', 'visitOrder': 1, 'checkedIn': true},
    {
      'storeName': '선술',
      'category': '이자카야',
      'visitOrder': 2,
      'checkedIn': false,
    },
    {
      'storeName': '궁동버거',
      'category': '수제버거',
      'visitOrder': 3,
      'checkedIn': false,
    },
  ],
  'nextDestination': '선술',
};

void main() {
  setUpAll(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          Response<dynamic> Function(RequestOptions options)? responder;
          if (options.path == '/challenges/current') {
            responder = _challengeRespond;
          } else if (options.path.startsWith('/routes/')) {
            responder = _routeDetailRespond;
          }
          if (responder == null) {
            handler.next(options);
            return;
          }
          try {
            handler.resolve(responder(options));
          } on DioException catch (e) {
            handler.reject(e);
          }
        },
      ),
    );
  });

  setUp(() {
    _challengeRespond = null;
    _routeDetailRespond = null;
  });

  testWidgets('진행 중인 도전이 있으면 스탬프 현황과 다음 목적지를 보여준다', (tester) async {
    _challengeRespond = (options) =>
        Response(requestOptions: options, statusCode: 200, data: _challengeJson);

    await tester.pumpWidget(const MaterialApp(home: RoutePage()));
    await tester.pumpAndSettle();

    expect(find.text('진행 중인 도전'), findsOneWidget);
    expect(find.text('도장  1/3'), findsOneWidget);
    expect(find.text('33% 완료'), findsOneWidget);
    expect(find.text('볕들다'), findsOneWidget);
    expect(find.text('궁동버거'), findsOneWidget);
    // '선술'은 스탬프 목록과 다음 목적지 카드 두 곳에 나타난다.
    expect(find.text('선술'), findsNWidgets(2));
  });

  testWidgets('스탬프를 전부 찍은 도전은 정리하고 양해 문구를 보여준다', (tester) async {
    _challengeRespond = (options) => Response(
      requestOptions: options,
      statusCode: 200,
      data: {
        ..._challengeJson,
        'status': 'COMPLETED',
        'checkedInCount': 3,
      },
    );

    await tester.pumpWidget(const MaterialApp(home: RoutePage()));
    await tester.pumpAndSettle();

    expect(find.text('진행 중인 도전'), findsNothing);
    expect(find.text('루트를 완주했어요!'), findsOneWidget);
    expect(find.textContaining('히스토리 탭에서'), findsOneWidget);
  });

  testWidgets('진행 중인 도전이 없으면(404) 안내 문구를 보여준다', (tester) async {
    _challengeRespond = (options) => throw DioException(
      requestOptions: options,
      response: Response(requestOptions: options, statusCode: 404),
      type: DioExceptionType.badResponse,
    );

    await tester.pumpWidget(const MaterialApp(home: RoutePage()));
    await tester.pumpAndSettle();

    expect(find.text('진행 중인 도전이 없어요'), findsOneWidget);
  });

  testWidgets('지도에서 이어하기를 누르면 루트 상세를 불러와 진행 화면으로 이동한다', (
    tester,
  ) async {
    _challengeRespond = (options) =>
        Response(requestOptions: options, statusCode: 200, data: _challengeJson);
    _routeDetailRespond = (options) => Response(
      requestOptions: options,
      statusCode: 200,
      data: {
        'routeId': 2,
        'totalDistanceMeters': 1200,
        'estimatedDurationMinutes': 40,
        'storeCount': 3,
        'stops': [
          {
            'storeName': '볕들다',
            'category': '카페',
            'address': '궁동 123',
            'walkMinutes': 3,
            'reason': '',
            'latitude': 36.36,
            'longitude': 127.34,
          },
          {
            'storeName': '선술',
            'category': '이자카야',
            'address': '궁동 124',
            'walkMinutes': 5,
            'reason': '',
          },
          {
            'storeName': '궁동버거',
            'category': '수제버거',
            'address': '궁동 125',
            'walkMinutes': 4,
            'reason': '',
          },
        ],
      },
    );

    await tester.pumpWidget(const MaterialApp(home: RoutePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('지도에서 이어하기'));
    await tester.pumpAndSettle();

    expect(find.byType(RouteProgressPage), findsOneWidget);
  });
}
