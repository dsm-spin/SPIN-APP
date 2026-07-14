import 'package:flutter/material.dart';
import 'package:spin_app/core/storage/point_store.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/models/point_model.dart';
import 'package:spin_app/pages/point/rewards_page.dart';

/// '포인트' 탭: 현재 잔액과 체크인으로 쌓인 적립 내역을 보여준다.
/// 내역은 기기에 저장된 원장([PointStore])에서 읽어온다.
class PointPage extends StatefulWidget {
  const PointPage({super.key});

  @override
  State<PointPage> createState() => _PointPageState();
}

class _PointPageState extends State<PointPage> {
  late Future<PointLedger> _future = _loadLedger();

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

  Future<void> _openRewards(int balance) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RewardsPage(initialBalance: balance),
      ),
    );
    // 혜택 교환으로 잔액/내역이 바뀌었을 수 있으니 다시 불러온다.
    if (!mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<PointLedger>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final ledger =
                snapshot.data ??
                const PointLedger(balance: 0, entries: <PointEntry>[]);
            final entries = ledger.entries;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(25, 30, 25, 24),
                children: [
                  const Text(
                    '내 포인트',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _BalanceCard(ledger: ledger),
                  const SizedBox(height: 14),
                  _RedeemButton(onTap: () => _openRewards(ledger.balance)),
                  const SizedBox(height: 28),
                  const Text(
                    '포인트 내역',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greenKelp,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (entries.isEmpty)
                    const _EmptyEntries()
                  else
                    for (final entry in entries) ...[
                      _EntryRow(entry: entry),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 천 단위 콤마: 12345 -> '12,345'
String formatPoints(int value) {
  final text = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return buffer.toString();
}

class _BalanceCard extends StatelessWidget {
  final PointLedger ledger;

  const _BalanceCard({required this.ledger});

  @override
  Widget build(BuildContext context) {
    final thisMonth = ledger.earnedThisMonth(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: AppColors.greenWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.button.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.button,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.paid_rounded,
                  size: 15,
                  color: AppColors.background,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '보유 포인트',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenKelp.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${formatPoints(ledger.balance)}P',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.greenKelp,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '이번 달 +${formatPoints(thisMonth)}P · 총 ${ledger.earnCount}번 적립',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.button.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '모은 포인트는 앱에 등록된 가게에서 현금처럼 쓸 수 있어요',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.greenKelp.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// 잔액 카드 아래의 "포인트로 혜택 받기" 버튼
class _RedeemButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RedeemButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.button,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.card_giftcard_rounded,
              size: 18,
              color: AppColors.background,
            ),
            const SizedBox(width: 8),
            const Text(
              '포인트로 혜택 받기',
              style: TextStyle(
                fontSize: 15,
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

class _EntryRow extends StatelessWidget {
  final PointEntry entry;

  const _EntryRow({required this.entry});

  bool get _isSpend => entry.type == PointEntryType.spend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.button.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _isSpend
              ? Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.impact.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    size: 18,
                    color: AppColors.greenKelp,
                  ),
                )
              : Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage('assets/images/stamp.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.storeName.isEmpty ? '체크인 적립' : entry.storeName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenKelp,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isSpend ? '${entry.earnedAtLabel} · 혜택 교환' : entry.earnedAtLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.greenKelp.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_isSpend ? '-' : '+'}${formatPoints(entry.points)}P',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _isSpend ? const Color(0xFFC2607A) : AppColors.button,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEntries extends StatelessWidget {
  const _EmptyEntries();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.paid_rounded,
            size: 44,
            color: AppColors.button.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 14),
          const Text(
            '아직 적립 내역이 없어요',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.greenKelp,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '루트를 돌며 가게에서 QR 도장을 찍으면\n포인트가 쌓여요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.greenKelp.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
