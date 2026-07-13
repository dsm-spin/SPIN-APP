import 'package:flutter/material.dart';
import 'package:spin_app/auth/InputWidget.dart';
import 'package:spin_app/components/bottom_button.dart';
class LogInWidget extends StatefulWidget {
  const LogInWidget({super.key});

  @override
  State<LogInWidget> createState() => _LogInWidgetState();
}

class _LogInWidgetState extends State<LogInWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24.0),
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
            const SizedBox(height: 100),
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
              style: TextStyle(
                color: Colors.black.withAlpha(128),
              ),
            ),
            const SizedBox(height: 30),
            InputWidget(),
            const SizedBox(height: 370),
            BottomButton(text: '로그인', onTap: () {}),
          ],
        ),
      ),
    );
  }
}
