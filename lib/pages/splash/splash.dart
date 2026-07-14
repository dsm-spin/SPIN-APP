import 'package:flutter/material.dart';
import 'package:spin_app/core/components/bottom_button.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spin_app/pages/auth/log_in.dart';
import 'package:spin_app/pages/auth/sign_up/sign_up.dart';

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              SvgPicture.asset(
                'assets/images/logo.svg',
                width: 120,
                height: 120,
              ),
              const Spacer(),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '계정이 없다면?',
                        style: TextStyle(
                          color: Color(0xFF6A6A6A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => SignUpWidget()),
                            (route) => false,
                          );
                        },
                        child: Text(
                          '회원가입',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  BottomButton(
                    text: '로그인',
                    onTap: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => LogInWidget()),
                      (route) => false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
