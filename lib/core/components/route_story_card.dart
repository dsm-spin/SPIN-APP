import 'package:flutter/material.dart';
import 'package:spin_app/core/components/route_map_painter.dart';
import 'package:spin_app/core/components/summary_stat.dart';
import 'package:spin_app/models/history_model.dart';
import 'package:spin_app/models/store_model.dart';

/// 인스타 스토리로 올라가는 카드 (402x874 비율의 검정 배경).
///
/// 완주 직후 공유 제안 다이얼로그의 미리보기와, 히스토리에서 들어가는 공유
/// 페이지가 같은 카드를 쓴다 — 미리 본 그대로가 스토리에 올라가야 하기 때문.
///
/// 카드 안쪽 여백과 글자 크기가 스토리 크기(402x874) 기준이라, 작은 기기에서
/// 그대로 그리면 내용이 넘친다. 그래서 항상 스토리 크기로 배치한 뒤 주어진
/// 자리에 맞게 통째로 축소한다 — 어느 기기에서도 비율과 모양이 같다.
class RouteStoryCard extends StatelessWidget {
  static const Size storySize = Size(402, 874);

  final HistoryModel history;
  final List<StoreModel> stores;

  const RouteStoryCard({
    super.key,
    required this.history,
    required this.stores,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: storySize.width,
        height: storySize.height,
        // 기기의 글꼴 크기 설정이 카드 안 글자를 밀어내지 않도록 고정한다.
        // (스토리 이미지는 어디서 보든 같은 그림이어야 한다.)
        child: MediaQuery.withNoTextScaling(child: _StoryCardBody(
          history: history,
          stores: stores,
        )),
      ),
    );
  }
}

class _StoryCardBody extends StatelessWidget {
  final HistoryModel history;
  final List<StoreModel> stores;

  const _StoryCardBody({required this.history, required this.stores});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        color: Colors.black,
      ),
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 캡처 크기가 달라져도 비율이 유지되도록 카드 폭 기준으로 스케일 계산
          final scale = constraints.maxWidth / 354;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: constraints.maxHeight * 0.42,
                width: double.infinity,
                child: CustomPaint(painter: RouteMapPainter(stores: stores)),
              ),
              SizedBox(height: 30 * scale),
              SummaryStat(
                label: '거리',
                value: history.distanceKmLabel,
                unit: 'km',
              ),
              SizedBox(height: 14 * scale),
              SummaryStat(label: '방문', value: '${stores.length}'),
              SizedBox(height: 14 * scale),
              SummaryStat(label: '소요 시간', value: history.durationLabel),
              const Spacer(),
              Center(
                child: Text(
                  '같은 루트로 시작하기',
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 40 * scale),
            ],
          );
        },
      ),
    );
  }
}
