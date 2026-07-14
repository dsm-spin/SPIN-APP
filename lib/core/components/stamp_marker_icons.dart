import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spin_app/core/theme/colors.dart';

/// 도장 마커 크기. 미니 지도는 작게, 전체 지도(상세)는 크게 그린다.
enum StampMarkerSize {
  compact(diameter: 40, fontSize: 11),
  detail(diameter: 68, fontSize: 24);

  const StampMarkerSize({required this.diameter, required this.fontSize});

  final double diameter;
  final double fontSize;
}

/// 지도 마커용 도장 아이콘. 아직 방문하지 않은 곳은 순번이 적힌 빈 도장,
/// QR 체크인을 마친 곳은 stamp.png로 채워진 도장으로 그린다.
class StampMarkerIcons {
  StampMarkerIcons._();

  static const double _scale = 3;

  static ui.Image? _stampImage;
  static final Map<String, BitmapDescriptor> _emptyCache = {};
  static final Map<StampMarkerSize, BitmapDescriptor> _filledCache = {};

  static Future<ui.Image> _loadStampImage() async {
    final cached = _stampImage;
    if (cached != null) return cached;
    final data = await rootBundle.load('assets/images/stamp.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    _stampImage = frame.image;
    return frame.image;
  }

  /// 순번이 적힌 빈 도장 (아직 체크인하지 않은 가게)
  static Future<BitmapDescriptor> empty(
    int order, {
    StampMarkerSize size = StampMarkerSize.compact,
  }) async {
    final cacheKey = '${size.name}_$order';
    final cached = _emptyCache[cacheKey];
    if (cached != null) return cached;

    final diameter = size.diameter;
    final canvasSize = diameter * _scale;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(canvasSize / 2, canvasSize / 2);
    final radius = canvasSize / 2 - _scale * 2;

    canvas.drawCircle(center, radius, Paint()..color = AppColors.background);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.button
        ..style = PaintingStyle.stroke
        ..strokeWidth = _scale * 2.4,
    );

    final painter = TextPainter(
      text: TextSpan(
        text: '$order',
        style: TextStyle(
          fontSize: size.fontSize * _scale,
          fontWeight: FontWeight.w800,
          color: AppColors.button,
          fontFamily: 'SUITVariable',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));

    final icon = await _finish(recorder, canvasSize, diameter);
    _emptyCache[cacheKey] = icon;
    return icon;
  }

  /// stamp.png로 채워진 도장 (체크인 완료한 가게)
  static Future<BitmapDescriptor> filled({
    StampMarkerSize size = StampMarkerSize.compact,
  }) async {
    final cached = _filledCache[size];
    if (cached != null) return cached;

    final image = await _loadStampImage();
    final diameter = size.diameter;
    final canvasSize = diameter * _scale;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(canvasSize / 2, canvasSize / 2);
    final radius = canvasSize / 2 - _scale * 1.5;
    final destRect = Rect.fromCircle(center: center, radius: radius);

    canvas.save();
    canvas.clipPath(Path()..addOval(destRect));
    final srcSize = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(BoxFit.cover, srcSize, destRect.size);
    final srcRect = Alignment.center.inscribe(fitted.source, Offset.zero & srcSize);
    canvas.drawImageRect(
      image,
      srcRect,
      destRect,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.button
        ..style = PaintingStyle.stroke
        ..strokeWidth = _scale * 1.5,
    );

    final icon = await _finish(recorder, canvasSize, diameter);
    _filledCache[size] = icon;
    return icon;
  }

  static Future<BitmapDescriptor> _finish(
    ui.PictureRecorder recorder,
    double canvasSize,
    double diameter,
  ) async {
    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasSize.round(), canvasSize.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: diameter,
      height: diameter,
    );
  }
}
