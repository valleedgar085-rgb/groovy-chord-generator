import 'dart:math';

import '../models/types.dart';
import '../utils/music_theory.dart';

/// Musical role of a song section.
///
/// The same progression can be excellent for a verse and wrong for a chorus,
/// so section intent is part of producer-level harmonic decision making.
enum HarmonySection { neutral, verse, preChorus, chorus, bridge }

/// Song-level context used when judging a progression as part of an arc rather
/// than as an isolated loop.
class HarmonyTransitionContext {
  const HarmonyTransitionContext({
    this.previousProgression = const <Chord>[],
    this.previousSection = HarmonySection.neutral,
    this.nextSection = HarmonySection.neutral,
    this.targetTension,
    this.targetEnergy,
  })  : assert(targetTension == null ||
            (targetTension >= 0.0 && targetTension <= 1.0)),
        assert(targetEnergy == null ||
            (targetEnergy >= 0.0 && targetEnergy <= 1.0));

  final List<Chord> previousProgression;
  final HarmonySection previousSection;
  final HarmonySection nextSection;
  final double? targetTension;
  final double? targetEnergy;
}

/// A reusable, UI-independent harmonic quality layer.
class HarmonyEngine {
  HarmonyEngine({int? seed}) : _random = Random(seed);

  static const double _epsilon = 0.000001;
  final Random _random;

  List<Chord> selectBest(
    List<List<Chord>> candidates, {
    bool applyVoicing = true,
    HarmonySection section = HarmonySection.neutral,
    HarmonyTransitionContext? context,
  }) {
    if (candidates.isEmpty) return const <Chord>[];

    var bestScore = double.negativeInfinity;
    final tiedBest = <List<Chord>>[];

    for (final candidate in candidates) {
      final candidateScore = score(
        candidate,
        section: section,
        context: context,
      );
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
  ///
  /// [context] adds song-arc awareness without changing the standalone score
  /// contract used by the current generator UI.
  double score(
    List<Chord> progression, {
    HarmonySection section = HarmonySection.neutral,
    HarmonyTransitionContext? context,
  }) {
    if (progression.length < 2) return 0;

    var value = 50.0;
    value += _motionScore(progression);
    value += _cadenceScore(progression);
    value += _repetitionScore(progression);
    value += _complexityScore(progression);
    value += _voiceLeadingPotential(progression);
    value += _functionalQualityScore(progression);
    value += _phraseDirectionScore(progression);
    value += _sectionScore(progression, section);
    if (context != null) {
      value += _transitionScore(progression, section, context);
      value += _targetTensionScore(progression, section, context.targetTension);
    }

    return value.clamp(0.0, 100.0).toDouble();
  }

  double _motionScore(List<Chord> progression) {
    var score = 0.0;
    for (var i = 1; i < progression.length; i++) {
      final previous = progression[i - 1].degree;
      final current = progression[i].degree;
      if (_isStrongResolution(previous, current)) {
        score += 4.0;
      } else if (_isDeceptiveResolution(previous, current)) {
        score += 2.25;
      } else if (_isSecondaryResolution(previous, current)) {
        score += 3.5;
      } else if (_baseDegree(previous) == _baseDegree(current)) {
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

    // Authentic cadence: V -> I/i is the strongest home arrival.
    if (_isDominant(penultimate) && _isPrimaryTonic(last)) return 12.0;
    // Deceptive cadence resolves dominant energy without pretending vi/VI is
    // literally the tonic. The previous engine over-rewarded this as +12.
    if (_isDeceptiveResolution(penultimate, last)) return 5.0;
    if (_isSubdominant(penultimate) && _isPrimaryTonic(last)) return 7.0;
    if (_isSecondaryResolution(penultimate, last)) return 6.0;
    if (_isDominant(last)) return 3.0;
    return 0.0;
  }

  double _repetitionScore(List<Chord> progression) {
    var penalty = 0.0;
    var run = 1;
    for (var i = 1; i < progression.length; i++) {
      if (_baseDegree(progression[i].degree) ==
          _baseDegree(progression[i - 1].degree)) {
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
      if (a.isEmpty || b.isEmpty) continue;
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

  /// Rejects obvious degree/quality contradictions before a candidate can win
  /// simply because its roots happen to move smoothly.
  double _functionalQualityScore(List<Chord> progression) {
    var value = 0.0;
    for (final chord in progression) {
      final degree = _baseDegree(chord.degree);
      final type = chord.type;

      if (chord.isSecondaryDominant || chord.degree.contains('/')) {
        value += type == ChordTypeName.dominant7 ? 2.0 : -5.0;
        continue;
      }

      if (degree == 'vii') {
        value += _isDiminishedFamily(type) ? 1.5 : -2.0;
        continue;
      }

      if (chord.isBorrowed || chord.isTritoneSubstitution) continue;

      final lowercase = degree == degree.toLowerCase();
      final uppercase = degree == degree.toUpperCase();
      if (lowercase && _isMajorFamily(type)) value -= 1.5;
      if (uppercase && _isMinorFamily(type)) value -= 1.5;

      if (_isDominant(degree) && type == ChordTypeName.dominant7) {
        value += 1.25;
      }
    }
    return value.clamp(-10.0, 7.0).toDouble();
  }

  /// Rewards phrase grammar such as predominant -> dominant -> tonic and
  /// secondary-dominant preparation rather than only inspecting the last pair.
  double _phraseDirectionScore(List<Chord> progression) {
    var value = 0.0;
    for (var i = 1; i < progression.length; i++) {
      final from = progression[i - 1].degree;
      final to = progression[i].degree;
      if (_isSubdominant(from) && _isDominant(to)) value += 1.5;
      if (_isSecondaryResolution(from, to)) value += 2.0;
      if (_isDominant(from) && _isPrimaryTonic(to)) value += 2.0;
    }

    for (var i = 2; i < progression.length; i++) {
      final a = progression[i - 2].degree;
      final b = progression[i - 1].degree;
      final c = progression[i].degree;
      if (_isSubdominant(a) && _isDominant(b) && _isPrimaryTonic(c)) {
        value += 3.0;
      }
      if (_baseDegree(a) == 'vi' &&
          _isSubdominant(b) &&
          _isDominant(c)) {
        value += 1.5;
      }
    }
    return value.clamp(-4.0, 8.0).toDouble();
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
        var value = endsDominant ? 10.0 : 0.0;
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

  double _transitionScore(
    List<Chord> progression,
    HarmonySection section,
    HarmonyTransitionContext context,
  ) {
    var value = 0.0;
    final previous = context.previousProgression;

    if (previous.isNotEmpty) {
      final previousLast = previous.last.degree;
      final currentFirst = progression.first.degree;

      if (_isDominant(previousLast) && _isPrimaryTonic(currentFirst)) {
        value += section == HarmonySection.chorus ? 9.0 : 5.0;
      } else if (_isSubdominant(previousLast) && _isDominant(currentFirst)) {
        value += 3.0;
      } else if (_isSecondaryResolution(previousLast, currentFirst)) {
        value += 3.0;
      }

      if (_baseDegree(previousLast) == _baseDegree(currentFirst)) value -= 4.0;

      if (context.previousSection == HarmonySection.bridge &&
          section == HarmonySection.chorus &&
          _isPrimaryTonic(currentFirst)) {
        value += 3.0;
      }
    }

    if (section == HarmonySection.preChorus &&
        context.nextSection == HarmonySection.chorus) {
      if (_isDominant(progression.last.degree)) value += 6.0;
      if (_isPrimaryTonic(progression.last.degree)) value -= 4.0;
    }

    if (section == HarmonySection.verse &&
        context.nextSection == HarmonySection.preChorus &&
        _isDominant(progression.last.degree)) {
      value -= 2.0;
    }

    return value.clamp(-10.0, 14.0).toDouble();
  }

  double _targetTensionScore(
    List<Chord> progression,
    HarmonySection section,
    double? targetTension,
  ) {
    if (targetTension == null) return 0.0;

    var estimated = 0.35;
    final last = progression.last.degree;
    final penultimate = progression[progression.length - 2].degree;
    final alteredRatio = progression.where((chord) =>
        chord.isBorrowed ||
        chord.isSecondaryDominant ||
        chord.isTritoneSubstitution).length / progression.length;

    if (_isDominant(last)) estimated += 0.28;
    if (_isDominant(penultimate) && _isPrimaryTonic(last)) estimated -= 0.15;
    estimated += alteredRatio * 0.25;
    if (section == HarmonySection.chorus) estimated += 0.08;
    estimated = estimated.clamp(0.0, 1.0).toDouble();

    final distance = (estimated - targetTension).abs();
    if (distance <= 0.12) return 4.0;
    if (distance <= 0.25) return 1.5;
    if (distance >= 0.50) return -4.0;
    return -1.0;
  }

  bool _isStrongResolution(String from, String to) =>
      (_isDominant(from) && _isPrimaryTonic(to)) ||
      (_isSubdominant(from) && _isDominant(to));

  bool _isDeceptiveResolution(String from, String to) {
    if (!_isDominant(from)) return false;
    final target = _baseDegree(to);
    return target == 'vi' || target == 'VI';
  }

  bool _isSecondaryResolution(String from, String to) =>
      from.contains('/') && _baseDegree(from) == 'V' && _baseDegree(to) == 'V';

  bool _isPrimaryTonic(String degree) {
    final base = _baseDegree(degree);
    return base == 'I' || base == 'i';
  }

  bool _isDominant(String degree) {
    final base = _baseDegree(degree);
    return base == 'V' || base == 'v';
  }

  bool _isSubdominant(String degree) {
    final base = _baseDegree(degree);
    return base == 'IV' || base == 'iv' || base == 'ii' || base == 'II';
  }

  String _baseDegree(String degree) {
    final trimmed = degree.trim();
    if (trimmed.contains('/')) {
      final beforeSlash = trimmed.split('/').first;
      final match = RegExp(r'^([b#]?[IViv]+)').firstMatch(beforeSlash);
      return match?.group(1) ?? beforeSlash;
    }
    final match = RegExp(r'^([b#]?[IViv]+)').firstMatch(trimmed);
    return match?.group(1) ?? trimmed;
  }

  bool _isMajorFamily(ChordTypeName type) =>
      type == ChordTypeName.major ||
      type == ChordTypeName.major7 ||
      type == ChordTypeName.major9 ||
      type == ChordTypeName.add9 ||
      type == ChordTypeName.sus2 ||
      type == ChordTypeName.sus4 ||
      type == ChordTypeName.dominant7;

  bool _isMinorFamily(ChordTypeName type) =>
      type == ChordTypeName.minor ||
      type == ChordTypeName.minor7 ||
      type == ChordTypeName.minor9;

  bool _isDiminishedFamily(ChordTypeName type) =>
      type == ChordTypeName.diminished ||
      type == ChordTypeName.diminished7 ||
      type == ChordTypeName.halfDim7;
}
