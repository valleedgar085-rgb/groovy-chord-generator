import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/producer_analysis.dart';
import 'package:groovy_chord_generator/models/types.dart';

void main() {
  group('Producer Brain 2.0 analysis', () {
    final analyzer = ProducerAnalyzer();
    final progression = <Chord>[
      _chord('C', ChordTypeName.major, 'I'),
      _chord('F', ChordTypeName.major, 'IV'),
      _chord('G', ChordTypeName.dominant7, 'V'),
      _chord('C', ChordTypeName.major, 'I'),
    ];

    test('returns the complete ten-dimension scorecard', () {
      final analysis = analyzer.analyze(
        progression: progression,
        melody: _coherentMelody,
        bass: _anchoredBass,
        genre: GenreKey.happyPop,
        rhythm: RhythmLevel.moderate,
        section: HarmonySection.chorus,
        spice: SpiceLevel.medium,
        tempo: 120,
        swing: 0.08,
        grooveTemplate: GrooveTemplate.straight,
      );

      expect(analysis.metrics, hasLength(10));
      expect(analysis.overallScore, inInclusiveRange(0.0, 100.0));
      for (final metric in analysis.metrics.where((metric) => metric.active)) {
        expect(metric.score, inInclusiveRange(0.0, 100.0));
        expect(metric.action, isNotEmpty);
        expect(metric.insight, isNotEmpty);
      }
    });

    test('large melodic leaps lower melody and playability scores', () {
      final coherent = analyzer.analyze(
        progression: progression,
        melody: _coherentMelody,
        bass: _anchoredBass,
        genre: GenreKey.happyPop,
        rhythm: RhythmLevel.moderate,
        section: HarmonySection.chorus,
        spice: SpiceLevel.medium,
        tempo: 120,
        swing: 0.08,
        grooveTemplate: GrooveTemplate.straight,
      );
      final jagged = analyzer.analyze(
        progression: progression,
        melody: _jaggedMelody,
        bass: _anchoredBass,
        genre: GenreKey.happyPop,
        rhythm: RhythmLevel.moderate,
        section: HarmonySection.chorus,
        spice: SpiceLevel.medium,
        tempo: 120,
        swing: 0.08,
        grooveTemplate: GrooveTemplate.straight,
      );

      expect(
        jagged.metricFor(ProducerDimension.melody)!.score,
        lessThan(coherent.metricFor(ProducerDimension.melody)!.score),
      );
      expect(
        jagged.metricFor(ProducerDimension.playability)!.score,
        lessThan(coherent.metricFor(ProducerDimension.playability)!.score),
      );
    });

    test('disabled melody and bass are N/A and do not zero the overall score', () {
      final analysis = analyzer.analyze(
        progression: progression,
        melody: const <MelodyNote>[],
        bass: const <BassNote>[],
        genre: GenreKey.happyPop,
        rhythm: RhythmLevel.moderate,
        section: HarmonySection.chorus,
        spice: SpiceLevel.mild,
        tempo: 120,
        swing: 0,
        grooveTemplate: GrooveTemplate.straight,
      );

      expect(analysis.metricFor(ProducerDimension.melody)!.active, isFalse);
      expect(analysis.metricFor(ProducerDimension.bass)!.active, isFalse);
      expect(analysis.overallScore, greaterThan(0));
    });
  });
}

Chord _chord(String root, ChordTypeName type, String degree) => Chord(
      root: root,
      type: type,
      degree: degree,
      numeral: degree,
    );

const _coherentMelody = <MelodyNote>[
  MelodyNote(note: 'C', duration: 0.5, velocity: 0.72, chordIndex: 0, octave: 4),
  MelodyNote(note: 'E', duration: 0.5, velocity: 0.82, chordIndex: 0, octave: 4),
  MelodyNote(note: 'F', duration: 0.25, velocity: 0.68, chordIndex: 1, octave: 4),
  MelodyNote(note: 'A', duration: 0.75, velocity: 0.88, chordIndex: 1, octave: 4),
  MelodyNote(note: 'G', duration: 0.5, velocity: 0.76, chordIndex: 2, octave: 4),
  MelodyNote(note: 'B', duration: 0.5, velocity: 0.90, chordIndex: 2, octave: 4),
  MelodyNote(note: 'G', duration: 0.25, velocity: 0.70, chordIndex: 3, octave: 4),
  MelodyNote(note: 'E', duration: 0.75, velocity: 0.84, chordIndex: 3, octave: 4),
];

const _jaggedMelody = <MelodyNote>[
  MelodyNote(note: 'C', duration: 0.5, velocity: 0.72, chordIndex: 0, octave: 3),
  MelodyNote(note: 'B', duration: 0.5, velocity: 0.82, chordIndex: 0, octave: 5),
  MelodyNote(note: 'C#', duration: 0.25, velocity: 0.68, chordIndex: 1, octave: 3),
  MelodyNote(note: 'A', duration: 0.75, velocity: 0.88, chordIndex: 1, octave: 5),
  MelodyNote(note: 'Db', duration: 0.5, velocity: 0.76, chordIndex: 2, octave: 3),
  MelodyNote(note: 'F#', duration: 0.5, velocity: 0.90, chordIndex: 2, octave: 5),
  MelodyNote(note: 'D#', duration: 0.25, velocity: 0.70, chordIndex: 3, octave: 3),
  MelodyNote(note: 'A#', duration: 0.75, velocity: 0.84, chordIndex: 3, octave: 5),
];

const _anchoredBass = <BassNote>[
  BassNote(note: 'C', duration: 1, velocity: 0.82, octave: 2, chordIndex: 0, style: BassStyle.root),
  BassNote(note: 'F', duration: 1, velocity: 0.76, octave: 2, chordIndex: 1, style: BassStyle.root),
  BassNote(note: 'G', duration: 1, velocity: 0.86, octave: 2, chordIndex: 2, style: BassStyle.root),
  BassNote(note: 'C', duration: 1, velocity: 0.80, octave: 2, chordIndex: 3, style: BassStyle.root),
];
