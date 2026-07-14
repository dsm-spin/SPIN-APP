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
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("'${reward.title}'로 교환할까요?"),
        content: Text('${formatPoints(reward.cost)}P가 차감돼요'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('교환'),
          ),
        ],
      ),
    );
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
