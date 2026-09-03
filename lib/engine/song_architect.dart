import '../models/types.dart';
import 'song_architecture.dart';
import 'song_draft.dart';
import 'song_request.dart';
import 'song_section_candidate_pool.dart';

typedef SectionCandidateBuilder = List<Chord> Function(
  SongSectionPlan section,
  int candidateSeed,
  int candidateIndex,
  List<Chord> repetitionReference,
);

/// Generates a connected multi-section song from one immutable request/plan.
///
/// The architect intentionally owns arrangement flow, while the supplied
/// candidate builder owns the musical generation details. This keeps section
/// planning, scoring, and concrete harmony generation independently testable.
class SongArchitect {
  SongArchitect({SongSectionCandidatePool? candidatePool})
      : _candidatePool = candidatePool ?? SongSectionCandidatePool();

  final SongSectionCandidatePool _candidatePool;

  SongDraft generate({
    required SongRequest request,
    required SongPlan plan,
    required SectionCandidateBuilder buildCandidate,
  }) {
    var draft = SongDraft(plan: plan);

    for (final section in plan.sections) {
      final previousProgression = draft.previousProgressionFor(section.id);
      final reference = draft.repetitionReferenceFor(section.id);
      final repetitionProgression = reference?.progression ?? const <Chord>[];

      final winner = _candidatePool.generateBest(
        request: request,
        plan: plan,
        sectionId: section.id,
        previousProgression: previousProgression,
        repetitionReference: repetitionProgression,
        buildCandidate: (candidateSeed, candidateIndex) => buildCandidate(
          section,
          candidateSeed,
          candidateIndex,
          repetitionProgression,
        ),
      );

      draft = draft.withSection(GeneratedSongSection(
        plan: section,
        candidate: winner,
      ));
    }

    return draft;
  }
}
