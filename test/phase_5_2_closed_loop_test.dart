import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/harmony_candidate_pool.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/producer_brain_telemetry.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/models/types.dart';

void main() {
  group('Phase 5.2 closed-loop Producer Brain', () {
    final request = SongRequest(
      seed: 424242,
      key: KeyName.C,
      genre: GenreKey.happyPop,
      mood: MoodType.happy,
      complexity: ComplexityLevel.medium,
      spice: SpiceLevel.medium,
      rhythm: RhythmLevel.moderate,
      section: HarmonySection.chorus,
      candidateCount: 8,
      chordVariety: 55,
      includeMelody: true,
      includeBass: true,
    );

    List<Chord> build(int seed, int index) {
      // Deliberately repetitive input gives the closed-loop refiner useful work
      // while small index changes preserve deterministic candidate identity.
      if (index.isEven) {
        return <Chord>[
          _chord('C', ChordTypeName.major, 'I'),
          _chord('C', ChordTypeName.major, 'I'),
          _chord('F', ChordTypeName.major, 'IV'),
          _chord('F', ChordTypeName.major, 'IV'),
          _chord('G', ChordTypeName.dominant7, 'V'),
          _chord('C', ChordTypeName.major, 'I'),
        ];
      }
      return <Chord>[
        _chord('C', ChordTypeName.major, 'I'),
        _chord('A', ChordTypeName.minor, 'vi'),
        _chord('F', ChordTypeName.major, 'IV'),
        _chord('G', ChordTypeName.major, 'V'),
        _chord('C', ChordTypeName.major, 'I'),
        _chord('C', ChordTypeName.major, 'I'),
      ];
    }

    test('evolves the top three and never accepts a regressive repair', () {
      final pool = HarmonyCandidatePool();
      final ranked = pool.generateRefinedMusicalForRequest(
        request: request,
        buildCandidate: build,
      );

      expect(ranked, isNotEmpty);
      for (var i = 1; i < ranked.length; i++) {
        expect(ranked[i - 1].score, greaterThanOrEqualTo(ranked[i].score));
      }

      final refined = ranked.where((candidate) => candidate.wasRefined).toList();
      expect(refined, isNotEmpty);
      for (final candidate in refined) {
        expect(candidate.beforeRefineScore, isNotNull);
        expect(candidate.score + 0.01,
            greaterThanOrEqualTo(candidate.beforeRefineScore!));
        expect(candidate.repairs, isNotEmpty);
      }
    });

    test('same request produces the same winning evolution', () {
      final first = HarmonyCandidatePool().generateRefinedMusicalForRequest(
        request: request,
        buildCandidate: build,
      );
      final second = HarmonyCandidatePool().generateRefinedMusicalForRequest(
        request: request,
        buildCandidate: build,
      );

      expect(first.first.score, closeTo(second.first.score, 0.000001));
      expect(first.first.variationStyle, second.first.variationStyle);
      expect(
        first.first.progression.map((c) => '${c.root}:${c.type.name}').toList(),
        second.first.progression.map((c) => '${c.root}:${c.type.name}').toList(),
      );
    });

    test('publishes winner and A/B/C diagnostics for the UI', () {
      final pool = HarmonyCandidatePool();
      final winner = pool.generateBestForRequest(
        request: request,
        buildCandidate: build,
      );
      final snapshot = ProducerBrainTelemetry.instance.latest;

      expect(snapshot, isNotNull);
      expect(snapshot!.winner.score, closeTo(winner.score, 0.000001));
      expect(snapshot.variations.length, lessThanOrEqualTo(3));
      expect(
        snapshot.variations.map((c) => c.variationStyle).toSet().length,
        snapshot.variations.length,
      );
    });
  });
}

Chord _chord(String root, ChordTypeName type, String degree) => Chord(
      root: root,
      type: type,
      degree: degree,
      numeral: degree,
    );
