import 'package:flutter/material.dart';
import 'package:spin_app/api/auth_api.dart';
import 'package:spin_app/core/components/app_snackbar.dart';
import 'package:spin_app/core/components/bottom_button.dart';
import 'package:spin_app/core/components/bottom_navigationbar.dart';
import 'package:spin_app/pages/auth/InputWidget.dart';
import 'package:spin_app/pages/auth/sign_up/sign_up.dart';

class LogInWidget extends StatefulWidget {
  /// 로그인 성공 시 홈으로 이동하는 대신 실행할 콜백.
  /// 공유 링크 미리보기처럼, 로그인 후 원래 보던 화면으로 돌아가야 할 때 쓴다.
  final VoidCallback? onLoggedIn;

  const LogInWidget({super.key, this.onLoggedIn});

  @override
  State<LogInWidget> createState() => _LogInWidgetState();
}

class _LogInWidgetState extends State<LogInWidget> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _logIn() async {
    final success = await logInApi(
      _idController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;

    if (success) {
      // 로그인 성공: 세션 쿠키가 저장됐으니 홈으로 이동
      // (콜백이 있으면 그 화면이 대신 처리 — 예: 공유 링크 미리보기로 복귀)
      if (widget.onLoggedIn != null) {
        widget.onLoggedIn!();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BottomNavigationbar()),
        );
      }
    } else {
      AppSnackBar.error(context, '로그인에 실패했어요. 아이디와 비밀번호를 확인해주세요.');
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
                          InputWidget(
                            idController: _idController,
                            passwordController: _passwordController,
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 좁은 기기나 큰 글꼴에서는 두 줄로 넘겨 잘리지 않게 한다.
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '아직 회원이 아니신가요?',
                                style: TextStyle(
                                  color: Colors.black.withAlpha(128),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignUpWidget(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  '회원가입',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          BottomButton(text: '로그인', onTap: _logIn),
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
