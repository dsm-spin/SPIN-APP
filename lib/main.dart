import 'package:flutter/material.dart';
import 'package:spin_app/splash/splash.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SUITVariable',
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Splash()
    );
  }
}
