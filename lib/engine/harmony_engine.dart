import 'dart:math';

import '../models/types.dart';
import '../utils/music_theory.dart';

/// Musical role of a song section.
///
/// The same progression can be excellent for a verse and wrong for a chorus,
/// so section intent is part of producer-level harmonic decision making.
enum HarmonySection { neutral, verse, preChorus, chorus, bridge }

/// A reusable, UI-independent harmonic quality layer.
///
/// Chord Flow can use this engine to rank candidate progressions before they
/// reach playback/export. Keeping scoring here also lets MidiArcade consume
/// the same harmonic policy later without duplicating UI/provider logic.
class HarmonyEngine {
  HarmonyEngine({int? seed}) : _random = Random(seed);

  static const double _epsilon = 0.000001;
  final Random _random;

  /// Returns the strongest candidate according to harmonic motion, cadence,
  /// repetition control, complexity balance, voice-leading potential, and
  /// optional section intent.
  ///
  /// A seeded random choice is used only among truly tied best candidates.
  /// Randomness can never make a lower-scoring progression win.
  List<Chord> selectBest(
    List<List<Chord>> candidates, {
    bool applyVoicing = true,
    HarmonySection section = HarmonySection.neutral,
  }) {
    if (candidates.isEmpty) return const <Chord>[];

    var bestScore = double.negativeInfinity;
    final tiedBest = <List<Chord>>[];

    for (final candidate in candidates) {
      final candidateScore = score(candidate, section: section);
      if (candidateScore > bestScore + _epsilon) {
        bestScore = candidateScore;
        tiedBest
          ..clear()
          ..add(candidate);
      } else if ((candidateScore - bestScore).abs() <= _epsilon) {
        tiedBest.add(candidate);
      }
    }

    final best = tiedBest.length == 1
        ? tiedBest.first
        : tiedBest[_random.nextInt(tiedBest.length)];

    return applyVoicing ? applyVoiceLeading(best) : List<Chord>.from(best);
  }

  /// Scores a progression on a 0-100 producer-oriented quality scale.
  double score(
    List<Chord> progression, {
    HarmonySection section = HarmonySection.neutral,
  }) {
    if (progression.length < 2) return 0;

    var value = 50.0;
    value += _motionScore(progression);
    value += _cadenceScore(progression);
    value += _repetitionScore(progression);
    value += _complexityScore(progression);
    value += _voiceLeadingPotential(progression);
    value += _sectionScore(progression, section);

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
    if (_isDominant(last)) return 3.0;
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

  double _sectionScore(List<Chord> progression, HarmonySection section) {
    if (section == HarmonySection.neutral) return 0.0;

    final last = progression.last.degree;
    final penultimate = progression[progression.length - 2].degree;
    final resolvesHome = _isDominant(penultimate) && _isPrimaryTonic(last);
    final endsDominant = _isDominant(last);
    final startsHome = _isPrimaryTonic(progression.first.degree);
    final alteredCount = progression.where((chord) =>
        chord.isBorrowed ||
        chord.isSecondaryDominant ||
        chord.isTritoneSubstitution).length;

    switch (section) {
      case HarmonySection.verse:
        var value = startsHome ? 2.0 : 0.0;
        if (resolvesHome) value += 2.0;
        if (alteredCount > 1) value -= 2.5;
        return value;
      case HarmonySection.preChorus:
        // A pre-chorus must lean forward strongly enough to outweigh the
        // generic cadence bonus that a complete V-I resolution receives.
        var value = endsDominant ? 7.0 : 0.0;
        if (resolvesHome) value -= 8.0;
        return value;
      case HarmonySection.chorus:
        var value = resolvesHome ? 8.0 : 0.0;
        if (_isPrimaryTonic(last)) value += 2.0;
        return value;
      case HarmonySection.bridge:
        if (alteredCount == 1) return 6.0;
        if (alteredCount == 2 && progression.length >= 6) return 3.0;
        if (alteredCount > 2) return -4.0;
        return 0.5;
      case HarmonySection.neutral:
        return 0.0;
    }
  }

  bool _isStrongResolution(String from, String to) =>
      (_isDominant(from) && _isTonic(to)) ||
      (_isSubdominant(from) && _isDominant(to));

  bool _isPrimaryTonic(String degree) => degree == 'I' || degree == 'i';

  bool _isTonic(String degree) =>
      _isPrimaryTonic(degree) || degree == 'vi' || degree == 'VI';

  bool _isDominant(String degree) =>
      degree == 'V' || degree == 'v' || degree == 'V7' || degree == 'V/V';

  bool _isSubdominant(String degree) =>
      degree == 'IV' || degree == 'iv' || degree == 'ii' || degree == 'II';
}
