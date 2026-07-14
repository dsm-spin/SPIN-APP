import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spin_app/core/storage/point_store.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/models/point_model.dart';
import 'package:spin_app/models/reward_model.dart';
import 'package:spin_app/models/store_model.dart';
import 'package:spin_app/pages/point/point_page.dart' show formatPoints;

/// 포인트로 교환해서 쌓인 쿠폰(사용 내역)을 모아 보여주는 화면.
/// 아직 가게에서 쓰지 않은 쿠폰은 코드를 다시 확인하고 '사용 처리'할 수 있다.
class CouponsPage extends StatefulWidget {
  const CouponsPage({super.key});

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> {
  late Future<PointLedger> _future = _loadLedger();

  Future<PointLedger> _loadLedger() async {
    return PointLedger.fromEntries(await pointStore.load());
  }

  Future<void> _refresh() async {
    final future = _loadLedger();
    setState(() => _future = future);
    await future;
  }

  Future<void> _useCoupon(PointEntry coupon) async {
    final confirmed = await showUseCouponDialog(context, coupon: coupon);
    if (confirmed != true || coupon.code == null) return;

    await pointStore.markCouponUsed(coupon.code!);
    if (!mounted) return;

    await _refresh();
    if (!mounted) return;

    await showCouponUsedDialog(context, coupon: coupon);
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
                '내 쿠폰함',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<PointLedger>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final coupons =
                      snapshot.data?.coupons ?? const <PointEntry>[];

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: coupons.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(25, 40, 25, 24),
                            children: const [_EmptyCoupons()],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(25, 0, 25, 24),
                            itemCount: coupons.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final coupon = coupons[index];
                              return _CouponCard(
                                coupon: coupon,
                                onUse: coupon.used
                                    ? null
                                    : () => _useCoupon(coupon),
                              );
                            },
                          ),
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

RewardModel? _rewardFor(String rewardTitle) {
  for (final reward in rewardCatalog) {
    if (reward.title == rewardTitle) return reward;
  }
  return null;
}

String _emojiFor(String rewardTitle) => _rewardFor(rewardTitle)?.emoji ?? '🎟️';

class _CouponCard extends StatelessWidget {
  final PointEntry coupon;
  final VoidCallback? onUse;

  const _CouponCard({required this.coupon, required this.onUse});

  bool get _isUsed => coupon.used;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isUsed ? AppColors.springWood : AppColors.greenWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.button.withValues(alpha: _isUsed ? 0.08 : 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _emojiFor(coupon.storeName),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coupon.storeName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greenKelp.withValues(
                          alpha: _isUsed ? 0.45 : 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${coupon.earnedAtLabel} · ${formatPoints(coupon.points)}P 사용',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.greenKelp.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(used: _isUsed),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.button.withValues(alpha: 0.12)),
            ),
            child: Text(
              coupon.code ?? '-',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: _isUsed
                    ? AppColors.greenKelp.withValues(alpha: 0.35)
                    : AppColors.button,
              ),
            ),
          ),
          if (onUse != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onUse,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.button,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '가게에서 사용하기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.background,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool used;

  const _StatusBadge({required this.used});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: used
            ? AppColors.greenKelp.withValues(alpha: 0.08)
            : AppColors.button.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        used ? '사용완료' : '사용가능',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: used
              ? AppColors.greenKelp.withValues(alpha: 0.4)
              : AppColors.button,
        ),
      ),
    );
  }
}

class _EmptyCoupons extends StatelessWidget {
  const _EmptyCoupons();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 44,
            color: AppColors.button.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 14),
          const Text(
            '아직 교환한 쿠폰이 없어요',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.greenKelp,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '포인트로 혜택을 교환하면\n여기서 쿠폰을 다시 확인할 수 있어요',
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

/// "가게에서 사용하기"를 누르면 뜨는 확인 모달.
/// 어느 매장에서 쓸 수 있는지 지도로 보여주고, 사용 처리 여부를 확인받는다.
Future<bool?> showUseCouponDialog(
  BuildContext context, {
  required PointEntry coupon,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '쿠폰 사용 확인',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, _, _) => Center(child: _UseCouponDialog(coupon: coupon)),
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

class _UseCouponDialog extends StatelessWidget {
  final PointEntry coupon;

  const _UseCouponDialog({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final reward = _rewardFor(coupon.storeName);
    final stores = reward?.stores ?? const <StoreModel>[];

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.greenWhite,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _emojiFor(coupon.storeName),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.storeName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.greenKelp,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '이 쿠폰을 사용 처리할까요?',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.greenKelp.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.springWood,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.button.withValues(alpha: 0.12)),
              ),
              child: Text(
                coupon.code ?? '-',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: AppColors.button,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.place_rounded,
                  size: 16,
                  color: AppColors.greenKelp.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 4),
                Text(
                  '여기서 사용할 수 있어요',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenKelp.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _CouponLocationMap(stores: stores),
            ),
            if (stores.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                stores.map((s) => s.name).join(' · '),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.greenKelp.withValues(alpha: 0.55),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              '가게 직원에게 코드를 보여준 뒤에 사용 처리해주세요.\n한 번 사용 처리하면 되돌릴 수 없어요.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.greenKelp.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 18),
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
                        '사용',
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

/// 쿠폰을 쓸 수 있는 매장 위치를 보여주는 작은 지도.
/// 매장 정보가 없는 혜택(앱 안에서 바로 적용되는 혜택 등)은 안내 문구로 대신한다.
class _CouponLocationMap extends StatelessWidget {
  final List<StoreModel> stores;

  const _CouponLocationMap({required this.stores});

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        alignment: Alignment.center,
        color: AppColors.springWood,
        child: Text(
          '앱 안에서 바로 적용되는 혜택이에요',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.greenKelp.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final target = LatLng(stores.first.latitude, stores.first.longitude);

    return SizedBox(
      height: 130,
      width: double.infinity,
      child: IgnorePointer(
        ignoring: false,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: target, zoom: 13.5),
          markers: {
            for (final store in stores)
              Marker(
                markerId: MarkerId(store.name),
                position: LatLng(store.latitude, store.longitude),
                infoWindow: InfoWindow(title: store.name, snippet: store.address),
              ),
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          liteModeEnabled: true,
        ),
      ),
    );
  }
}

/// 쿠폰을 가게에서 사용 처리한 직후 보여주는 축하 모달.
Future<void> showCouponUsedDialog(
  BuildContext context, {
  required PointEntry coupon,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '쿠폰 사용 완료',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, _, _) => Center(child: _CouponUsedCard(coupon: coupon)),
    transitionBuilder: (context, animation, _, child) {
      // 배경 어두워짐 + 살짝 커지며 등장. 안쪽 축하 연출은
      // _CouponUsedCard가 자체 컨트롤러로 단계별로 재생한다.
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

/// 체크 아이콘이 통통 튀며 나타나고 색종이가 흩날린 뒤, 문구·코드·버튼이
/// 순서대로 나타나는 축하 카드. 구성은 체크인 보상 다이얼로그와 결을 맞췄다.
class _CouponUsedCard extends StatefulWidget {
  final PointEntry coupon;

  const _CouponUsedCard({required this.coupon});

  @override
  State<_CouponUsedCard> createState() => _CouponUsedCardState();
}

class _CouponUsedCardState extends State<_CouponUsedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  late final Animation<double> _ringScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
  );

  late final Animation<double> _iconScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.05, 0.5, curve: Curves.elasticOut),
  );

  late final Animation<double> _confetti = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.1, 0.65, curve: Curves.easeOut),
  );

  late final Animation<double> _textReveal = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
  );

  late final Animation<double> _codeReveal = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.6, 0.9, curve: Curves.easeOutBack),
  );

  late final Animation<double> _buttonFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.82, 1.0, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coupon = widget.coupon;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(28),
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
            SizedBox(
              height: 108,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(180, 108),
                        painter: _ConfettiPainter(progress: _confetti.value),
                      ),
                      Transform.scale(
                        scale: 1 + _ringScale.value * 0.9,
                        child: Opacity(
                          opacity: (1 - _ringScale.value).clamp(0.0, 1.0),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.button.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      ScaleTransition(
                        scale: _iconScale,
                        child: Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.button,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.button.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppColors.background,
                            size: 34,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            FadeTransition(
              opacity: _textReveal,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(_textReveal),
                child: Column(
                  children: [
                    const Text(
                      '쿠폰을 사용했어요!',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenKelp,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "'${coupon.storeName}' 쿠폰 사용이 완료됐어요",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.greenKelp.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            ScaleTransition(
              scale: _codeReveal,
              child: FadeTransition(
                opacity: _codeReveal,
                child: _UsedCodeTicket(code: coupon.code ?? '-'),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _buttonFade,
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.button,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 사용 완료된 코드를 취소선과 함께 보여주는 작은 티켓. "사용완료" 스탬프가
/// 코드 위에 살짝 기울어져 겹친다.
class _UsedCodeTicket extends StatelessWidget {
  final String code;

  const _UsedCodeTicket({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.springWood,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.button.withValues(alpha: 0.12)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            code,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: AppColors.greenKelp.withValues(alpha: 0.3),
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.greenKelp.withValues(alpha: 0.3),
              decorationThickness: 2,
            ),
          ),
          Transform.rotate(
            angle: -0.18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.button,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '사용완료',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.background,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 체크 아이콘 주위로 색색의 색종이 조각이 흩날리는 축하 연출.
class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter({required this.progress});

  static const _pieces = <_ConfettiPiece>[
    _ConfettiPiece(angle: -100, distance: 46, size: 4.5, color: AppColors.button),
    _ConfettiPiece(angle: -55, distance: 58, size: 3.5, color: AppColors.impact),
    _ConfettiPiece(angle: -15, distance: 50, size: 4.0, color: AppColors.warning),
    _ConfettiPiece(angle: 20, distance: 60, size: 3.0, color: AppColors.button),
    _ConfettiPiece(angle: 60, distance: 48, size: 4.5, color: AppColors.impact),
    _ConfettiPiece(angle: 100, distance: 56, size: 3.5, color: AppColors.warning),
    _ConfettiPiece(angle: 140, distance: 50, size: 3.0, color: AppColors.button),
    _ConfettiPiece(angle: -140, distance: 54, size: 4.0, color: AppColors.impact),
    _ConfettiPiece(angle: 180, distance: 46, size: 3.5, color: AppColors.warning),
    _ConfettiPiece(angle: 0, distance: 62, size: 3.0, color: AppColors.button),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;

    // 앞부분에서 튀어나가고, 뒷부분에서 옅어지며 사라진다.
    final travel = Curves.easeOut.transform(p);
    final fade = p < 0.6 ? 1.0 : 1 - ((p - 0.6) / 0.4);

    final center = Offset(size.width / 2, size.height / 2 - 6);

    for (final piece in _pieces) {
      final rad = piece.angle * math.pi / 180;
      final offset =
          center + Offset(math.cos(rad), math.sin(rad)) * piece.distance * travel;
      final paint = Paint()
        ..color = piece.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.drawCircle(offset, piece.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ConfettiPiece {
  final double angle;
  final double distance;
  final double size;
  final Color color;

  const _ConfettiPiece({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
  });
}
