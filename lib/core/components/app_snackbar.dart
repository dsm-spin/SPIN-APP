import 'package:flutter/material.dart';
import 'package:spin_app/core/theme/colors.dart';

/// 앱 전체에서 통일된 모양으로 띄우는 커스텀 스낵바.
/// 성공/실패/경고/안내 네 가지 상태에 맞는 색과 아이콘을 자동으로 골라준다.
enum AppSnackBarType { success, error, warning, info }

class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarType type = AppSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = _themeFor(type);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(theme.icon, color: theme.foreground, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: theme.foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  /// 저장/완료 등 긍정적인 결과를 알릴 때
  static void success(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackBarType.success);

  /// API 실패, 예외 등 에러를 알릴 때
  static void error(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackBarType.error);

  /// 입력 누락 등 사용자가 고쳐야 할 상황을 알릴 때
  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackBarType.warning);

  /// 그 외 단순 안내
  static void info(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackBarType.info);

  static _SnackTheme _themeFor(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return const _SnackTheme(
          background: AppColors.button,
          foreground: AppColors.background,
          icon: Icons.check_circle_rounded,
        );
      case AppSnackBarType.error:
        return const _SnackTheme(
          background: AppColors.error,
          foreground: AppColors.background,
          icon: Icons.error_rounded,
        );
      case AppSnackBarType.warning:
        return const _SnackTheme(
          background: AppColors.warning,
          foreground: AppColors.background,
          icon: Icons.warning_rounded,
        );
      case AppSnackBarType.info:
        return const _SnackTheme(
          background: AppColors.greenKelp,
          foreground: AppColors.background,
          icon: Icons.info_rounded,
        );
    }
  }
}

class _SnackTheme {
  final Color background;
  final Color foreground;
  final IconData icon;

  const _SnackTheme({
    required this.background,
    required this.foreground,
    required this.icon,
  });
}
