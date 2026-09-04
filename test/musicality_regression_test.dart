import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/harmonic_realizer.dart';
import 'package:groovy_chord_generator/engine/harmony_candidate_pool.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/models/types.dart';

SongRequest request({
  KeyName key = KeyName.C,
  GenreKey genre = GenreKey.happyPop,
}) {
  return SongRequest(
    seed: 1234,
    key: key,
    genre: genre,
    mood: MoodType.happy,
    complexity: ComplexityLevel.medium,
    spice: SpiceLevel.medium,
    rhythm: RhythmLevel.moderate,
    candidateCount: 2,
    useVoiceLeading: false,
  );
}

Chord raw(String degree, ChordTypeName type, {String root = 'C'}) => Chord(
      root: root,
      type: type,
      degree: degree,
      numeral: degree,
    );

void main() {
  group('HarmonicRealizer', () {
    const realizer = HarmonicRealizer();

    test('repairs secondary dominant V/V to the dominant of V', () {
      final repaired = realizer.repairChord(
        raw('V/V', ChordTypeName.minor9),
        request(),
      );

      expect(repaired.root, 'D');
      expect(repaired.type, ChordTypeName.dominant7);
      expect(repaired.numeral, 'V/V');
      expect(repaired.isSecondaryDominant, isTrue);
    });

    test('keeps altered bVII away from tonic', () {
      final repaired = realizer.repairChord(
        raw('bVII', ChordTypeName.major),
        request(),
      );

      expect(repaired.root, anyOf('A#', 'Bb'));
      expect(repaired.root, isNot('C'));
      expect(repaired.numeral, 'bVII');
    });

    test('repairs ii extensions into the minor chord family', () {
      final repaired = realizer.repairChord(
        raw('ii', ChordTypeName.major9),
        request(),
      );

      expect(repaired.root, 'D');
      expect(repaired.type, ChordTypeName.minor9);
      expect(repaired.numeral, 'ii');
    });

    test('realizes leading-tone vii as diminished in a major key', () {
      final repaired = realizer.repairChord(
        raw('vii', ChordTypeName.major),
        request(),
      );

      expect(repaired.root, 'B');
      expect(repaired.type, ChordTypeName.diminished);
    });

    test('uppercase V in a minor key becomes a real dominant', () {
      final repaired = realizer.repairChord(
        raw('V', ChordTypeName.minor7),
        request(key: KeyName.Am),
      );

      expect(repaired.root, 'E');
      expect(repaired.type, ChordTypeName.dominant7);
    });
  });

  group('Producer candidate normalization', () {
    test('repairs candidate harmony before scoring and returning it', () {
      final pool = HarmonyCandidatePool(engine: HarmonyEngine(seed: 7));
      final result = pool.generateBestForRequest(
        request: request(),
        buildCandidate: (seed, index) => <Chord>[
          raw('ii', ChordTypeName.major9),
          raw('V/V', ChordTypeName.minor9),
          raw('V', ChordTypeName.dominant7),
          raw('I', ChordTypeName.major),
        ],
      );

      expect(result.progression[0].type, ChordTypeName.minor9);
      expect(result.progression[1].root, 'D');
      expect(result.progression[1].type, ChordTypeName.dominant7);
      expect(result.progression[2].root, 'G');
      expect(result.progression[3].root, 'C');
    });
  });

  group('HarmonyEngine cadence semantics', () {
    test('authentic cadence scores above deceptive cadence', () {
      final engine = HarmonyEngine(seed: 3);
      final authentic = <Chord>[
        raw('IV', ChordTypeName.major, root: 'F'),
        raw('V', ChordTypeName.dominant7, root: 'G'),
        raw('I', ChordTypeName.major, root: 'C'),
      ];
      final deceptive = <Chord>[
        raw('IV', ChordTypeName.major, root: 'F'),
        raw('V', ChordTypeName.dominant7, root: 'G'),
        raw('vi', ChordTypeName.minor, root: 'A'),
      ];

      expect(engine.score(authentic), greaterThan(engine.score(deceptive)));
    });

    test('V/V resolving to V is rewarded over an unrelated move', () {
      final engine = HarmonyEngine(seed: 3);
      final prepared = <Chord>[
        raw('ii', ChordTypeName.minor, root: 'D'),
        raw('V/V', ChordTypeName.dominant7, root: 'D'),
        raw('V', ChordTypeName.dominant7, root: 'G'),
        raw('I', ChordTypeName.major, root: 'C'),
      ];
      final unrelated = <Chord>[
        raw('ii', ChordTypeName.minor, root: 'D'),
        raw('bVII', ChordTypeName.major, root: 'Bb'),
        raw('iii', ChordTypeName.minor, root: 'E'),
        raw('I', ChordTypeName.major, root: 'C'),
      ];

      expect(engine.score(prepared), greaterThan(engine.score(unrelated)));
    });
  });
}
