import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/widgets/gradient_button.dart';
import 'package:frontend/features/zone/zone_editor_screen.dart';
import 'package:frontend/providers/match_rules_provider.dart';
import 'package:frontend/providers/room_provider.dart';
import 'package:frontend/ui/lobby/lobby_screen.dart';

void main() {
  testWidgets('Lobby: non-host cannot see zone edit entry', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(roomProvider.notifier).joinRoom(myName: '나', code: 'ABCD');
    expect(container.read(roomProvider).amIHost, isFalse);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LobbyScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lobbyZoneEditButton')), findsNothing);
    expect(find.text('구역 설정'), findsNothing);
  });

  testWidgets('ZoneEditor: save enabled only when >=3 points (fallback)', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(roomProvider.notifier).createRoom(myName: '호스트');
    expect(container.read(roomProvider).amIHost, isTrue);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ZoneEditorScreen()));
              });
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('zoneAddPoint')), findsOneWidget);
    expect(find.byKey(const Key('zoneSave')), findsOneWidget);

    GradientButton saveBtn() => tester.widget<GradientButton>(find.byKey(const Key('zoneSave')));

    expect(find.textContaining('폴리곤 점: 0'), findsOneWidget);
    expect(saveBtn().onPressed, isNull);

    await tester.tap(find.byKey(const Key('zoneAddPoint')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('zoneAddPoint')));
    await tester.pump();
    expect(find.textContaining('폴리곤 점: 2'), findsOneWidget);
    expect(saveBtn().onPressed, isNull);

    await tester.tap(find.byKey(const Key('zoneAddPoint')));
    await tester.pump();
    expect(find.textContaining('폴리곤 점: 3'), findsOneWidget);
    expect(saveBtn().onPressed, isNotNull);

    await tester.ensureVisible(find.byKey(const Key('zoneSave')));
    await tester.tap(find.byKey(const Key('zoneSave')));
    await tester.pumpAndSettle();

    final poly = container.read(matchRulesProvider).zonePolygon;
    expect(poly, isNotNull);
    expect(poly!.length, greaterThanOrEqualTo(3));
  });
}
