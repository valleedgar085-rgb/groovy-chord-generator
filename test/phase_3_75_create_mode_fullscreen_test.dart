import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:groovy_chord_generator/providers/app_state.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';
import 'package:groovy_chord_generator/widgets/create_mode_panel.dart';

void main() {
  group('Phase 3.75 create mode surface', () {
    testWidgets('progression mode is the primary fast-create path',
        (tester) async {
      final appState = AppState();
      final session = SongSessionController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<SongSessionController>.value(value: session),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CreateModePanel()),
          ),
        ),
      );

      expect(find.text('CREATE PROGRESSION'), findsOneWidget);
      expect(appState.currentProgression, isEmpty);

      await tester.tap(find.byKey(const Key('create-progression-primary')));
      await tester.pump();

      expect(appState.currentProgression, isNotEmpty);
      expect(find.text('NEW PROGRESSION'), findsOneWidget);
    });

    testWidgets('full song mode generates and opens the Song Composer',
        (tester) async {
      final appState = AppState();
      final session = SongSessionController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<SongSessionController>.value(value: session),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CreateModePanel()),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('create-mode-song')));
      await tester.pump();
      expect(find.text('CREATE FULL SONG'), findsOneWidget);

      await tester.tap(find.byKey(const Key('create-full-song-primary')));
      await tester.pumpAndSettle();

      expect(session.hasSong, isTrue);
      expect(session.isComplete, isTrue);
      expect(session.currentDraft!.sections, hasLength(10));
      expect(find.text('SONG COMPOSER'), findsOneWidget);
    });
  });
}
