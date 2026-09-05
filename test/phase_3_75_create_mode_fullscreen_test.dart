import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:groovy_chord_generator/providers/app_state.dart';
import 'package:groovy_chord_generator/providers/create_mode_controller.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';
import 'package:groovy_chord_generator/widgets/create_mode_panel.dart';

void main() {
  group('Phase 3.75 create mode surface', () {
    testWidgets('progression mode is the primary fast-create path',
        (tester) async {
      final appState = AppState();
      final session = SongSessionController();
      final createMode = CreateModeController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<SongSessionController>.value(value: session),
            ChangeNotifierProvider<CreateModeController>.value(value: createMode),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CreateModePanel()),
          ),
        ),
      );

      expect(createMode.isProgression, isTrue);
      expect(find.text('CREATE PROGRESSION'), findsOneWidget);
      expect(appState.currentProgression, isEmpty);

      await tester.tap(find.byKey(const Key('create-progression-primary')));
      await tester.pump();

      expect(appState.currentProgression, isNotEmpty);
      expect(find.text('NEW PROGRESSION'), findsOneWidget);
    });

    testWidgets('full song mode is shared and opens the Song Composer',
        (tester) async {
      final appState = AppState();
      final session = SongSessionController();
      final createMode = CreateModeController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<SongSessionController>.value(value: session),
            ChangeNotifierProvider<CreateModeController>.value(value: createMode),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CreateModePanel()),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('create-mode-song')));
      await tester.pump();
      expect(createMode.isFullSong, isTrue);
      expect(find.text('CREATE FULL SONG'), findsOneWidget);

      await tester.tap(find.byKey(const Key('create-full-song-primary')));
      await tester.pumpAndSettle();

      expect(session.hasSong, isTrue);
      expect(session.isComplete, isTrue);
      expect(session.currentDraft!.sections, hasLength(10));
      expect(find.text('SONG COMPOSER'), findsOneWidget);

      // The Composer is a modal route. Pop that route directly so the next
      // interaction targets the underlying Create surface rather than the
      // modal barrier.
      Navigator.of(tester.element(find.text('SONG COMPOSER'))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('create-mode-progression')));
      await tester.pump();
      expect(createMode.isProgression, isTrue);
      // Switching views must not destroy the generated arrangement.
      expect(session.hasSong, isTrue);
    });
  });
}
