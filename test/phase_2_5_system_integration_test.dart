import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/producer_song_composer.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/engine/song_section_candidate_pool.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';

SongRequest request({int seed = 424242}) => SongRequest(
      seed: seed,
      key: KeyName.C,
      genre: GenreKey.happyPop,
      mood: MoodType.happy,
      complexity: ComplexityLevel.medium,
      spice: SpiceLevel.medium,
      rhythm: RhythmLevel.moderate,
      candidateCount: 4,
      chordVariety: 55,
      useVoiceLeading: true,
      useAdvancedTheory: false,
      useModalInterchange: false,
      useFunctionalHarmony: false,
      includeMelody: true,
      includeBass: true,
    );

List<String> harmonySignature(ProducerSongComposer composer, SongRequest req) {
  final draft = composer.compose(
    request: req,
    bassStyle: BassStyle.root,
    bassVariety: 50,
    grooveTemplate: GrooveTemplate.straight,
  );
  return draft.sections
      .expand((section) => section.progression.map(
            (chord) =>
                '${section.plan.id}:${chord.root}:${chord.type.name}:${chord.degree}',
          ))
      .toList(growable: false);
}

void main() {
  group('Phase 2.5 system integration', () {
    test('canonical composer produces a complete standard song', () {
      final draft = ProducerSongComposer().compose(
        request: request(),
        bassStyle: BassStyle.root,
        bassVariety: 50,
        grooveTemplate: GrooveTemplate.straight,
      );

      expect(draft.isComplete, isTrue);
      expect(draft.sections, hasLength(10));
      expect(draft.sections.first.plan.id, 'intro');
      expect(draft.sections.last.plan.id, 'outro');
      expect(draft.averageHarmonyScore, greaterThan(0));

      for (final section in draft.sections) {
        expect(section.progression.length, greaterThanOrEqualTo(2));
        expect(section.melody, isNotEmpty,
            reason: '${section.plan.id} should carry deterministic melody');
        expect(section.bass, isNotEmpty,
            reason: '${section.plan.id} should carry deterministic bass');
      }
    });

    test('same request seed reproduces identical full-song harmony', () {
      final composer = ProducerSongComposer();
      final first = harmonySignature(composer, request(seed: 99117));
      final second = harmonySignature(composer, request(seed: 99117));

      expect(second, orderedEquals(first));
    });

    test('different song seeds produce different harmonic identities', () {
      final composer = ProducerSongComposer();
      final first = harmonySignature(composer, request(seed: 101));
      final second = harmonySignature(composer, request(seed: 202));

      expect(second, isNot(orderedEquals(first)));
    });

    test('SongSessionController selects sections and replay preserves identity', () {
      final controller = SongSessionController();
      controller.generate(
        request: request(seed: 8080),
        bassStyle: BassStyle.fifths,
        bassVariety: 60,
        grooveTemplate: GrooveTemplate.straight,
      );

      expect(controller.hasSong, isTrue);
      expect(controller.isComplete, isTrue);
      expect(controller.selectedSectionId, 'intro');
      expect(controller.selectSection('chorus-2'), isTrue);
      final before = controller.selectedProgression
          .map((c) => '${c.root}:${c.type.name}:${c.degree}')
          .toList(growable: false);

      controller.replay();

      expect(controller.selectedSectionId, 'chorus-2');
      final after = controller.selectedProgression
          .map((c) => '${c.root}:${c.type.name}:${c.degree}')
          .toList(growable: false);
      expect(after, orderedEquals(before));
      expect(controller.selectedMelody, isNotEmpty);
      expect(controller.selectedBass, isNotEmpty);
    });

    test('Song Architect section candidates use canonical theory repair', () {
      final plan = SongPlan(
        seed: 77,
        sections: const [
          SongSectionPlan(
            id: 'test-section',
            type: SongSectionType.verse,
            bars: 4,
            targetTension: 0.4,
            targetEnergy: 0.4,
          ),
        ],
      );
      final winner = SongSectionCandidatePool().generateBest(
        request: request(seed: 77).copyWith(useVoiceLeading: false),
        plan: plan,
        sectionId: 'test-section',
        buildCandidate: (_, __) => const [
          Chord(
            root: 'C',
            type: ChordTypeName.major,
            degree: 'I',
            numeral: 'I',
          ),
          // Deliberately malformed raw candidate. In C, V/V must realize as D7.
          Chord(
            root: 'C',
            type: ChordTypeName.major,
            degree: 'V/V',
            numeral: 'V/V',
          ),
        ],
      );

      expect(winner.progression[1].root, 'D');
      expect(winner.progression[1].type, ChordTypeName.dominant7);
      expect(winner.progression[1].numeral, 'V/V');
      expect(winner.progression[1].isSecondaryDominant, isTrue);
    });
  });
}
