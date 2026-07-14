import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spin_app/models/route_model.dart';
import 'package:spin_app/pages/route/route_detail_page.dart';
import 'package:spin_app/pages/route/route_map_page.dart';

const _stopsWithCoords = [
  RouteStopModel(
    storeName: '볕들다',
    category: '카페',
    address: '궁동 123',
    walkMinutes: 3,
    reason: '첫 잔',
    latitude: 36.3621,
    longitude: 127.3455,
  ),
  RouteStopModel(
    storeName: '선술',
    category: '이자카야',
    address: '궁동 124',
    walkMinutes: 5,
    reason: '두 번째',
    latitude: 36.3628,
    longitude: 127.3470,
  ),
  RouteStopModel(
    storeName: '궁동버거',
    category: '수제버거',
    address: '궁동 125',
    walkMinutes: 4,
    reason: '세 번째',
    latitude: 36.3634,
    longitude: 127.3461,
  ),
];

void main() {
  test('좌표가 있는 가게들을 방문 순서대로 잇는 경로선을 만든다', () {
    final polylines = buildRoutePolyline(_stopsWithCoords);

    expect(polylines, hasLength(1));
    final polyline = polylines.first;
    expect(polyline.points, const [
      LatLng(36.3621, 127.3455),
      LatLng(36.3628, 127.3470),
      LatLng(36.3634, 127.3461),
    ]);
  });

  test('좌표가 있는 가게가 2곳 미만이면 경로선을 만들지 않는다', () {
    expect(buildRoutePolyline([_stopsWithCoords.first]), isEmpty);
    expect(
      buildRoutePolyline(const [
        RouteStopModel(
          storeName: '좌표없음',
          category: '카페',
          address: '주소',
          walkMinutes: 1,
          reason: '',
        ),
      ]),
      isEmpty,
    );
  });

  test('좌표가 없는 가게는 건너뛰고 마커를 만든다', () async {
    final stops = [
      _stopsWithCoords[0],
      const RouteStopModel(
        storeName: '좌표없음',
        category: '카페',
        address: '주소',
        walkMinutes: 1,
        reason: '',
      ),
      _stopsWithCoords[1],
    ];
    final markers = await buildStopMarkers(stops);

    expect(markers, hasLength(2));
    expect(markers.first.infoWindow.title, '1. 볕들다');
    expect(markers.last.infoWindow.title, '2. 선술');
  });

  testWidgets('상세 화면 미니 지도에 경로선과 마커가 전달된다', (tester) async {
    final result = RouteGenerateResult(
      totalDistanceMeters: 2400,
      estimatedDurationMinutes: 80,
      storeCount: 3,
      stops: _stopsWithCoords,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RouteDetailPage(result: result, region: '유성구', purpose: '데이트'),
      ),
    );
    await tester.pumpAndSettle();

    // 도장 마커 아이콘은 에셋 로드 + 이미지 디코딩을 거치는 실제 비동기 작업이라
    // (buildStopMarkers 단위 테스트에서 별도로 검증) 여기서는 동기적으로 확인
    // 가능한 경로선 전달만 확인한다.
    final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
    expect(map.polylines, hasLength(1));
    expect(map.polylines.first.points, hasLength(3));
  });

  testWidgets('미니 지도를 탭하면 전체 지도 페이지로 이동한다', (tester) async {
    final result = RouteGenerateResult(
      totalDistanceMeters: 2400,
      estimatedDurationMinutes: 80,
      storeCount: 3,
      stops: _stopsWithCoords,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RouteDetailPage(result: result, region: '유성구', purpose: '데이트'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(GoogleMap));
    await tester.pumpAndSettle();

    expect(find.byType(RouteMapPage), findsOneWidget);
    expect(find.text('유성구 루트'), findsOneWidget);
  });
}
