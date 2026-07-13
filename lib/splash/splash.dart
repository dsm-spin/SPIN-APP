import 'package:flutter/material.dart';
import 'package:spin_app/components/bottom_button.dart';
import 'package:spin_app/theme/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 320),
          SvgPicture.asset(
            'lib/assets/images/logo.svg',
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 230),
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
                    onPressed: onSignIn,
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
                  onTap: onLogin,
              )
            ],
          ),
        ],
      ),
    );
  }

  void onSignIn() {}

  void onLogin() {}
}
