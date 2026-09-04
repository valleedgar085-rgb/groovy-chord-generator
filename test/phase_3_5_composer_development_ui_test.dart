import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:groovy_chord_generator/engine/section_development_metadata.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/app_state.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';
import 'package:groovy_chord_generator/widgets/producer_brain_panel.dart';

SongRequest _request(int seed) => SongRequest(
      seed: seed,
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
  group('Phase 3.5 Composer development metadata', () {
    test('generated and replayed sections retain truthful A/A-prime lineage', () {
      final session = SongSessionController();
      session.generate(request: _request(93501));
      final draft = session.currentDraft!;

      final verse1 = draft.sectionById('verse-1')!;
      final verse2 = draft.sectionById('verse-2')!;
      final chorus1 = draft.sectionById('chorus-1')!;
      final chorus2 = draft.sectionById('chorus-2')!;
      final finalChorus = draft.sectionById('final-chorus')!;

      expect(verse1.development.identity, SectionDevelopmentIdentity.original);
      expect(verse1.development.sourceSectionId, 'verse-1');
      expect(verse1.development.operations, isEmpty);

      expect(verse2.development.identity, SectionDevelopmentIdentity.aPrime);
      expect(verse2.development.sourceSectionId, 'verse-1');
      expect(verse2.development.operations, isNotEmpty);

      expect(chorus1.development.identity, SectionDevelopmentIdentity.original);
      expect(chorus2.development.identity, SectionDevelopmentIdentity.aPrime);
      expect(chorus2.development.sourceSectionId, 'chorus-1');
      expect(finalChorus.development.identity, SectionDevelopmentIdentity.aDoublePrime);
      expect(finalChorus.development.sourceSectionId, 'chorus-1');
      expect(finalChorus.development.operations, isNotEmpty);

      expect(session.regenerateSection('verse-2'), isTrue);
      final regenerated = session.currentDraft!.sectionById('verse-2')!;
      final expectedOperations = List.of(regenerated.development.operations);
      expect(regenerated.development.identity, SectionDevelopmentIdentity.aPrime);
      expect(regenerated.development.sourceSectionId, 'verse-1');
      expect(expectedOperations, isNotEmpty);

      session.replay();
      final replayed = session.currentDraft!.sectionById('verse-2')!;
      expect(replayed.development.identity, SectionDevelopmentIdentity.aPrime);
      expect(replayed.development.sourceSectionId, 'verse-1');
      expect(replayed.development.operations, expectedOperations);
    });

    testWidgets('Composer exposes selected section identity and real lineage',
        (tester) async {
      final appState = AppState();
      final session = SongSessionController();
      session.generate(request: _request(93502));
      expect(session.selectSection('verse-2'), isTrue);

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
      expect(find.text('FROM VERSE 1'), findsOneWidget);
      expect(find.text('DEVELOPMENT MOVES'), findsOneWidget);
      expect(find.text('A′'), findsWidgets);
      expect(find.textContaining('IDENTITY '), findsOneWidget);

      // The Final Chorus card may be outside the horizontal viewport. Select it
      // through the live session so the selected-card lineage is rendered and
      // verify the true A″ source instead of depending on lazy ListView layout.
      expect(session.selectSection('final-chorus'), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('A″'), findsOneWidget);
      expect(find.text('FROM CHORUS 1'), findsOneWidget);
    });
  });
}
