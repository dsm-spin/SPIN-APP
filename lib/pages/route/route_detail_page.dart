import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spin_app/api/challenge_api.dart';
import 'package:spin_app/core/components/app_snackbar.dart';
import 'package:spin_app/core/components/bottom_button.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/models/route_model.dart';
import 'package:spin_app/pages/route/route_map_page.dart';
import 'package:spin_app/pages/route/route_progress_page.dart';

class RouteDetailPage extends StatefulWidget {
  final RouteGenerateResult result;
  final String region;
  final String purpose;

  const RouteDetailPage({
    super.key,
    required this.result,
    required this.region,
    required this.purpose,
  });

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  bool _isStarting = false;

  Future<void> _startRoute() async {
    final routeId = widget.result.routeId;
    if (routeId == null) {
      AppSnackBar.error(context, '루트 정보를 찾을 수 없어 시작할 수 없어요');
      return;
    }

    setState(() => _isStarting = true);
    final challenge = await startChallenge(routeId: routeId);
    if (!mounted) return;
    setState(() => _isStarting = false);

    if (challenge == null) {
      AppSnackBar.error(context, '루트 시작에 실패했어요. 잠시 후 다시 시도해주세요.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteProgressPage(
          result: widget.result,
          region: widget.region,
          challenge: challenge,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final region = widget.region;
    final purpose = widget.purpose;
    final title = '$region $purpose 코스';

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
              _HeroSection(region: region, stops: result.stops),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenKelp,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _StatsCard(result: result),
                    const SizedBox(height: 24),
                    _StopTimeline(stops: result.stops),
                    const SizedBox(height: 18),
                    _StampInfoBox(),
                    const SizedBox(height: 20),
                    _isStarting
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : BottomButton(text: '루트 시작', onTap: _startRoute),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// 상단 지도 영역: 루트 경로와 마커를 미리 보여주고, 탭하면 전체 지도로 이동한다.
class _HeroSection extends StatefulWidget {
  final String region;
  final List<RouteStopModel> stops;

  const _HeroSection({required this.region, required this.stops});

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  late final Future<Set<Marker>> _markersFuture = buildStopMarkers(
    widget.stops,
  );

  void _openFullMap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            RouteMapPage(region: widget.region, stops: widget.stops),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final points = routePoints(widget.stops);
    final initialTarget = points.isNotEmpty
        ? points.first
        : (districtCenters[widget.region] ?? daejeonCenter);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: GestureDetector(
        onTap: () => _openFullMap(context),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 182,
                width: double.infinity,
                // 미니 지도 자체 조작은 막고 탭은 받아서 전체 지도로 이동
                child: AbsorbPointer(
                  child: FutureBuilder<Set<Marker>>(
                    future: _markersFuture,
                    builder: (context, snapshot) {
                      return GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: initialTarget,
                          zoom: points.isNotEmpty ? 14.5 : 14,
                        ),
                        markers: snapshot.data ?? {},
                        polylines: buildRoutePolyline(widget.stops),
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.greenWhite,
                  border: Border.all(color: AppColors.button, width: 1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  widget.region,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                width: 34,
                height: 34,
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
                child: const Icon(
                  Icons.open_in_full,
                  size: 16,
                  color: AppColors.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 총 거리 / 예상 소요 / 가게 수 통계 카드
class _StatsCard extends StatelessWidget {
  final RouteGenerateResult result;

  const _StatsCard({required this.result});

  String get _distanceLabel =>
      (result.totalDistanceMeters / 1000).toStringAsFixed(1);

  String get _durationLabel {
    final hours = result.estimatedDurationMinutes ~/ 60;
    final minutes = result.estimatedDurationMinutes % 60;
    if (hours <= 0) return '$minutes';
    return '$hours';
  }

  String get _durationUnit {
    final hours = result.estimatedDurationMinutes ~/ 60;
    final minutes = result.estimatedDurationMinutes % 60;
    if (hours <= 0) return 'm';
    if (minutes <= 0) return 'h';
    return 'h $minutes'
        'm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.greenWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _StatColumn(
                label: '총 거리',
                value: _distanceLabel,
                unit: 'km',
              ),
            ),
            _VerticalDivider(),
            Expanded(
              child: _StatColumn(
                label: '예상 소요',
                value: _durationLabel,
                unit: _durationUnit,
              ),
            ),
            _VerticalDivider(),
            Expanded(
              child: _StatColumn(
                label: '가게',
                value: '${result.storeCount}',
                unit: '곳',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, color: AppColors.button.withValues(alpha: 0.16));
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.12,
              color: AppColors.greenKelp.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenKelp,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenKelp.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 번호가 매겨진 방문 코스 타임라인
class _StopTimeline extends StatelessWidget {
  final List<RouteStopModel> stops;

  const _StopTimeline({required this.stops});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < stops.length; i++)
          _StopTile(index: i, stop: stops[i], isLast: i == stops.length - 1),
      ],
    );
  }
}

class _StopTile extends StatelessWidget {
  final int index;
  final RouteStopModel stop;
  final bool isLast;

  const _StopTile({
    required this.index,
    required this.stop,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.button,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: AppColors.button)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: _StopCard(stop: stop),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  final RouteStopModel stop;

  const _StopCard({required this.stop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.springWood,
        border: Border.all(color: AppColors.button.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  stop.storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenKelp,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  stop.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.greenKelp.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '도보 ${stop.walkMinutes}분',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.button,
            ),
          ),
          if (stop.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              stop.reason,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: AppColors.greenKelp.withValues(alpha: 0.72),
              ),
            ),
          ],
          if (stop.discountTag.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.button.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                stop.discountTag,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.button,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 스탬프 적립 안내 박스
class _StampInfoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.button.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        '모든 곳을 방문해 스탬프를 찍으면\n현금처럼 사용 가능한 포인트를 받을 수 있어요',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, height: 1.5, color: Colors.black),
      ),
    );
  }
}
