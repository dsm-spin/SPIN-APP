import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spin_app/pages/home/home.dart';

void main() {
  testWidgets('삭제를 누르면 고른 지역과 적은 목적을 비운다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Home()));

    // 힌트 문구('혼자 커피 한 잔')와 겹치지 않는 값이어야 한다.
    await tester.enterText(find.byType(TextField), '골목 카페 투어');
    await tester.tap(find.text('유성구'));
    await tester.pump();

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(find.text('골목 카페 투어'), findsNothing);
    expect(find.text('적어둔 내용을 지웠어요'), findsOneWidget);
  });
}
