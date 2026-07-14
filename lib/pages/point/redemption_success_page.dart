import 'dart:math';

import 'package:flutter/material.dart';
import 'package:spin_app/core/components/bottom_button.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/models/reward_model.dart';

/// 교환 코드를 만든다. 서버 검증 없이 기기에서만 보여주는 데모용 코드라
/// 형식만 갖추면 충분하다 (예: 4A9K-72XZ).
String generateRedemptionCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = Random();
  String block() =>
      List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
  return '${block()}-${block()}';
}

/// 혜택 교환이 끝난 뒤 보여주는 완료 화면.
/// 가게 직원에게 보여줄 교환 코드를 큼직하게 표시한다.
class RedemptionSuccessPage extends StatelessWidget {
  final RewardModel reward;
  final String code;
  final int remainingBalance;

  const RedemptionSuccessPage({
    super.key,
    required this.reward,
    required this.code,
    required this.remainingBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 12, 25, 12),
          // 작은 기기나 큰 글꼴에서는 쿠폰이 화면에 다 안 들어간다.
          // 남는 자리에 억지로 우겨넣지 말고 스크롤로 흘려보낸다.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.button,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.background,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '교환 완료!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenKelp,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "'${reward.title}'로 교환됐어요",
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.greenKelp.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _CouponTicket(reward: reward, code: code),
                    const SizedBox(height: 24),
                    Text(
                      '남은 포인트 ${remainingBalance}P',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greenKelp.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 16),
                    BottomButton(
                      text: '확인',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CouponTicket extends StatelessWidget {
  final RewardModel reward;
  final String code;

  const _CouponTicket({required this.reward, required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: AppColors.greenWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.button.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(reward.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 14),
          Text(
            reward.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.greenKelp,
            ),
          ),
          const SizedBox(height: 24),
          const _DashedDivider(),
          const SizedBox(height: 24),
          Text(
            '가게 직원에게 아래 코드를 보여주세요',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.greenKelp.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            code,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: AppColors.button,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 6.0;
          const gap = 5.0;
          final count = (constraints.maxWidth / (dashWidth + gap)).floor();
          return Row(
            children: List.generate(
              count,
              (_) => Padding(
                padding: const EdgeInsets.only(right: gap),
                child: Container(
                  width: dashWidth,
                  height: 1,
                  color: AppColors.button.withValues(alpha: 0.3),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
