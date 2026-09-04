import 'package:flutter_test/flutter_test.dart';

import 'package:groovy_chord_generator/engine/motif_transformation_engine.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/utils/music_theory.dart';

Chord _chord(String root, String degree, ChordTypeName type) => Chord(
      root: root,
      type: type,
      degree: degree,
      numeral: degree,
    );

const _melody = <MelodyNote>[
  MelodyNote(note: 'E', duration: 1.0, velocity: 0.82, chordIndex: 0, octave: 4),
  MelodyNote(note: 'G', duration: 0.5, velocity: 0.68, chordIndex: 0, octave: 4),
  MelodyNote(note: 'A', duration: 0.5, velocity: 0.74, chordIndex: 1, octave: 4),
  MelodyNote(note: 'C', duration: 1.0, velocity: 0.76, chordIndex: 1, octave: 5),
  MelodyNote(note: 'A', duration: 0.5, velocity: 0.72, chordIndex: 2, octave: 4),
  MelodyNote(note: 'C', duration: 0.5, velocity: 0.80, chordIndex: 2, octave: 5),
  MelodyNote(note: 'D', duration: 1.0, velocity: 0.78, chordIndex: 3, octave: 5),
  MelodyNote(note: 'C', duration: 1.0, velocity: 0.88, chordIndex: 3, octave: 5),
];

const _bass = <BassNote>[
  BassNote(note: 'C', duration: 1, velocity: 0.8, octave: 2, chordIndex: 0, style: BassStyle.root),
  BassNote(note: 'A', duration: 1, velocity: 0.8, octave: 2, chordIndex: 1, style: BassStyle.root),
  BassNote(note: 'F', duration: 1, velocity: 0.8, octave: 2, chordIndex: 2, style: BassStyle.root),
  BassNote(note: 'C', duration: 1, velocity: 0.8, octave: 2, chordIndex: 3, style: BassStyle.root),
];

List<Chord> _progression() => [
      _chord('C', 'I', ChordTypeName.major7),
      _chord('A', 'vi', ChordTypeName.minor7),
      _chord('F', 'IV', ChordTypeName.major7),
      _chord('C', 'I', ChordTypeName.major),
    ];

double _duration(List<MelodyNote> melody) =>
    melody.fold<double>(0, (sum, note) => sum + note.duration);

List<String> _melodySignature(List<MelodyNote> melody) => melody
    .map((note) =>
        '${note.note}:${note.octave}:${note.duration}:${note.velocity}:${note.chordIndex}')
    .toList(growable: false);

List<String> _harmonySignature(List<Chord> progression) => progression
    .map((chord) => '${chord.root}:${chord.degree}:${chord.type.name}')
    .toList(growable: false);

void main() {
  group('Phase 3.5 motif transformations', () {
    test('subtle development preserves phrase duration and replays exactly', () {
      const engine = MotifTransformationEngine();
      final first = engine.transform(
        progression: _progression(),
        melody: _melody,
        bass: _bass,
        seed: 93001,
        intensity: MotifVariationIntensity.subtle,
      );
      final second = engine.transform(
        progression: _progression(),
        melody: _melody,
        bass: _bass,
        seed: 93001,
        intensity: MotifVariationIntensity.subtle,
      );

      expect(first.operations, isNotEmpty);
      expect(_duration(first.melody), closeTo(_duration(_melody), 0.000001));
      expect(_melodySignature(first.melody), _melodySignature(second.melody));
      expect(_harmonySignature(first.progression), _harmonySignature(second.progression));
      expect(first.operations, second.operations);
    });

    test('developed tonic ending intensifies to dominant-seven then tonic', () {
      const engine = MotifTransformationEngine();
      final result = engine.transform(
        progression: _progression(),
        melody: _melody,
        bass: _bass,
        seed: 93002,
        intensity: MotifVariationIntensity.developed,
        emphasizeCadence: true,
      );

      final penultimate = result.progression[result.progression.length - 2];
      final tonic = result.progression.last;
      expect(penultimate.degree, 'V');
      expect(penultimate.root, 'G');
      expect(penultimate.type, ChordTypeName.dominant7);
      expect(penultimate.harmonyFunction, HarmonyFunction.dominant);
      expect(tonic.degree, 'I');
      expect(tonic.root, 'C');
      expect(result.operations, contains(MotifOperation.cadenceIntensification));
      expect(result.operations, contains(MotifOperation.rhythmicDisplacement));
      expect(
        result.operations.any((operation) =>
            operation == MotifOperation.contourInversion ||
            operation == MotifOperation.sequence),
        isTrue,
      );
      expect(_duration(result.melody), closeTo(_duration(_melody), 0.000001));
    });

    test('pitch transformations remain inside the active chord', () {
      const engine = MotifTransformationEngine();
      final result = engine.transform(
        progression: _progression(),
        melody: _melody,
        bass: _bass,
        seed: 93003,
        intensity: MotifVariationIntensity.developed,
      );

      for (final note in result.melody) {
        expect(note.chordIndex, inInclusiveRange(0, result.progression.length - 1));
        final allowed = getChordNotes(result.progression[note.chordIndex])
            .map(getNoteIndex)
            .toSet();
        expect(
          allowed,
          contains(getNoteIndex(note.note)),
          reason: '${note.note} must belong to chord ${note.chordIndex}',
        );
      }
    });

    test('cadence intensification does not rewrite a non-tonic ending', () {
      const engine = MotifTransformationEngine();
      final progression = [
        _chord('C', 'I', ChordTypeName.major),
        _chord('A', 'vi', ChordTypeName.minor),
        _chord('F', 'IV', ChordTypeName.major),
        _chord('G', 'V', ChordTypeName.dominant7),
      ];
      final result = engine.transform(
        progression: progression,
        melody: _melody,
        bass: _bass,
        seed: 93004,
        intensity: MotifVariationIntensity.developed,
        emphasizeCadence: true,
      );

      expect(result.progression.last.degree, 'V');
      expect(
        result.operations,
        isNot(contains(MotifOperation.cadenceIntensification)),
      );
    });
  });
}
