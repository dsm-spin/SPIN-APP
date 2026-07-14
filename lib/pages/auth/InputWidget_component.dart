import 'package:flutter/material.dart';

class InputComponent extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool secureText;

  const InputComponent({
    super.key,
    required this.controller,
    required this.hintText,
    this.secureText = false,

  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.0,horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          width: 1.0,
        ),
      ),
      width: double.infinity,
      height: 60,
      child: TextFormField(
        obscureText: secureText,
        onTapOutside: (event)=>FocusManager.instance.primaryFocus?.unfocus(),
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
        ),
      ),
    );
  }
}
