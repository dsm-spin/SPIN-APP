import 'package:flutter/material.dart';
import 'package:spin_app/api/challenge_api.dart';
import 'package:spin_app/api/route_api.dart';
import 'package:spin_app/core/components/app_snackbar.dart';
import 'package:spin_app/core/components/bottom_button.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/models/challenge_model.dart';
import 'package:spin_app/pages/route/route_progress_page.dart';

/// '루트' 탭: 현재 진행 중인 도전의 스탬프 현황을 보여준다. (GET /challenges/current)
class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  late Future<ChallengeProgressModel?> _future = getCurrentChallenge();
  bool _isOpeningMap = false;

  Future<void> _refresh() async {
    final future = getCurrentChallenge();
    setState(() {
      _future = future;
    });
    await future;
  }

  /// 루트 상세(GET /routes/{routeId})를 불러와 지도가 있는 진행 화면으로 이어간다.
  Future<void> _openMap(ChallengeProgressModel progress) async {
    setState(() => _isOpeningMap = true);
    final detail = await getRouteDetail(progress.routeId);
    if (!mounted) return;
    setState(() => _isOpeningMap = false);

    if (detail == null) {
      AppSnackBar.error(context, '루트 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요.');
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteProgressPage(
          result: detail,
          region: '',
          challenge: ChallengeModel(
            challengeId: progress.challengeId,
            routeId: progress.routeId,
            status: progress.status,
            totalStops: progress.totalStops,
            checkedInCount: progress.checkedInCount,
            startedAt: '',
            completedAt: '',
          ),
        ),
      ),
    );
    // 지도 화면에서 완주해 돌아왔을 수 있으니 진행 상황을 다시 불러온다.
    if (!mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<ChallengeProgressModel?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final progress = snapshot.data;
            if (progress == null) {
              return _EmptyState(onRefresh: _refresh);
            }
            if (progress.isCompleted) {
              return _EmptyState(onRefresh: _refresh, justCompleted: true);
            }
            return _ProgressView(
              progress: progress,
              onRefresh: _refresh,
              onOpenMap: () => _openMap(progress),
              isOpeningMap: _isOpeningMap,
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  /// true면 방금 완주한 도전이 목록에서 정리된 직후라는 뜻.
  /// 문구를 다르게 보여준다.
  final bool justCompleted;

  const _EmptyState({required this.onRefresh, this.justCompleted = false});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            children: [
              SizedBox(
                height: constraints.maxHeight,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        justCompleted ? Icons.emoji_events : Icons.route,
                        size: 48,
                        color: AppColors.button.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        justCompleted ? '루트를 완주했어요!' : '진행 중인 도전이 없어요',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.greenKelp,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        justCompleted
                            ? '완주한 루트는 이 화면에서 정리돼요.\n'
                                  '기록은 히스토리 탭에서 확인하실 수 있어요.\n'
                                  '표시가 조금 늦어질 수 있는 점 양해 부탁드려요 :)'
                            : '홈에서 새로운 루트를 만들고\n도전을 시작해보세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.greenKelp.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressView extends StatelessWidget {
  final ChallengeProgressModel progress;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenMap;
  final bool isOpeningMap;

  const _ProgressView({
    required this.progress,
    required this.onRefresh,
    required this.onOpenMap,
    required this.isOpeningMap,
  });

  @override
  Widget build(BuildContext context) {
    final stamps = [...progress.stamps]
      ..sort((a, b) => a.visitOrder.compareTo(b.visitOrder));
    final next = progress.nextDestination;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(25, 12, 25, 24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '진행 중인 도전',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                      color: AppColors.button,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '도장  ${progress.checkedInCount}/${progress.totalStops}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.button,
                      ),
                    ),
                    Text(
                      '${progress.percentComplete}% 완료',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: progress.totalStops <= 0
                        ? 0
                        : progress.checkedInCount / progress.totalStops,
                    minHeight: 8,
                    backgroundColor: AppColors.greenWhite,
                    color: AppColors.button,
                  ),
                ),
                if (next != null) ...[
                  const SizedBox(height: 20),
                  _NextDestinationCard(next: next),
                ],
                const SizedBox(height: 24),
                const Text(
                  '스탬프 현황',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenKelp,
                  ),
                ),
                const SizedBox(height: 12),
                for (final stamp in stamps) ...[
                  _StampRow(stamp: stamp),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 0, 25, 12),
          child: isOpeningMap
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                )
              : BottomButton(text: '지도에서 이어하기', onTap: onOpenMap),
        ),
      ],
    );
  }
}

class _NextDestinationCard extends StatelessWidget {
  final NextDestination next;

  const _NextDestinationCard({required this.next});

  @override
  Widget build(BuildContext context) {
    final hasCoords = next.latitude != null && next.longitude != null;
    final storeName = next.storeName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.greenWhite,
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
          const SizedBox(height: 6),
          Text(
            storeName != null && storeName.isNotEmpty ? storeName : '위치 정보 없음',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.greenKelp,
            ),
          ),
          if (hasCoords) ...[
            const SizedBox(height: 4),
            Text(
              '${next.latitude!.toStringAsFixed(5)}, ${next.longitude!.toStringAsFixed(5)}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.greenKelp.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StampRow extends StatelessWidget {
  final StampModel stamp;

  const _StampRow({required this.stamp});

  @override
  Widget build(BuildContext context) {
    final isDone = stamp.checkedIn;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDone ? AppColors.greenWhite : AppColors.background,
        border: Border.all(
          color: AppColors.button.withValues(alpha: isDone ? 0.16 : 0.1),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? AppColors.button : AppColors.background,
              image: isDone
                  ? const DecorationImage(
                      image: AssetImage('assets/images/stamp.png'),
                      fit: BoxFit.cover,
                    )
                  : null,
              border: isDone
                  ? null
                  : Border.all(
                      color: AppColors.greenKelp.withValues(alpha: 0.2),
                      width: 2,
                    ),
            ),
            child: isDone
                ? null
                : Text(
                    '${stamp.visitOrder}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greenKelp.withValues(alpha: 0.4),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stamp.storeName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenKelp,
                  ),
                ),
                if (stamp.category.isNotEmpty)
                  Text(
                    stamp.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.greenKelp.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone
                ? AppColors.button
                : AppColors.greenKelp.withValues(alpha: 0.25),
            size: 20,
          ),
        ],
      ),
    );
  }
}
