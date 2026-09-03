import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/harmony_candidate_pool.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/models/types.dart';

Chord chord(String root, String degree, ChordTypeName type) => Chord(
      root: root,
      type: type,
      degree: degree,
      numeral: degree,
    );

void main() {
  group('HarmonyCandidatePool', () {
    test('builds the requested number of candidates', () {
      var calls = 0;
      final pool = HarmonyCandidatePool(engine: HarmonyEngine(seed: 7));

      pool.generateBest(
        candidateCount: 6,
        applyVoicing: false,
        buildCandidate: () {
          calls++;
          return <Chord>[
            chord('F', 'IV', ChordTypeName.major),
            chord('G', 'V', ChordTypeName.dominant7),
            chord('C', 'I', ChordTypeName.major),
          ];
        },
      );

      expect(calls, 6);
    });

    test('selects the strongest progression from generated alternatives', () {
      var calls = 0;
      final pool = HarmonyCandidatePool(engine: HarmonyEngine(seed: 42));

      final selected = pool.generateBest(
        candidateCount: 4,
        applyVoicing: false,
        buildCandidate: () {
          calls++;
          if (calls == 3) {
            return <Chord>[
              chord('F', 'IV', ChordTypeName.major),
              chord('G', 'V', ChordTypeName.dominant7),
              chord('C', 'I', ChordTypeName.major),
            ];
          }
          return <Chord>[
            chord('C', 'I', ChordTypeName.major),
            chord('C', 'I', ChordTypeName.major),
            chord('C', 'I', ChordTypeName.major),
          ];
        },
      );

      expect(selected.map((chord) => chord.degree), ['IV', 'V', 'I']);
    });

    test('clamps candidate count to a safe maximum', () {
      var calls = 0;
      final pool = HarmonyCandidatePool(engine: HarmonyEngine(seed: 1));

      pool.generateBest(
        candidateCount: 1000,
        applyVoicing: false,
        buildCandidate: () {
          calls++;
          return <Chord>[
            chord('G', 'V', ChordTypeName.dominant7),
            chord('C', 'I', ChordTypeName.major),
          ];
        },
      );

      expect(calls, 32);
    });

    test('filters short candidates before selecting the best progression', () {
      var calls = 0;
      final pool = HarmonyCandidatePool(engine: HarmonyEngine(seed: 42));

      final selected = pool.generateBest(
        candidateCount: 4,
        applyVoicing: false,
        buildCandidate: () {
          calls++;
          if (calls == 1 || calls == 3) {
            return <Chord>[chord('C', 'I', ChordTypeName.major)];
          }
          if (calls == 4) {
            return <Chord>[
              chord('F', 'IV', ChordTypeName.major),
              chord('G', 'V', ChordTypeName.dominant7),
              chord('C', 'I', ChordTypeName.major),
            ];
          }
          return <Chord>[
            chord('C', 'I', ChordTypeName.major),
            chord('C', 'I', ChordTypeName.major),
            chord('C', 'I', ChordTypeName.major),
          ];
        },
      );

      expect(selected.map((chord) => chord.degree), ['IV', 'V', 'I']);
    });

    test('generateScored returns candidates ordered best first', () {
      var calls = 0;
      final pool = HarmonyCandidatePool(engine: HarmonyEngine(seed: 2));

      final scored = pool.generateScored(
        candidateCount: 2,
        section: HarmonySection.chorus,
        buildCandidate: () {
          calls++;
          if (calls == 1) {
            return <Chord>[
              chord('C', 'I', ChordTypeName.major),
              chord('C', 'I', ChordTypeName.major),
              chord('C', 'I', ChordTypeName.major),
            ];
          }
          return <Chord>[
            chord('F', 'IV', ChordTypeName.major),
            chord('G', 'V', ChordTypeName.dominant7),
            chord('C', 'I', ChordTypeName.major),
          ];
        },
      );

      expect(scored, hasLength(2));
      expect(scored.first.score, greaterThan(scored.last.score));
      expect(scored.first.progression.last.degree, 'I');
    });
  });
}
