import 'package:flutter/material.dart';
import 'package:spin_app/api/auth_api.dart';
import 'package:spin_app/core/components/bottom_navigationbar.dart';
import 'package:spin_app/core/theme/colors.dart';
import 'package:spin_app/pages/splash/splash.dart';

/// 앱 시작 시 저장된 세션이 아직 유효한지 확인해서, 유효하면 로그인 화면 없이
/// 바로 홈으로 보낸다(자동 로그인). 세션이 없거나 만료됐으면 기존 스플래시로 보낸다.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<bool> _sessionValid = hasValidSession();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessionValid,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == true
            ? const BottomNavigationbar()
            : const Splash();
      },
    );
  }
}
