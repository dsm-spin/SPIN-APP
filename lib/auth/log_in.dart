import 'package:flutter/material.dart';
import 'package:spin_app/auth/InputWidget.dart';
import 'package:spin_app/components/bottom_button.dart';
import 'package:spin_app/log_in_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/svg.dart';
class LogInWidget extends StatefulWidget {
  const LogInWidget({super.key});

  @override
  State<LogInWidget> createState() => _LogInWidgetState();
}

class _LogInWidgetState extends State<LogInWidget> {
  TextEditingController _idcontroller = TextEditingController();
  TextEditingController _passwordcontroller = TextEditingController();

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
              idController: _idcontroller,
              passwordController: _passwordcontroller,
            ),
            const SizedBox(height: 370),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '회원가입을 아직 안하셨나요?',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 20),
                TextButton(
                  onPressed: () {
                    context.go('/signup');
                  },
                  child: Text(
                    '회원가입',
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
              text: '로그인',
              onTap: () async{
                print('로그인 시도... ID: ${_idcontroller.text}');
                
                final result = await loginapi(_idcontroller.text, _passwordcontroller.text);

                if(result != null) {
                  print('로그인 최종 성공!');
                } else {
                  print('로그인 최종 실패');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
