import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:spin_app/core/components/InputWidget_component.dart';

class InputWidget extends StatefulWidget {
  final TextEditingController idController;
  final TextEditingController passwordController;

  const InputWidget({
    super.key,
    required this.idController,
    required this.passwordController,
  });

  @override
  State<InputWidget> createState() => _InputWidgetState();
}

class _InputWidgetState extends State<InputWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InputComponent(controller: widget.idController, hintText: '아이디'),
        const SizedBox(height: 10),
        InputComponent(
          controller: widget.passwordController,
          hintText: '비밀번호',
          secureText: true,
        ),
      ],
    );
  }
}
