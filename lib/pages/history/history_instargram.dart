import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spin_app/core/components/bottom_button.dart';
import 'package:spin_app/core/components/route_map_painter.dart';
import 'package:spin_app/core/components/summary_stat.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/models/history_model.dart';
import 'package:spin_app/models/store_model.dart';

/// 루트 공유 스토리 페이지.
/// 스토리 카드를 미리 보여주고, 이미지로 캡처해 인스타그램(공유 시트)으로 보낸다.
class HistoryInstargram extends StatefulWidget {
  final HistoryModel history;
  final List<StoreModel> stores;

  const HistoryInstargram({
    super.key,
    required this.history,
    required this.stores,
  });

  @override
  State<HistoryInstargram> createState() => _HistoryInstargramState();
}

class _HistoryInstargramState extends State<HistoryInstargram> {
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;

  /// 스토리 카드를 PNG로 캡처해 임시 파일로 저장한 뒤 공유 시트를 띄운다.
  /// 인스타그램이 설치돼 있으면 공유 시트에서 바로 스토리로 올릴 수 있다.
  Future<void> _shareToInstagram() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      // 인스타 스토리 해상도(1080px 폭)에 맞도록 3배로 캡처
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/route_story.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'image/png')]),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: AspectRatio(
                    aspectRatio: 402 / 874,
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: _StoryCard(
                        history: widget.history,
                        stores: widget.stores,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            BottomButton(
              text: _sharing ? '공유 준비 중...' : '인스타 공유',
              onTap: _shareToInstagram,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// 인스타 스토리로 올라가는 카드 (402x874 비율의 검정 배경)
class _StoryCard extends StatelessWidget {
  final HistoryModel history;
  final List<StoreModel> stores;

  const _StoryCard({required this.history, required this.stores});

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
                child: CustomPaint(
                  painter: RouteMapPainter(stores: stores),
                ),
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
