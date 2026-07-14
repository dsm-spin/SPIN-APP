import 'package:flutter/material.dart';
import 'package:spin_app/api/auth_api.dart';
import 'package:spin_app/core/components/app_snackbar.dart';
import 'package:spin_app/core/components/bottom_button.dart';
import 'package:spin_app/pages/auth/InputWidget.dart';
import 'package:spin_app/pages/auth/log_in.dart';

class SignUpWidget extends StatefulWidget {
  const SignUpWidget({super.key});

  @override
  State<SignUpWidget> createState() => SignUpWidgetState();
}

class SignUpWidgetState extends State<SignUpWidget> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    final success = await signUpApi(
      _idController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;

    if (!success) {
      AppSnackBar.error(context, '회원가입에 실패했어요. 이미 사용 중인 아이디인지 확인해주세요.');
      return;
    }

    // 가입 성공: 바로 로그인해서 세션을 받고 홈으로 이동
    final loggedIn = await logInApi(
      _idController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;

    if (loggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LogInWidget()),
      );
    } else {
      AppSnackBar.success(context, '회원가입 완료! 로그인해주세요.');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'spin',
                        style: TextStyle(
                          color: Color(0xFF3D532B),
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
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
                          InputWidget(
                            idController: _idController,
                            passwordController: _passwordController,
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '회원이신가요?',
                                style: TextStyle(
                                  color: Colors.black.withAlpha(128),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // 로그인 페이지로 돌아가기
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => LogInWidget(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  '로그인',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          BottomButton(text: '회원가입', onTap: signUp),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
