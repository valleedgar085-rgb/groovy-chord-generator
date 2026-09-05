import 'dart:math';

import '../models/types.dart';
import '../utils/music_theory.dart';
import 'song_architecture.dart';
import 'song_draft.dart';
import 'song_memory.dart';

enum SongDirectorDimension {
  structure,
  transitions,
  chorusPayoff,
  motifRecall,
  energyCurve,
  sectionContrast,
  ending,
}

class SongDirectorMetric {
  const SongDirectorMetric({
    required this.dimension,
    required this.label,
    required this.score,
    required this.insight,
    required this.action,
    this.weight = 1.0,
    this.active = true,
  });

  final SongDirectorDimension dimension;
  final String label;
  final double score;
  final String insight;
  final String action;
  final double weight;
  final bool active;

  bool get needsAttention => active && score < 72.0;
  bool get isStrength => active && score >= 85.0;
}

class SongTransitionAssessment {
  const SongTransitionAssessment({
    required this.fromSectionId,
    required this.toSectionId,
    required this.score,
    required this.harmonyContinuity,
    required this.bassContinuity,
    required this.melodyHandoff,
    required this.energyHandoff,
    required this.action,
  });

  final String fromSectionId;
  final String toSectionId;
  final double score;
  final double harmonyContinuity;
  final double bassContinuity;
  final double melodyHandoff;
  final double energyHandoff;
  final String action;

  String get label => '$fromSectionId → $toSectionId';
}

class SongSectionAssessment {
  const SongSectionAssessment({
    required this.sectionId,
    required this.type,
    required this.score,
    required this.energyFit,
    required this.identityFit,
    required this.candidateScore,
  });

  final String sectionId;
  final SongSectionType type;
  final double score;
  final double energyFit;
  final double identityFit;
  final double candidateScore;
}

class SongDirectorAnalysis {
  SongDirectorAnalysis({
    required this.overallScore,
    required List<SongDirectorMetric> metrics,
    required List<SongTransitionAssessment> transitions,
    required List<SongSectionAssessment> sections,
  })  : metrics = List<SongDirectorMetric>.unmodifiable(metrics),
        transitions = List<SongTransitionAssessment>.unmodifiable(transitions),
        sections = List<SongSectionAssessment>.unmodifiable(sections);

  factory SongDirectorAnalysis.empty() => SongDirectorAnalysis(
        overallScore: 0,
        metrics: const <SongDirectorMetric>[],
        transitions: const <SongTransitionAssessment>[],
        sections: const <SongSectionAssessment>[],
      );

  final double overallScore;
  final List<SongDirectorMetric> metrics;
  final List<SongTransitionAssessment> transitions;
  final List<SongSectionAssessment> sections;

  SongDirectorMetric? metricFor(SongDirectorDimension dimension) {
    for (final metric in metrics) {
      if (metric.dimension == dimension) return metric;
    }
    return null;
  }

  SongDirectorMetric? get weakestMetric {
    final active = metrics.where((metric) => metric.active).toList(growable: false);
    if (active.isEmpty) return null;
    return active.reduce((a, b) => a.score <= b.score ? a : b);
  }

  SongTransitionAssessment? get weakestTransition {
    if (transitions.isEmpty) return null;
    return transitions.reduce((a, b) => a.score <= b.score ? a : b);
  }

  SongSectionAssessment? get weakestSection {
    if (sections.isEmpty) return null;
    return sections.reduce((a, b) => a.score <= b.score ? a : b);
  }

  String get weakestLinkLabel {
    final metric = weakestMetric;
    final transition = weakestTransition;
    if (transition != null &&
        (metric == null || transition.score + 3.0 < metric.score)) {
      return transition.label;
    }
    return metric?.label ?? 'Song';
  }

  double get weakestLinkScore {
    final metric = weakestMetric;
    final transition = weakestTransition;
    if (transition != null &&
        (metric == null || transition.score + 3.0 < metric.score)) {
      return transition.score;
    }
    return metric?.score ?? 0.0;
  }

  String get weakestLinkAction {
    final metric = weakestMetric;
    final transition = weakestTransition;
    if (transition != null &&
        (metric == null || transition.score + 3.0 < metric.score)) {
      return transition.action;
    }
    return metric?.action ?? 'Generate a complete song to unlock Director guidance.';
  }

  List<SongDirectorMetric> get priorities {
    final result = metrics.where((metric) => metric.active).toList()
      ..sort((a, b) => a.score.compareTo(b.score));
    return List<SongDirectorMetric>.unmodifiable(result.take(3));
  }
}

/// Phase 5.5 arrangement-level Producer intelligence.
///
/// Producer Brain judges local musical material. Song Director judges whether
/// those parts form a convincing complete song: build/release, section identity,
/// transitions, hook payoff, contrast and ending behavior.
class SongDirectorAnalyzer {
  const SongDirectorAnalyzer();

  SongDirectorAnalysis analyze({
    required SongDraft draft,
    SongMemory? memory,
  }) {
    if (draft.sections.isEmpty) return SongDirectorAnalysis.empty();

    final transitions = _transitionAssessments(draft);
    final sections = _sectionAssessments(draft, memory);
    final metrics = <SongDirectorMetric>[
      _structureMetric(draft),
      _transitionMetric(transitions),
      _chorusPayoffMetric(draft),
      _motifRecallMetric(draft, memory),
      _energyCurveMetric(draft),
      _sectionContrastMetric(draft, memory),
      _endingMetric(draft),
    ];

    var weighted = 0.0;
    var totalWeight = 0.0;
    for (final metric in metrics) {
      if (!metric.active) continue;
      weighted += metric.score * metric.weight;
      totalWeight += metric.weight;
    }

    final overall = totalWeight == 0 ? 0.0 : weighted / totalWeight;
    return SongDirectorAnalysis(
      overallScore: _score(overall),
      metrics: metrics,
      transitions: transitions,
      sections: sections,
    );
  }

  SongDirectorMetric _structureMetric(SongDraft draft) {
    final plan = draft.plan;
    final generated = draft.sections;
    final completeness = generated.length / max(1, plan.sections.length);
    final types = generated.map((section) => section.plan.type).toSet();
    final hasVerse = types.contains(SongSectionType.verse);
    final hasChorus = types.contains(SongSectionType.chorus);
    final hasContrast = types.contains(SongSectionType.bridge) ||
        types.contains(SongSectionType.preChorus);
    final hasEnding = types.contains(SongSectionType.outro);
    final roleCoverage = <bool>[hasVerse, hasChorus, hasContrast, hasEnding]
            .where((value) => value)
            .length /
        4.0;

    var orderChecks = 0;
    var orderHits = 0;
    for (var i = 1; i < generated.length; i++) {
      final previous = generated[i - 1].plan.type;
      final current = generated[i].plan.type;
      if (current == SongSectionType.chorus) {
        orderChecks++;
        if (previous == SongSectionType.preChorus ||
            previous == SongSectionType.verse ||
            previous == SongSectionType.bridge) {
          orderHits++;
        }
      }
      if (current == SongSectionType.outro) {
        orderChecks++;
        if (i == generated.length - 1) orderHits++;
      }
    }
    final orderScore = orderChecks == 0 ? 0.75 : orderHits / orderChecks;

    final totalBars = generated.fold<int>(0, (sum, section) => sum + section.plan.bars);
    final durationScore = totalBars >= 24 && totalBars <= 96
        ? 1.0
        : totalBars >= 16 && totalBars <= 128
            ? 0.78
            : 0.55;

    final value = _score(
      completeness * 42 +
          roleCoverage * 24 +
          orderScore * 22 +
          durationScore * 12,
    );
    return SongDirectorMetric(
      dimension: SongDirectorDimension.structure,
      label: 'Structure',
      score: value,
      weight: 0.17,
      insight:
          '${generated.length}/${plan.sections.length} planned sections, $totalBars bars, ${(roleCoverage * 100).round()}% core-role coverage.',
      action: value >= 85
          ? 'Preserve the arrangement skeleton; improve transitions and section development instead.'
          : 'Strengthen the verse → lift → chorus → contrast → final payoff arc before adding more detail.',
    );
  }

  SongDirectorMetric _transitionMetric(
    List<SongTransitionAssessment> transitions,
  ) {
    if (transitions.isEmpty) {
      return const SongDirectorMetric(
        dimension: SongDirectorDimension.transitions,
        label: 'Transitions',
        score: 0,
        weight: 0.18,
        insight: 'No adjacent section handoffs are available yet.',
        action: 'Generate at least two song sections to evaluate transitions.',
        active: false,
      );
    }
    final average = transitions.fold<double>(0, (sum, item) => sum + item.score) /
        transitions.length;
    final weakest = transitions.reduce((a, b) => a.score <= b.score ? a : b);
    final value = _score(average * 0.76 + weakest.score * 0.24);
    return SongDirectorMetric(
      dimension: SongDirectorDimension.transitions,
      label: 'Transitions',
      score: value,
      weight: 0.18,
      insight:
          'Average handoff ${average.round()}; weakest is ${weakest.label} at ${weakest.score.round()}.',
      action: value >= 85
          ? 'Keep the handoff language; reserve transition variation for later repeats.'
          : weakest.action,
    );
  }

  SongDirectorMetric _chorusPayoffMetric(SongDraft draft) {
    final choruses = draft.sections
        .where((section) => section.plan.type == SongSectionType.chorus)
        .toList(growable: false);
    if (choruses.isEmpty) {
      return const SongDirectorMetric(
        dimension: SongDirectorDimension.chorusPayoff,
        label: 'Chorus Payoff',
        score: 0,
        weight: 0.16,
        insight: 'This arrangement has no chorus section.',
        action: 'Add a hook/payoff section or use a genre structure with an equivalent drop/refrain.',
        active: false,
      );
    }

    var total = 0.0;
    for (final chorus in choruses) {
      final index = draft.sections.indexOf(chorus);
      final previous = index > 0 ? draft.sections[index - 1] : null;
      final chorusEnergy = _actualEnergy(chorus);
      final previousEnergy = previous == null ? max(0.0, chorusEnergy - 0.18) : _actualEnergy(previous);
      final actualLift = chorusEnergy - previousEnergy;
      final targetLift = previous == null
          ? 0.18
          : chorus.plan.targetEnergy - previous.plan.targetEnergy;
      final liftScore = _closeness(actualLift, targetLift, tolerance: 0.34);
      final targetFit = _closeness(
        chorusEnergy,
        chorus.plan.targetEnergy,
        tolerance: 0.48,
      );
      final melodic = _melodicPresenceScore(chorus);
      total += liftScore * 0.42 + targetFit * 0.30 + melodic * 0.28;
    }

    var value = total / choruses.length;
    final finalChorus = choruses.last;
    final maxOtherEnergy = draft.sections
        .where((section) => section.plan.id != finalChorus.plan.id)
        .map(_actualEnergy)
        .fold<double>(0.0, max);
    if (finalChorus.plan.variation >= 2) {
      value += _actualEnergy(finalChorus) + 0.02 >= maxOtherEnergy ? 6 : -8;
    }
    value = _score(value);

    return SongDirectorMetric(
      dimension: SongDirectorDimension.chorusPayoff,
      label: 'Chorus Payoff',
      score: value,
      weight: 0.16,
      insight:
          '${choruses.length} chorus moments; final payoff energy ${(_actualEnergy(finalChorus) * 100).round()}%.',
      action: value >= 85
          ? 'The chorus reads as a payoff; develop later choruses without losing the hook.'
          : 'Increase the arrival contrast: stronger pre-chorus tension, melodic lift, density or final-chorus escalation.',
    );
  }

  SongDirectorMetric _motifRecallMetric(SongDraft draft, SongMemory? memory) {
    if (memory == null || memory.sections.isEmpty) {
      return const SongDirectorMetric(
        dimension: SongDirectorDimension.motifRecall,
        label: 'Motif Recall',
        score: 0,
        weight: 0.14,
        insight: 'Song Memory is not available for motif comparison.',
        action: 'Capture Song Memory before judging repeated-section identity.',
        active: false,
      );
    }

    final scores = <double>[];
    final similarities = <double>[];
    for (final section in draft.sections) {
      final memorySection = memory.section(section.plan.id);
      if (memorySection == null ||
          memorySection.sourceSectionId == section.plan.id) {
        continue;
      }
      final source = memory.sourceFor(section.plan.id);
      if (source == null) continue;
      final similarity = memorySection.identitySimilarityTo(source);
      similarities.add(similarity);
      final target = section.plan.variation <= 0
          ? 0.88
          : section.plan.variation == 1
              ? 0.68
              : 0.54;
      scores.add(_closeness(similarity, target, tolerance: 0.36));
    }

    if (scores.isEmpty) {
      return const SongDirectorMetric(
        dimension: SongDirectorDimension.motifRecall,
        label: 'Motif Recall',
        score: 76,
        weight: 0.14,
        insight: 'No repeated-section family requires comparison in this arrangement.',
        action: 'Keep one recognizable motif family available for later song development.',
      );
    }

    final average = scores.reduce((a, b) => a + b) / scores.length;
    final averageSimilarity = similarities.reduce((a, b) => a + b) / similarities.length;
    final value = _score(average);
    return SongDirectorMetric(
      dimension: SongDirectorDimension.motifRecall,
      label: 'Motif Recall',
      score: value,
      weight: 0.14,
      insight:
          '${scores.length} developed repeats average ${(averageSimilarity * 100).round()}% source identity.',
      action: value >= 85
          ? 'Identity and development are balanced; preserve the recognizable cells.'
          : averageSimilarity < 0.45
              ? 'Recall more of the source motif, rhythm or harmonic skeleton in later repeats.'
              : 'Vary one dimension at a time so repeated sections evolve without becoming copy/paste.',
    );
  }

  SongDirectorMetric _energyCurveMetric(SongDraft draft) {
    final fits = <double>[];
    for (final section in draft.sections) {
      fits.add(_closeness(
        _actualEnergy(section),
        section.plan.targetEnergy,
        tolerance: 0.50,
      ));
    }
    var value = fits.reduce((a, b) => a + b) / fits.length;

    final choruses = draft.sections
        .where((section) => section.plan.type == SongSectionType.chorus)
        .toList(growable: false);
    final verses = draft.sections
        .where((section) => section.plan.type == SongSectionType.verse)
        .toList(growable: false);
    if (choruses.isNotEmpty && verses.isNotEmpty) {
      final chorusEnergy = choruses.map(_actualEnergy).reduce((a, b) => a + b) /
          choruses.length;
      final verseEnergy = verses.map(_actualEnergy).reduce((a, b) => a + b) /
          verses.length;
      value += chorusEnergy > verseEnergy + 0.04 ? 6 : -9;
    }
    if (draft.sections.last.plan.type == SongSectionType.outro &&
        draft.sections.length > 1) {
      final outro = _actualEnergy(draft.sections.last);
      final before = _actualEnergy(draft.sections[draft.sections.length - 2]);
      value += outro < before ? 4 : -6;
    }
    value = _score(value);

    return SongDirectorMetric(
      dimension: SongDirectorDimension.energyCurve,
      label: 'Energy Curve',
      score: value,
      weight: 0.14,
      insight:
          'Generated density/velocity follows ${(fits.reduce((a, b) => a + b) / fits.length).round()}% of the planned section-energy arc.',
      action: value >= 85
          ? 'The build/release curve is clear; keep section-level changes proportional.'
          : 'Separate verse, pre, chorus, bridge and outro energy more clearly using density, velocity and register.',
    );
  }

  SongDirectorMetric _sectionContrastMetric(SongDraft draft, SongMemory? memory) {
    final contrasts = <double>[];
    for (var i = 1; i < draft.sections.length; i++) {
      final a = draft.sections[i - 1];
      final b = draft.sections[i];
      if (a.plan.type == b.plan.type) continue;
      final energyDifference = (_actualEnergy(a) - _actualEnergy(b)).abs();
      final harmonicDifference = _harmonicDifference(a, b);
      contrasts.add(_score(
        min(1.0, energyDifference / 0.28) * 46 + harmonicDifference * 54,
      ));
    }

    if (memory != null) {
      final bridges = draft.sections
          .where((section) => section.plan.type == SongSectionType.bridge)
          .toList(growable: false);
      final choruses = draft.sections
          .where((section) => section.plan.type == SongSectionType.chorus)
          .toList(growable: false);
      if (bridges.isNotEmpty && choruses.isNotEmpty) {
        final similarity = memory.similarity(
          bridges.first.plan.id,
          choruses.first.plan.id,
        );
        contrasts.add(_closeness(similarity, 0.35, tolerance: 0.38));
      }
    }

    if (contrasts.isEmpty) {
      return const SongDirectorMetric(
        dimension: SongDirectorDimension.sectionContrast,
        label: 'Section Contrast',
        score: 70,
        weight: 0.11,
        insight: 'Not enough contrasting section types are available to judge contrast strongly.',
        action: 'Introduce a section with a different energy, contour, rhythm or harmonic function.',
      );
    }

    final average = contrasts.reduce((a, b) => a + b) / contrasts.length;
    final value = _score(average);
    return SongDirectorMetric(
      dimension: SongDirectorDimension.sectionContrast,
      label: 'Section Contrast',
      score: value,
      weight: 0.11,
      insight: '${contrasts.length} structural contrast points average ${value.round()}.',
      action: value >= 85
          ? 'Contrast is strong without losing continuity.'
          : 'Differentiate bridge/chorus/verse behavior while retaining shared motif identity.',
    );
  }

  SongDirectorMetric _endingMetric(SongDraft draft) {
    final ending = draft.sections.last;
    var value = ending.plan.type == SongSectionType.outro ? 24.0 : 10.0;
    final progression = ending.progression;
    if (progression.isNotEmpty) {
      final degree = progression.last.degree.toLowerCase();
      if (degree == 'i' || degree == '1') {
        value += 42;
      } else if (degree.startsWith('v')) {
        value += 10;
      } else {
        value += 26;
      }
    }
    if (draft.sections.length > 1) {
      final before = _actualEnergy(draft.sections[draft.sections.length - 2]);
      final outro = _actualEnergy(ending);
      value += outro <= before ? 24 : 10;
    } else {
      value += 16;
    }
    value += ending.candidate.score >= 75 ? 10 : 5;
    value = _score(value);

    return SongDirectorMetric(
      dimension: SongDirectorDimension.ending,
      label: 'Ending',
      score: value,
      weight: 0.10,
      insight:
          '${ending.plan.id} closes at ${(_actualEnergy(ending) * 100).round()}% estimated energy.',
      action: value >= 85
          ? 'The ending resolves the arrangement cleanly.'
          : 'Make the final cadence and energy release more deliberate; avoid ending on accidental unresolved tension.',
    );
  }

  List<SongTransitionAssessment> _transitionAssessments(SongDraft draft) {
    final result = <SongTransitionAssessment>[];
    for (var i = 1; i < draft.sections.length; i++) {
      final from = draft.sections[i - 1];
      final to = draft.sections[i];
      final harmony = _harmonyHandoff(from, to);
      final bass = _noteHandoff(
        from.bass.isEmpty ? null : _bassPitch(from.bass.last),
        to.bass.isEmpty ? null : _bassPitch(to.bass.first),
      );
      final melody = _noteHandoff(
        from.melody.isEmpty ? null : _melodyPitch(from.melody.last),
        to.melody.isEmpty ? null : _melodyPitch(to.melody.first),
      );
      final actualDelta = _actualEnergy(to) - _actualEnergy(from);
      final targetDelta = to.plan.targetEnergy - from.plan.targetEnergy;
      final energy = _closeness(actualDelta, targetDelta, tolerance: 0.42);
      final score = _score(
        harmony * 0.40 + bass * 0.18 + melody * 0.18 + energy * 0.24,
      );

      final parts = <MapEntry<String, double>>[
        MapEntry('harmony', harmony),
        MapEntry('bass movement', bass),
        MapEntry('melody handoff', melody),
        MapEntry('energy change', energy),
      ]..sort((a, b) => a.value.compareTo(b.value));
      final weakest = parts.first.key;
      result.add(SongTransitionAssessment(
        fromSectionId: from.plan.id,
        toSectionId: to.plan.id,
        score: score,
        harmonyContinuity: harmony,
        bassContinuity: bass,
        melodyHandoff: melody,
        energyHandoff: energy,
        action: 'Repair ${from.plan.id} → ${to.plan.id} by targeting its weakest handoff: $weakest.',
      ));
    }
    return List<SongTransitionAssessment>.unmodifiable(result);
  }

  List<SongSectionAssessment> _sectionAssessments(
    SongDraft draft,
    SongMemory? memory,
  ) {
    return draft.sections.map((section) {
      final energyFit = _closeness(
        _actualEnergy(section),
        section.plan.targetEnergy,
        tolerance: 0.50,
      );
      var identityFit = 82.0;
      final sectionMemory = memory?.section(section.plan.id);
      final source = memory?.sourceFor(section.plan.id);
      if (sectionMemory != null &&
          source != null &&
          sectionMemory.sourceSectionId != section.plan.id) {
        final similarity = sectionMemory.identitySimilarityTo(source);
        final target = section.plan.variation == 1 ? 0.68 : 0.54;
        identityFit = _closeness(similarity, target, tolerance: 0.36);
      }
      final candidate = section.candidate.score.clamp(0.0, 100.0).toDouble();
      return SongSectionAssessment(
        sectionId: section.plan.id,
        type: section.plan.type,
        score: _score(candidate * 0.45 + energyFit * 0.32 + identityFit * 0.23),
        energyFit: energyFit,
        identityFit: identityFit,
        candidateScore: candidate,
      );
    }).toList(growable: false);
  }

  double _harmonyHandoff(GeneratedSongSection from, GeneratedSongSection to) {
    if (from.progression.isEmpty || to.progression.isEmpty) return 60.0;
    final last = from.progression.last;
    final first = to.progression.first;
    final lastDegree = last.degree.toLowerCase();
    final firstDegree = first.degree.toLowerCase();

    if (lastDegree.startsWith('v') &&
        (firstDegree == 'i' || firstDegree == '1')) {
      return 100.0;
    }
    if (last.root == first.root && last.type == first.type) return 46.0;

    final fromIndex = getNoteIndex(last.root);
    final toIndex = getNoteIndex(first.root);
    final clockwise = (toIndex - fromIndex) % 12;
    final distance = min(clockwise, 12 - clockwise);
    if (clockwise == 5 || clockwise == 7) return 94.0;
    if (distance <= 2) return 86.0;
    if (distance <= 4) return 80.0;
    return 72.0;
  }

  double _noteHandoff(int? from, int? to) {
    if (from == null || to == null) return 72.0;
    final interval = (to - from).abs();
    if (interval <= 2) return 100.0;
    if (interval <= 5) return 92.0;
    if (interval <= 7) return 82.0;
    if (interval <= 12) return 66.0;
    return max(35.0, 62.0 - (interval - 12) * 2.4);
  }

  double _actualEnergy(GeneratedSongSection section) {
    final bars = max(1, section.plan.bars);
    final noteCount = section.melody.length + section.bass.length;
    final density = (noteCount / (bars * 12.0)).clamp(0.0, 1.0).toDouble();
    final velocities = <double>[
      ...section.melody.map((note) => note.velocity),
      ...section.bass.map((note) => note.velocity),
    ];
    final velocity = velocities.isEmpty
        ? 0.58
        : velocities.reduce((a, b) => a + b) / velocities.length;
    final chordDensity =
        (section.progression.length / (bars * 1.5)).clamp(0.0, 1.0).toDouble();
    final melodyPresence = section.melody.isEmpty ? 0.0 : 1.0;
    return (density * 0.34 +
            velocity.clamp(0.0, 1.0) * 0.34 +
            chordDensity * 0.18 +
            melodyPresence * 0.14)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double _melodicPresenceScore(GeneratedSongSection section) {
    if (section.melody.isEmpty) return 58.0;
    final pitches = section.melody.map(_melodyPitch).toList(growable: false);
    final range = pitches.reduce(max) - pitches.reduce(min);
    final rangeScore = range >= 5 && range <= 19
        ? 100.0
        : range <= 26
            ? 78.0
            : 58.0;
    final density = section.melody.length / max(1, section.plan.bars);
    final densityScore = _closeness(density, 5.0, tolerance: 4.5);
    return _score(rangeScore * 0.55 + densityScore * 0.45);
  }

  double _harmonicDifference(GeneratedSongSection a, GeneratedSongSection b) {
    if (a.progression.isEmpty || b.progression.isEmpty) return 0.5;
    final compared = min(a.progression.length, b.progression.length);
    var matches = 0;
    for (var i = 0; i < compared; i++) {
      if (a.progression[i].degree == b.progression[i].degree) matches++;
    }
    final ratio = matches / max(1, compared);
    return (1.0 - ratio).clamp(0.0, 1.0).toDouble();
  }

  int _melodyPitch(MelodyNote note) => noteToPitch(note.note, note.octave);
  int _bassPitch(BassNote note) => noteToPitch(note.note, note.octave);

  double _closeness(
    double value,
    double target, {
    required double tolerance,
  }) {
    if (tolerance <= 0) return value == target ? 100.0 : 0.0;
    final distance = (value - target).abs();
    return _score((1.0 - distance / tolerance) * 100.0);
  }

  double _score(num value) => value.clamp(0.0, 100.0).toDouble();
}
