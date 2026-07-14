import 'package:flutter/material.dart';
import 'package:spin_app/auth/log_in.dart';
import 'package:spin_app/router/router.dart';
import 'package:spin_app/splash/splash.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'spin',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}