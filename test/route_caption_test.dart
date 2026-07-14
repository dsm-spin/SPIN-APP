import 'package:flutter_test/flutter_test.dart';
import 'package:spin_app/core/share/route_caption.dart';

void main() {
  test('지역·가게·거리·시간·포인트를 캡션으로 조립한다', () {
    final caption = buildRouteCaption(
      region: '유성구',
      storeNames: ['볕들다', '선술', '궁동버거'],
      distanceMeters: 3400,
      durationMinutes: 80,
      pointsEarned: 40,
    );

    expect(caption, '''
대전 유성구 골목 가게 3곳, 오늘 다 돌았어요 🎉
볕들다 → 선술 → 궁동버거
3.4km · 1h 20m · +40P
#SPIN #대전 #유성구 #골목루트 #동네탐방''');
  });

  test('지역을 모르면 지역 문구와 지역 해시태그를 뺀다', () {
    final caption = buildRouteCaption(
      region: '',
      storeNames: ['볕들다', '선술'],
      distanceMeters: 900,
      durationMinutes: 45,
      pointsEarned: 20,
    );

    expect(caption, '''
골목 가게 2곳, 오늘 다 돌았어요 🎉
볕들다 → 선술
0.9km · 45m · +20P
#SPIN #골목루트 #동네탐방''');
  });

  test('비어 있는 정보는 줄에서 빠진다', () {
    final caption = buildRouteCaption(
      region: '중구',
      storeNames: [],
      distanceMeters: 0,
      durationMinutes: 0,
      pointsEarned: 0,
    );

    expect(caption, '''
대전 중구 골목 루트 완주! 🎉
#SPIN #대전 #중구 #골목루트 #동네탐방''');
  });
}
