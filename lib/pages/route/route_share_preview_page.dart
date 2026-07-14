import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spin_app/api/auth_api.dart';
import 'package:spin_app/api/challenge_api.dart';
import 'package:spin_app/api/route_api.dart';
import 'package:spin_app/core/components/app_snackbar.dart';
import 'package:spin_app/core/components/bottom_button.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/models/route_model.dart';
import 'package:spin_app/pages/auth/log_in.dart';
import 'package:spin_app/pages/route/route_map_page.dart';
import 'package:spin_app/pages/route/route_progress_page.dart';

/// 공유 링크(인스타 스토리 등)로 들어왔을 때 보여주는 루트 미리보기.
/// GET /routes/{routeId}는 로그인 없이도 볼 수 있어서, 로그인 전 사용자도
/// 루트 내용과 "N명이 다녀갔어요"를 먼저 확인한 뒤 시작할 수 있다.
class RouteSharePreviewPage extends StatefulWidget {
  final int routeId;

  const RouteSharePreviewPage({super.key, required this.routeId});

  @override
  State<RouteSharePreviewPage> createState() => _RouteSharePreviewPageState();
}

class _RouteSharePreviewPageState extends State<RouteSharePreviewPage> {
  late Future<RouteGenerateResult?> _future = getRouteDetail(widget.routeId);
  bool _isStarting = false;

  Future<void> _startSameRoute() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    final hasSession = await hasValidSession();
    if (!mounted) return;

    if (!hasSession) {
      setState(() => _isStarting = false);
      AppSnackBar.info(context, '같은 루트로 시작하려면 먼저 로그인해주세요');
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LogInWidget(
            onLoggedIn: () => Navigator.of(context).pop(),
          ),
        ),
      );
      if (!mounted) return;
      // 로그인하고 돌아왔으면 이어서 시작을 시도한다.
      await _startSameRoute();
      return;
    }

    final challenge = await startChallenge(routeId: widget.routeId);
    if (!mounted) return;
    setState(() => _isStarting = false);

    if (challenge == null) {
      AppSnackBar.error(context, '루트 시작에 실패했어요. 잠시 후 다시 시도해주세요.');
      return;
    }

    final result = await _future;
    if (!mounted || result == null) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RouteProgressPage(
          result: result,
          region: result.region ?? '',
          challenge: challenge,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<RouteGenerateResult?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final result = snapshot.data;
            if (result == null) {
              return _ErrorState(
                onRetry: () =>
                    setState(() => _future = getRouteDetail(widget.routeId)),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroMap(region: result.region ?? '', stops: result.stops),
                        const SizedBox(height: 20),
                        Text(
                          result.purpose?.isNotEmpty == true
                              ? result.purpose!
                              : '${result.region ?? ''} 골목 루트',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.greenKelp,
                          ),
                        ),
                        if (result.completedCount != null) ...[
                          const SizedBox(height: 8),
                          _CompletedBadge(count: result.completedCount!),
                        ],
                        const SizedBox(height: 20),
                        _StatsRow(result: result),
                        const SizedBox(height: 24),
                        for (var i = 0; i < result.stops.length; i++)
                          _StopTile(
                            index: i,
                            stop: result.stops[i],
                            isLast: i == result.stops.length - 1,
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 12, 25, 16),
                  child: _isStarting
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : BottomButton(
                          text: '같은 루트로 시작하기',
                          onTap: _startSameRoute,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroMap extends StatefulWidget {
  final String region;
  final List<RouteStopModel> stops;

  const _HeroMap({required this.region, required this.stops});

  @override
  State<_HeroMap> createState() => _HeroMapState();
}

class _HeroMapState extends State<_HeroMap> {
  late final Future<Set<Marker>> _markersFuture = buildStopMarkers(
    widget.stops,
  );

  @override
  Widget build(BuildContext context) {
    final points = routePoints(widget.stops);
    final initialTarget = points.isNotEmpty
        ? points.first
        : (districtCenters[widget.region] ?? daejeonCenter);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 182,
        width: double.infinity,
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
    );
  }
}

/// "이 루트, N명이 다녀갔어요" 배지
class _CompletedBadge extends StatelessWidget {
  final int count;

  const _CompletedBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.greenWhite,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '이 루트, $count명이 다녀갔어요',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.button,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final RouteGenerateResult result;

  const _StatsRow({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.greenWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              label: '총 거리',
              value: (result.totalDistanceMeters / 1000).toStringAsFixed(1),
              unit: 'km',
            ),
          ),
          Container(width: 1, color: AppColors.button.withValues(alpha: 0.16)),
          Expanded(
            child: _Stat(
              label: '예상 소요',
              value: '${result.estimatedDurationMinutes}',
              unit: 'm',
            ),
          ),
          Container(width: 1, color: AppColors.button.withValues(alpha: 0.16)),
          Expanded(
            child: _Stat(
              label: '가게',
              value: '${result.storeCount}',
              unit: '곳',
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _Stat({required this.label, required this.value, required this.unit});

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
              color: AppColors.greenKelp.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.greenKelp,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.greenKelp.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ],
      ),
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
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.button,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 13,
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
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.storeName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenKelp,
                    ),
                  ),
                  if (stop.category.isNotEmpty)
                    Text(
                      stop.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.greenKelp.withValues(alpha: 0.5),
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

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: AppColors.greenKelp.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              '루트 정보를 불러오지 못했어요',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
