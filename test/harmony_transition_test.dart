import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';
import 'package:groovy_chord_generator/models/types.dart';

Chord c(String root, String degree, ChordTypeName type) => Chord(
      root: root,
      type: type,
      degree: degree,
      numeral: degree,
    );

void main() {
  group('song-level harmonic transitions', () {
    test('chorus rewards dominant handoff from previous pre-chorus', () {
      final engine = HarmonyEngine(seed: 7);
      final pre = <Chord>[
        c('C', 'I', ChordTypeName.major),
        c('F', 'IV', ChordTypeName.major),
        c('G', 'V', ChordTypeName.dominant7),
      ];
      final tonicArrival = <Chord>[
        c('C', 'I', ChordTypeName.major),
        c('F', 'IV', ChordTypeName.major),
        c('G', 'V', ChordTypeName.dominant7),
        c('C', 'I', ChordTypeName.major),
      ];
      final weakEntrance = <Chord>[
        c('F', 'IV', ChordTypeName.major),
        c('G', 'V', ChordTypeName.dominant7),
        c('C', 'I', ChordTypeName.major),
      ];
      final context = HarmonyTransitionContext(
        previousProgression: pre,
        previousSection: HarmonySection.preChorus,
        targetTension: 0.88,
      );

      expect(
        engine.score(
          tonicArrival,
          section: HarmonySection.chorus,
          context: context,
        ),
        greaterThan(engine.score(
          weakEntrance,
          section: HarmonySection.chorus,
          context: context,
        )),
      );
    });

    test('pre-chorus scores higher when it prepares an upcoming chorus', () {
      final engine = HarmonyEngine(seed: 7);
      final forward = <Chord>[
        c('C', 'I', ChordTypeName.major),
        c('F', 'IV', ChordTypeName.major),
        c('G', 'V', ChordTypeName.dominant7),
      ];
      final settled = <Chord>[
        c('F', 'IV', ChordTypeName.major),
        c('G', 'V', ChordTypeName.dominant7),
        c('C', 'I', ChordTypeName.major),
      ];
      const context = HarmonyTransitionContext(
        nextSection: HarmonySection.chorus,
        targetTension: 0.70,
      );

      expect(
        engine.score(
          forward,
          section: HarmonySection.preChorus,
          context: context,
        ),
        greaterThan(engine.score(
          settled,
          section: HarmonySection.preChorus,
          context: context,
        )),
      );
    });

    test('repeating the same chord across a section boundary is penalized', () {
      final engine = HarmonyEngine(seed: 7);
      final previous = <Chord>[
        c('C', 'I', ChordTypeName.major),
        c('F', 'IV', ChordTypeName.major),
      ];
      final repeatedBoundary = <Chord>[
        c('F', 'IV', ChordTypeName.major),
        c('G', 'V', ChordTypeName.major),
        c('C', 'I', ChordTypeName.major),
      ];
      final freshBoundary = <Chord>[
        c('D', 'ii', ChordTypeName.minor),
        c('G', 'V', ChordTypeName.major),
        c('C', 'I', ChordTypeName.major),
      ];
      final context = HarmonyTransitionContext(
        previousProgression: previous,
        previousSection: HarmonySection.verse,
      );

      expect(
        engine.score(repeatedBoundary, context: context),
        lessThan(engine.score(freshBoundary, context: context)),
      );
    });

    test('SongPlan derives neighbor roles and target tension for scoring', () {
      final plan = SongPlan.standard(seed: 1234);
      final context = plan.harmonyContextFor(
        'chorus-1',
        previousProgression: [
          c('G', 'V', ChordTypeName.dominant7),
        ],
      );

      expect(context.previousSection, HarmonySection.preChorus);
      expect(context.nextSection, HarmonySection.verse);
      expect(context.targetTension, 0.88);
      expect(context.targetEnergy, 0.92);
      expect(context.previousProgression.single.degree, 'V');
    });
  });
}
