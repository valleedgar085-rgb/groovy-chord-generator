import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/harmony_candidate_pool.dart';
import 'package:groovy_chord_generator/engine/producer_analysis.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/models/types.dart';

void main() {
  group('Phase 5.1 multidimensional candidate ranking', () {
    final request = SongRequest(
      seed: 515151,
      key: KeyName.C,
      genre: GenreKey.happyPop,
      mood: MoodType.happy,
      complexity: ComplexityLevel.medium,
      spice: SpiceLevel.medium,
      rhythm: RhythmLevel.moderate,
      candidateCount: 4,
      chordVariety: 55,
      includeMelody: true,
      includeBass: true,
    );

    List<Chord> build(int seed, int index) {
      if (index.isEven) {
        return <Chord>[
          _chord('C', ChordTypeName.major, 'I'),
          _chord('F', ChordTypeName.major, 'IV'),
          _chord('G', ChordTypeName.dominant7, 'V'),
          _chord('C', ChordTypeName.major, 'I'),
        ];
      }
      return <Chord>[
        _chord('C', ChordTypeName.major, 'I'),
        _chord('A', ChordTypeName.minor, 'vi'),
        _chord('F', ChordTypeName.major, 'IV'),
        _chord('G', ChordTypeName.dominant7, 'V'),
      ];
    }

    test('scores all candidates with the ten-dimensional Producer Brain', () {
      final pool = HarmonyCandidatePool();
      final candidates = pool.generateScoredMusicalForRequest(
        request: request,
        buildCandidate: build,
      );

      expect(candidates, hasLength(4));
      for (final candidate in candidates) {
        final analysis = candidate.producerAnalysis;
        expect(analysis, isNotNull);
        expect(analysis!.metrics, hasLength(10));
        expect(candidate.score, analysis.overallScore);
        expect(candidate.score, inInclusiveRange(0.0, 100.0));
      }

      for (var i = 1; i < candidates.length; i++) {
        expect(candidates[i - 1].score, greaterThanOrEqualTo(candidates[i].score));
      }
    });

    test('replaying the same request produces the same winner and score', () {
      final first = HarmonyCandidatePool().generateBestForRequest(
        request: request,
        buildCandidate: build,
      );
      final second = HarmonyCandidatePool().generateBestForRequest(
        request: request,
        buildCandidate: build,
      );

      expect(second.candidateIndex, first.candidateIndex);
      expect(second.seed, first.seed);
      expect(second.score, first.score);
      expect(second.progression.map((chord) => chord.degree),
          first.progression.map((chord) => chord.degree));
    });

    test('disabled performance layers remain inactive during candidate ranking', () {
      final noPerformance = request.copyWith(
        seed: 919191,
        includeMelody: false,
        includeBass: false,
      );
      final winner = HarmonyCandidatePool().generateBestForRequest(
        request: noPerformance,
        buildCandidate: build,
      );
      final analysis = winner.producerAnalysis!;

      expect(analysis.metricFor(ProducerDimension.melody)!.active, isFalse);
      expect(analysis.metricFor(ProducerDimension.bass)!.active, isFalse);
      expect(winner.score, greaterThan(0));
    });
  });
}

Chord _chord(String root, ChordTypeName type, String degree) => Chord(
      root: root,
      type: type,
      degree: degree,
      numeral: degree,
    );
