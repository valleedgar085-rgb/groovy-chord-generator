import 'dart:math';

import '../models/types.dart';
import '../utils/music_theory.dart';
import 'seeded_harmony_builder.dart';
import 'seeded_music_generation.dart';
import 'song_architect.dart';
import 'song_architecture.dart';
import 'song_candidate.dart';
import 'song_draft.dart';
import 'song_request.dart';

/// Canonical full-song composition pipeline used by the live application.
///
/// This class deliberately has no Flutter/provider dependency. It composes the
/// arrangement with [SongArchitect], builds harmony through the same
/// [SeededHarmonyBuilder] used by single-progression generation, then attaches
/// deterministic melody, bass, and performance metadata per section.
class ProducerSongComposer {
  ProducerSongComposer({
    SongArchitect? architect,
    SeededHarmonyBuilder? harmonyBuilder,
    SeededMusicGeneration? generation,
  })  : _architect = architect ?? SongArchitect(),
        _harmonyBuilder = harmonyBuilder ?? const SeededHarmonyBuilder(),
        _generation = generation ?? const SeededMusicGeneration();

  final SongArchitect _architect;
  final SeededHarmonyBuilder _harmonyBuilder;
  final SeededMusicGeneration _generation;

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
      final sectionRequest = request.copyWith(
        seed: songPlan.sectionSeed(section.plan.id),
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

      final melody = request.includeMelody
          ? _generation.generateMelody(
              random: Random(sectionRequest.melodySeed),
              progression: progression,
              genre: request.genre,
              rhythm: request.rhythm,
              key: request.key,
            )
          : const <MelodyNote>[];
      final bass = request.includeBass
          ? _generation.generateBass(
              random: Random(sectionRequest.bassSeed),
              progression: progression,
              style: bassStyle,
              variety: bassVariety,
              rhythm: request.rhythm,
            )
          : const <BassNote>[];

      completed = completed.withSection(GeneratedSongSection(
        plan: section.plan,
        candidate: candidate,
        melody: melody,
        bass: bass,
      ));
    }

    return completed;
  }
}
