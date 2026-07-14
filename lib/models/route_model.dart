class RouteStopModel {
  final String storeName;
  final String category;
  final String address;
  final int walkMinutes;
  final String reason;
  final String discountTag;
  final double? latitude;
  final double? longitude;

  const RouteStopModel({
    required this.storeName,
    required this.category,
    required this.address,
    required this.walkMinutes,
    required this.reason,
    this.discountTag = '',
    this.latitude,
    this.longitude,
  });

  factory RouteStopModel.fromJson(Map<String, dynamic> json) {
    return RouteStopModel(
      storeName: json['storeName'] as String,
      category: (json['category'] as String?) ?? '',
      address: json['address'] as String,
      walkMinutes: (json['walkMinutes'] as int?) ?? 0,
      reason: (json['reason'] as String?) ?? '',
      discountTag: (json['discountTag'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class RouteGenerateResult {
  final int? routeId;
  final String? region;
  final String? purpose;
  final int totalDistanceMeters;
  final int estimatedDurationMinutes;
  final int storeCount;
  final List<RouteStopModel> stops;

  /// 이 루트를 완주한 사람 수. 공유 링크 미리보기(GET /routes/{routeId})에서만
  /// 내려온다 — "이 루트, N명이 다녀갔어요"를 보여주는 데 쓴다.
  final int? completedCount;

  const RouteGenerateResult({
    this.routeId,
    this.region,
    this.purpose,
    required this.totalDistanceMeters,
    required this.estimatedDurationMinutes,
    required this.storeCount,
    required this.stops,
    this.completedCount,
  });

  factory RouteGenerateResult.fromJson(Map<String, dynamic> json) {
    final stops = ((json['stops'] as List?) ?? [])
        .map((e) => RouteStopModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return RouteGenerateResult(
      routeId: (json['routeId'] as num?)?.toInt(),
      region: json['region'] as String?,
      purpose: json['purpose'] as String?,
      totalDistanceMeters: (json['totalDistanceMeters'] as int?) ?? 0,
      estimatedDurationMinutes: (json['estimatedDurationMinutes'] as int?) ?? 0,
      // 공유 미리보기 응답엔 storeCount가 따로 없어서, 없으면 stops 개수로 대신한다.
      storeCount: (json['storeCount'] as int?) ?? stops.length,
      stops: stops,
      completedCount: (json['completedCount'] as num?)?.toInt(),
    );
  }
}
