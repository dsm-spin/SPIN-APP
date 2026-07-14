import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spin_app/api/api_client.dart';
import 'package:spin_app/core/storage/point_store.dart';
import 'package:spin_app/models/challenge_model.dart';
import 'package:spin_app/models/history_model.dart';
import 'package:spin_app/models/point_model.dart';
import 'package:spin_app/models/reward_model.dart';
import 'package:spin_app/models/route_model.dart';
import 'package:spin_app/models/store_model.dart';
import 'package:spin_app/pages/auth/log_in.dart';
import 'package:spin_app/pages/auth/sign_up/sign_up.dart';
import 'package:spin_app/pages/history/history.dart';
import 'package:spin_app/pages/history/history_detail.dart';
import 'package:spin_app/pages/history/history_instargram.dart';
import 'package:spin_app/pages/home/home.dart';
import 'package:spin_app/pages/point/point_page.dart';
import 'package:spin_app/pages/point/redemption_success_page.dart';
import 'package:spin_app/pages/point/rewards_page.dart';
import 'package:spin_app/pages/route/route_detail_page.dart';

/// 기기별 화면 크기(논리 픽셀). 가장 작은 기기(iPhone SE 1세대급)부터
/// 가장 큰 기기(Pro Max급)까지 훑는다. 여기서 RenderFlex 오버플로가 나면
/// 위젯 테스트가 예외로 잡아내므로, 화면을 띄우는 것만으로 검증이 된다.
const _phones = <String, Size>{
  'SE 1세대 (320x568)': Size(320, 568),
  'SE 3세대 (375x667)': Size(375, 667),
  'iPhone 16 (393x852)': Size(393, 852),
  'Pro Max (430x932)': Size(430, 932),
};

/// 글꼴 크기를 키운 사용자(접근성 설정). 작은 기기 + 큰 글꼴이 가장 빡세다.
const _textScales = <double>[1.0, 1.3];

class _FakePointStore implements PointStore {
  final List<PointEntry> entries;

  _FakePointStore(this.entries);

  @override
  Future<List<PointEntry>> load() async => entries;

  @override
  Future<void> add(PointEntry entry) async => entries.add(entry);
}

final _history = HistoryModel(
  challengeId: 1,
  routeId: 2,
  region: '유성구',
  purpose: '친구랑 저녁 먹고 갑천 따라 산책하기',
  totalDistanceMeters: 3400,
  estimatedDurationMinutes: 80,
  startedAt: DateTime(2026, 7, 14, 15),
  completedAt: DateTime(2026, 7, 14, 17, 20),
  photoUrl: '',
  storeNames: '오구 에스프레소바, 샌드바게트, 욘더, 궁동버거',
);

const _stores = [
  StoreModel(
    name: '오구 에스프레소바',
    address: '유성구 궁동 123',
    latitude: 36.3608,
    longitude: 127.3452,
  ),
  StoreModel(
    name: '샌드바게트',
    address: '유성구 궁동 124',
    latitude: 36.3625,
    longitude: 127.3478,
  ),
  StoreModel(
    name: '욘더',
    address: '유성구 궁동 125',
    latitude: 36.3641,
    longitude: 127.3440,
  ),
];

const _routeResult = RouteGenerateResult(
  routeId: 2,
  totalDistanceMeters: 3400,
  estimatedDurationMinutes: 80,
  storeCount: 3,
  stops: [
    RouteStopModel(
      storeName: '오구 에스프레소바',
      category: '카페',
      address: '유성구 궁동 123',
      walkMinutes: 3,
      reason: '첫 잔은 가볍게, 로스터리 핸드드립으로 시작해요.',
      discountTag: '아메리카노 1+1',
      latitude: 36.3608,
      longitude: 127.3452,
    ),
    RouteStopModel(
      storeName: '샌드바게트',
      category: '베이커리',
      address: '유성구 궁동 124',
      walkMinutes: 5,
      reason: '갓 구운 바게트가 나오는 시간에 맞춰 들르기 좋아요.',
      discountTag: '기본안주 서비스',
      latitude: 36.3625,
      longitude: 127.3478,
    ),
    RouteStopModel(
      storeName: '욘더',
      category: '수제버거',
      address: '유성구 궁동 125',
      walkMinutes: 4,
      reason: '든든한 메인. 수제 패티가 알찬 집이에요.',
      latitude: 36.3641,
      longitude: 127.3440,
    ),
  ],
);

final _entries = [
  PointEntry(
    storeName: '오구 에스프레소바',
    points: 20,
    balanceAfter: 1210,
    earnedAt: DateTime(2026, 7, 14, 16),
    challengeId: 1,
  ),
  PointEntry(
    storeName: '아메리카노 1잔 무료',
    points: -1500,
    balanceAfter: 1190,
    earnedAt: DateTime(2026, 7, 13, 12),
    challengeId: 0,
    type: PointEntryType.spend,
  ),
];

/// 화면마다 (이름, 만드는 법). 모두 실제 페이지 위젯이다.
final _screens = <String, Widget Function()>{
  '홈': () => const Home(),
  '로그인': () => const LogInWidget(),
  '회원가입': () => const SignUpWidget(),
  '포인트': () => const PointPage(),
  '혜택 교환': () => const RewardsPage(initialBalance: 1200),
  '교환 완료': () => RedemptionSuccessPage(
    reward: rewardCatalog.first,
    code: 'SPIN-1A2B-3C4D',
    remainingBalance: 300,
  ),
  '히스토리 목록': () => const HistoryList(),
  '히스토리 상세': () => HistoryDetail(history: _history, stores: _stores),
  '인스타 공유': () => HistoryInstargram(history: _history, stores: _stores),
  '루트 상세': () => const RouteDetailPage(
    result: _routeResult,
    region: '유성구',
    purpose: '친구랑 저녁 먹고 산책',
  ),
};

void main() {
  setUp(() {
    pointStore = _FakePointStore([..._entries]);

    // 히스토리 목록이 부르는 GET /challenges/history를 가짜 응답으로 막는다.
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: [_history.toJson()..['storeNames'] = ['욘더', '궁동버거']],
          ),
        ),
      ),
    );
  });

  for (final phone in _phones.entries) {
    for (final textScale in _textScales) {
      for (final screen in _screens.entries) {
        testWidgets('${screen.key} — ${phone.key}, 글꼴 x$textScale', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = phone.value;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: phone.value,
                textScaler: TextScaler.linear(textScale),
              ),
              child: MaterialApp(home: screen.value()),
            ),
          );
          await tester.pumpAndSettle();

          // 세로 스크롤이 있는 화면은 끝까지 훑어 아래쪽도 확인한다.
          final scrollable = find.byType(Scrollable);
          if (scrollable.evaluate().isNotEmpty) {
            await tester.drag(scrollable.first, const Offset(0, -400));
            await tester.pumpAndSettle();
          }
        });
      }
    }
  }
}
