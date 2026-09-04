import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/app_state.dart';
import 'package:groovy_chord_generator/providers/song_request_adapter.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';
import 'package:groovy_chord_generator/widgets/producer_brain_panel.dart';

void main() {
  group('Phase 2.5 Composer entry', () {
    test('AppState settings map into one immutable full-song request', () {
      final state = AppState();
      state.setCurrentKey(KeyName.Dm);
      state.setGenre(GenreKey.funk);
      state.setComplexity(ComplexityLevel.advanced);
      state.setRhythm(RhythmLevel.strong);
      state.setMood(MoodType.dark);
      state.setSpiceLevel(SpiceLevel.hot);
      state.setUseVoiceLeading(true);
      state.setUseAdvancedTheory(true);
      state.setUseModalInterchange(true);
      state.setUseFunctionalHarmony(true);
      state.setIncludeMelody(true);
      state.setIncludeBass(true);
      state.setChordVariety(73);

      final request = SongRequestAdapter.fromAppState(state, seed: 240904);

      expect(request.seed, 240904);
      expect(request.key, KeyName.Dm);
      expect(request.genre, GenreKey.funk);
      expect(request.complexity, ComplexityLevel.advanced);
      expect(request.rhythm, RhythmLevel.strong);
      expect(request.mood, MoodType.dark);
      expect(request.spice, SpiceLevel.hot);
      expect(request.useVoiceLeading, isTrue);
      expect(request.useAdvancedTheory, isTrue);
      expect(request.useModalInterchange, isTrue);
      expect(request.useFunctionalHarmony, isTrue);
      expect(request.includeMelody, isTrue);
      expect(request.includeBass, isTrue);
      expect(request.chordVariety, 73);
      expect(request.candidateCount, state.producerCandidateCount);
    });

    test('current AppState setup can produce a complete SongSession', () {
      final state = AppState();
      state.setGenre(GenreKey.soulfulRnb);
      state.setCurrentKey(KeyName.C);
      state.setIncludeMelody(true);
      state.setIncludeBass(true);

      final request = SongRequestAdapter.fromAppState(state, seed: 2511);
      final session = SongSessionController();
      session.generate(
        request: request,
        bassStyle: state.bassStyle,
        bassVariety: state.bassVariety,
        grooveTemplate: state.grooveTemplate,
      );

      expect(session.hasSong, isTrue);
      expect(session.isComplete, isTrue);
      expect(session.currentDraft!.sections, hasLength(10));
      expect(session.selectedSectionId, 'intro');
      expect(session.currentDraft!.sections.every((s) => s.progression.isNotEmpty), isTrue);
      expect(session.currentDraft!.sections.every((s) => s.melody.isNotEmpty), isTrue);
      expect(session.currentDraft!.sections.every((s) => s.bass.isNotEmpty), isTrue);
    });

    testWidgets('SONG control opens the full-song Composer surface', (tester) async {
      final appState = AppState();
      final songSession = SongSessionController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<SongSessionController>.value(value: songSession),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ProducerBrainPanel(appState: appState),
            ),
          ),
        ),
      );

      expect(find.text('SONG'), findsOneWidget);
      await tester.tap(find.text('SONG'));
      await tester.pumpAndSettle();

      expect(find.text('SONG COMPOSER'), findsOneWidget);
      expect(find.text('CREATE FULL SONG'), findsOneWidget);
      expect(find.text('FROM LOOP TO SONG'), findsOneWidget);
    });
  });
}
