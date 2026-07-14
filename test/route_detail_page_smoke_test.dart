import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spin_app/models/route_model.dart';
import 'package:spin_app/pages/route/route_detail_page.dart';

void main() {
  testWidgets('RouteDetailPage renders sample data without error', (tester) async {
    final result = RouteGenerateResult(
      totalDistanceMeters: 2400,
      estimatedDurationMinutes: 80,
      storeCount: 4,
      stops: const [
        RouteStopModel(
          storeName: '볕들다',
          category: '카페',
          address: '궁동 123',
          walkMinutes: 3,
          reason: '첫 잔은 가볍게, 로스터리 핸드드립으로 시작해요.',
          discountTag: '아메리카노 1+1',
          latitude: 36.3621,
          longitude: 127.3455,
        ),
        RouteStopModel(
          storeName: '선술',
          category: '이자카야',
          address: '궁동 124',
          walkMinutes: 5,
          reason: '골목 안쪽 숨은 술집, 사케 한 잔 곁들이기 좋아요.',
          discountTag: '기본안주 서비스',
        ),
        RouteStopModel(
          storeName: '궁동버거',
          category: '수제버거',
          address: '궁동 125',
          walkMinutes: 4,
          reason: '든든한 메인. 수제 패티가 알찬 집이에요.',
        ),
        RouteStopModel(
          storeName: '달밤',
          category: '디저트바',
          address: '궁동 126',
          walkMinutes: 2,
          reason: '마무리는 달게. 야장에서 먹는 티라미수.',
          discountTag: '디저트 10% 할인',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RouteDetailPage(result: result, region: '궁동', purpose: '하루 종일'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('궁동 하루 종일 코스'), findsOneWidget);
    expect(find.text('볕들다'), findsOneWidget);
    expect(find.text('아메리카노 1+1'), findsOneWidget);
    expect(find.text('4'), findsWidgets);
    expect(find.text('루트 시작'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('루트 시작'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('루트 시작'));
    await tester.pump();
    // routeId가 없는 샘플 데이터이므로 챌린지 API를 호출하지 않고 안내만 뜬다.
    expect(find.text('루트 정보를 찾을 수 없어 시작할 수 없어요'), findsOneWidget);
  });
}
