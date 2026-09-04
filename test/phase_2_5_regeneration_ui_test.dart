import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/app_state.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';
import 'package:groovy_chord_generator/widgets/producer_brain_panel.dart';

SongRequest uiRequest() => const SongRequest(
      seed: 52001,
      key: KeyName.C,
      genre: GenreKey.happyPop,
      mood: MoodType.happy,
      complexity: ComplexityLevel.medium,
      spice: SpiceLevel.medium,
      rhythm: RhythmLevel.moderate,
      candidateCount: 8,
      chordVariety: 55,
      useVoiceLeading: true,
      useAdvancedTheory: true,
      useModalInterchange: false,
      useFunctionalHarmony: true,
      includeMelody: true,
      includeBass: true,
    );

void main() {
  testWidgets('RE action regenerates the selected SongSession section',
      (tester) async {
    final appState = AppState();
    final session = SongSessionController()..generate(request: uiRequest());
    final originalSeed = session.selectedSection!.candidate.seed;

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

    expect(find.byIcon(Icons.autorenew_rounded), findsOneWidget);
    expect(find.text('RE'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.autorenew_rounded));
    await tester.pump();

    expect(session.revisionFor('intro'), 1);
    expect(session.selectedSectionId, 'intro');
    expect(session.selectedSection!.candidate.seed, isNot(originalSeed));
    expect(find.text('R1'), findsOneWidget);
  });
}
