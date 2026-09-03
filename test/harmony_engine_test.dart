import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/models/types.dart';

Chord chord(String root, String degree, ChordTypeName type) => Chord(
      root: root,
      type: type,
      degree: degree,
      numeral: degree,
    );

void main() {
  group('HarmonyEngine', () {
    final engine = HarmonyEngine(seed: 42);

    test('rewards functional dominant-to-tonic resolution', () {
      final resolved = <Chord>[
        chord('C', 'I', ChordTypeName.major),
        chord('F', 'IV', ChordTypeName.major),
        chord('G', 'V', ChordTypeName.major),
        chord('C', 'I', ChordTypeName.major),
      ];
      final repetitive = <Chord>[
        chord('C', 'I', ChordTypeName.major),
        chord('C', 'I', ChordTypeName.major),
        chord('C', 'I', ChordTypeName.major),
        chord('C', 'I', ChordTypeName.major),
      ];

      expect(engine.score(resolved), greaterThan(engine.score(repetitive)));
    });

    test('penalizes excessive advanced substitutions', () {
      final tasteful = <Chord>[
        chord('C', 'I', ChordTypeName.major7),
        chord('D', 'ii', ChordTypeName.minor7),
        const Chord(
          root: 'D',
          type: ChordTypeName.dominant7,
          degree: 'V/V',
          numeral: 'V/V',
          isSecondaryDominant: true,
        ),
        chord('G', 'V', ChordTypeName.dominant7),
        chord('C', 'I', ChordTypeName.major7),
      ];
      final overloaded = List<Chord>.generate(
        5,
        (_) => const Chord(
          root: 'Db',
          type: ChordTypeName.dominant7,
          degree: 'bII7',
          numeral: 'bII7',
          isTritoneSubstitution: true,
        ),
      );

      expect(engine.score(tasteful), greaterThan(engine.score(overloaded)));
    });

    test('selectBest returns the strongest candidate', () {
      final weak = <Chord>[
        chord('C', 'I', ChordTypeName.major),
        chord('C', 'I', ChordTypeName.major),
        chord('C', 'I', ChordTypeName.major),
      ];
      final strong = <Chord>[
        chord('F', 'IV', ChordTypeName.major),
        chord('G', 'V', ChordTypeName.dominant7),
        chord('C', 'I', ChordTypeName.major),
      ];

      final selected = engine.selectBest([weak, strong], applyVoicing: false);
      expect(selected.last.degree, 'I');
      expect(selected[1].degree, 'V');
    });
  });
}
