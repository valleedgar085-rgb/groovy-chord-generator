import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/providers/app_state.dart';

void main() {
  group('AppState Producer Brain', () {
    test('generation keeps up to three ranked Smart Takes', () {
      final state = AppState();

      state.generateProgression();

      expect(state.currentProgression, isNotEmpty);
      expect(state.harmonyAlternatives, isNotEmpty);
      expect(state.harmonyAlternatives.length, lessThanOrEqualTo(3));
      expect(state.selectedHarmonyAlternative, 0);
      expect(state.lastHarmonyScore, inInclusiveRange(0.0, 100.0));
    });

    test('section intent is stored and used by future generations', () {
      final state = AppState();
      state.setHarmonySection(HarmonySection.chorus);

      expect(state.harmonySection, HarmonySection.chorus);

      state.generateProgression();
      expect(state.currentProgression, isNotEmpty);
      expect(state.lastHarmonyScore, inInclusiveRange(0.0, 100.0));
    });

    test('Smart Takes can be selected without another generation pass', () {
      final state = AppState();

      for (var attempt = 0;
          attempt < 5 && state.harmonyAlternatives.length < 2;
          attempt++) {
        state.generateProgression();
      }

      expect(
        state.harmonyAlternatives.length,
        greaterThanOrEqualTo(2),
        reason: 'Producer Brain should retain multiple valid Smart Takes.',
      );

      final secondTake = state.harmonyAlternatives[1];
      final expectedIdentity = secondTake
          .map((chord) => '${chord.root}:${chord.degree}:${chord.type.name}')
          .toList();

      state.selectHarmonyAlternative(1);

      final selectedIdentity = state.currentProgression
          .map((chord) => '${chord.root}:${chord.degree}:${chord.type.name}')
          .toList();
      expect(state.selectedHarmonyAlternative, 1);
      expect(selectedIdentity, orderedEquals(expectedIdentity));
      expect(state.lastHarmonyScore, inInclusiveRange(0.0, 100.0));
    });

    test('Smart Takes exposed by AppState are deeply read-only', () {
      final state = AppState();
      state.generateProgression();

      final takes = state.harmonyAlternatives;
      expect(
        () => takes.first.add(takes.first.first),
        throwsUnsupportedError,
      );
    });
  });
}
