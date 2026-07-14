import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spin_app/core/components/route_map_painter.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/models/store_model.dart';
import 'package:spin_app/pages/route/route_map_page.dart' show daejeonCenter;

/// 가게 실좌표들을 실제 Google 지도 위에 경로선으로 이어 캡처한 PNG를 만든다.
/// (나이키런 클럽처럼 완주 경로를 진짜 지도 배경 위에 보여주기 위함)
///
/// GoogleMap은 플랫폼 뷰라 RepaintBoundary로 직접 캡처할 수 없어서, 화면 밖
/// Overlay에 잠깐 띄워 [GoogleMapController.takeSnapshot]으로 PNG 바이트를 얻는다.
/// 같은 경로는 한 번만 캡처하도록 결과를 캐시한다.
class RouteMapSnapshotService {
  RouteMapSnapshotService._();

  static final Map<String, Future<Uint8List?>> _cache = {};

  static String _keyFor(List<StoreModel> stores, Size size) =>
      '${size.width.round()}x${size.height.round()}:'
      '${stores.map((s) => '${s.latitude},${s.longitude}').join('|')}';

  static Future<Uint8List?> capture(
    BuildContext context, {
    required List<StoreModel> stores,
    Size size = const Size(700, 700),
  }) {
    if (stores.isEmpty) return Future.value(null);
    // flutter test(위젯 테스트)엔 실제 지도 플랫폼이 없어 GoogleMap을 띄워도
    // 스냅샷을 얻을 수 없다. 무의미하게 Overlay/애니메이션을 만들지 않도록
    // 바로 폴백(null → 추상 경로도)으로 보낸다.
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return Future.value(null);
    }
    final key = _keyFor(stores, size);
    return _cache.putIfAbsent(
      key,
      () => _captureNew(context, stores: stores, size: size),
    );
  }

  static Future<Uint8List?> _captureNew(
    BuildContext context, {
    required List<StoreModel> stores,
    required Size size,
  }) async {
    final completer = Completer<Uint8List?>();
    late final OverlayEntry entry;
    final overlay = Overlay.of(context, rootOverlay: true);

    // 화면 훨씬 밖(음수 좌표)에 실제 크기로 띄워야 GoogleMap이 정상 렌더링된다.
    // Opacity(0)으로 숨기면 네이티브 플랫폼 뷰가 아예 합성되지 않아
    // takeSnapshot()이 null을 반환하므로, 투명도 대신 화면 밖 배치로만 숨긴다.
    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: -size.width - 200,
        top: -size.height - 200,
        width: size.width,
        height: size.height,
        child: IgnorePointer(
          child: _SnapshotMap(
            stores: stores,
            onCaptured: (bytes) {
              if (!completer.isCompleted) completer.complete(bytes);
            },
          ),
        ),
      ),
    );
    // 이 메서드는 흔히 initState/didChangeDependencies에서 호출되는데, 그
    // 시점엔 프레임워크가 아직 빌드 중이라 Overlay.insert가 바로 setState를
    // 트리거하면 "build 중 setState" 예외가 난다. 현재 빌드가 끝난 뒤로 미룬다.
    WidgetsBinding.instance.addPostFrameCallback((_) => overlay.insert(entry));

    final result = await completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () => null,
    );
    entry.remove();
    return result;
  }
}

class _SnapshotMap extends StatefulWidget {
  final List<StoreModel> stores;
  final ValueChanged<Uint8List?> onCaptured;

  const _SnapshotMap({required this.stores, required this.onCaptured});

  @override
  State<_SnapshotMap> createState() => _SnapshotMapState();
}

class _SnapshotMapState extends State<_SnapshotMap> {
  bool _done = false;

  List<LatLng> get _points => [
    for (final s in widget.stores) LatLng(s.latitude, s.longitude),
  ];

  Set<Marker> get _markers => {
    for (var i = 0; i < widget.stores.length; i++)
      Marker(
        markerId: MarkerId('snapshot_$i'),
        position: LatLng(widget.stores[i].latitude, widget.stores[i].longitude),
      ),
  };

  Set<Polyline> get _polylines {
    final points = _points;
    if (points.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: AppColors.button,
        width: 6,
      ),
    };
  }

  void _finish(Uint8List? bytes) {
    if (_done) return;
    _done = true;
    widget.onCaptured(bytes);
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    try {
      final points = _points;
      if (points.length > 1) {
        var minLat = points.first.latitude, maxLat = points.first.latitude;
        var minLng = points.first.longitude, maxLng = points.first.longitude;
        for (final p in points) {
          if (p.latitude < minLat) minLat = p.latitude;
          if (p.latitude > maxLat) maxLat = p.latitude;
          if (p.longitude < minLng) minLng = p.longitude;
          if (p.longitude > maxLng) maxLng = p.longitude;
        }
        final bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );
        // 지도가 완전히 뜨기 전에 카메라를 옮기면 무시되는 경우가 있어 잠시 대기
        await Future.delayed(const Duration(milliseconds: 250));
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 70),
        );
      }
      // 타일이 그려질 시간을 준다.
      await Future.delayed(const Duration(milliseconds: 500));
      final bytes = await controller.takeSnapshot();
      _finish(bytes);
    } catch (e) {
      // 플랫폼 채널이 없거나(테스트 환경) 스냅샷에 실패하면 폴백(추상 경로도)이
      // 쓰이도록 조용히 null을 반환한다.
      _finish(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = _points;
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: points.isNotEmpty ? points.first : daejeonCenter,
        zoom: 15,
      ),
      markers: _markers,
      polylines: _polylines,
      onMapCreated: _onMapCreated,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      liteModeEnabled: false,
    );
  }
}

/// 실좌표 경로를 실제 지도 위에 그려 보여주는 위젯. 스냅샷이 준비되기 전에는
/// 로딩 표시를, 실패하면 기존 추상 경로도([RouteMapPainter])를 대신 보여준다.
class RouteMapImage extends StatefulWidget {
  final List<StoreModel> stores;
  final Size snapshotSize;

  const RouteMapImage({
    super.key,
    required this.stores,
    this.snapshotSize = const Size(700, 700),
  });

  @override
  State<RouteMapImage> createState() => _RouteMapImageState();
}

class _RouteMapImageState extends State<RouteMapImage> {
  Future<Uint8List?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= RouteMapSnapshotService.capture(
      context,
      stores: widget.stores,
      size: widget.snapshotSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return const ColoredBox(
            color: Color(0xFF1B1B1B),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              ),
            ),
          );
        }
        if (bytes == null) {
          return CustomPaint(painter: RouteMapPainter(stores: widget.stores));
        }
        return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
      },
    );
  }
}
