import 'dart:math';

import '../models/types.dart';
import '../utils/music_theory.dart';
import 'emotion_performance_shaper.dart';
import 'phrase_composer.dart';
import 'seeded_harmony_builder.dart';
import 'seeded_music_generation.dart';
import 'song_architect.dart';
import 'song_architecture.dart';
import 'song_candidate.dart';
import 'song_draft.dart';
import 'song_request.dart';
import 'song_section_candidate_pool.dart';

/// Canonical full-song composition pipeline used by the live application.
///
/// This class deliberately has no Flutter/provider dependency. It composes the
/// arrangement with [SongArchitect], builds harmony through the same
/// [SeededHarmonyBuilder] used by single-progression generation, then attaches
/// deterministic phrase-first melody, bass, emotional performance shaping, and
/// performance metadata per section.
class ProducerSongComposer {
  ProducerSongComposer({
    SongArchitect? architect,
    SongSectionCandidatePool? candidatePool,
    SeededHarmonyBuilder? harmonyBuilder,
    SeededMusicGeneration? generation,
    PhraseComposer? phraseComposer,
    EmotionPerformanceShaper? emotionShaper,
  })  : _architect = architect ?? SongArchitect(),
        _candidatePool = candidatePool ?? SongSectionCandidatePool(),
        _harmonyBuilder = harmonyBuilder ?? const SeededHarmonyBuilder(),
        _generation = generation ?? const SeededMusicGeneration(),
        _phraseComposer = phraseComposer ?? const PhraseComposer(),
        _emotionShaper = emotionShaper ?? const EmotionPerformanceShaper();

  final SongArchitect _architect;
  final SongSectionCandidatePool _candidatePool;
  final SeededHarmonyBuilder _harmonyBuilder;
  final SeededMusicGeneration _generation;
  final PhraseComposer _phraseComposer;
  final EmotionPerformanceShaper _emotionShaper;

  SongDraft compose({
    required SongRequest request,
    SongPlan? plan,
    BassStyle bassStyle = BassStyle.root,
    int bassVariety = 50,
    GrooveTemplate grooveTemplate = GrooveTemplate.straight,
  }) {
    final songPlan = plan ?? SongPlan.standard(seed: request.seed);

    final harmonyDraft = _architect.generate(
      request: request,
      plan: songPlan,
      buildCandidate: (
        section,
        candidateSeed,
        candidateIndex,
        repetitionReference,
      ) {
        final sectionRequest = request.copyWith(
          seed: songPlan.sectionSeed(section.id),
          section: section.harmonySection,
        );
        return _harmonyBuilder.build(
          request: sectionRequest,
          random: Random(candidateSeed),
        );
      },
    );

    var completed = harmonyDraft;
    for (final section in harmonyDraft.sections) {
      final repetitionSource = _priorRepetitionReference(completed, section.plan);
      completed = completed.withSection(
        _decorateSection(
          request: request,
          section: section,
          sectionSeed: songPlan.sectionSeed(section.plan.id),
          bassStyle: bassStyle,
          bassVariety: bassVariety,
          grooveTemplate: grooveTemplate,
          repetitionSource: repetitionSource,
        ),
      );
    }

    return completed;
  }

  /// Rebuilds exactly one section while preserving the rest of [draft].
  ///
  /// [revision] is part of the deterministic seed lineage. The same song,
  /// section id and revision always produce the same replacement. A later
  /// revision produces a new candidate family without turning regeneration
  /// into untraceable randomness.
  GeneratedSongSection regenerateSection({
    required SongRequest request,
    required SongDraft draft,
    required String sectionId,
    required int revision,
    BassStyle bassStyle = BassStyle.root,
    int bassVariety = 50,
    GrooveTemplate grooveTemplate = GrooveTemplate.straight,
  }) {
    if (revision < 1) {
      throw ArgumentError.value(revision, 'revision', 'Must be at least 1');
    }

    final sectionPlan = draft.plan.sectionById(sectionId);
    if (sectionPlan == null) {
      throw ArgumentError.value(sectionId, 'sectionId', 'Unknown song section');
    }

    // A temporary plan gives only this regeneration request a new deterministic
    // section seed. The arrangement intent itself remains identical.
    final regenerationPlan = SongPlan(
      seed: _regenerationPlanSeed(draft.plan.seed, sectionId, revision),
      sections: draft.plan.sections,
    );
    final sectionSeed = regenerationPlan.sectionSeed(sectionId);
    final previousProgression = draft.previousProgressionFor(sectionId);
    final repetitionSource = _priorRepetitionReference(draft, sectionPlan);
    final repetitionReference =
        repetitionSource?.progression ?? const <Chord>[];

    final winner = _candidatePool.generateBest(
      request: request,
      plan: regenerationPlan,
      sectionId: sectionId,
      previousProgression: previousProgression,
      repetitionReference: repetitionReference,
      buildCandidate: (candidateSeed, candidateIndex) {
        final sectionRequest = request.copyWith(
          seed: sectionSeed,
          section: sectionPlan.harmonySection,
        );
        return _harmonyBuilder.build(
          request: sectionRequest,
          random: Random(candidateSeed),
        );
      },
    );

    final harmonySection = GeneratedSongSection(
      plan: sectionPlan,
      candidate: winner,
    );

    return _decorateSection(
      request: request,
      section: harmonySection,
      sectionSeed: sectionSeed,
      bassStyle: bassStyle,
      bassVariety: bassVariety,
      grooveTemplate: grooveTemplate,
      repetitionSource: repetitionSource,
    );
  }

  GeneratedSongSection _decorateSection({
    required SongRequest request,
    required GeneratedSongSection section,
    required int sectionSeed,
    required BassStyle bassStyle,
    required int bassVariety,
    required GrooveTemplate grooveTemplate,
    GeneratedSongSection? repetitionSource,
  }) {
    final sectionRequest = request.copyWith(
      seed: sectionSeed,
      section: section.plan.harmonySection,
    );
    final progression = applyGrooveToProgression(
      section.progression,
      grooveTemplate,
    );
    final candidate = SongCandidate(
      progression: progression,
      score: section.candidate.score,
      seed: section.candidate.seed,
      candidateIndex: section.candidate.candidateIndex,
      section: section.candidate.section,
    );

    final rawMelody = request.includeMelody
        ? _phraseComposer
            .compose(
              random: Random(sectionRequest.melodySeed),
              progression: progression,
              genre: request.genre,
              rhythm: request.rhythm,
              key: request.key,
              section: section.plan,
              sourceMelody:
                  repetitionSource?.melody ?? const <MelodyNote>[],
              sourceChordCount: repetitionSource?.progression.length ?? 0,
            )
            .melody
        : const <MelodyNote>[];
    final melody = request.includeMelody
        ? _emotionShaper.shapeMelody(
            melody: rawMelody,
            mood: request.mood,
            section: section.plan,
          )
        : const <MelodyNote>[];

    final rawBass = request.includeBass
        ? _generation.generateBass(
            random: Random(sectionRequest.bassSeed),
            progression: progression,
            style: bassStyle,
            variety: bassVariety,
            rhythm: request.rhythm,
          )
        : const <BassNote>[];
    final bass = request.includeBass
        ? _emotionShaper.shapeBass(
            bass: rawBass,
            mood: request.mood,
            section: section.plan,
          )
        : const <BassNote>[];

    return GeneratedSongSection(
      plan: section.plan,
      candidate: candidate,
      melody: melody,
      bass: bass,
    );
  }

  /// Repetition identity for regeneration must come from an earlier section,
  /// never a later variation. Verse 2 may reference Verse 1; Verse 1 must not
  /// accidentally use Verse 2 as its source just because the draft is complete.
  GeneratedSongSection? _priorRepetitionReference(
    SongDraft draft,
    SongSectionPlan target,
  ) {
    final group = target.repetitionGroup;
    if (group == null) return null;
    final targetIndex =
        draft.plan.sections.indexWhere((section) => section.id == target.id);
    if (targetIndex <= 0) return null;

    for (var i = 0; i < targetIndex; i++) {
      final planSection = draft.plan.sections[i];
      if (planSection.repetitionGroup != group) continue;
      final generated = draft.sectionById(planSection.id);
      if (generated != null && generated.melody.isNotEmpty) return generated;
    }
    return null;
  }

  int _regenerationPlanSeed(int baseSeed, String sectionId, int revision) {
    var value = (baseSeed & 0x7fffffff) ^
        ((revision * 0x45d9f3b) & 0x7fffffff);
    for (final codeUnit in sectionId.codeUnits) {
      value = ((value * 33) ^ codeUnit) & 0x7fffffff;
    }
    value = ((value ^ (value >> 16)) * 0x45d9f3b) & 0x7fffffff;
    value = (value ^ (value >> 16)) & 0x7fffffff;
    return value;
  }
}
