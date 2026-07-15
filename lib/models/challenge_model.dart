class ChallengeModel {
  final int challengeId;
  final int routeId;
  final String status;
  final int totalStops;
  final int checkedInCount;
  final String startedAt;
  final String completedAt;

  const ChallengeModel({
    required this.challengeId,
    required this.routeId,
    required this.status,
    required this.totalStops,
    required this.checkedInCount,
    required this.startedAt,
    required this.completedAt,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      challengeId: (json['challengeId'] as num?)?.toInt() ?? 0,
      routeId: (json['routeId'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? '',
      totalStops: (json['totalStops'] as num?)?.toInt() ?? 0,
      checkedInCount: (json['checkedInCount'] as num?)?.toInt() ?? 0,
      startedAt: (json['startedAt'] as String?) ?? '',
      completedAt: (json['completedAt'] as String?) ?? '',
    );
  }

  bool get isCompleted => checkedInCount >= totalStops && totalStops > 0;

  int get percentComplete =>
      totalStops <= 0 ? 0 : ((checkedInCount / totalStops) * 100).round();

  ChallengeModel copyWith({int? checkedInCount}) {
    return ChallengeModel(
      challengeId: challengeId,
      routeId: routeId,
      status: status,
      totalStops: totalStops,
      checkedInCount: checkedInCount ?? this.checkedInCount,
      startedAt: startedAt,
      completedAt: completedAt,
    );
  }
}

/// POST /challenges/checkins 응답: 체크인 결과와 포인트 적립 내역.
/// 마지막 도장을 찍으면 status가 COMPLETED로 내려온다.
class CheckInResult {
  final int challengeId;
  final int routeId;
  final String status;
  final int totalStops;
  final int checkedInCount;

  /// 이번 체크인으로 적립된 포인트
  final int pointsEarned;

  /// 적립 후 총 포인트 잔액
  ///
  final int totalPoints;

  /// 이 챌린지를 시작한 시각. completedAt과 같은 응답에서 함께 내려오므로,
  /// 서버 시계가 어느 시간대로 돌든 둘 사이 시간대는 항상 같다
  /// (소요 시간을 구할 땐 이 값과 [completedAt]을 같이 써야 안전하다).
  final String? startedAt;

  /// 완주 시각. 완주 전(진행 중) 체크인 응답에서는 null.
  final String? completedAt;

  const CheckInResult({
    required this.challengeId,
    required this.routeId,
    required this.status,
    required this.totalStops,
    required this.checkedInCount,
    required this.pointsEarned,
    required this.totalPoints,
    this.startedAt,
    this.completedAt,
  });

  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    return CheckInResult(
      challengeId: (json['challengeId'] as num?)?.toInt() ?? 0,
      routeId: (json['routeId'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? '',
      totalStops: (json['totalStops'] as num?)?.toInt() ?? 0,
      checkedInCount: (json['checkedInCount'] as num?)?.toInt() ?? 0,
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      startedAt: json['startedAt'] as String?,
      completedAt: json['completedAt'] as String?,
    );
  }

  bool get isCompleted => status == 'COMPLETED';
}

class StampModel {
  final String storeName;
  final String category;
  final int visitOrder;
  final bool checkedIn;

  const StampModel({
    required this.storeName,
    required this.category,
    required this.visitOrder,
    required this.checkedIn,
  });

  factory StampModel.fromJson(Map<String, dynamic> json) {
    return StampModel(
      storeName: (json['storeName'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      visitOrder: (json['visitOrder'] as num?)?.toInt() ?? 0,
      checkedIn: (json['checkedIn'] as bool?) ?? false,
    );
  }
}

/// 다음 목적지. 서버 스키마가 문자열(가게 이름)인지 좌표를 포함한 객체인지
/// 아직 확정되지 않아, 두 형태 모두 방어적으로 파싱한다.
class NextDestination {
  final String? storeName;
  final double? latitude;
  final double? longitude;

  const NextDestination({this.storeName, this.latitude, this.longitude});

  static NextDestination? fromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      if (value.isEmpty) return null;
      return NextDestination(storeName: value);
    }
    if (value is Map<String, dynamic>) {
      final storeName = value['storeName'] as String?;
      final latitude = (value['latitude'] as num?)?.toDouble();
      final longitude = (value['longitude'] as num?)?.toDouble();
      if (storeName == null && latitude == null && longitude == null) {
        return null;
      }
      return NextDestination(
        storeName: storeName,
        latitude: latitude,
        longitude: longitude,
      );
    }
    return null;
  }
}

/// GET /challenges/current 응답: 현재 진행 중인 챌린지의 스탬프 현황.
class ChallengeProgressModel {
  final int challengeId;
  final int routeId;
  final String status;
  final int totalStops;
  final int checkedInCount;
  final List<StampModel> stamps;
  final NextDestination? nextDestination;

  const ChallengeProgressModel({
    required this.challengeId,
    required this.routeId,
    required this.status,
    required this.totalStops,
    required this.checkedInCount,
    required this.stamps,
    this.nextDestination,
  });

  factory ChallengeProgressModel.fromJson(Map<String, dynamic> json) {
    return ChallengeProgressModel(
      challengeId: (json['challengeId'] as num?)?.toInt() ?? 0,
      routeId: (json['routeId'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? '',
      totalStops: (json['totalStops'] as num?)?.toInt() ?? 0,
      checkedInCount: (json['checkedInCount'] as num?)?.toInt() ?? 0,
      stamps: ((json['stamps'] as List?) ?? [])
          .map((e) => StampModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextDestination: NextDestination.fromDynamic(json['nextDestination']),
    );
  }

  int get percentComplete =>
      totalStops <= 0 ? 0 : ((checkedInCount / totalStops) * 100).round();

  /// 서버가 status를 갱신하기 전에도 스탬프를 다 찍었으면 완료로 본다.
  bool get isCompleted =>
      status == 'COMPLETED' || (totalStops > 0 && checkedInCount >= totalStops);
}
