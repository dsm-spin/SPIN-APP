import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spin_app/auth/log_in.dart';
import 'package:spin_app/auth/sign_up/sign_up.dart';
import 'package:spin_app/splash/splash.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const Splash();
      },
    ),

    GoRoute(
      path: '/signup',
      builder: (BuildContext context, GoRouterState state) {
        return const SignUpWidget();
      },
    ),

    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const LogInWidget();
      },
    ),
  ],
);