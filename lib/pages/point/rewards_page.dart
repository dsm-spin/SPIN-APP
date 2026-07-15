import 'package:flutter/material.dart';
import 'package:spin_app/core/storage/point_store.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/models/point_model.dart';
import 'package:spin_app/models/reward_model.dart';
import 'package:spin_app/pages/point/point_page.dart' show formatPoints;
import 'package:spin_app/pages/point/redemption_success_page.dart';

/// 포인트를 가게 혜택으로 교환하는 화면.
///
/// 서버에 포인트 사용 API가 아직 없어서, 기기에서 잔액을 직접 차감하고
/// 사용 내역을 [pointStore]에 남긴다.
class RewardsPage extends StatefulWidget {
  final int initialBalance;

  const RewardsPage({super.key, required this.initialBalance});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  late int _balance = widget.initialBalance;
  bool _redeeming = false;

  Future<void> _redeem(RewardModel reward) async {
    if (_redeeming || _balance < reward.cost) return;
    setState(() => _redeeming = true);

    final confirmed = await _confirmRedeem(reward);
    if (!mounted || confirmed != true) {
      setState(() => _redeeming = false);
      return;
    }

    final newBalance = _balance - reward.cost;
    final code = generateRedemptionCode();
    await pointStore.add(
      PointEntry(
        storeName: reward.title,
        points: reward.cost,
        balanceAfter: newBalance,
        earnedAt: DateTime.now(),
        challengeId: 0,
        type: PointEntryType.spend,
        code: code,
      ),
    );
    if (!mounted) return;

    setState(() {
      _balance = newBalance;
      _redeeming = false;
    });

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RedemptionSuccessPage(
          reward: reward,
          code: code,
          remainingBalance: newBalance,
        ),
      ),
    );
  }

  Future<bool?> _confirmRedeem(RewardModel reward) {
    return showRedeemConfirmDialog(context, reward: reward, balance: _balance);
  }

  @override
  Widget build(BuildContext context) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '포인트로 혜택 받기',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '보유 포인트 ${formatPoints(_balance)}P',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.button,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(25, 0, 25, 24),
                itemCount: rewardCatalog.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final reward = rewardCatalog[index];
                  return _RewardCard(
                    reward: reward,
                    affordable: _balance >= reward.cost,
                    onTap: () => _redeem(reward),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final RewardModel reward;
  final bool affordable;
  final VoidCallback onTap;

  const _RewardCard({
    required this.reward,
    required this.affordable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: affordable ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: affordable ? AppColors.greenWhite : AppColors.springWood,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.button.withValues(alpha: affordable ? 0.15 : 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Text(
                reward.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenKelp.withValues(
                        alpha: affordable ? 1 : 0.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    reward.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.greenKelp.withValues(
                        alpha: affordable ? 0.55 : 0.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatPoints(reward.cost)}P',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: affordable
                        ? AppColors.button
                        : AppColors.greenKelp.withValues(alpha: 0.35),
                  ),
                ),
                if (!affordable) ...[
                  const SizedBox(height: 3),
                  Text(
                    '포인트 부족',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.greenKelp.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "포인트로 혜택 받기"에서 혜택을 고르면 뜨는 교환 확인 모달.
/// 현재 잔액 → 차감 → 교환 후 잔액을 한눈에 보여준다.
Future<bool?> showRedeemConfirmDialog(
  BuildContext context, {
  required RewardModel reward,
  required int balance,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '포인트 교환 확인',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, _, _) =>
        Center(child: _RedeemConfirmDialog(reward: reward, balance: balance)),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _RedeemConfirmDialog extends StatelessWidget {
  final RewardModel reward;
  final int balance;

  const _RedeemConfirmDialog({required this.reward, required this.balance});

  @override
  Widget build(BuildContext context) {
    final remaining = balance - reward.cost;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.greenWhite,
                shape: BoxShape.circle,
              ),
              child: Text(reward.emoji, style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(height: 16),
            Text(
              "'${reward.title}'로\n교환할까요?",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.35,
                color: AppColors.greenKelp,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reward.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.greenKelp.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.springWood,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.button.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  _PointColumn(label: '현재', value: balance),
                  Icon(
                    Icons.remove_rounded,
                    size: 16,
                    color: AppColors.greenKelp.withValues(alpha: 0.35),
                  ),
                  _PointColumn(label: '교환', value: reward.cost, accent: true),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.greenKelp.withValues(alpha: 0.35),
                  ),
                  _PointColumn(label: '남음', value: remaining),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.greenWhite,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.greenKelp.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.button,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '교환',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 포인트 내역 박스 안에서 "현재 / 교환 / 남음" 한 칸을 그린다.
class _PointColumn extends StatelessWidget {
  final String label;
  final int value;
  final bool accent;

  const _PointColumn({
    required this.label,
    required this.value,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.greenKelp.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${accent ? '-' : ''}${formatPoints(value)}P',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: accent ? const Color(0xFFC2607A) : AppColors.greenKelp,
            ),
          ),
        ],
      ),
    );
  }
}
