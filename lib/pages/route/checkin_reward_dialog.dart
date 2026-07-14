import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/models/challenge_model.dart';
import 'package:spin_app/models/route_model.dart';

/// QR 체크인 성공 후 보여주는 포인트 적립 보상 화면.
/// 도장이 통통 튀며 나타나고, 이번에 적립된 포인트와 누적 포인트가
/// 순서대로 카운트업된다.
Future<void> showCheckInRewardDialog(
  BuildContext context, {
  required RouteStopModel store,
  required CheckInResult result,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '체크인 보상',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, _) =>
        Center(child: _CheckInRewardCard(store: store, result: result)),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _CheckInRewardCard extends StatefulWidget {
  final RouteStopModel store;
  final CheckInResult result;

  const _CheckInRewardCard({required this.store, required this.result});

  @override
  State<_CheckInRewardCard> createState() => _CheckInRewardCardState();
}

class _CheckInRewardCardState extends State<_CheckInRewardCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  late final Animation<double> _stampScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.05, 0.45, curve: Curves.elasticOut),
  );

  late final Animation<double> _sparkle = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
  );

  late final Animation<double> _pointsScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 0.55, curve: Curves.easeOutBack),
  );

  late final Animation<double> _pointsCount = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
  );

  late final Animation<double> _messageFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
  );

  late final Animation<double> _totalReveal = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
  );

  int get _prevTotal =>
      (widget.result.totalPoints - widget.result.pointsEarned).clamp(
        0,
        widget.result.totalPoints,
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final store = widget.store;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 314,
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(30),
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
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Icon(
                    Icons.close,
                    size: 24,
                    color: AppColors.greenKelp,
                  ),
                ),
                const Spacer(),
                if (result.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.button,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      '루트 완주',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.background,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 108,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _sparkle,
                    builder: (context, _) => CustomPaint(
                      size: const Size(190, 108),
                      painter: _SparklePainter(progress: _sparkle.value),
                    ),
                  ),
                  ScaleTransition(
                    scale: _stampScale,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/stamp.png',
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 2,
                    child: ScaleTransition(
                      scale: _pointsScale,
                      child: _PointsBadge(
                        animation: _pointsCount,
                        points: result.pointsEarned,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              store.storeName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.greenKelp,
              ),
            ),
            const SizedBox(height: 14),
            FadeTransition(
              opacity: _messageFade,
              child: Text(
                "'${store.storeName}'에 방문해서 포인트를 얻었어요!\n\n"
                '모은 포인트는 앱에 등록된 가게 내에서\n현금처럼 사용 가능해요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                  color: AppColors.greenKelp.withValues(alpha: 0.72),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _totalReveal,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(_totalReveal),
                child: _TotalPointsPill(
                  animation: _totalReveal,
                  from: _prevTotal,
                  to: result.totalPoints,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 도장 옆에 통통 튀며 나타나는 "+N P" 배지. [animation]은 0→1 단조 증가여야
/// 숫자가 흔들림 없이 목표값까지 카운트업된다.
class _PointsBadge extends StatelessWidget {
  final Animation<double> animation;
  final int points;

  const _PointsBadge({required this.animation, required this.points});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final shown = (animation.value.clamp(0.0, 1.0) * points).round();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.button,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: AppColors.button.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            '+$shown P',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.background,
            ),
          ),
        );
      },
    );
  }
}

/// 하단의 "총 포인트" 알약. [from]에서 [to]까지 카운트업된다.
class _TotalPointsPill extends StatelessWidget {
  final Animation<double> animation;
  final int from;
  final int to;

  const _TotalPointsPill({
    required this.animation,
    required this.from,
    required this.to,
  });

  static String _format(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value.clamp(0.0, 1.0);
        final shown = (from + (to - from) * t).round();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.greenWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.button.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
                '총 포인트',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenKelp.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_format(shown)}P',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.greenKelp,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 도장 주위로 은은하게 퍼지는 반짝임 장식.
class _SparklePainter extends CustomPainter {
  final double progress;

  _SparklePainter({required this.progress});

  static const _angles = [-70.0, -20.0, 35.0, 110.0, 160.0, 210.0];

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;

    final center = Offset(size.width / 2, size.height / 2 - 4);
    final paint = Paint()..color = AppColors.button.withValues(alpha: 0.75 * p);

    for (var i = 0; i < _angles.length; i++) {
      final rad = _angles[i] * math.pi / 180;
      final distance = 44 + 14 * p;
      final dotCenter = center + Offset(math.cos(rad), math.sin(rad)) * distance;
      final radius = (i.isEven ? 3.2 : 2.0) * p;
      canvas.drawCircle(dotCenter, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
