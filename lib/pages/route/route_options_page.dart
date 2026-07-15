import 'package:flutter/material.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/models/route_model.dart';
import 'package:spin_app/pages/route/route_detail_page.dart';

/// 루트를 3개 만들어서 카드로 보여주고, 마음에 드는 걸 고르게 하는 화면.
///
/// 서버에 "여러 개 한 번에 생성" API가 없어서, 홈 화면에서 /routes를 3번
/// 호출해 각각의 결과를 여기로 넘겨받는다. 개수가 3보다 적으면(일부 생성
/// 실패) 성공한 만큼만 보여준다.
class RouteOptionsPage extends StatelessWidget {
  final List<RouteGenerateResult> options;
  final String region;
  final String purpose;

  const RouteOptionsPage({
    super.key,
    required this.options,
    required this.region,
    required this.purpose,
  });

  void _selectOption(BuildContext context, RouteGenerateResult option) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteDetailPage(
          result: option,
          region: region,
          purpose: purpose,
        ),
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
                    '마음에 드는 루트를\n골라보세요',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$region · $purpose',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.greenKelp.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(25, 0, 25, 24),
                itemCount: options.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) => _RouteOptionCard(
                  index: index,
                  option: options[index],
                  onSelect: () => _selectOption(context, options[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteOptionCard extends StatelessWidget {
  final int index;
  final RouteGenerateResult option;
  final VoidCallback onSelect;

  const _RouteOptionCard({
    required this.index,
    required this.option,
    required this.onSelect,
  });

  static const _labels = ['코스 A', '코스 B', '코스 C'];

  String get _label => index < _labels.length ? _labels[index] : '코스 ${index + 1}';

  String get _distanceLabel =>
      (option.totalDistanceMeters / 1000).toStringAsFixed(1);

  String get _durationLabel {
    final hours = option.estimatedDurationMinutes ~/ 60;
    final minutes = option.estimatedDurationMinutes % 60;
    if (hours <= 0) return '$minutes분';
    if (minutes <= 0) return '$hours시간';
    return '$hours시간 $minutes분';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.button,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    _label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.background,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.greenKelp.withValues(alpha: 0.35),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              [for (final stop in option.stops) stop.storeName].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.4,
                color: AppColors.greenKelp,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniStat(icon: Icons.route_rounded, text: '$_distanceLabel km'),
                const SizedBox(width: 14),
                _MiniStat(icon: Icons.schedule_rounded, text: _durationLabel),
                const SizedBox(width: 14),
                _MiniStat(
                  icon: Icons.storefront_rounded,
                  text: '${option.storeCount}곳',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniStat({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.button.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.greenKelp.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}
