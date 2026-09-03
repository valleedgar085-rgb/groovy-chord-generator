import 'dart:math';

import '../models/types.dart';
import '../utils/music_theory.dart';

/// A reusable, UI-independent harmonic quality layer.
///
/// Chord Flow can use this engine to rank candidate progressions before they
/// reach playback/export. Keeping scoring here also lets MidiArcade consume
/// the same harmonic policy later without duplicating UI/provider logic.
class HarmonyEngine {
  HarmonyEngine({int? seed}) : _random = Random(seed);

  final Random _random;

  /// Returns the strongest candidate according to harmonic motion, cadence,
  /// repetition control, complexity balance, and voice-leading potential.
  List<Chord> selectBest(
    List<List<Chord>> candidates, {
    bool applyVoicing = true,
  }) {
    if (candidates.isEmpty) return const <Chord>[];

    var best = candidates.first;
    var bestScore = score(best);

    for (final candidate in candidates.skip(1)) {
      final candidateScore = score(candidate);
      if (candidateScore > bestScore) {
        best = candidate;
        bestScore = candidateScore;
      } else if (candidateScore == bestScore) {
        // Tiny seeded jitter prevents identical-score candidates from always
        // choosing the first item while remaining reproducible in tests.
        final tieBreak = (_random.nextDouble() - 0.5) * 0.001;
        if (tieBreak > 0) {
          best = candidate;
        }
      }
    }

    return applyVoicing ? applyVoiceLeading(best) : List<Chord>.from(best);
  }

  /// Scores a progression on a 0-100 producer-oriented quality scale.
  double score(List<Chord> progression) {
    if (progression.length < 2) return 0;

    var value = 50.0;
    value += _motionScore(progression);
    value += _cadenceScore(progression);
    value += _repetitionScore(progression);
    value += _complexityScore(progression);
    value += _voiceLeadingPotential(progression);

    return value.clamp(0.0, 100.0).toDouble();
  }

  double _motionScore(List<Chord> progression) {
    var score = 0.0;
    for (var i = 1; i < progression.length; i++) {
      final previous = progression[i - 1].degree;
      final current = progression[i].degree;
      if (_isStrongResolution(previous, current)) {
        score += 4.0;
      } else if (previous == current) {
        score -= 3.0;
      } else {
        score += 0.75;
      }
    }
    return score.clamp(-10.0, 14.0).toDouble();
  }

  double _cadenceScore(List<Chord> progression) {
    final penultimate = progression[progression.length - 2].degree;
    final last = progression.last.degree;

    if (_isDominant(penultimate) && _isTonic(last)) return 12.0;
    if (_isSubdominant(penultimate) && _isTonic(last)) return 7.0;
    if (_isDominant(last)) return 3.0; // useful unresolved loop tension
    return 0.0;
  }

  double _repetitionScore(List<Chord> progression) {
    var penalty = 0.0;
    var run = 1;
    for (var i = 1; i < progression.length; i++) {
      if (progression[i].degree == progression[i - 1].degree) {
        run++;
        penalty += run >= 3 ? 5.0 : 2.0;
      } else {
        run = 1;
      }
    }
    return -penalty.clamp(0.0, 14.0).toDouble();
  }

  double _complexityScore(List<Chord> progression) {
    final altered = progression.where((chord) =>
        chord.isBorrowed ||
        chord.isSecondaryDominant ||
        chord.isTritoneSubstitution).length;
    final ratio = altered / progression.length;

    // Reward tasteful color, penalize harmony that becomes substitutions all
    // the time. This keeps "advanced" musical rather than merely complicated.
    if (ratio == 0) return 0.0;
    if (ratio <= 0.34) return 5.0;
    if (ratio <= 0.5) return 1.0;
    return -8.0;
  }

  double _voiceLeadingPotential(List<Chord> progression) {
    var score = 0.0;
    for (var i = 1; i < progression.length; i++) {
      final a = getChordNotes(progression[i - 1]);
      final b = getChordNotes(progression[i]);
      var nearestTotal = 0;
      for (final note in b) {
        final pitch = getNoteIndex(note);
        var nearest = 12;
        for (final previous in a) {
          final previousPitch = getNoteIndex(previous);
          final raw = (pitch - previousPitch).abs();
          final distance = min(raw, 12 - raw);
          nearest = min(nearest, distance);
        }
        nearestTotal += nearest;
      }
      final average = nearestTotal / b.length;
      score += average <= 2.0 ? 1.5 : (average >= 4.0 ? -1.0 : 0.25);
    }
    return score.clamp(-5.0, 7.0).toDouble();
  }

  bool _isStrongResolution(String from, String to) =>
      (_isDominant(from) && _isTonic(to)) ||
      (_isSubdominant(from) && _isDominant(to));

  bool _isTonic(String degree) =>
      degree == 'I' || degree == 'i' || degree == 'vi' || degree == 'VI';

  bool _isDominant(String degree) =>
      degree == 'V' || degree == 'v' || degree == 'V7' || degree == 'V/V';

  bool _isSubdominant(String degree) =>
      degree == 'IV' || degree == 'iv' || degree == 'ii' || degree == 'II';
}
