import 'package:flutter/material.dart';
import 'package:spin_app/theme/colors.dart';

class SelectButton extends StatelessWidget {
  bool isOn;
  final String text;
  final VoidCallback onTap;

  SelectButton({
    super.key,
    required this.text,
    required this.onTap,
    required this.isOn,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isOn ? AppColors.button : Color(0xFFF1F3EA),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.button, width: 1.5),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isOn ? AppColors.background : Colors.black,
          ),
        ),
      ),
    );
  }
}
