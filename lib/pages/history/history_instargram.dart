import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spin_app/core/components/app_snackbar.dart';
import 'package:spin_app/core/components/bottom_button.dart';
import 'package:spin_app/core/components/route_map_snapshot.dart';
import 'package:spin_app/core/components/route_story_card.dart';
import 'package:spin_app/core/services/instagram_share_service.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/models/history_model.dart';
import 'package:spin_app/models/store_model.dart';

class HistoryInstargram extends StatefulWidget {
  final HistoryModel history;
  final List<StoreModel> stores;

  /// [stores]의 좌표가 실제 위치인지. true면 지도 배경을 실제 지도 위 경로로 그린다.
  final bool hasRealLocation;

  const HistoryInstargram({
    super.key,
    required this.history,
    required this.stores,
    this.hasRealLocation = false,
  });

  @override
  State<HistoryInstargram> createState() => _HistoryInstargramState();
}

class _HistoryInstargramState extends State<HistoryInstargram> {
  final GlobalKey _cardKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();

  bool _sharing = false;
  bool _mapReady = false;
  bool _warmedUp = false;
  File? _backgroundPhoto;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_warmedUp) return;
    _warmedUp = true;
    if (widget.hasRealLocation) {
      _warmUpMap();
    } else {
      _mapReady = true;
    }
  }

  // 공유 캡처 시점에 지도 스냅샷이 아직 로딩 중(스피너)이면 그 화면이 그대로
  // 캡처되니, 미리 한 번 불러와 캐시에 채워둔다.
  Future<void> _warmUpMap() async {
    await RouteMapSnapshotService.capture(context, stores: widget.stores);
    if (!mounted) return;
    setState(() => _mapReady = true);
  }

  Future<void> _pickBackgroundPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;
    setState(() => _backgroundPhoto = File(picked.path));
  }

  void _resetBackground() {
    setState(() => _backgroundPhoto = null);
  }

  Future<void> _shareToInstagram() async {
    if (_sharing) return;

    if (!_mapReady) {
      AppSnackBar.info(context, '지도를 준비하고 있어요. 잠시만 기다려주세요');
      return;
    }

    setState(() => _sharing = true);

    try {
      final boundary =
      _cardKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;

      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3);

      final byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

      image.dispose();

      if (byteData == null) return;

      final dir = await getTemporaryDirectory();

      final file = File('${dir.path}/route_story.png');

      await file.writeAsBytes(byteData.buffer.asUint8List());

      // 공유 링크 자동 복사
      await Clipboard.setData(
        ClipboardData(
          text: widget.history.shareUrl!,
        ),
      );

      // 인스타그램 스토리 열기
      final handled = await InstagramShareService.shareToStory(
        file.path,
        contentUrl: widget.history.shareUrl!,
      );

      if (handled) return;

      // 인스타그램이 없으면 일반 공유
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'image/png',
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
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
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 22,
                ),
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
                        hasRealLocation: widget.hasRealLocation,
                        backgroundPhoto: _backgroundPhoto,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _BackgroundOptionChip(
                      label: '지도 배경',
                      icon: Icons.map_outlined,
                      selected: _backgroundPhoto == null,
                      onTap: _resetBackground,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BackgroundOptionChip(
                      label: '내 사진 배경',
                      icon: Icons.image_outlined,
                      selected: _backgroundPhoto != null,
                      onTap: _pickBackgroundPhoto,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "공유 링크가 자동으로 복사됩니다.\n"
                            "Instagram에서 '링크' 스티커를 추가한 후 붙여넣으면 "
                            "다른 사용자도 바로 루트를 확인할 수 있습니다.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: BottomButton(
                text: !_mapReady
                    ? '지도 준비 중...'
                    : (_sharing ? '공유 준비 중...' : '인스타 공유'),
                onTap: _shareToInstagram,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// "지도 배경" / "내 사진 배경"을 고르는 선택 칩.
class _BackgroundOptionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _BackgroundOptionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.greenWhite : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.button
                : Colors.grey.shade300,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? AppColors.button : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.button : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
