import '../models/types.dart';
import 'harmony_engine.dart';
import 'song_architecture.dart';
import 'song_candidate.dart';
import 'song_request.dart';

/// Deterministic candidate selector for one section inside a [SongPlan].
///
/// Unlike the legacy pool, candidates are evaluated with neighboring section
/// intent and the actual previous section progression.
class SongSectionCandidatePool {
  SongSectionCandidatePool({HarmonyEngine? engine})
      : _engine = engine ?? HarmonyEngine();

  final HarmonyEngine _engine;

  SongCandidate generateBest({
    required SongRequest request,
    required SongPlan plan,
    required String sectionId,
    required List<Chord> Function(int candidateSeed, int candidateIndex)
        buildCandidate,
    List<Chord> previousProgression = const <Chord>[],
  }) {
    final section = plan.sectionById(sectionId);
    if (section == null) {
      throw ArgumentError.value(sectionId, 'sectionId', 'Unknown song section');
    }

    final sectionRequest = request.copyWith(
      seed: plan.sectionSeed(sectionId),
      section: section.harmonySection,
    );
    final context = plan.harmonyContextFor(
      sectionId,
      previousProgression: previousProgression,
    );

    SongCandidate? best;
    for (var i = 0; i < sectionRequest.candidateCount; i++) {
      final candidateSeed = sectionRequest.candidateSeed(i);
      final progression = List<Chord>.from(buildCandidate(candidateSeed, i));
      if (progression.length < 2) continue;

      final score = _engine.score(
        progression,
        section: section.harmonySection,
        context: context,
      );
      final candidate = SongCandidate(
        progression: List<Chord>.unmodifiable(progression),
        score: score,
        seed: candidateSeed,
        candidateIndex: i,
        section: section.harmonySection,
      );

      if (best == null ||
          candidate.score > best.score ||
          (candidate.score == best.score &&
              candidate.candidateIndex < best.candidateIndex)) {
        best = candidate;
      }
    }

    if (best == null) {
      return SongCandidate(
        progression: const <Chord>[],
        score: 0.0,
        seed: sectionRequest.seed,
        candidateIndex: -1,
        section: section.harmonySection,
      );
    }

    if (!request.useVoiceLeading) return best;
    final voiced = _engine.selectBest(
      [best.progression],
      section: section.harmonySection,
      context: context,
      applyVoicing: true,
    );
    return SongCandidate(
      progression: List<Chord>.unmodifiable(voiced),
      score: best.score,
      seed: best.seed,
      candidateIndex: best.candidateIndex,
      section: best.section,
    );
  }
}
