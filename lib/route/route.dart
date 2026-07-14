import 'package:flutter/material.dart';
import 'package:spin_app/core/theme/colors.dart';

class RoutePage extends StatelessWidget {
  const RoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('루트'),
      ),
    );
  }
}
