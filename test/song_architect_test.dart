import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/song_architect.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
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
      candidateCount: 4,
      useVoiceLeading: false,
    );

void main() {
  group('SongArchitect', () {
    test('generates every planned section in arrangement order', () {
      final plan = SongPlan(
        seed: 77,
        sections: const [
          SongSectionPlan(
            id: 'verse-1',
            type: SongSectionType.verse,
            bars: 4,
            targetTension: 0.35,
            targetEnergy: 0.4,
            repetitionGroup: 'verse-a',
          ),
          SongSectionPlan(
            id: 'pre-1',
            type: SongSectionType.preChorus,
            bars: 2,
            targetTension: 0.7,
            targetEnergy: 0.7,
          ),
          SongSectionPlan(
            id: 'chorus-1',
            type: SongSectionType.chorus,
            bars: 4,
            targetTension: 0.9,
            targetEnergy: 0.95,
            repetitionGroup: 'chorus-a',
          ),
          SongSectionPlan(
            id: 'verse-2',
            type: SongSectionType.verse,
            bars: 4,
            targetTension: 0.45,
            targetEnergy: 0.5,
            repetitionGroup: 'verse-a',
            variation: 1,
          ),
        ],
      );
      final architect = SongArchitect();

      final draft = architect.generate(
        request: request(123),
        plan: plan,
        buildCandidate: (section, seed, index, reference) {
          switch (section.type) {
            case SongSectionType.preChorus:
              return [
                c('F', 'IV', ChordTypeName.major),
                c('G', 'V', ChordTypeName.dominant7),
              ];
            case SongSectionType.chorus:
              return [
                c('C', 'I', ChordTypeName.major),
                c('F', 'IV', ChordTypeName.major),
                c('G', 'V', ChordTypeName.dominant7),
                c('C', 'I', ChordTypeName.major),
              ];
            case SongSectionType.verse:
              if (reference.isNotEmpty) {
                return [
                  ...reference.take(reference.length - 1),
                  c('G', 'V', ChordTypeName.major),
                ];
              }
              return [
                c('C', 'I', ChordTypeName.major),
                c('A', 'vi', ChordTypeName.minor),
                c('F', 'IV', ChordTypeName.major),
                c('G', 'V', ChordTypeName.major),
              ];
            case SongSectionType.intro:
            case SongSectionType.bridge:
            case SongSectionType.outro:
              return [
                c('C', 'I', ChordTypeName.major),
                c('F', 'IV', ChordTypeName.major),
              ];
          }
        },
      );

      expect(draft.sections.map((s) => s.plan.id), orderedEquals([
        'verse-1',
        'pre-1',
        'chorus-1',
        'verse-2',
      ]));
      expect(draft.isComplete, isTrue);
      expect(
        draft.sectionById('verse-2')?.progression.first.degree,
        draft.sectionById('verse-1')?.progression.first.degree,
      );
    });

    test('same request and plan replay the same full-song harmony', () {
      final plan = SongPlan.standard(seed: 501);
      final architect = SongArchitect();

      List<Chord> builder(
        SongSectionPlan section,
        int seed,
        int index,
        List<Chord> reference,
      ) {
        final middle = seed.isEven ? 'IV' : 'ii';
        return [
          c('C', 'I', ChordTypeName.major),
          c(
            middle == 'IV' ? 'F' : 'D',
            middle,
            middle == 'IV' ? ChordTypeName.major : ChordTypeName.minor,
          ),
          c('G', 'V', ChordTypeName.dominant7),
        ];
      }

      final first = architect.generate(
        request: request(999),
        plan: plan,
        buildCandidate: builder,
      );
      final second = architect.generate(
        request: request(999),
        plan: plan,
        buildCandidate: builder,
      );

      expect(second.sections.length, first.sections.length);
      for (var i = 0; i < first.sections.length; i++) {
        expect(second.sections[i].candidate.seed, first.sections[i].candidate.seed);
        expect(
          second.sections[i].progression.map((chord) => chord.degree),
          orderedEquals(first.sections[i].progression.map((chord) => chord.degree)),
        );
      }
    });
  });
}
