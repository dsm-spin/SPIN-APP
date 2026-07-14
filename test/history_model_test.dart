import 'package:flutter_test/flutter_test.dart';
import 'package:spin_app/models/history_model.dart';

void main() {
  test('실서버 GET /challenges/history 응답을 파싱한다', () {
    // 실제 완주 기록 응답을 그대로 옮긴 것 (photoUrl은 미첨부 시 null)
    final model = HistoryModel.fromJson({
      'challengeId': 20,
      'region': '유성구',
      'purpose': '혼자 커피 한 잔',
      'totalDistanceMeters': 953,
      'estimatedDurationMinutes': 14,
      'startedAt': '2026-07-14T08:29:26.271403',
      'completedAt': '2026-07-14T09:39:26.71606',
      'photoUrl': null,
      'storeNames': ['오구 에스프레소바', '샌드바게트', '욘더'],
    });

    expect(model.challengeId, 20);
    expect(model.region, '유성구');
    expect(model.totalDistanceMeters, 953);
    expect(model.completedAt.minute, 39);
    expect(model.photoUrl, '');
    expect(model.storeNames, '오구 에스프레소바, 샌드바게트, 욘더');
    // 제목은 '무엇을 하러 갔는지'
    expect(model.title, '혼자 커피 한 잔');
  });

  test('목적을 안 적은 기록은 지역으로 제목을 세운다', () {
    final model = _history(region: '중구', purpose: '  ');

    expect(model.title, '중구 골목 루트');
  });

  test('목적도 지역도 없으면 기본 제목', () {
    final model = _history(region: '', purpose: '');

    expect(model.title, '골목 루트');
  });
}

HistoryModel _history({required String region, required String purpose}) {
  return HistoryModel(
    challengeId: 1,
    region: region,
    purpose: purpose,
    totalDistanceMeters: 900,
    estimatedDurationMinutes: 20,
    startedAt: DateTime(2026, 7, 14, 15),
    completedAt: DateTime(2026, 7, 14, 16),
    photoUrl: '',
    storeNames: '볕들다',
  );
}
