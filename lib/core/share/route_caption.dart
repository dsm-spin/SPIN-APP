/// 완주한 루트를 인스타에 올릴 때 함께 쓸 캡션 문구를 만든다.
///
/// 지역·가게·거리 정보는 루트마다 비어 있을 수 있어(예: 루트 탭에서 이어한 도전은
/// 지역을 모른다) 있는 정보만으로 자연스럽게 이어지도록 한 줄씩 조립한다.
String buildRouteCaption({
  required String region,
  required List<String> storeNames,
  required int distanceMeters,
  required int durationMinutes,
  required int pointsEarned,
}) {
  final stores = storeNames.where((name) => name.trim().isNotEmpty).toList();
  final lines = <String>[];

  final where = region.trim().isEmpty ? '골목' : '대전 ${region.trim()} 골목';
  lines.add(
    stores.isEmpty
        ? '$where 루트 완주! 🎉'
        : '$where 가게 ${stores.length}곳, 오늘 다 돌았어요 🎉',
  );

  if (stores.isNotEmpty) lines.add(stores.join(' → '));

  final stats = <String>[];
  if (distanceMeters > 0) {
    stats.add('${(distanceMeters / 1000).toStringAsFixed(1)}km');
  }
  if (durationMinutes > 0) stats.add(_durationLabel(durationMinutes));
  if (pointsEarned > 0) stats.add('+${pointsEarned}P');
  if (stats.isNotEmpty) lines.add(stats.join(' · '));

  final tags = ['#SPIN', '#골목루트', '#동네탐방'];
  if (region.trim().isNotEmpty) {
    tags.insert(1, '#${region.trim()}');
    tags.insert(1, '#대전');
  }
  lines.add(tags.join(' '));

  return lines.join('\n');
}

/// 80 -> '1h 20m', 45 -> '45m'
String _durationLabel(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours <= 0) return '${rest}m';
  if (rest == 0) return '${hours}h';
  return '${hours}h ${rest}m';
}
