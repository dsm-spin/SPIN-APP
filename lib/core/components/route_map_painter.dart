import 'package:flutter/material.dart';
import 'package:spin_app/models/store_model.dart';

/// 매장들의 실제 좌표를 캔버스에 정규화해 배치하고 직각 연결선으로 잇는 루트맵.
/// 히스토리 상세 카드와 인스타 스토리 공유 이미지에서 공용으로 사용한다.
class RouteMapPainter extends CustomPainter {
  final List<StoreModel> stores;

  RouteMapPainter({required this.stores});

  static const _lineColor = Color(0xFF6F7F45);
  // 라벨/마커가 캔버스 밖으로 나가지 않도록 두는 여백 비율
  static const _padding = 0.14;

  /// 좌표 바운딩 박스를 캔버스 크기에 맞게 정규화 (위도가 클수록 위쪽)
  List<Offset> _normalizePositions(Size size) {
    var minLat = stores.first.latitude, maxLat = stores.first.latitude;
    var minLng = stores.first.longitude, maxLng = stores.first.longitude;
    for (final s in stores) {
      if (s.latitude < minLat) minLat = s.latitude;
      if (s.latitude > maxLat) maxLat = s.latitude;
      if (s.longitude < minLng) minLng = s.longitude;
      if (s.longitude > maxLng) maxLng = s.longitude;
    }
    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;
    final drawWidth = size.width * (1 - _padding * 2);
    final drawHeight = size.height * (1 - _padding * 2);

    return [
      for (final s in stores)
        Offset(
          size.width * _padding +
              (lngRange == 0 ? 0.5 : (s.longitude - minLng) / lngRange) * drawWidth,
          size.height * _padding +
              (latRange == 0 ? 0.5 : (maxLat - s.latitude) / latRange) * drawHeight,
        ),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (stores.isEmpty) return;

    final n = stores.length;
    final positions = _normalizePositions(size);

    final linePaint = Paint()
      ..color = _lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 직각 연결선: 세로로 이동한 뒤 가로로 이동
    final path = Path()..moveTo(positions[0].dx, positions[0].dy);
    for (var i = 1; i < n; i++) {
      path.lineTo(positions[i - 1].dx, positions[i].dy);
      path.lineTo(positions[i].dx, positions[i].dy);
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = _lineColor;
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(positions[i], 7, dotPaint);
      _paintLabel(canvas, size, stores[i].name, positions[i]);
    }
  }

  void _paintLabel(Canvas canvas, Size size, String text, Offset dot) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: 'SUITVariable',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // 위쪽에 있는 노드는 라벨을 위로, 아래쪽 노드는 아래로
    final above = dot.dy < size.height / 2;
    final dx = (dot.dx - painter.width / 2).clamp(0.0, size.width - painter.width);
    final dy = above ? dot.dy - painter.height - 14 : dot.dy + 14;
    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(RouteMapPainter oldDelegate) {
    if (oldDelegate.stores.length != stores.length) return true;
    for (var i = 0; i < stores.length; i++) {
      final a = oldDelegate.stores[i];
      final b = stores[i];
      if (a.name != b.name || a.latitude != b.latitude || a.longitude != b.longitude) {
        return true;
      }
    }
    return false;
  }
}
