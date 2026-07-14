import 'package:flutter_test/flutter_test.dart';
import 'package:spin_app/core/components/history_thumbnail.dart';

void main() {
  test('목적에서 여행 테마를 고른다', () {
    expect(
      tripThemeFor(purpose: '혼자 커피 한 잔', storeNames: '볕들다'),
      TripTheme.cafe,
    );
    expect(
      tripThemeFor(purpose: '퇴근하고 맥주', storeNames: '선술'),
      TripTheme.drink,
    );
    expect(
      tripThemeFor(purpose: '친구랑 저녁 먹기', storeNames: '궁동버거'),
      TripTheme.food,
    );
    expect(
      tripThemeFor(purpose: '갑천 산책', storeNames: '한밭수목원'),
      TripTheme.walk,
    );
    expect(
      tripThemeFor(purpose: '전시 보러', storeNames: '시립미술관'),
      TripTheme.culture,
    );
  });

  test('제목(목적)이 가게 이름보다 우선한다', () {
    // '산책'이 제목인데 가게에 '카페'가 있다고 커피잔이 뜨면 안 된다.
    expect(
      tripThemeFor(purpose: '갑천 따라 산책', storeNames: '카페 볕들다, 동네빵집'),
      TripTheme.walk,
    );
    expect(
      tripThemeFor(purpose: '전시 보고 오기', storeNames: '선술, 맥주집'),
      TripTheme.culture,
    );
  });

  test("'혼자' 여행은 가게가 카페여도 혼자 테마", () {
    // 예전엔 목적에 걸리는 낱말이 없어 가게(카페)로 넘어가 커피잔이 떴다.
    expect(
      tripThemeFor(purpose: '혼자 여행', storeNames: '오구 에스프레소바, 욘더'),
      TripTheme.solo,
    );
    expect(
      tripThemeFor(purpose: '혼자 놀기', storeNames: '카페 볕들다'),
      TripTheme.solo,
    );
  });

  test("'혼자 커피 한 잔'처럼 활동이 함께 적히면 그 활동을 따른다", () {
    expect(
      tripThemeFor(purpose: '혼자 커피 한 잔', storeNames: ''),
      TripTheme.cafe,
    );
    expect(
      tripThemeFor(purpose: '혼자 맥주 한잔', storeNames: ''),
      TripTheme.drink,
    );
  });

  test('목적이 비어 있으면 가게 이름에서 고른다', () {
    expect(
      tripThemeFor(purpose: '', storeNames: '골목카페, 동네빵집'),
      TripTheme.cafe,
    );
  });

  test('걸리는 낱말이 없으면 기본 테마', () {
    expect(tripThemeFor(purpose: '그냥 돌아다니기', storeNames: ''), TripTheme.explore);
  });

  test('여러 테마가 걸리면 앞선 테마로 정해진다', () {
    // '카페'와 '한잔'이 함께 있으면 카페
    expect(
      tripThemeFor(purpose: '카페에서 한잔', storeNames: ''),
      TripTheme.cafe,
    );
  });

  test("'미술관'의 '술'을 술집으로 착각하지 않는다", () {
    expect(
      tripThemeFor(purpose: '', storeNames: '대전시립미술관'),
      TripTheme.culture,
    );
  });
}
