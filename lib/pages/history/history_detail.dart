import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spin_app/api/route_api.dart';
import 'package:spin_app/core/components/route_map_painter.dart';
import 'package:spin_app/core/components/summary_stat.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/models/route_model.dart';
import 'package:spin_app/pages/history/history_instargram.dart';
import 'package:spin_app/pages/route/route_map_page.dart';
import 'package:spin_app/models/history_model.dart';
import 'package:spin_app/models/store_model.dart';

class HistoryDetail extends StatefulWidget {
  final HistoryModel history;
  final List<StoreModel> stores;

  const HistoryDetail({super.key, required this.history, required this.stores});

  @override
  State<HistoryDetail> createState() => _HistoryDetailState();
}

class _HistoryDetailState extends State<HistoryDetail> {
  late List<StoreModel> _stores = widget.stores;
  List<RouteStopModel>? _liveStops;

  bool get _hasRealLocation => _liveStops != null;

  @override
  void initState() {
    super.initState();
    _loadRealStores();
  }

  /// 히스토리 목록 API는 가게 좌표를 안 내려줘서, 처음엔 순번만 임의 배치한
  /// 좌표로 그린다. routeId가 있으면 루트 상세(GET /routes/{routeId})를 다시
  /// 불러와 실좌표로 바꿔치기해 진짜 지도 위 경로를 보여준다.
  Future<void> _loadRealStores() async {
    final routeId = widget.history.routeId;
    if (routeId == null) return;

    final result = await getRouteDetail(routeId);
    if (!mounted || result == null) return;

    final stops = result.stops;
    final hasAllCoords =
        stops.isNotEmpty &&
        stops.every((s) => s.latitude != null && s.longitude != null);
    if (!hasAllCoords) return;

    setState(() {
      _liveStops = stops;
      _stores = [
        for (final s in stops)
          StoreModel(
            name: s.storeName,
            address: s.address,
            latitude: s.latitude!,
            longitude: s.longitude!,
          ),
      ];
    });
  }

  void _openInstagramShare(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HistoryInstargram(
          history: widget.history,
          stores: _stores,
          hasRealLocation: _hasRealLocation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.history;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                ),
              ),
              // 무엇을 하러 간 여행이었는지를 제목으로 세운다.
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 6, 25, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (history.region.trim().isNotEmpty) history.region,
                        history.completedAtLabel,
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6A6A6A),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: _RouteSummaryCard(
                  history: history,
                  stores: _stores,
                  liveStops: _liveStops,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 14, 25, 20),
                child: GestureDetector(
                  onTap: () => _openInstagramShare(context),
                  child: const Text(
                    '인스타 스토리로 공유하기',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6A6A6A),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    for (var i = 0; i < _stores.length; i++)
                      _StoreTimelineTile(
                        store: _stores[i],
                        isLast: i == _stores.length - 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

/// 상단 검정 카드: 루트맵 + 거리/방문/소요 시간 요약
class _RouteSummaryCard extends StatelessWidget {
  final HistoryModel history;
  final List<StoreModel> stores;

  /// 실좌표가 있을 때만 채워진다. 있으면 진짜 지도 위 경로를, 없으면 추상
  /// 경로도를 보여준다.
  final List<RouteStopModel>? liveStops;

  const _RouteSummaryCard({
    required this.history,
    required this.stores,
    required this.liveStops,
  });

  @override
  Widget build(BuildContext context) {
    final stops = liveStops;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 230,
              width: double.infinity,
              child: stops != null
                  ? _LiveRouteMap(region: history.region, stops: stops)
                  : CustomPaint(painter: RouteMapPainter(stores: stores)),
            ),
          ),
          const SizedBox(height: 20),
          SummaryStat(label: '거리', value: history.distanceKmLabel, unit: 'km'),
          const SizedBox(height: 16),
          SummaryStat(label: '방문', value: '${stores.length}'),
          const SizedBox(height: 16),
          SummaryStat(label: '소요 시간', value: history.durationLabel),
        ],
      ),
    );
  }
}

/// 실좌표가 있을 때 보여주는 실제 지도 위 경로 미리보기. 탭하면 전체 지도로 연다.
class _LiveRouteMap extends StatefulWidget {
  final String region;
  final List<RouteStopModel> stops;

  const _LiveRouteMap({required this.region, required this.stops});

  @override
  State<_LiveRouteMap> createState() => _LiveRouteMapState();
}

class _LiveRouteMapState extends State<_LiveRouteMap> {
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    // 이미 완주한 루트라 전부 채워진 도장으로 표시한다.
    final markers = await buildStopMarkers(
      widget.stops,
      checkedInCount: widget.stops.length,
    );
    if (!mounted) return;
    setState(() => _markers = markers);
  }

  void _openFullMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteMapPage(
          region: widget.region,
          stops: widget.stops,
          checkedInCount: widget.stops.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final points = routePoints(widget.stops);
    return GestureDetector(
      onTap: _openFullMap,
      child: AbsorbPointer(
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: points.isNotEmpty
                ? points.first
                : (districtCenters[widget.region] ?? daejeonCenter),
            zoom: 14.5,
          ),
          markers: _markers,
          polylines: buildRoutePolyline(widget.stops),
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }
}

/// 방문 매장 타임라인 한 칸 (점 + 세로선 + 이름/주소)
class _StoreTimelineTile extends StatelessWidget {
  final StoreModel store;
  final bool isLast;

  const _StoreTimelineTile({required this.store, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 14,
            child: Column(
              children: [
                const SizedBox(height: 5),
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF6F7F45),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: const Color(0xFFD9D9D9),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (store.address.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      store.address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6A6A6A),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
