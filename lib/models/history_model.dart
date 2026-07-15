class HistoryModel {
  final int challengeId;
  final int? routeId;
  final String region;
  final String purpose;
  final int totalDistanceMeters;
  final int estimatedDurationMinutes;
  final DateTime startedAt;
  final DateTime completedAt;
  final String photoUrl;
  final String storeNames;

  const HistoryModel({
    required this.challengeId,
    this.routeId,
    required this.region,
    required this.purpose,
    required this.totalDistanceMeters,
    required this.estimatedDurationMinutes,
    required this.startedAt,
    required this.completedAt,
    required this.photoUrl,
    required this.storeNames,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      // 서버 OpenAPI 스펙(RouteHistoryResponse)엔 required 필드가 하나도
      // 없어서, 모든 필드가 null로 내려올 수 있다는 전제로 안전하게 캐스팅한다.
      challengeId: (json['challengeId'] as num?)?.toInt() ?? 0,
      routeId: (json['routeId'] as num?)?.toInt(),
      region: (json['region'] as String?) ?? '',
      purpose: (json['purpose'] as String?) ?? '',
      totalDistanceMeters: (json['totalDistanceMeters'] as num?)?.toInt() ?? 0,
      estimatedDurationMinutes:
          (json['estimatedDurationMinutes'] as num?)?.toInt() ?? 0,
      startedAt:
          DateTime.tryParse((json['startedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      completedAt:
          DateTime.tryParse((json['completedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      // 미첨부 시 서버가 null을 내려준다
      photoUrl: (json['photoUrl'] as String?) ?? '',
      // 서버는 방문 순서대로의 가게 이름 "배열"을 내려준다
      storeNames: ((json['storeNames'] as List?) ?? []).join(', '),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challengeId': challengeId,
      'routeId': routeId,
      'region': region,
      'purpose': purpose,
      'totalDistanceMeters': totalDistanceMeters,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
      'photoUrl': photoUrl,
      'storeNames': storeNames,
    };
  }

  /// 인스타그램 스토리에 링크 스티커로 붙일 공유 페이지 URL. routeId가 없으면 null.
  String? get shareUrl => routeId == null
      ? null
      : 'https://dsm-spin.github.io/SPIN-BE/share/?routeId=$routeId';

  /// 이 여행에서 뭘 하려고 했는지 — 히스토리의 제목으로 쓴다.
  /// 목적을 안 적고 만든 루트는 지역만으로 제목을 세운다.
  String get title {
    final purpose = this.purpose.trim();
    if (purpose.isNotEmpty) return purpose;

    final region = this.region.trim();
    return region.isEmpty ? '골목 루트' : '$region 골목 루트';
  }

  /// totalDistanceMeters를 '3.4' (km) 형태로 변환
  String get distanceKmLabel => (totalDistanceMeters / 1000).toStringAsFixed(1);

  /// 소요 시간을 '3h 21m' 형태로 변환
  String get durationLabel {
    final duration = completedAt.difference(startedAt);
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  }

  /// completedAt을 '2026.06.18 (목)' 형태로 변환
  String get completedAtLabel {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final d = completedAt;
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y.$m.$day (${weekdays[d.weekday - 1]})';
  }
}
