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
  });
}
