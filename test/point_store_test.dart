import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spin_app/core/storage/point_store.dart';
import 'package:spin_app/models/point_model.dart';

void main() {
  late Directory tempDir;
  late FilePointStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('point_store_test');
    store = FilePointStore(File('${tempDir.path}/points.json'));
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  PointEntry entry({
    required String storeName,
    required int points,
    required int balanceAfter,
    required DateTime earnedAt,
  }) {
    return PointEntry(
      storeName: storeName,
      points: points,
      balanceAfter: balanceAfter,
      earnedAt: earnedAt,
      challengeId: 1,
    );
  }

  test('내역이 없으면 빈 목록을 준다', () async {
    expect(await store.load(), isEmpty);
  });

  test('추가한 내역이 저장되고 최신순으로 읽힌다', () async {
    await store.add(
      entry(
        storeName: '골목커피',
        points: 10,
        balanceAfter: 10,
        earnedAt: DateTime(2026, 7, 14, 10),
      ),
    );
    await store.add(
      entry(
        storeName: '동네빵집',
        points: 20,
        balanceAfter: 30,
        earnedAt: DateTime(2026, 7, 14, 12),
      ),
    );

    final entries = await store.load();

    expect(entries.map((e) => e.storeName), ['동네빵집', '골목커피']);
    expect(entries.first.points, 20);
    expect(entries.first.balanceAfter, 30);
  });

  test('잔액은 가장 최근 적립 직후의 서버 잔액이다', () async {
    await store.add(
      entry(
        storeName: '골목커피',
        points: 10,
        balanceAfter: 110,
        earnedAt: DateTime(2026, 7, 14, 10),
      ),
    );
    await store.add(
      entry(
        storeName: '동네빵집',
        points: 20,
        balanceAfter: 130,
        earnedAt: DateTime(2026, 7, 14, 12),
      ),
    );

    final ledger = PointLedger.fromEntries(await store.load());

    // 로컬 합계(30)가 아니라 서버가 알려준 잔액(130)
    expect(ledger.balance, 130);
    expect(ledger.earnedThisMonth(DateTime(2026, 7, 20)), 30);
    expect(ledger.earnedThisMonth(DateTime(2026, 8, 1)), 0);
  });

  test('파일이 깨져 있으면 빈 목록으로 취급한다', () async {
    await File('${tempDir.path}/points.json').writeAsString('{ 이건 JSON이 아니다');

    expect(await store.load(), isEmpty);
  });
}
