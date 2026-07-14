import 'package:flutter/material.dart';

/// 어두운 배경 위에 라벨 + 큰 숫자(옵션으로 작은 단위)를 표시하는 스탯 묶음.
/// 히스토리 상세 카드와 인스타 스토리 공유 이미지에서 공용으로 사용한다.
class SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;

  const SummaryStat({
    super.key,
    required this.label,
    required this.value,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFBDBDBD),
          ),
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
            children: [
              if (unit != null)
                TextSpan(
                  text: unit,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
