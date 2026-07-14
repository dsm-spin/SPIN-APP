import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spin_app/core/storage/point_store.dart';
import 'package:spin_app/models/point_model.dart';
import 'package:spin_app/pages/point/point_page.dart';

/// 파일 IO 없이 즉시 응답하는 원장. 위젯 테스트의 가짜 시계는 실제 디스크
/// 읽기가 끝나기를 기다려주지 않아, 화면 테스트에서는 이 구현을 끼운다.
class _FakePointStore implements PointStore {
  final List<PointEntry> entries;

  _FakePointStore([List<PointEntry>? entries]) : entries = entries ?? [];

  @override
  Future<List<PointEntry>> load() async {
    return [...entries]..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
  }

  @override
  Future<void> add(PointEntry entry) async {
    entries.add(entry);
  }

  @override
  Future<void> addTestPoint({
    required int points,
    required int challengeId,
    String storeName = '테스트 가게',
  }) async {
    entries.add(
      PointEntry(
        storeName: storeName,
        points: points,
        balanceAfter:
            (entries.isEmpty ? 0 : entries.first.balanceAfter) + points,
        earnedAt: DateTime.now(),
        challengeId: challengeId,
      ),
    );
  }

  @override
  Future<void> spendTestPoint({
    required int points,
    required int challengeId,
    String storeName = '테스트 사용',
  }) async {
    entries.add(
      PointEntry(
        storeName: storeName,
        points: points,
        balanceAfter: ((entries.isEmpty ? 0 : entries.first.balanceAfter) - points)
            .clamp(0, 999999999),
        earnedAt: DateTime.now(),
        challengeId: challengeId,
        type: PointEntryType.spend,
      ),
    );
  }

  @override
  Future<void> markCouponUsed(String code) async {
    final index = entries.indexWhere((e) => e.code == code);
    if (index == -1) return;
    entries[index] = entries[index].copyWith(used: true);
  }

  @override
  Future<void> clear() async {
    entries.clear();
  }
}

void main() {
  testWidgets('적립 내역이 없으면 빈 상태를 보여준다', (tester) async {
    pointStore = _FakePointStore();

    await tester.pumpWidget(const MaterialApp(home: PointPage()));
    await tester.pumpAndSettle();

    expect(find.text('아직 적립 내역이 없어요'), findsOneWidget);
    expect(find.text('0P'), findsOneWidget);
  });

  testWidgets('잔액과 적립 내역을 최신순으로 보여준다', (tester) async {
    pointStore = _FakePointStore([
      PointEntry(
        storeName: '골목커피',
        points: 10,
        balanceAfter: 1190,
        earnedAt: DateTime(2026, 7, 14, 15, 4),
        challengeId: 1,
      ),
      PointEntry(
        storeName: '동네빵집',
        points: 10,
        balanceAfter: 1200,
        earnedAt: DateTime(2026, 7, 14, 16, 20),
        challengeId: 1,
      ),
    ]);

    await tester.pumpWidget(const MaterialApp(home: PointPage()));
    await tester.pumpAndSettle();

    // 잔액은 가장 최근 적립 직후의 서버 잔액
    expect(find.text('1,200P'), findsOneWidget);
    expect(find.text('골목커피'), findsOneWidget);
    expect(find.text('동네빵집'), findsOneWidget);
    expect(find.text('2026.07.14 (화) 15:04'), findsOneWidget);
    expect(find.text('+10P'), findsNWidgets(2));
    expect(find.text('아직 적립 내역이 없어요'), findsNothing);

    final entryRows = tester.widgetList<Text>(
      find.textContaining(RegExp('골목커피|동네빵집')),
    );
    expect(entryRows.first.data, '동네빵집');
  });
}
