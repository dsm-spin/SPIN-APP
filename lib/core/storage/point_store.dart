import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:spin_app/models/point_model.dart';

/// 앱 전체에서 공유하는 포인트 원장.
///
/// 서버에는 잔액 조회(GET /points)만 있고 적립 "내역" API는 아직 없어서,
/// 체크인에 성공할 때마다 그 결과를 기기에 직접 쌓아 내역을 만든다.
///
/// 사용 전 main()에서 [initPointStore]가 먼저 호출되어야 한다.
/// (테스트에서는 가짜 원장으로 교체할 수 있도록 final이 아니다.)
late PointStore pointStore;

Future<void> initPointStore() async {
  final dir = await getApplicationDocumentsDirectory();
  pointStore = FilePointStore(File('${dir.path}/points.json'));
}

abstract class PointStore {
  /// 적립 내역을 최신순으로 읽어온다.
  Future<List<PointEntry>> load();

  /// 적립 내역 한 건을 추가한다.
  Future<void> add(PointEntry entry);
}

/// 앱 문서 폴더의 JSON 파일(points.json)에 내역을 쌓는 기본 구현.
class FilePointStore implements PointStore {
  final File file;

  FilePointStore(this.file);

  /// 파일이 없거나 내용이 깨졌으면 빈 목록을 준다(내역이 없는 것과 같이 취급).
  @override
  Future<List<PointEntry>> load() async {
    try {
      if (!await file.exists()) return [];

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return [];

      final entries = decoded
          .whereType<Map<String, dynamic>>()
          .map(PointEntry.fromJson)
          .toList();
      entries.sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
      return entries;
    } catch (e) {
      print('포인트 내역 읽기 실패: $e');
      return [];
    }
  }

  /// 저장에 실패해도 예외를 던지지 않는다 — 체크인 자체는 서버에서 이미
  /// 성공했으므로 화면 흐름을 막지 않는다.
  @override
  Future<void> add(PointEntry entry) async {
    try {
      final entries = await load();
      entries.add(entry);
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode(entries.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      print('포인트 내역 저장 실패: $e');
    }
  }
}

/// 화면에 뿌릴 포인트 요약. [balance]는 가장 최근 적립 직후 서버가 알려준
/// 잔액이라, 로컬 합계가 아니라 서버 기준 값이다(앱 설치 전 적립분까지 포함).
class PointLedger {
  final int balance;

  /// 최신순 적립 내역
  final List<PointEntry> entries;

  const PointLedger({required this.balance, required this.entries});

  /// [entries]는 최신순이어야 한다([PointStore.load]가 그렇게 준다).
  factory PointLedger.fromEntries(List<PointEntry> entries) {
    return PointLedger(
      balance: entries.isEmpty ? 0 : entries.first.balanceAfter,
      entries: entries,
    );
  }

  /// 이번 달에 적립한 포인트 합계 (사용 내역은 제외)
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

  /// 적립 내역 건수 (사용 내역은 제외)
  int get earnCount =>
      entries.where((e) => e.type == PointEntryType.earn).length;
}
