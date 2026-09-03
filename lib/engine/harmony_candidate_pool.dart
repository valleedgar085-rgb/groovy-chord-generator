import '../models/types.dart';
import 'harmony_engine.dart';

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
  /// The callback is invoked independently for every candidate so existing
  /// stochastic generation code can naturally produce variation without being
  /// duplicated inside the ranking engine.
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
        progression: candidate,
        score: _engine.score(candidate, section: section),
      ));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return List<ScoredHarmonyCandidate>.unmodifiable(scored);
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
