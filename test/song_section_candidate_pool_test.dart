import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/engine/song_section_candidate_pool.dart';
import 'package:groovy_chord_generator/models/types.dart';

Chord c(String root, String degree, ChordTypeName type) => Chord(
      root: root,
      type: type,
      degree: degree,
      numeral: degree,
    );

SongRequest request(int seed) => SongRequest(
      seed: seed,
      key: KeyName.C,
      genre: GenreKey.happyPop,
      mood: MoodType.happy,
      complexity: ComplexityLevel.medium,
      spice: SpiceLevel.medium,
      rhythm: RhythmLevel.moderate,
    );

void main() {
  test('section selector uses previous pre-chorus to prefer tonic chorus arrival', () {
    final pool = SongSectionCandidatePool();
    final plan = SongPlan.standard(seed: 9001);
    final previous = <Chord>[
      c('F', 'IV', ChordTypeName.major),
      c('G', 'V', ChordTypeName.dominant7),
    ];

    final winner = pool.generateBest(
      request: request(42),
      plan: plan,
      sectionId: 'chorus-1',
      previousProgression: previous,
      buildCandidate: (_, index) {
        if (index.isEven) {
          return [
            c('F', 'IV', ChordTypeName.major),
            c('G', 'V', ChordTypeName.dominant7),
            c('C', 'I', ChordTypeName.major),
          ];
        }
        return [
          c('C', 'I', ChordTypeName.major),
          c('F', 'IV', ChordTypeName.major),
          c('G', 'V', ChordTypeName.dominant7),
          c('C', 'I', ChordTypeName.major),
        ];
      },
    );

    expect(winner.progression.first.degree, 'I');
    expect(winner.section.name, 'chorus');
  });

  test('same plan and request replay the same winning candidate', () {
    final plan = SongPlan.standard(seed: 111);
    final pool = SongSectionCandidatePool();

    List<Chord> builder(int seed, int index) {
      final middle = seed.isEven ? 'IV' : 'ii';
      return [
        c('C', 'I', ChordTypeName.major),
        c(middle == 'IV' ? 'F' : 'D', middle,
            middle == 'IV' ? ChordTypeName.major : ChordTypeName.minor),
        c('G', 'V', ChordTypeName.dominant7),
      ];
    }

    final first = pool.generateBest(
      request: request(500),
      plan: plan,
      sectionId: 'pre-1',
      buildCandidate: builder,
    );
    final second = pool.generateBest(
      request: request(500),
      plan: plan,
      sectionId: 'pre-1',
      buildCandidate: builder,
    );

    expect(second.seed, first.seed);
    expect(second.candidateIndex, first.candidateIndex);
    expect(
      second.progression.map((chord) => chord.degree),
      orderedEquals(first.progression.map((chord) => chord.degree)),
    );
  });

  test('verse 2 prefers recognizable variation of verse 1', () {
    final plan = SongPlan.standard(seed: 222);
    final pool = SongSectionCandidatePool();
    final reference = <Chord>[
      c('C', 'I', ChordTypeName.major),
      c('A', 'vi', ChordTypeName.minor),
      c('F', 'IV', ChordTypeName.major),
      c('G', 'V', ChordTypeName.major),
    ];

    final winner = pool.generateBest(
      request: request(900),
      plan: plan,
      sectionId: 'verse-2',
      repetitionReference: reference,
      buildCandidate: (_, index) {
        if (index.isEven) {
          return [
            c('C', 'I', ChordTypeName.major),
            c('A', 'vi', ChordTypeName.minor),
            c('D', 'ii', ChordTypeName.minor),
            c('G', 'V', ChordTypeName.major),
          ];
        }
        return [
          c('D', 'ii', ChordTypeName.minor),
          c('G', 'V', ChordTypeName.major),
          c('D', 'ii', ChordTypeName.minor),
          c('G', 'V', ChordTypeName.major),
        ];
      },
    );

    expect(winner.progression.first.degree, 'I');
    expect(winner.progression[1].degree, 'vi');
    expect(winner.progression.last.degree, 'V');
  });
}
