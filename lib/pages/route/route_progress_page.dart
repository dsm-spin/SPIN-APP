
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spin_app/api/challenge_api.dart';
import 'package:spin_app/core/components/app_snackbar.dart';
import 'package:spin_app/core/components/bottom_button.dart';
import 'package:spin_app/core/share/route_caption.dart';
import 'package:spin_app/core/storage/point_store.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/models/challenge_model.dart';
import 'package:spin_app/models/history_model.dart';
import 'package:spin_app/models/point_model.dart';
import 'package:spin_app/models/route_model.dart';
import 'package:spin_app/models/store_model.dart';
import 'package:spin_app/pages/history/history_instargram.dart';
import 'package:spin_app/pages/route/checkin_reward_dialog.dart';
import 'package:spin_app/pages/route/qr_scan_page.dart';
import 'package:spin_app/pages/route/route_complete_dialog.dart';
import 'package:spin_app/pages/route/route_map_page.dart';

/// 루트 진행 화면: 스탬프 현황, 다음 목적지, QR 체크인.
class RouteProgressPage extends StatefulWidget {
  final RouteGenerateResult result;
  final String region;
  final ChallengeModel challenge;

  const RouteProgressPage({
    super.key,
    required this.result,
    required this.region,
    required this.challenge,
  });

  @override
  State<RouteProgressPage> createState() => _RouteProgressPageState();
}

class _RouteProgressPageState extends State<RouteProgressPage> {
  late final ChallengeModel _challenge = widget.challenge;
  ChallengeProgressModel? _progress;
  Set<Marker> _markers = {};
  bool _isCheckingIn = false;

  /// 이 화면이 뜬 시점(=챌린지 시작 직후)의 기기 로컬 시각.
  /// 완주 시 소요 시간은 원래 마지막 체크인 응답의 startedAt/completedAt을
  /// 그대로 쓴다(둘 다 서버 값이라 시간대가 항상 맞다). 이 값은 그 응답에
  /// 값이 비어 있는 등 예외적인 경우에만 대신 쓰는 대비책이다.
  final DateTime _localStartedAt = DateTime.now();

  int get _totalStops => _progress?.totalStops ?? _challenge.totalStops;

  int get _checkedInCount =>
      _progress?.checkedInCount ?? _challenge.checkedInCount;

  int get _percentComplete =>
      _totalStops <= 0 ? 0 : ((_checkedInCount / _totalStops) * 100).round();

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    _refreshProgress();
  }

  Future<void> _loadMarkers() async {
    final markers = await buildStopMarkers(
      widget.result.stops,
      checkedInCount: _checkedInCount,
    );
    if (!mounted) return;
    setState(() => _markers = markers);
  }

  Future<void> _refreshProgress() async {
    final progress = await getCurrentChallenge();
    if (!mounted || progress == null) return;
    setState(() => _progress = progress);
    _loadMarkers();
  }

  Future<void> _scanQr() async {
    if (_checkedInCount >= _totalStops) {
      AppSnackBar.info(context, '이미 모든 도장을 찍었어요');
      return;
    }

    final code = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QrScanPage()));
    if (code == null || !mounted) return;

    setState(() => _isCheckingIn = true);
    final outcome = await checkIn(qrCode: code);
    if (!mounted) return;
    setState(() => _isCheckingIn = false);

    final data = outcome.data;
    if (data == null) {
      final message = switch (outcome.error!) {
        CheckInError.unknownCode => '유효하지 않은 QR 코드예요',
        CheckInError.storeNotInChallenge => '이 루트에 포함되지 않은 가게예요',
        CheckInError.alreadyCheckedIn => '이미 도장을 찍은 가게예요',
        CheckInError.other => '체크인에 실패했어요. 잠시 후 다시 시도해주세요',
      };
      AppSnackBar.error(context, message);
      return;
    }

    final justCompleted =
        data.isCompleted || data.checkedInCount >= data.totalStops;

    final stops = widget.result.stops;
    if (stops.isEmpty) {
      await _recordPoints(data, storeName: '');
      if (!mounted) return;
      if (justCompleted) {
        Navigator.of(context).pop();
        return;
      }
      await _refreshProgress();
      return;
    }
    final checkedInIndex = (data.checkedInCount - 1).clamp(0, stops.length - 1);
    await _recordPoints(data, storeName: stops[checkedInIndex].storeName);
    if (!mounted) return;
    await showCheckInRewardDialog(
      context,
      store: stops[checkedInIndex],
      result: data,
    );
    if (!mounted) return;
    // 루트를 완주하면 축하 + 인스타 공유를 제안하고 이 화면(진행 중인 루트)은 닫는다.
    // 완주한 기록은 히스토리 탭에서만 보여준다.
    if (justCompleted) {
      await _celebrateAndOfferShare(data);
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }
    await _refreshProgress();
  }

  /// 완주 축하 다이얼로그를 띄우고, 원하면 인스타 스토리 공유 화면으로 이어간다.
  /// [finalCheckIn]은 루트를 완주시킨 마지막 체크인 응답 — startedAt/completedAt이
  /// 이 안에 함께 담겨 있어, 소요 시간을 구할 때 그대로 쓴다.
  Future<void> _celebrateAndOfferShare(CheckInResult finalCheckIn) async {
    final history = _historyForShare(finalCheckIn);
    final stores = _storesForShare();
    final hasRealLocation = widget.result.stops.every(
      (stop) => stop.latitude != null && stop.longitude != null,
    );

    // 스토리 카드에는 글이 안 실리니, 함께 올릴 캡션은 붙여넣을 수 있게 복사해둔다.
    final caption = buildRouteCaption(
      region: widget.region,
      storeNames: [for (final stop in widget.result.stops) stop.storeName],
      distanceMeters: widget.result.totalDistanceMeters,
      durationMinutes: widget.result.estimatedDurationMinutes,
      pointsEarned: await _pointsEarnedOnThisRoute(),
    );
    if (!mounted) return;

    final wantsShare = await showRouteCompleteDialog(
      context,
      history: history,
      stores: stores,
      hasRealLocation: hasRealLocation,
    );
    if (!mounted || !wantsShare) return;

    await Clipboard.setData(ClipboardData(text: caption));
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoryInstargram(
          history: history,
          stores: stores,
          hasRealLocation: hasRealLocation,
        ),
      ),
    );
  }

  /// 이번 루트에서 적립한 포인트 합계. 기기 원장에서 이 도전의 내역만 더한다.
  Future<int> _pointsEarnedOnThisRoute() async {
    final entries = await pointStore.load();
    return entries
        .where((e) => e.challengeId == _challenge.challengeId)
        .fold<int>(0, (sum, e) => sum + e.points);
  }

  HistoryModel _historyForShare(CheckInResult finalCheckIn) {
    // startedAt·completedAt은 반드시 같은 응답(마지막 체크인)에서 나온 값끼리
    // 짝지어 써야 한다 — 서버 시계가 어느 시간대로 돌든 같은 응답 안의 두
    // 값은 같은 시간대라 소요 시간 계산이 항상 맞는다. 어느 한쪽이라도
    // 파싱에 실패하면(필드 누락 등) 기기 로컬 시각으로 통째로 대신한다 —
    // 서버 값과 기기 값을 섞으면 시간대가 어긋나 소요 시간이 크게 틀어진다.
    final serverStartedAt = DateTime.tryParse(finalCheckIn.startedAt ?? '');
    final serverCompletedAt = DateTime.tryParse(finalCheckIn.completedAt ?? '');
    final now = DateTime.now();
    final bothFromServer =
        serverStartedAt != null && serverCompletedAt != null;

    return HistoryModel(
      challengeId: _challenge.challengeId,
      routeId: _challenge.routeId,
      region: widget.region,
      purpose: '',
      totalDistanceMeters: widget.result.totalDistanceMeters,
      estimatedDurationMinutes: widget.result.estimatedDurationMinutes,
      startedAt: bothFromServer ? serverStartedAt : _localStartedAt,
      completedAt: bothFromServer ? serverCompletedAt : now,
      photoUrl: '',
      storeNames: [
        for (final stop in widget.result.stops) stop.storeName,
      ].join(', '),
    );
  }

  /// 스토리 카드의 루트맵용 가게 목록. 좌표가 없는 가게가 하나라도 있으면
  /// 히스토리 화면과 같이 방문 순서만 보이도록 순번별 좌표를 임의로 배치한다.
  List<StoreModel> _storesForShare() {
    final stops = widget.result.stops;
    final hasAllCoords = stops.every(
      (stop) => stop.latitude != null && stop.longitude != null,
    );

    return [
      for (var i = 0; i < stops.length; i++)
        StoreModel(
          name: stops[i].storeName,
          address: stops[i].address,
          latitude: hasAllCoords ? stops[i].latitude! : -i.toDouble(),
          longitude: hasAllCoords ? stops[i].longitude! : (i.isEven ? 0 : 1),
        ),
    ];
  }

  /// 서버에는 적립 "내역" API가 없어서, 체크인 결과를 기기 원장에 남겨
  /// 포인트 탭에서 내역으로 보여줄 수 있게 한다.
  Future<void> _recordPoints(
    CheckInResult data, {
    required String storeName,
  }) async {
    await pointStore.add(
      PointEntry(
        storeName: storeName,
        points: data.pointsEarned,
        balanceAfter: data.totalPoints,
        earnedAt: DateTime.now(),
        challengeId: data.challengeId,
      ),
    );
  }

  void _openFullMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteMapPage(
          region: widget.region,
          stops: widget.result.stops,
          checkedInCount: _checkedInCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stops = widget.result.stops;
    final nextIndex = _checkedInCount;
    final nextStop = nextIndex < stops.length ? stops[nextIndex] : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '도장  $_checkedInCount/$_totalStops',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$_percentComplete% 완료',
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 106,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 25),
                itemCount: stops.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _StampBadge(
                  index: index,
                  stop: stops[index],
                  checkedInCount: _checkedInCount,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: GestureDetector(
                  onTap: _openFullMap,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AbsorbPointer(
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: routePoints(stops).isNotEmpty
                                  ? routePoints(stops).first
                                  : (districtCenters[widget.region] ??
                                        daejeonCenter),
                              zoom: 14.5,
                            ),
                            markers: _markers,
                            polylines: buildRoutePolyline(stops),
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                            mapToolbarEnabled: false,
                          ),
                        ),
                      ),
                      if (nextStop != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _NextDestinationCard(
                            stop: nextStop,
                            onOpenMap: _openFullMap,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 16, 25, 12),
              child: _isCheckingIn
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : BottomButton(text: 'QR로 도장 찍기', onTap: _scanQr),
            ),
          ],
        ),
      ),
    );
  }
}

class _StampBadge extends StatelessWidget {
  final int index;
  final RouteStopModel stop;
  final int checkedInCount;

  const _StampBadge({
    required this.index,
    required this.stop,
    required this.checkedInCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = index < checkedInCount;
    final isCurrent = index == checkedInCount;

    Widget circle;
    Color labelColor;

    if (isDone) {
      circle = Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          color: AppColors.button,
          shape: BoxShape.circle,
          image: DecorationImage(
            image: AssetImage('assets/images/stamp.png'),
            fit: BoxFit.cover,
          ),
        ),
      );
      labelColor = AppColors.greenKelp;
    } else if (isCurrent) {
      circle = Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.button, width: 2),
        ),
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.button,
          ),
        ),
      );
      labelColor = AppColors.button;
    } else {
      circle = Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.greenKelp.withValues(alpha: 0.15),
            width: 2,
          ),
        ),
        child: Text(
          '${index + 1}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.greenKelp.withValues(alpha: 0.3),
          ),
        ),
      );
      labelColor = AppColors.greenKelp.withValues(alpha: 0.4);
    }

    return Column(
      children: [
        circle,
        const SizedBox(height: 5),
        SizedBox(
          width: 60,
          child: Text(
            stop.storeName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: labelColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _NextDestinationCard extends StatelessWidget {
  final RouteStopModel stop;
  final VoidCallback onOpenMap;

  const _NextDestinationCard({required this.stop, required this.onOpenMap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        border: Border.all(color: AppColors.button.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '다음 목적지',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.14,
              color: AppColors.button,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stop.storeName} · ${stop.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenKelp,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onOpenMap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.button,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Text(
                    '지도 열기',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
