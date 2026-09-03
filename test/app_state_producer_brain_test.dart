import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/providers/app_state.dart';

void main() {
  group('AppState Producer Brain', () {
    test('generation selects from an eight-candidate pool and exposes confidence', () {
      final state = AppState();
      state.setIncludeMelody(false);
      state.setIncludeBass(false);

      state.generateProgression();

      expect(state.producerCandidateCount, 8);
      expect(state.currentProgression.length, greaterThanOrEqualTo(2));
      expect(state.lastHarmonyScore, inInclusiveRange(0.0, 100.0));
    });

    test('section intent is carried by AppState', () {
      final state = AppState();
      state.setHarmonySection(HarmonySection.chorus);

      expect(state.harmonySection, HarmonySection.chorus);
    });

    test('locked chord survives full candidate generation and post processing', () {
      final state = AppState();
      state.setIncludeMelody(false);
      state.setIncludeBass(false);
      state.generateProgression();

      final locked = state.currentProgression.first;
      state.toggleChordLock(0);
      state.generateProgression();

      final regenerated = state.currentProgression.first;
      expect(regenerated.root, locked.root);
      expect(regenerated.type, locked.type);
      expect(regenerated.degree, locked.degree);
    });

    test('same seed exactly replays harmony melody and bass', () {
      final state = AppState();
      state.setIncludeMelody(true);
      state.setIncludeBass(true);
      state.setUseFunctionalHarmony(false);
      state.setChordVariety(72);

      const seed = 20260903;
      state.generateProgression(seed: seed);

      final firstHarmony = state.currentProgression
          .map((chord) => '${chord.root}:${chord.type.name}:${chord.degree}')
          .toList(growable: false);
      final firstMelody = state.currentMelody
          .map((note) =>
              '${note.note}:${note.octave}:${note.duration}:${note.velocity}:${note.chordIndex}')
          .toList(growable: false);
      final firstBass = state.currentBassLine
          .map((note) =>
              '${note.note}:${note.octave}:${note.duration}:${note.velocity}:${note.chordIndex}:${note.style.name}')
          .toList(growable: false);
      final firstScore = state.lastHarmonyScore;

      state.generateProgression(seed: seed);

      expect(state.lastGenerationSeed, seed);
      expect(
        state.currentProgression
            .map((chord) => '${chord.root}:${chord.type.name}:${chord.degree}')
            .toList(growable: false),
        firstHarmony,
      );
      expect(
        state.currentMelody
            .map((note) =>
                '${note.note}:${note.octave}:${note.duration}:${note.velocity}:${note.chordIndex}')
            .toList(growable: false),
        firstMelody,
      );
      expect(
        state.currentBassLine
            .map((note) =>
                '${note.note}:${note.octave}:${note.duration}:${note.velocity}:${note.chordIndex}:${note.style.name}')
            .toList(growable: false),
        firstBass,
      );
      expect(state.lastHarmonyScore, firstScore);
    });
  });
}
