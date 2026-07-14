// 개발용 미리보기 엔트리포인트. 좌표가 포함된 샘플 데이터로 루트 상세/진행 화면을 바로 띄운다.
// 실행: flutter run -t lib/main_preview.dart
import 'package:flutter/material.dart';
import 'package:spin_app/models/challenge_model.dart';
import 'package:spin_app/models/history_model.dart';
import 'package:spin_app/models/route_model.dart';
import 'package:spin_app/models/store_model.dart';
import 'package:spin_app/pages/history/history_detail.dart';
import 'package:spin_app/pages/history/history_instargram.dart';
import 'package:spin_app/pages/route/route_complete_dialog.dart';
import 'package:spin_app/pages/route/route_detail_page.dart';
import 'package:spin_app/pages/route/route_progress_page.dart';

void main() {
  runApp(const _PreviewApp());
}

const _stops = [
  RouteStopModel(
    storeName: '볕들다',
    category: '카페',
    address: '궁동 123',
    walkMinutes: 3,
    reason: '첫 잔은 가볍게, 로스터리 핸드드립으로 시작해요.',
    discountTag: '아메리카노 1+1',
    latitude: 36.3608,
    longitude: 127.3452,
  ),
  RouteStopModel(
    storeName: '선술',
    category: '이자카야',
    address: '궁동 124',
    walkMinutes: 5,
    reason: '골목 안쪽 숨은 술집, 사케 한 잔 곁들이기 좋아요.',
    discountTag: '기본안주 서비스',
    latitude: 36.3625,
    longitude: 127.3478,
  ),
  RouteStopModel(
    storeName: '궁동버거',
    category: '수제버거',
    address: '궁동 125',
    walkMinutes: 4,
    reason: '든든한 메인. 수제 패티가 알찬 집이에요.',
    latitude: 36.3641,
    longitude: 127.3466,
  ),
  RouteStopModel(
    storeName: '달밤',
    category: '디저트바',
    address: '궁동 126',
    walkMinutes: 2,
    reason: '마무리는 달게. 야장에서 먹는 티라미수.',
    discountTag: '디저트 10% 할인',
    latitude: 36.3632,
    longitude: 127.3441,
  ),
];

const _result = RouteGenerateResult(
  totalDistanceMeters: 2400,
  estimatedDurationMinutes: 80,
  storeCount: 4,
  stops: _stops,
);

const _challenge = ChallengeModel(
  challengeId: 1,
  routeId: 1,
  status: 'IN_PROGRESS',
  totalStops: 4,
  checkedInCount: 1,
  startedAt: '2026-07-14T00:00:00.000Z',
  completedAt: '',
);

// 실좌표 기반 지도/사진 배경 공유 카드를 미리 보기 위한 샘플 데이터.
final _sampleStores = [
  for (final s in _stops)
    StoreModel(
      name: s.storeName,
      address: s.address,
      latitude: s.latitude!,
      longitude: s.longitude!,
    ),
];

final _sampleHistory = HistoryModel(
  challengeId: 1,
  routeId: 1,
  region: '유성구',
  purpose: '친구랑 저녁 먹고 갑천 따라 산책하기',
  totalDistanceMeters: 2400,
  estimatedDurationMinutes: 80,
  startedAt: DateTime(2026, 7, 14, 15),
  completedAt: DateTime(2026, 7, 14, 17, 20),
  photoUrl: '',
  storeNames: [for (final s in _stops) s.storeName].join(', '),
);

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RouteDetailPage(
                        result: _result,
                        region: '유성구',
                        purpose: '하루 종일',
                      ),
                    ),
                  ),
                  child: const Text('루트 상세 화면'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RouteProgressPage(
                        result: _result,
                        region: '유성구',
                        challenge: _challenge,
                      ),
                    ),
                  ),
                  child: const Text('루트 진행 화면'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HistoryDetail(
                        history: _sampleHistory,
                        stores: _sampleStores,
                      ),
                    ),
                  ),
                  child: const Text('히스토리 상세 (실좌표)'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HistoryInstargram(
                        history: _sampleHistory,
                        stores: _sampleStores,
                        hasRealLocation: true,
                      ),
                    ),
                  ),
                  child: const Text('인스타 공유 (실제 지도 + 사진 배경)'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => showRouteCompleteDialog(
                    context,
                    history: _sampleHistory,
                    stores: _sampleStores,
                    hasRealLocation: true,
                  ),
                  child: const Text('완주 축하 다이얼로그 (실제 지도)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
