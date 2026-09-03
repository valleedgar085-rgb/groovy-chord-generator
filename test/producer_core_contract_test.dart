import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/harmony_candidate_pool.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/models/types.dart';

void main() {
  SongRequest request({int seed = 424242}) => SongRequest(
        seed: seed,
        key: KeyName.C,
        genre: GenreKey.happyPop,
        mood: MoodType.happy,
        complexity: ComplexityLevel.medium,
        spice: SpiceLevel.medium,
        rhythm: RhythmLevel.moderate,
        section: HarmonySection.chorus,
        candidateCount: 8,
      );

  List<Chord> buildFromSeed(int seed) {
    final random = Random(seed);
    const middleDegrees = ['ii', 'IV', 'V', 'vi'];
    final middle = middleDegrees[random.nextInt(middleDegrees.length)];

    return [
      const Chord(
        root: 'C',
        type: ChordTypeName.major,
        degree: 'I',
        numeral: 'I',
      ),
      Chord(
        root: middle == 'V' ? 'G' : 'F',
        type: middle == 'ii' || middle == 'vi'
            ? ChordTypeName.minor
            : ChordTypeName.major,
        degree: middle,
        numeral: middle,
      ),
      const Chord(
        root: 'G',
        type: ChordTypeName.major,
        degree: 'V',
        numeral: 'V',
      ),
      const Chord(
        root: 'C',
        type: ChordTypeName.major,
        degree: 'I',
        numeral: 'I',
      ),
    ];
  }

  test('SongRequest derives stable and distinct candidate seeds', () {
    final first = request();
    final replay = request();

    final firstSeeds =
        List.generate(first.candidateCount, first.candidateSeed, growable: false);
    final replaySeeds = List.generate(
        replay.candidateCount, replay.candidateSeed,
        growable: false);

    expect(firstSeeds, replaySeeds);
    expect(firstSeeds.toSet().length, first.candidateCount);
  });

  test('same request seed reproduces the same ranked candidate set', () {
    final pool = HarmonyCandidatePool(engine: HarmonyEngine(seed: 1));

    final first = pool.generateScoredDeterministic(
      request: request(),
      buildCandidate: buildFromSeed,
    );
    final replay = pool.generateScoredDeterministic(
      request: request(),
      buildCandidate: buildFromSeed,
    );

    expect(first.length, replay.length);
    expect(first.map((c) => c.seed), replay.map((c) => c.seed));
    expect(first.map((c) => c.score), replay.map((c) => c.score));
    expect(
      first.map((c) => c.progression.map((chord) => chord.degree).join('-')),
      replay.map((c) => c.progression.map((chord) => chord.degree).join('-')),
    );
  });

  test('changing the request seed changes the candidate identity', () {
    final pool = HarmonyCandidatePool(engine: HarmonyEngine(seed: 1));

    final first = pool.generateScoredDeterministic(
      request: request(seed: 111),
      buildCandidate: buildFromSeed,
    );
    final second = pool.generateScoredDeterministic(
      request: request(seed: 222),
      buildCandidate: buildFromSeed,
    );

    expect(first.map((c) => c.seed).toList(),
        isNot(equals(second.map((c) => c.seed).toList())));
  });
}
