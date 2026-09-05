import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/producer_brain_telemetry.dart';
import 'package:groovy_chord_generator/engine/song_candidate.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/app_state.dart';
import 'package:groovy_chord_generator/widgets/producer_variation_sheet.dart';

void main() {
  group('Phase 5.3 actionable Producer variants', () {
    test('selection changes the active option without rewriting the brain winner', () {
      final winner = _candidate(
        ProducerVariationStyle.polished,
        0,
        86,
        const ['Tightened final resolution'],
      );
      final creative = _candidate(
        ProducerVariationStyle.creative,
        1,
        84,
        const ['Added one controlled harmonic color event'],
      );
      final hook = _candidate(
        ProducerVariationStyle.hook,
        2,
        82,
        const ['Recalled the opening motif'],
      );
      final snapshot = ProducerDecisionSnapshot(
        winner: winner,
        variations: [winner, creative, hook],
      );

      expect(snapshot.activeCandidate.variationStyle,
          ProducerVariationStyle.polished);

      final selected = snapshot.select(creative);
      expect(selected.winner, same(winner));
      expect(selected.activeCandidate.variationStyle,
          ProducerVariationStyle.creative);
      expect(selected.isSelected(creative), isTrue);
      expect(selected.isSelected(hook), isFalse);
    });

    test('applying the same option reuses the original seed for melody and bass', () {
      const seed = 20260905;
      final candidate = _candidate(
        ProducerVariationStyle.creative,
        3,
        83.5,
        const ['Added one controlled harmonic color event'],
      );

      final first = AppState();
      first.setIncludeMelody(true);
      first.setIncludeBass(true);
      first.generateProgression(seed: seed);
      expect(first.progressionHistory, isEmpty);
      expect(first.applyProducerCandidate(candidate), isTrue);

      final firstHarmony = _harmonySignature(first.currentProgression);
      final firstMelody = _melodySignature(first.currentMelody);
      final firstBass = _bassSignature(first.currentBassLine);

      expect(first.lastGenerationSeed, seed);
      expect(first.progressionHistory.length, 1);
      expect(first.lastHarmonyScore, candidate.score);

      final second = AppState();
      second.setIncludeMelody(true);
      second.setIncludeBass(true);
      second.generateProgression(seed: seed);
      expect(second.applyProducerCandidate(candidate), isTrue);

      expect(_harmonySignature(second.currentProgression), firstHarmony);
      expect(_melodySignature(second.currentMelody), firstMelody);
      expect(_bassSignature(second.currentBassLine), firstBass);
      expect(second.lastGenerationSeed, seed);
    });

    testWidgets('A/B/C sheet renders choices without initializing preview audio',
        (tester) async {
      final appState = AppState();
      final winner = _candidate(
        ProducerVariationStyle.polished,
        0,
        86,
        const ['Tightened final resolution'],
      );
      final creative = _candidate(
        ProducerVariationStyle.creative,
        1,
        84,
        const ['Added one controlled harmonic color event'],
      );
      final decision = ProducerDecisionSnapshot(
        winner: winner,
        variations: [winner, creative],
      );

      await tester.binding.setSurfaceSize(const Size(500, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SizedBox(
              height: 900,
              child: ProducerVariationSheet(
                appState: appState,
                decision: decision,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Producer A / B / C'), findsOneWidget);
      expect(find.byKey(const ValueKey('producerVariation-polished')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('producerVariation-creative')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('preview-creative')), findsOneWidget);
      expect(find.byKey(const ValueKey('use-creative')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

SongCandidate _candidate(
  ProducerVariationStyle style,
  int index,
  double score,
  List<String> repairs,
) {
  return SongCandidate(
    progression: <Chord>[
      _chord('C', ChordTypeName.major, 'I'),
      _chord('A', ChordTypeName.minor, 'vi'),
      _chord('F', ChordTypeName.major, 'IV'),
      _chord('G', ChordTypeName.dominant7, 'V'),
    ],
    score: score,
    seed: 7000 + index,
    candidateIndex: index,
    section: HarmonySection.chorus,
    variationStyle: style,
    beforeRefineScore: score - 2,
    repairs: repairs,
  );
}

Chord _chord(String root, ChordTypeName type, String degree) => Chord(
      root: root,
      type: type,
      degree: degree,
      numeral: degree,
    );

List<String> _harmonySignature(List<Chord> chords) => chords
    .map((chord) =>
        '${chord.root}:${chord.type.name}:${chord.degree}:${chord.numeral}')
    .toList(growable: false);

List<String> _melodySignature(List<MelodyNote> notes) => notes
    .map((note) =>
        '${note.note}:${note.octave}:${note.duration}:${note.velocity}:${note.chordIndex}')
    .toList(growable: false);

List<String> _bassSignature(List<BassNote> notes) => notes
    .map((note) =>
        '${note.note}:${note.octave}:${note.duration}:${note.velocity}:${note.chordIndex}:${note.style.name}')
    .toList(growable: false);
