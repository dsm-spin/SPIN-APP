import 'package:flutter/material.dart';
import 'package:spin_app/api/api_client.dart';
import 'package:spin_app/core/config/env.dart';
import 'package:spin_app/core/services/deep_link_service.dart';
import 'package:spin_app/core/storage/point_store.dart';
import 'package:spin_app/pages/splash/auth_gate.dart';
import 'package:spin_app/pages/splash/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  await initApiClient();
  await initPointStore();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    DeepLinkService.init(_navigatorKey);
  }

  @override
  void dispose() {
    DeepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'spin',
      theme: ThemeData(primarySwatch: Colors.orange,scaffoldBackgroundColor: Colors.white),
      debugShowCheckedModeBanner: false,
      home: const Splash(),
    );
  }
}
