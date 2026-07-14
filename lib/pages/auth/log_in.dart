import 'package:flutter/material.dart';
import 'package:spin_app/pages/auth/InputWidget.dart';
import 'package:spin_app/core/components/bottom_button.dart';
import 'package:spin_app/log_in_test.dart';

class LogInWidget extends StatefulWidget {
  const LogInWidget({super.key});

  @override
  State<LogInWidget> createState() => _LogInWidgetState();
}

class _LogInWidgetState extends State<LogInWidget> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'spin',
                style: TextStyle(
                  color: Color(0xFF3D532B),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const Spacer(),
              Text(
                '로그인',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 35,
                ),
              ),
              Text(
                '아이디와 비밀번호를 입력해주세요',
                style: TextStyle(color: Colors.black.withAlpha(128)),
              ),
              const SizedBox(height: 30),
              InputWidget(
                idController: _idController,
                passwordController: _passwordController,
              ),
              const Spacer(),
              BottomButton(
                text: '로그인',
                onTap: () async {
                  print('로그인 시도... ID: ${_idController.text}');
          
                  final result = await loginapi(
                    _idController.text,
                    _passwordController.text,
                  );
          
                  if (result != null) {
                    print('로그인 최종 성공!');
                  } else {
                    print('로그인 최종 실패');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
