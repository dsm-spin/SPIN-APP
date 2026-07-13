import 'package:flutter/material.dart';
import 'package:spin_app/auth/InputWidget_component.dart';
class InputWidget extends StatefulWidget {
  const InputWidget({super.key});

  @override
  State<InputWidget> createState() => _InputWidgetState();
}

class _InputWidgetState extends State<InputWidget> {
  TextEditingController _idcontroller = TextEditingController();
  TextEditingController _passwordcontroller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InputComponent(controller: _idcontroller, hintText: '아이디'),
        const SizedBox(height: 10),
        InputComponent(controller: _passwordcontroller, hintText: '비밀번호'),
      ],
    );
  }
}
