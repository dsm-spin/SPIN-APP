import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spin_app/core/components/bottom_button.dart';
import 'package:spin_app/core/components/route_story_card.dart';
import 'package:spin_app/core/services/instagram_share_service.dart';
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

  /// 스토리 카드를 PNG로 캡처해 임시 파일로 저장한 뒤 인스타그램 스토리로 바로 전달한다.
  /// 인스타그램이 없거나 네이티브 전달에 실패하면 기존 공유 시트로 대체한다.
  Future<void> _shareToInstagram() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // 인스타 스토리 해상도(1080px 폭)에 맞도록 3배로 캡처
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/route_story.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // TODO(diagnostic): 링크 스티커가 안 붙는 문제 확인 후 제거
      debugPrint('[spin_share] routeId=${widget.history.routeId} shareUrl=${widget.history.shareUrl}');

      final handledNatively = await InstagramShareService.shareToStory(
        file.path,
        contentUrl: widget.history.shareUrl,
      );
      debugPrint('[spin_share] handledNatively=$handledNatively');
      if (handledNatively) return;

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 10,
                  ),
                  child: AspectRatio(
                    aspectRatio: 402 / 874,
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: RouteStoryCard(
                        history: widget.history,
                        stores: widget.stores,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: BottomButton(
                text: _sharing ? '공유 준비 중...' : '인스타 공유',
                onTap: _shareToInstagram,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
