import 'package:flutter/material.dart';
import 'package:spin_app/core/components/route_map_painter.dart';
import 'package:spin_app/core/components/summary_stat.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/pages/history/history_instargram.dart';
import 'package:spin_app/models/history_model.dart';
import 'package:spin_app/models/store_model.dart';

class HistoryDetail extends StatelessWidget {
  final HistoryModel history;
  final List<StoreModel> stores;

  const HistoryDetail({
    super.key,
    required this.history,
    required this.stores,
  });

  void _openInstagramShare(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HistoryInstargram(
          history: history,
          stores: stores,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: _RouteSummaryCard(history: history, stores: stores),
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
                    for (var i = 0; i < stores.length; i++)
                      _StoreTimelineTile(
                        store: stores[i],
                        isLast: i == stores.length - 1,
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

  const _RouteSummaryCard({required this.history, required this.stores});

  @override
  Widget build(BuildContext context) {
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
          SizedBox(
            height: 230,
            width: double.infinity,
            child: CustomPaint(
              painter: RouteMapPainter(stores: stores),
            ),
          ),
          const SizedBox(height: 20),
          SummaryStat(
            label: '거리',
            value: history.distanceKmLabel,
            unit: 'km',
          ),
          const SizedBox(height: 16),
          SummaryStat(label: '방문', value: '${stores.length}'),
          const SizedBox(height: 16),
          SummaryStat(label: '소요 시간', value: history.durationLabel),
        ],
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
                    child: Container(width: 1.5, color: const Color(0xFFD9D9D9)),
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
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    store.address,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6A6A6A)),
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
