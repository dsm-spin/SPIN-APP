class HistoryModel {
  final int challengeId;
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
      challengeId: json['challengeId'] as int,
      region: json['region'] as String,
      purpose: json['purpose'] as String,
      totalDistanceMeters: json['totalDistanceMeters'] as int,
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: DateTime.parse(json['completedAt'] as String),
      photoUrl: json['photoUrl'] as String,
      storeNames: json['storeNames'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challengeId': challengeId,
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
