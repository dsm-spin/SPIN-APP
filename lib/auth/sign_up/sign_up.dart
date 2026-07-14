import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:spin_app/auth/InputWidget.dart';
import 'package:spin_app/components/bottom_button.dart';

class SignUpWidget extends StatefulWidget {
  const SignUpWidget({super.key});

  @override
  State<SignUpWidget> createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUpWidget> {
  final TextEditingController _idcontroller = TextEditingController();
  final TextEditingController _passwordcontroller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(
              'lib/assets/images/logo.svg',
              width: 20,
              height: 20,
            ),
            const SizedBox(height: 100),
            Text(
              '회원가입',
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
            InputWidget(idController: _idcontroller, passwordController: _passwordcontroller),
            const SizedBox(height: 370),
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
                  onPressed: () {
                    context.go('/login');
                  },
                  child: Text(
                    '로그인',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            BottomButton(
                onTap: () {},
                text: '회원가입',
            ),
          ],
        ),
      ),
    );
  }
}
