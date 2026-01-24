// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/app.dart';

void main() {
  testWidgets('App boots to OFF_GAME home', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GyeongdoPlusApp()));
    await tester.pumpAndSettle();

    expect(find.text('환영합니다'), findsOneWidget);
  });

  testWidgets('Create room -> Lobby shows room code', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GyeongdoPlusApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('방 만들기'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('createRoomNameField')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('createRoomNameField')), '테스터');
    await tester.tap(find.text('만들기'));
    await tester.pumpAndSettle();

    expect(find.text('로비'), findsOneWidget);
    expect(find.byKey(const Key('roomCodeText')), findsOneWidget);

    final codeText = tester.widget<Text>(find.byKey(const Key('roomCodeText'))).data ?? '';
    expect(codeText, isNotEmpty);
    expect(RegExp(r'^[A-Z0-9]{4,6}$').hasMatch(codeText), isTrue);
  });

  testWidgets('PostGame 전적 보기 -> OFF_GAME 전적 탭 포커스', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GyeongdoPlusApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('방 만들기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('만들기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('준비 완료'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('경기 시작'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('매치'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('경기 종료(테스트)'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('경기 종료(테스트)'));
    await tester.pumpAndSettle();

    expect(find.text('경기 종료'), findsOneWidget);
    await tester.tap(find.text('전적 보기'));
    await tester.pumpAndSettle();

    expect(find.text('최근 경기 기록'), findsOneWidget);
  });
}
