import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spin_app/pages/auth/log_in.dart';
import 'package:spin_app/pages/auth/sign_up/sign_up.dart';

void main() {
  testWidgets('로그인 페이지가 렌더링된다', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LogInWidget()));

    expect(find.text('로그인'), findsWidgets);
    expect(find.text('아이디와 비밀번호를 입력해주세요'), findsOneWidget);
    expect(find.text('아이디'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
    expect(find.text('회원가입'), findsOneWidget);
  });

  testWidgets('로그인 페이지에서 회원가입 페이지로 이동한다', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LogInWidget()));

    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();

    expect(find.byType(SignUpWidget), findsOneWidget);
    expect(find.text('회원가입'), findsWidgets);
  });

  testWidgets('회원가입 페이지에서 로그인 링크를 누르면 돌아간다', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LogInWidget()));

    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpWidget), findsOneWidget);

    await tester.tap(find.text('로그인').last);
    await tester.pumpAndSettle();

    expect(find.byType(SignUpWidget), findsNothing);
    expect(find.byType(LogInWidget), findsOneWidget);
  });

  testWidgets('로그인 화면은 키보드가 올라와도 오버플로우 없이 렌더링된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 500),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: const LogInWidget(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('회원가입 화면은 키보드가 올라와도 오버플로우 없이 렌더링된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 500),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: const SignUpWidget(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
