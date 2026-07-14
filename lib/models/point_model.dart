/// 포인트 내역 한 건의 종류. 체크인 적립인지, 혜택 교환으로 인한 사용인지 구분한다.
enum PointEntryType { earn, spend }

/// 포인트 내역 한 건. 체크인 적립이나 혜택 교환 때마다 한 건씩 기기에 쌓인다.
class PointEntry {
  /// 적립이면 도장을 찍은 가게 이름, 사용이면 교환한 혜택 이름
  final String storeName;

  /// 적립/사용된 포인트 크기(항상 양수). 적립인지 사용인지는 [type]으로 구분한다.
  final int points;

  /// 이 내역이 반영된 직후의 총 잔액.
  /// 적립 내역은 서버가 체크인 응답으로 내려준 값을 그대로 보관하고,
  /// 사용 내역은 교환 시점에 기기에서 직접 계산한 값이다
  /// (서버에 아직 포인트 사용 API가 없어서 기기에서만 처리한다).
  final int balanceAfter;

  final DateTime earnedAt;

  final int challengeId;

  final PointEntryType type;

  /// 혜택 교환(사용) 내역에만 있는 교환 코드. 가게 직원에게 보여주는 코드로,
  /// [CouponsPage]에서 다시 조회할 수 있도록 저장해둔다.
  final String? code;

  /// 교환 코드를 실제로 가게에서 사용 처리했는지 여부. 적립 내역에는 의미 없다.
  final bool used;

  const PointEntry({
    required this.storeName,
    required this.points,
    required this.balanceAfter,
    required this.earnedAt,
    required this.challengeId,
    this.type = PointEntryType.earn,
    this.code,
    this.used = false,
  });

  factory PointEntry.fromJson(Map<String, dynamic> json) {
    return PointEntry(
      storeName: (json['storeName'] as String?) ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toInt() ?? 0,
      earnedAt:
          DateTime.tryParse((json['earnedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      challengeId: (json['challengeId'] as num?)?.toInt() ?? 0,
      // 기존에 저장된 내역(사용 기능 이전)은 전부 적립이었다.
      type: (json['type'] as String?) == 'spend'
          ? PointEntryType.spend
          : PointEntryType.earn,
      code: json['code'] as String?,
      used: (json['used'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeName': storeName,
      'points': points,
      'balanceAfter': balanceAfter,
      'earnedAt': earnedAt.toIso8601String(),
      'challengeId': challengeId,
      'type': type == PointEntryType.spend ? 'spend' : 'earn',
      'code': code,
      'used': used,
    };
  }

  PointEntry copyWith({bool? used}) {
    return PointEntry(
      storeName: storeName,
      points: points,
      balanceAfter: balanceAfter,
      earnedAt: earnedAt,
      challengeId: challengeId,
      type: type,
      code: code,
      used: used ?? this.used,
    );
  }

  /// earnedAt을 '2026.07.14 (화) 15:04' 형태로 변환
  String get earnedAtLabel {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final d = earnedAt.toLocal();
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.year}.$month.$day (${weekdays[d.weekday - 1]}) $hour:$minute';
  }
}
