import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/app_state.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';
import 'package:groovy_chord_generator/widgets/producer_brain_panel.dart';

SongRequest _request() => const SongRequest(
      seed: 94001,
      key: KeyName.C,
      genre: GenreKey.soulfulRnb,
      mood: MoodType.dreamy,
      complexity: ComplexityLevel.complex,
      spice: SpiceLevel.medium,
      rhythm: RhythmLevel.moderate,
      candidateCount: 8,
      chordVariety: 64,
      useVoiceLeading: true,
      useAdvancedTheory: true,
      useModalInterchange: true,
      useFunctionalHarmony: true,
      includeMelody: true,
      includeBass: true,
    );

void main() {
  testWidgets('Composer surfaces Song Memory identity for repeated sections',
      (tester) async {
    final appState = AppState();
    final session = SongSessionController();
    session.generate(request: _request());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          ChangeNotifierProvider<SongSessionController>.value(value: session),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProducerBrainPanel(appState: appState),
          ),
        ),
      ),
    );

    await tester.tap(find.text('SONG'));
    await tester.pumpAndSettle();

    expect(find.text('SONG COMPOSER'), findsOneWidget);
    expect(find.text('ARRANGEMENT • SONG MEMORY'), findsOneWidget);
    expect(find.text('A′'), findsWidgets);

    // Final Chorus is outside the initial horizontal arrangement viewport, so
    // select it through the session and verify the selected-section memory UI.
    expect(session.selectSection('final-chorus'), isTrue);
    await tester.pumpAndSettle();
    expect(session.selectedSectionId, 'final-chorus');
    expect(find.text('A″'), findsWidgets);

    expect(session.selectSection('verse-2'), isTrue);
    await tester.pumpAndSettle();

    expect(session.selectedSectionId, 'verse-2');
    expect(find.text('A′'), findsWidgets);
    expect(find.text('SOURCE'), findsOneWidget);
    expect(find.text('VERSE 1'), findsWidgets);
    expect(find.text('IDENTITY'), findsWidgets);
    expect(find.text('CADENCE'), findsOneWidget);
    expect(find.text('REGENERATE SECTION'), findsOneWidget);
  });
}
