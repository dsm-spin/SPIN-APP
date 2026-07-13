import 'package:flutter/material.dart';

class InputComponent extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const InputComponent({
    super.key,
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          width: 1.0,
        ),
      ),
      width: double.infinity,
      height: 60,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
        ),
      ),
    );
  }
}
