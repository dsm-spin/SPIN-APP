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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '로그인을 아직 안하셨나요?',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 20),
              TextButton(
                onPressed: () {},
                child: Text(
                  '로그인',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              )
            ],
          ),
          Container(
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
          ),
        ],
      ),
    );
  }
}
