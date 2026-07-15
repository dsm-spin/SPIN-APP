import 'package:flutter/material.dart';
import 'package:spin_app/api/auth_api.dart';
import 'package:spin_app/core/components/app_snackbar.dart';
import 'package:spin_app/core/storage/point_store.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/pages/point/point_page.dart' show formatPoints;
import 'package:spin_app/pages/splash/splash.dart';

/// '설정' 화면. 서버에 포인트 수정/로그아웃 API가 따로 없어서
/// 포인트는 기기 원장([PointStore])을 직접 건드리고,
/// 로그아웃은 기기에 저장된 세션 쿠키만 지운다.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _amountController = TextEditingController();
  late Future<PointLedger> _future = _loadLedger();
  bool _busy = false;

  Future<PointLedger> _loadLedger() async {
    return PointLedger.fromEntries(await pointStore.load());
  }

  Future<void> _refresh() async {
    final future = _loadLedger();
    setState(() {
      _future = future;
    });
    await future;
  }

  int? get _enteredAmount => int.tryParse(_amountController.text.trim());

  Future<void> _adjustPoint({required bool isEarn}) async {
    final amount = _enteredAmount;
    if (amount == null || amount <= 0) {
      AppSnackBar.warning(context, '수정할 포인트를 숫자로 입력해주세요');
      return;
    }

    setState(() => _busy = true);
    if (isEarn) {
      await pointStore.addTestPoint(
        points: amount,
        challengeId: 0,
        storeName: '포인트 직접 수정',
      );
    } else {
      await pointStore.spendTestPoint(
        points: amount,
        challengeId: 0,
        storeName: '포인트 직접 수정',
      );
    }
    if (!mounted) return;

    _amountController.clear();
    setState(() => _busy = false);
    await _refresh();
    if (!mounted) return;

    AppSnackBar.success(
      context,
      isEarn ? '${formatPoints(amount)}P를 적립했어요' : '${formatPoints(amount)}P를 차감했어요',
    );
  }

  Future<void> _confirmLogOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃 할까요?'),
        content: const Text('다시 이용하려면 로그인이 필요해요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '로그아웃',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await logOutApi();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Splash()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Text(
                '설정',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(25, 20, 25, 24),
                children: [
                  const Text(
                    '포인트 직접 수정',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greenKelp,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '서버 연동 전까지, 기기에 저장된 포인트를 직접 더하거나 뺄 수 있어요',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.greenKelp.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FutureBuilder<PointLedger>(
                    future: _future,
                    builder: (context, snapshot) {
                      final balance = snapshot.data?.balance ?? 0;
                      return _PointEditCard(
                        balance: balance,
                        controller: _amountController,
                        busy: _busy,
                        onEarn: () => _adjustPoint(isEarn: true),
                        onSpend: () => _adjustPoint(isEarn: false),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    '계정',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greenKelp,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LogOutTile(onTap: _confirmLogOut),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointEditCard extends StatelessWidget {
  final int balance;
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onEarn;
  final VoidCallback onSpend;

  const _PointEditCard({
    required this.balance,
    required this.controller,
    required this.busy,
    required this.onEarn,
    required this.onSpend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.greenWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.button.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '현재 잔액 ${formatPoints(balance)}P',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.button,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            enabled: !busy,
            decoration: InputDecoration(
              hintText: '수정할 포인트 (예: 500)',
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: '포인트 적립',
                  icon: Icons.add_rounded,
                  color: AppColors.button,
                  onTap: busy ? null : onEarn,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: '포인트 차감',
                  icon: Icons.remove_rounded,
                  color: AppColors.error,
                  onTap: busy ? null : onSpend,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? color : color.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.background),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.background,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogOutTile extends StatelessWidget {
  final VoidCallback onTap;

  const _LogOutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
            SizedBox(width: 10),
            Text(
              '로그아웃',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
