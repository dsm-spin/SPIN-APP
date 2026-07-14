import 'package:flutter/material.dart';
import 'package:spin_app/core/components/route_story_card.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/models/history_model.dart';
import 'package:spin_app/models/store_model.dart';

/// 루트를 완주했을 때 띄우는 축하 + 인스타 공유 제안 다이얼로그.
/// 공유 페이지에 올라가는 것과 같은 스토리 카드를 그대로 미리 보여준다.
///
/// 인스타에 올리기를 누르면 true, 나중에/닫기면 false를 반환한다.
Future<bool> showRouteCompleteDialog(
  BuildContext context, {
  required HistoryModel history,
  required List<StoreModel> stores,
}) async {
  final wantsShare = await showDialog<bool>(
    context: context,
    builder: (context) =>
        _RouteCompleteDialog(history: history, stores: stores),
  );
  return wantsShare ?? false;
}

class _RouteCompleteDialog extends StatelessWidget {
  final HistoryModel history;
  final List<StoreModel> stores;

  const _RouteCompleteDialog({required this.history, required this.stores});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.greenWhite,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🎉', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '루트를 완주하셨습니다!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.greenKelp,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '오늘 다녀온 골목,\n인스타에 올리시겠습니까?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.greenKelp.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 18),
              // 공유 페이지와 같은 카드 — 미리 본 그대로가 스토리에 올라간다.
              // (카드가 주어진 자리에 맞춰 알아서 축소된다.)
              Center(
                child: SizedBox(
                  height: 300,
                  child: AspectRatio(
                    aspectRatio:
                        RouteStoryCard.storySize.width /
                        RouteStoryCard.storySize.height,
                    child: RouteStoryCard(history: history, stores: stores),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.button,
                  foregroundColor: AppColors.background,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '인스타에 올리기',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  '나중에 할게요',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenKelp.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
