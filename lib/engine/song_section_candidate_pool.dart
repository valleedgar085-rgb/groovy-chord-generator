import '../models/types.dart';
import 'harmonic_realizer.dart';
import 'harmony_engine.dart';
import 'song_architecture.dart';
import 'song_candidate.dart';
import 'song_request.dart';

/// Deterministic candidate selector for one section inside a [SongPlan].
///
/// Candidates are evaluated with neighboring section intent, the actual
/// previous-section progression, and optional repetition-group identity.
class SongSectionCandidatePool {
  SongSectionCandidatePool({
    HarmonyEngine? engine,
    HarmonicRealizer? realizer,
  })  : _engine = engine ?? HarmonyEngine(),
        _realizer = realizer ?? const HarmonicRealizer();

  final HarmonyEngine _engine;
  final HarmonicRealizer _realizer;

  SongCandidate generateBest({
    required SongRequest request,
    required SongPlan plan,
    required String sectionId,
    required List<Chord> Function(int candidateSeed, int candidateIndex)
        buildCandidate,
    List<Chord> previousProgression = const <Chord>[],
    List<Chord> repetitionReference = const <Chord>[],
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
      final raw = List<Chord>.from(buildCandidate(candidateSeed, i));
      final progression = _realizer.repairProgression(raw, sectionRequest);
      if (progression.length < 2) continue;

      var score = _engine.score(
        progression,
        section: section.harmonySection,
        context: context,
      );
      if (section.repetitionGroup != null && repetitionReference.isNotEmpty) {
        score += _repetitionIdentityScore(
          progression,
          repetitionReference,
          section.variation,
        );
      }
      score = score.clamp(0.0, 100.0).toDouble();

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

  /// Rewards recognizable harmonic identity while allowing planned evolution.
  /// Variation 0 expects a close repeat, variation 1 allows moderate movement,
  /// and variation 2+ only applies a light family resemblance preference.
  double _repetitionIdentityScore(
    List<Chord> candidate,
    List<Chord> reference,
    int variation,
  ) {
    final compared = candidate.length < reference.length
        ? candidate.length
        : reference.length;
    if (compared == 0) return 0.0;

    var exactMatches = 0;
    var functionalMatches = 0;
    for (var i = 0; i < compared; i++) {
      final current = candidate[i];
      final original = reference[i];
      if (current.degree == original.degree) {
        exactMatches++;
      } else if (_sameFunction(current.degree, original.degree)) {
        functionalMatches++;
      }
    }

    final exactRatio = exactMatches / compared;
    final familyRatio = (exactMatches + functionalMatches * 0.5) / compared;
    final lengthPenalty = (candidate.length - reference.length).abs() * 0.75;

    if (variation <= 0) {
      return (exactRatio * 8.0 - (1.0 - exactRatio) * 4.0 - lengthPenalty)
          .clamp(-6.0, 8.0)
          .toDouble();
    }
    if (variation == 1) {
      return (familyRatio * 5.0 - lengthPenalty)
          .clamp(-3.0, 5.0)
          .toDouble();
    }
    return (familyRatio * 2.0 - lengthPenalty * 0.5)
        .clamp(-2.0, 2.0)
        .toDouble();
  }

  bool _sameFunction(String a, String b) {
    const tonic = {'I', 'i', 'iii', 'III', 'vi', 'VI'};
    const subdominant = {'ii', 'II', 'IV', 'iv'};
    const dominant = {'V', 'v', 'V7', 'V/V', 'vii', 'VII'};

    return (tonic.contains(a) && tonic.contains(b)) ||
        (subdominant.contains(a) && subdominant.contains(b)) ||
        (dominant.contains(a) && dominant.contains(b));
  }
}
