import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spin_app/core/components/stamp_marker_icons.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/models/route_model.dart';

/// 대전 각 구의 대략적인 중심 좌표 (좌표 없는 루트의 지도 초기 위치용)
const districtCenters = <String, LatLng>{
  '유성구': LatLng(36.3622, 127.3568),
  '대덕구': LatLng(36.3466, 127.4157),
  '서구': LatLng(36.3556, 127.3838),
  '중구': LatLng(36.3255, 127.4212),
  '동구': LatLng(36.3120, 127.4548),
};
const daejeonCenter = LatLng(36.3504, 127.3845);

/// 좌표가 있는 가게들을 방문 순서대로 이은 경로 좌표 목록
List<LatLng> routePoints(List<RouteStopModel> stops) => [
  for (final stop in stops)
    if (stop.latitude != null && stop.longitude != null)
      LatLng(stop.latitude!, stop.longitude!),
];

/// 좌표가 있는 가게들의 순번 마커.
/// [checkedInCount]번째까지는 채워진 도장, 나머지는 순번이 적힌 빈 도장으로 그린다.
/// [markerSize]는 미니 지도(compact)와 전체 지도(detail)에서 마커 크기를 다르게 하는 데 쓴다.
Future<Set<Marker>> buildStopMarkers(
  List<RouteStopModel> stops, {
  int checkedInCount = 0,
  StampMarkerSize markerSize = StampMarkerSize.compact,
}) async {
  final markers = <Marker>{};
  var order = 0;
  for (final stop in stops) {
    if (stop.latitude == null || stop.longitude == null) continue;
    order++;
    final icon = order <= checkedInCount
        ? await StampMarkerIcons.filled(size: markerSize)
        : await StampMarkerIcons.empty(order, size: markerSize);
    markers.add(
      Marker(
        markerId: MarkerId('stop_$order'),
        position: LatLng(stop.latitude!, stop.longitude!),
        icon: icon,
        infoWindow: InfoWindow(
          title: '$order. ${stop.storeName}',
          snippet: stop.category,
        ),
      ),
    );
  }
  return markers;
}

/// 방문 순서대로 가게들을 잇는 경로선
Set<Polyline> buildRoutePolyline(List<RouteStopModel> stops) {
  final points = routePoints(stops);
  if (points.length < 2) return {};
  return {
    Polyline(
      polylineId: const PolylineId('route'),
      points: points,
      color: AppColors.button,
      width: 4,
    ),
  };
}

/// 루트 전체를 보여주는 전체 화면 지도
class RouteMapPage extends StatefulWidget {
  final String region;
  final List<RouteStopModel> stops;
  final int checkedInCount;

  const RouteMapPage({
    super.key,
    required this.region,
    required this.stops,
    this.checkedInCount = 0,
  });

  @override
  State<RouteMapPage> createState() => _RouteMapPageState();
}

class _RouteMapPageState extends State<RouteMapPage> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    final markers = await buildStopMarkers(
      widget.stops,
      checkedInCount: widget.checkedInCount,
      markerSize: StampMarkerSize.detail,
    );
    if (!mounted) return;
    setState(() => _markers = markers);
  }

  Future<void> _fitRouteBounds() async {
    final points = routePoints(widget.stops);
    final controller = _controller;
    if (controller == null || points.length < 2) return;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
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
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  @override
  Widget build(BuildContext context) {
    final points = routePoints(widget.stops);
    final initialTarget = points.isNotEmpty
        ? points.first
        : (districtCenters[widget.region] ?? daejeonCenter);

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: points.isNotEmpty ? 15 : 14,
            ),
            markers: _markers,
            polylines: buildRoutePolyline(widget.stops),
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _controller = controller;
              _fitRouteBounds();
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      '${widget.region} 루트',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greenKelp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
