import 'package:flutter/material.dart';
import 'package:spin_app/core/theme/colors.dart';

class BottomButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const BottomButton({
    super.key,
    required this.text,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.button,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: TextButton(
        onPressed: onTap,
        child: Text(
          textAlign: TextAlign.center,
          text,
          style: TextStyle(
            color: AppColors.background,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

      ),
    );
  }
}
