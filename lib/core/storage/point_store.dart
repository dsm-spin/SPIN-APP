import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:spin_app/models/point_model.dart';

/// 앱 전체에서 공유하는 포인트 원장.
///
/// 서버에는 잔액 조회(GET /points)만 있고
/// 적립 내역 API는 아직 없으므로
/// 체크인 성공 시 기기에 직접 저장한다.
late PointStore pointStore;

Future<void> initPointStore() async {
  final dir = await getApplicationDocumentsDirectory();
  pointStore = FilePointStore(File('${dir.path}/points.json'));
}

abstract class PointStore {
  /// 적립 내역 조회
  Future<List<PointEntry>> load();

  /// 적립 내역 추가
  Future<void> add(PointEntry entry);

  /// 테스트용 적립
  Future<void> addTestPoint({
    required int points,
    required int challengeId,
    String storeName = '테스트 가게',
  });

  /// 테스트용 사용
  Future<void> spendTestPoint({
    required int points,
    required int challengeId,
    String storeName = '테스트 사용',
  });

  /// 전체 삭제
  Future<void> clear();

  /// 교환 코드로 쿠폰(사용 내역)을 찾아 사용 완료로 표시
  Future<void> markCouponUsed(String code);
}

class FilePointStore implements PointStore {
  final File file;

  FilePointStore(this.file);

  @override
  Future<List<PointEntry>> load() async {
    try {
      if (!await file.exists()) {
        return [];
      }

      final decoded = jsonDecode(await file.readAsString());

      if (decoded is! List) {
        return [];
      }

      final entries = decoded
          .whereType<Map<String, dynamic>>()
          .map(PointEntry.fromJson)
          .toList();

      entries.sort((a, b) => b.earnedAt.compareTo(a.earnedAt));

      return entries;
    } catch (e) {
      print('포인트 불러오기 실패 : $e');
      return [];
    }
  }

  Future<void> _save(List<PointEntry> entries) async {
    await file.parent.create(recursive: true);

    await file.writeAsString(
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<void> add(PointEntry entry) async {
    try {
      final entries = await load();

      entries.insert(0, entry);

      await _save(entries);
    } catch (e) {
      print(e);
    }
  }

  @override
  Future<void> addTestPoint({
    required int points,
    required int challengeId,
    String storeName = '테스트 가게',
  }) async {
    try {
      final entries = await load();

      final currentBalance = entries.isEmpty ? 0 : entries.first.balanceAfter;

      final entry = PointEntry(
        storeName: storeName,
        points: points,
        balanceAfter: currentBalance + points,
        earnedAt: DateTime.now(),
        challengeId: challengeId,
        type: PointEntryType.earn,
      );

      entries.insert(0, entry);

      await _save(entries);
    } catch (e) {
      print(e);
    }
  }

  @override
  Future<void> spendTestPoint({
    required int points,
    required int challengeId,
    String storeName = '테스트 사용',
  }) async {
    try {
      final entries = await load();

      final currentBalance = entries.isEmpty ? 0 : entries.first.balanceAfter;

      final remain = (currentBalance - points).clamp(0, 999999999);

      final entry = PointEntry(
        storeName: storeName,
        points: points,
        balanceAfter: remain,
        earnedAt: DateTime.now(),
        challengeId: challengeId,
        type: PointEntryType.spend,
      );

      entries.insert(0, entry);

      await _save(entries);
    } catch (e) {
      print(e);
    }
  }

  @override
  Future<void> markCouponUsed(String code) async {
    try {
      final entries = await load();

      final index = entries.indexWhere((e) => e.code == code);
      if (index == -1) return;

      entries[index] = entries[index].copyWith(used: true);

      await _save(entries);
    } catch (e) {
      print(e);
    }
  }

  @override
  Future<void> clear() async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print(e);
    }
  }
}

/// ---------------------------
/// 화면에 사용하는 포인트 정보
/// ---------------------------

class PointLedger {
  final int balance;

  final List<PointEntry> entries;

  const PointLedger({required this.balance, required this.entries});

  factory PointLedger.fromEntries(List<PointEntry> entries) {
    return PointLedger(
      balance: entries.isEmpty ? 0 : entries.first.balanceAfter,
      entries: entries,
    );
  }

  /// 이번 달 적립 포인트 합계
  int earnedThisMonth(DateTime now) {
    return entries
        .where(
          (e) =>
              e.type == PointEntryType.earn &&
              e.earnedAt.toLocal().year == now.year &&
              e.earnedAt.toLocal().month == now.month,
        )
        .fold(0, (sum, e) => sum + e.points);
  }

  /// 적립 횟수
  int get earnCount =>
      entries.where((e) => e.type == PointEntryType.earn).length;

  /// 사용 횟수
  int get spendCount =>
      entries.where((e) => e.type == PointEntryType.spend).length;

  /// 총 적립 포인트
  int get totalEarned => entries
      .where((e) => e.type == PointEntryType.earn)
      .fold(0, (sum, e) => sum + e.points);

  /// 총 사용 포인트
  int get totalSpent => entries
      .where((e) => e.type == PointEntryType.spend)
      .fold(0, (sum, e) => sum + e.points);

  /// 특정 챌린지의 적립 내역
  List<PointEntry> entriesByChallenge(int challengeId) {
    return entries.where((e) => e.challengeId == challengeId).toList();
  }

  /// 특정 가게의 적립 내역
  List<PointEntry> entriesByStore(String storeName) {
    return entries.where((e) => e.storeName == storeName).toList();
  }
  /// 최근 적립 내역
  PointEntry? get latestEntry => entries.isEmpty ? null : entries.first;

  /// 현재 잔액이 있는지
  bool get hasPoint => balance > 0;

  /// 내역 존재 여부
  bool get hasEntries => entries.isNotEmpty;

  /// 혜택 교환으로 생긴 쿠폰 목록 (사용 내역)
  List<PointEntry> get coupons =>
      entries.where((e) => e.type == PointEntryType.spend).toList();

  /// 아직 가게에서 사용하지 않은 쿠폰 수
  int get unusedCouponCount => coupons.where((e) => !e.used).length;
}
