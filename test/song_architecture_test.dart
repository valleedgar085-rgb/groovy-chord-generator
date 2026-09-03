import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';

void main() {
  group('SongPlan', () {
    test('standard plan creates a deliberate build and release arc', () {
      final plan = SongPlan.standard(seed: 42);

      final verse = plan.sectionById('verse-1')!;
      final pre = plan.sectionById('pre-1')!;
      final chorus = plan.sectionById('chorus-1')!;
      final finalChorus = plan.sectionById('final-chorus')!;
      final outro = plan.sectionById('outro')!;

      expect(pre.targetTension, greaterThan(verse.targetTension));
      expect(chorus.targetEnergy, greaterThan(pre.targetEnergy));
      expect(finalChorus.targetEnergy, greaterThan(chorus.targetEnergy));
      expect(outro.targetTension, lessThan(finalChorus.targetTension));
    });

    test('arrangement section maps to harmonic scoring intent', () {
      final plan = SongPlan.standard(seed: 42);

      expect(plan.sectionById('verse-1')!.harmonySection, HarmonySection.verse);
      expect(
        plan.sectionById('pre-1')!.harmonySection,
        HarmonySection.preChorus,
      );
      expect(
        plan.sectionById('chorus-1')!.harmonySection,
        HarmonySection.chorus,
      );
      expect(plan.sectionById('bridge')!.harmonySection, HarmonySection.bridge);
    });

    test('repeated sections preserve identity while increasing variation', () {
      final plan = SongPlan.standard(seed: 42);
      final verse1 = plan.sectionById('verse-1')!;
      final verse2 = plan.sectionById('verse-2')!;

      expect(verse2.repetitionGroup, verse1.repetitionGroup);
      expect(verse2.variation, greaterThan(verse1.variation));
    });

    test('section seeds are replayable and distinct', () {
      final first = SongPlan.standard(seed: 2026);
      final replay = SongPlan.standard(seed: 2026);

      expect(first.sectionSeed('verse-1'), replay.sectionSeed('verse-1'));
      expect(
        first.sectionSeed('verse-1'),
        isNot(first.sectionSeed('chorus-1')),
      );
    });
  });
}
