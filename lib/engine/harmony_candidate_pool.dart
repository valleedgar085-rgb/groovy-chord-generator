import '../models/types.dart';
import 'harmony_engine.dart';
import 'song_candidate.dart';
import 'song_request.dart';

/// Builds several harmonic candidates and lets [HarmonyEngine] keep the best.
///
/// Generation and ranking stay separate on purpose: AppState can keep using
/// its existing chord-construction pipeline while the producer brain evaluates
/// multiple alternatives before committing one to playback/export.
class HarmonyCandidatePool {
  HarmonyCandidatePool({HarmonyEngine? engine})
      : _engine = engine ?? HarmonyEngine();

  final HarmonyEngine _engine;

  /// Generate [candidateCount] alternatives with [buildCandidate], then select
  /// the strongest progression for the requested song [section].
  ///
  /// This legacy-compatible API remains available while generation call sites
  /// migrate to the deterministic [SongRequest] contract.
  List<Chord> generateBest({
    required List<Chord> Function() buildCandidate,
    int candidateCount = 8,
    HarmonySection section = HarmonySection.neutral,
    bool applyVoicing = true,
  }) {
    final count = candidateCount.clamp(1, 32).toInt();
    final candidates = List<List<Chord>>.generate(
      count,
      (_) => List<Chord>.from(buildCandidate()),
      growable: false,
    ).where((candidate) => candidate.length >= 2).toList(growable: false);

    if (candidates.isEmpty) return const <Chord>[];

    return _engine.selectBest(
      candidates,
      section: section,
      applyVoicing: applyVoicing,
    );
  }

  /// Returns every candidate and its score for diagnostics, testing, or a
  /// future "show me alternatives" UI without changing selection behavior.
  List<ScoredHarmonyCandidate> generateScored({
    required List<Chord> Function() buildCandidate,
    int candidateCount = 8,
    HarmonySection section = HarmonySection.neutral,
  }) {
    final count = candidateCount.clamp(1, 32).toInt();
    final scored = <ScoredHarmonyCandidate>[];

    for (var i = 0; i < count; i++) {
      final candidate = List<Chord>.from(buildCandidate());
      if (candidate.length < 2) continue;
      scored.add(ScoredHarmonyCandidate(
        progression: List<Chord>.unmodifiable(candidate),
        score: _engine.score(candidate, section: section),
      ));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return List<ScoredHarmonyCandidate>.unmodifiable(scored);
  }

  /// Deterministic producer-core API.
  ///
  /// Every candidate receives a stable seed derived from [request]. As long as
  /// [buildCandidate] uses only that seed for randomness, replaying the same
  /// request yields the same candidate set and ranking.
  List<SongCandidate> generateScoredDeterministic({
    required SongRequest request,
    required List<Chord> Function(int candidateSeed) buildCandidate,
  }) {
    final scored = <SongCandidate>[];

    for (var i = 0; i < request.candidateCount; i++) {
      final candidateSeed = request.candidateSeed(i);
      final progression = List<Chord>.from(buildCandidate(candidateSeed));
      if (progression.length < 2) continue;

      scored.add(SongCandidate(
        progression: List<Chord>.unmodifiable(progression),
        score: _engine.score(progression, section: request.section),
        seed: candidateSeed,
        candidateIndex: i,
        section: request.section,
      ));
    }

    scored.sort((a, b) {
      final scoreOrder = b.score.compareTo(a.score);
      if (scoreOrder != 0) return scoreOrder;
      return a.candidateIndex.compareTo(b.candidateIndex);
    });

    return List<SongCandidate>.unmodifiable(scored);
  }

  /// Returns the best deterministic candidate and optionally applies final
  /// voice leading after ranking, matching the existing producer workflow.
  SongCandidate? generateBestDeterministic({
    required SongRequest request,
    required List<Chord> Function(int candidateSeed) buildCandidate,
  }) {
    final candidates = generateScoredDeterministic(
      request: request,
      buildCandidate: buildCandidate,
    );
    if (candidates.isEmpty) return null;

    final best = candidates.first;
    final progression = request.useVoiceLeading
        ? _engine.selectBest(
            [best.progression],
            section: request.section,
            applyVoicing: true,
          )
        : List<Chord>.from(best.progression);

    return SongCandidate(
      progression: List<Chord>.unmodifiable(progression),
      score: best.score,
      seed: best.seed,
      candidateIndex: best.candidateIndex,
      section: best.section,
    );
  }

  /// App-facing deterministic API. The callback receives both the stable seed
  /// and candidate index so later A/B/C tooling can preserve candidate identity.
  /// Final voicing intentionally remains outside this method so ranking always
  /// evaluates raw harmony and AppState can apply performance processing once.
  SongCandidate generateBestForRequest({
    required SongRequest request,
    required List<Chord> Function(int candidateSeed, int candidateIndex)
        buildCandidate,
  }) {
    final candidates = <SongCandidate>[];

    for (var i = 0; i < request.candidateCount; i++) {
      final candidateSeed = request.candidateSeed(i);
      final progression =
          List<Chord>.from(buildCandidate(candidateSeed, i));
      if (progression.length < 2) continue;
      candidates.add(SongCandidate(
        progression: List<Chord>.unmodifiable(progression),
        score: _engine.score(progression, section: request.section),
        seed: candidateSeed,
        candidateIndex: i,
        section: request.section,
      ));
    }

    candidates.sort((a, b) {
      final scoreOrder = b.score.compareTo(a.score);
      if (scoreOrder != 0) return scoreOrder;
      return a.candidateIndex.compareTo(b.candidateIndex);
    });

    if (candidates.isNotEmpty) return candidates.first;
    return SongCandidate(
      progression: const <Chord>[],
      score: 0.0,
      seed: request.seed,
      candidateIndex: -1,
      section: request.section,
    );
  }
}

class ScoredHarmonyCandidate {
  const ScoredHarmonyCandidate({
    required this.progression,
    required this.score,
  });

  final List<Chord> progression;
  final double score;
}
