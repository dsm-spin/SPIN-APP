import 'package:flutter/material.dart';
import 'package:spin_app/core/components/bottom_navigationbar.dart';
import 'package:spin_app/core/config/env.dart';
import 'package:spin_app/pages/history/history.dart';
import 'package:spin_app/pages/splash/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
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
      home: const History(),
    );
  }
}
