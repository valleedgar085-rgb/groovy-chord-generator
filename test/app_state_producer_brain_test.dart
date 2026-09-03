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
      state.generateProgression();

      if (state.harmonyAlternatives.length > 1) {
        final secondTake = state.harmonyAlternatives[1];
        state.selectHarmonyAlternative(1);

        expect(state.selectedHarmonyAlternative, 1);
        expect(state.currentProgression.length, secondTake.length);
      }
    });
  });
}
