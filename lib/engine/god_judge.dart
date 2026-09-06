import 'dart:math';

import '../models/types.dart';
import 'emotion_director.dart';
import 'phrase_producer_brain.dart';
import 'song_architecture.dart';
import 'song_director.dart';
import 'song_draft.dart';
import 'song_memory_extractor.dart';
import 'song_request.dart';
import 'song_timeline.dart';

/// Final verification dimensions. These intentionally overlap lower-level
/// analyzers: the God Judge is allowed to veto a strong average when one critical
/// musical subsystem is weak.
enum GodJudgeDimension {
  localCraft,
  arrangement,
  phraseIntelligence,
  emotion,
  transitionFloor,
  hookPayoff,
  performanceSafety,
  consistency,
}

class GodJudgeMetric {
  const GodJudgeMetric({
    required this.dimension,
    required this.label,
    required this.score,
    required this.minimum,
    required this.weight,
  });

  final GodJudgeDimension dimension;
  final String label;
  final double score;
  final double minimum;
  final double weight;

  bool get passesFloor => score + 0.0001 >= minimum;
}

class GodJudgeVerdict {
  GodJudgeVerdict({
    required this.score,
    required this.approved,
    required List<GodJudgeMetric> metrics,
    required List<String> blockers,
    required this.emotion,
    required this.director,
    required this.phrases,
  })  : metrics = List<GodJudgeMetric>.unmodifiable(metrics),
        blockers = List<String>.unmodifiable(blockers);

  final double score;
  final bool approved;
  final List<GodJudgeMetric> metrics;
  final List<String> blockers;
  final EmotionSongAnalysis emotion;
  final SongDirectorAnalysis director;
  final SongPhraseProducerAnalysis phrases;

  GodJudgeMetric get weakestMetric =>
      metrics.reduce((a, b) => a.score <= b.score ? a : b);

  String get grade {
    if (!approved) return 'HELD';
    if (score >= 94) return 'EXCEPTIONAL';
    if (score >= 89) return 'ELITE';
    return 'APPROVED';
  }
}

/// Phase 5.10 final-quality gate.
///
/// This is intentionally conservative. It is not a claim that music can be
/// objectively proven "99% awesome" by software; instead it makes the product
/// promise measurable: anything exposed by the final A/B/C preview has cleared
/// every machine-checkable musical floor we currently know how to enforce.
///
/// Song Director remains an important critic, but this final layer is explicitly
/// genre-aware. Phase 5.7 deliberately reused the legacy section enum for
/// compatibility while encoding roles such as DROP, HOOK, HEAD, SOLO and CLIMAX
/// in section ids. A final judge must understand those roles instead of grading
/// Jazz, Lo-fi, Trap and EDM as malformed Pop songs.
class GodJudge {
  const GodJudge({
    this.approvalThreshold = 82.0,
    this.emotionDirector = const EmotionDirector(),
    this.songDirector = const SongDirectorAnalyzer(),
    this.phraseAnalyzer = const PhraseProducerAnalyzer(),
    this.memoryExtractor = const SongMemoryExtractor(),
  });

  final double approvalThreshold;
  final EmotionDirector emotionDirector;
  final SongDirectorAnalyzer songDirector;
  final PhraseProducerAnalyzer phraseAnalyzer;
  final SongMemoryExtractor memoryExtractor;

  GodJudgeVerdict evaluate({
    required SongDraft draft,
    required SongRequest request,
    required SongTimeline timeline,
  }) {
    if (draft.sections.isEmpty) {
      return GodJudgeVerdict(
        score: 0,
        approved: false,
        metrics: _emptyMetrics,
        blockers: const <String>['No generated song exists.'],
        emotion: EmotionSongAnalysis.empty(),
        director: SongDirectorAnalysis.empty(),
        phrases: SongPhraseProducerAnalysis.empty(),
      );
    }

    final memory = memoryExtractor.capture(draft);
    final director = songDirector.analyze(draft: draft, memory: memory);
    final phrases = phraseAnalyzer.analyze(draft: draft, memory: memory);
    final emotion = emotionDirector.analyze(draft: draft, mood: request.mood);

    final transitionFloor = director.weakestTransition?.score ?? 88.0;
    final localCraft = _localCraftScore(draft, phrases);
    final arrangement = _arrangementScore(draft, director);
    final phraseScore = phrases.overallScore;
    final emotionScore = emotion.overallScore;
    final hookPayoff = _hookPayoffScore(draft);
    final performance = _performanceScore(timeline);
    final consistency = _consistencyScore(
      arrangement: arrangement,
      transitionFloor: transitionFloor,
      hookPayoff: hookPayoff,
      localCraft: localCraft,
      phrases: phrases,
      emotion: emotion,
    );

    final metrics = <GodJudgeMetric>[
      GodJudgeMetric(
        dimension: GodJudgeDimension.localCraft,
        label: 'Local Craft',
        score: localCraft,
        minimum: 72,
        weight: 0.12,
      ),
      GodJudgeMetric(
        dimension: GodJudgeDimension.arrangement,
        label: 'Song Architecture',
        score: arrangement,
        minimum: 74,
        weight: 0.17,
      ),
      GodJudgeMetric(
        dimension: GodJudgeDimension.phraseIntelligence,
        label: 'Phrase Intelligence',
        score: phraseScore,
        minimum: request.includeMelody ? 74 : 0,
        weight: request.includeMelody ? 0.17 : 0.0,
      ),
      GodJudgeMetric(
        dimension: GodJudgeDimension.emotion,
        label: 'Emotion',
        score: emotionScore,
        minimum: request.includeMelody ? 70 : 0,
        weight: request.includeMelody ? 0.16 : 0.0,
      ),
      GodJudgeMetric(
        dimension: GodJudgeDimension.transitionFloor,
        label: 'Weakest Transition',
        score: transitionFloor,
        minimum: 54,
        weight: 0.10,
      ),
      GodJudgeMetric(
        dimension: GodJudgeDimension.hookPayoff,
        label: 'Hook / Payoff',
        score: hookPayoff,
        minimum: 66,
        weight: 0.11,
      ),
      GodJudgeMetric(
        dimension: GodJudgeDimension.performanceSafety,
        label: 'Performance Safety',
        score: performance,
        minimum: 86,
        weight: 0.09,
      ),
      GodJudgeMetric(
        dimension: GodJudgeDimension.consistency,
        label: 'No Weak Link',
        score: consistency,
        minimum: 68,
        weight: 0.08,
      ),
    ];

    final blockers = <String>[];
    if (draft.sections.length != draft.plan.sections.length) {
      blockers.add('Arrangement is incomplete.');
    }
    if (request.includeMelody && phrases.phrases.isEmpty) {
      blockers.add('Melody exists without judgeable phrase intelligence.');
    }

    final severeLineage = _severeLineageViolations(phrases);
    if (severeLineage > 0) {
      blockers.add('$severeLineage severe phrase lineage violation(s).');
    }

    final weakestPhrase = phrases.weakestPhrase;
    if (request.includeMelody && weakestPhrase != null && weakestPhrase.score < 58) {
      blockers.add(
        'Weakest phrase falls below the absolute musical floor (${weakestPhrase.score.round()}).',
      );
    }
    final weakestEmotion = emotion.weakestMetric;
    if (request.includeMelody &&
        weakestEmotion != null &&
        weakestEmotion.score < 48) {
      blockers.add(
        '${weakestEmotion.label} is emotionally flat or contradictory (${weakestEmotion.score.round()}).',
      );
    }

    for (final metric in metrics) {
      if (!metric.passesFloor) {
        blockers.add(
          '${metric.label} ${metric.score.round()} < ${metric.minimum.round()}.',
        );
      }
    }

    final active =
        metrics.where((metric) => metric.weight > 0).toList(growable: false);
    final weighted = active.fold<double>(
          0.0,
          (sum, metric) => sum + metric.score * metric.weight,
        ) /
        max(
          0.0001,
          active.fold<double>(0.0, (sum, metric) => sum + metric.weight),
        );
    final weakestScore = active.map((metric) => metric.score).reduce(min);
    final weakLinkPenalty =
        weakestScore < 72 ? (72 - weakestScore) * 0.20 : 0.0;
    final score =
        (weighted - weakLinkPenalty).clamp(0.0, 100.0).toDouble();
    final approved = blockers.isEmpty && score >= approvalThreshold;
    if (!approved && blockers.isEmpty) {
      blockers.add(
        'Final score ${score.toStringAsFixed(1)} < ${approvalThreshold.toStringAsFixed(1)} approval threshold.',
      );
    }

    return GodJudgeVerdict(
      score: score,
      approved: approved,
      metrics: metrics,
      blockers: blockers,
      emotion: emotion,
      director: director,
      phrases: phrases,
    );
  }

  /// Local craft combines the legacy section Producer score with what the newer
  /// phrase system can actually hear in the melody. A harmony score around 70 is
  /// not automatically mediocre when the phrase writer is delivering a clean
  /// 90-point musical sentence; likewise strong harmony cannot hide weak phrases.
  double _localCraftScore(
    SongDraft draft,
    SongPhraseProducerAnalysis phrases,
  ) {
    final values = <double>[];
    for (final section in draft.sections) {
      final producer = section.candidate.producerAnalysis?.overallScore;
      values.add(
        (producer ?? section.candidate.score).clamp(0.0, 100.0).toDouble(),
      );
    }
    if (values.isEmpty) return 0.0;
    values.sort();
    final average = values.reduce((a, b) => a + b) / values.length;
    final lowerQuartile =
        values[max(0, (values.length * 0.25).floor() - 1)];
    final sectionCraft = average * 0.74 + lowerQuartile * 0.26;
    if (phrases.phrases.isEmpty) {
      return sectionCraft.clamp(0.0, 100.0).toDouble();
    }
    final phraseFloor = phrases.weakestPhrase?.score ?? phrases.overallScore;
    final phraseCraft = phrases.overallScore * 0.74 + phraseFloor * 0.26;
    return (sectionCraft * 0.68 + phraseCraft * 0.32)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  /// Genre-aware architecture score. Completeness, deliberate role coverage,
  /// planned energy motion and real handoffs matter more than whether a section
  /// happened to be encoded as the old `chorus` enum value.
  double _arrangementScore(
    SongDraft draft,
    SongDirectorAnalysis director,
  ) {
    final completeness =
        draft.sections.length / max(1, draft.plan.sections.length);
    var hasSetup = false;
    var hasPayoff = false;
    var hasContrast = false;
    var hasEnding = false;
    for (final section in draft.sections) {
      final id = section.plan.id.toLowerCase();
      hasSetup |= section.plan.type == SongSectionType.verse ||
          id.contains('groove') ||
          id.contains('theme') ||
          id.contains('head') ||
          id.contains('verse');
      hasPayoff |= _isPayoff(section.plan);
      hasContrast |= section.plan.type == SongSectionType.preChorus ||
          section.plan.type == SongSectionType.bridge ||
          id.contains('build') ||
          id.contains('breakdown') ||
          id.contains('solo') ||
          id.contains('instrumental') ||
          id.contains('theme-b');
      hasEnding |= section.plan.type == SongSectionType.outro || id.contains('outro');
    }
    final roleCoverage = <bool>[hasSetup, hasPayoff, hasContrast, hasEnding]
            .where((value) => value)
            .length /
        4.0;

    final plannedEnergy =
        draft.sections.map((section) => section.plan.targetEnergy).toList();
    final energyRange = _range(plannedEnergy);
    final plannedArc = _windowScore(energyRange, 0.16, 0.72);
    final transitionMetric =
        director.metricFor(SongDirectorDimension.transitions)?.score ?? 76.0;

    return (completeness.clamp(0.0, 1.0) * 100.0 * 0.28 +
            roleCoverage * 100.0 * 0.18 +
            plannedArc * 0.18 +
            transitionMetric * 0.18 +
            director.overallScore * 0.18)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  /// Real payoff evidence is relative: the listener should feel a lift from the
  /// setup, stronger dynamics/density, a meaningful peak, and later escalation.
  /// This works for CHORUS, HOOK, DROP, CLIMAX and genre-specific payoff labels.
  double _hookPayoffScore(SongDraft draft) {
    final payoffs = draft.sections
        .where((section) => _isPayoff(section.plan))
        .toList(growable: false);
    if (payoffs.isEmpty) {
      // Blues/Jazz forms may organize around head/solo statements instead of a
      // conventional chorus. These still need a focal section.
      final focal = draft.sections.where((section) {
        final id = section.plan.id.toLowerCase();
        return id.contains('head') || id.contains('solo') || id.contains('theme');
      }).toList(growable: false);
      if (focal.isEmpty) return 58.0;
      return _focalPayoffScore(draft, focal);
    }
    return _focalPayoffScore(draft, payoffs);
  }

  double _focalPayoffScore(
    SongDraft draft,
    List<GeneratedSongSection> payoffs,
  ) {
    final allEnergy = draft.sections.map(_actualEnergy).toList(growable: false);
    final globalMin = allEnergy.reduce(min);
    final globalMax = allEnergy.reduce(max);
    final energySpan = max(0.001, globalMax - globalMin);
    final values = <double>[];

    for (final payoff in payoffs) {
      final index = draft.sections.indexOf(payoff);
      final before = index > 0 ? draft.sections[index - 1] : null;
      final energy = _actualEnergy(payoff);
      final previousEnergy = before == null ? globalMin : _actualEnergy(before);
      final lift = energy - previousEnergy;
      final relativePeak = ((energy - globalMin) / energySpan).clamp(0.0, 1.0);
      final liftScore = _windowScore(lift, 0.025, 0.36);
      final peakScore = (relativePeak * 100.0).clamp(35.0, 100.0).toDouble();
      final melodicScore = _melodicPayoffScore(payoff);
      final planFit = _closeness(
        energy,
        _relativeTargetEnergy(payoff.plan.targetEnergy, draft),
        0.34,
      );
      values.add(
        liftScore * 0.34 +
            peakScore * 0.28 +
            melodicScore * 0.24 +
            planFit * 0.14,
      );
    }

    var score = values.reduce((a, b) => a + b) / values.length;
    final finalPayoff = payoffs.last;
    final id = finalPayoff.plan.id.toLowerCase();
    if (finalPayoff.plan.variation >= 2 ||
        id.contains('final') ||
        id.contains('climax')) {
      final earlier = payoffs.length > 1
          ? payoffs.take(payoffs.length - 1).map(_actualEnergy).reduce(max)
          : globalMin;
      score += _actualEnergy(finalPayoff) + 0.015 >= earlier ? 5.0 : -7.0;
    }
    return score.clamp(0.0, 100.0).toDouble();
  }

  double _melodicPayoffScore(GeneratedSongSection section) {
    if (section.melody.isEmpty) return 50.0;
    final pitches = section.melody
        .map((note) => _melodyPitch(note))
        .toList(growable: false);
    final range = (pitches.reduce(max) - pitches.reduce(min)).toDouble();
    final density = section.melody.length / max(1, section.plan.bars);
    final velocity = section.melody
            .fold<double>(0.0, (sum, note) => sum + note.velocity) /
        section.melody.length;
    return (_windowScore(range, 5.0, 20.0) * 0.36 +
            _windowScore(density, 2.0, 7.0) * 0.34 +
            _windowScore(velocity, 0.52, 0.98) * 0.30)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _relativeTargetEnergy(double target, SongDraft draft) {
    final targets =
        draft.sections.map((section) => section.plan.targetEnergy).toList();
    if (targets.length < 2) return target;
    final low = targets.reduce(min);
    final high = targets.reduce(max);
    if ((high - low).abs() < 0.001) return 0.62;
    return (0.42 + ((target - low) / (high - low)) * 0.38)
        .clamp(0.38, 0.84)
        .toDouble();
  }

  double _actualEnergy(GeneratedSongSection section) {
    final bars = max(1, section.plan.bars);
    final noteCount = section.melody.length + section.bass.length;
    final density =
        (noteCount / (bars * 10.0)).clamp(0.0, 1.0).toDouble();
    final velocities = <double>[
      ...section.melody.map((note) => note.velocity),
      ...section.bass.map((note) => note.velocity),
    ];
    final velocity = velocities.isEmpty
        ? 0.50
        : velocities.reduce((a, b) => a + b) / velocities.length;
    final chordDensity =
        (section.progression.length / (bars * 1.35)).clamp(0.0, 1.0).toDouble();
    final range = section.melody.isEmpty
        ? 0.0
        : (() {
            final pitches = section.melody.map(_melodyPitch).toList();
            return ((pitches.reduce(max) - pitches.reduce(min)) / 18.0)
                .clamp(0.0, 1.0)
                .toDouble();
          })();
    return (density * 0.34 +
            velocity * 0.38 +
            chordDensity * 0.14 +
            range * 0.14)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  /// Any truly unsafe event is an immediate final-gate failure. Expression can
  /// never average away a stuck/overlong note or invalid MIDI pitch.
  double _performanceScore(SongTimeline timeline) {
    if (timeline.events.isEmpty) return 0.0;
    var unsafe = 0;
    var clipped = 0;
    final melodyVelocities = <double>[];
    final bassVelocities = <double>[];

    for (final event in timeline.events) {
      final duration = event.performedDurationBeats;
      if (duration <= 0 ||
          event.startBeat < 0 ||
          event.endBeat > timeline.totalBeats + 0.001) {
        unsafe++;
      }
      switch (event.track) {
        case TimelineTrackType.melody:
          if (duration > 1.66) unsafe++;
          melodyVelocities.add(event.performedVelocity);
        case TimelineTrackType.bass:
          if (duration > 1.16) unsafe++;
          bassVelocities.add(event.performedVelocity);
        case TimelineTrackType.harmony:
          if (duration > 3.71) unsafe++;
      }
      if (event.performedVelocity >= 0.999) clipped++;
      if (event.midiPitches.any((pitch) => pitch < 0 || pitch > 127)) unsafe++;
    }

    if (unsafe > 0) {
      return (58.0 - min(38.0, (unsafe - 1) * 7.0))
          .clamp(0.0, 58.0)
          .toDouble();
    }

    final clipRatio = clipped / timeline.events.length;
    final clipPenalty = max(0.0, (clipRatio - 0.08) * 120.0);
    final melodyRange = _range(melodyVelocities);
    final bassRange = _range(bassVelocities);
    final expression = melodyVelocities.length < 4
        ? 82.0
        : (_windowScore(melodyRange, 0.07, 0.62) * 0.72 +
            (bassVelocities.length < 4
                    ? 90.0
                    : _windowScore(bassRange, 0.035, 0.55)) *
                0.28);
    return ((100.0 - clipPenalty) * 0.74 + expression * 0.26)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _consistencyScore({
    required double arrangement,
    required double transitionFloor,
    required double hookPayoff,
    required double localCraft,
    required SongPhraseProducerAnalysis phrases,
    required EmotionSongAnalysis emotion,
  }) {
    final values = <double>[
      arrangement,
      transitionFloor,
      hookPayoff,
      localCraft,
      phrases.weakestPhrase?.score ??
          (phrases.phrases.isEmpty ? 82.0 : phrases.overallScore),
      emotion.weakestMetric?.score ?? emotion.overallScore,
    ]..sort();
    // The bottom three systems dominate. A brilliant hook cannot erase a bad
    // handoff; strong emotion cannot erase broken local craft.
    return (values[0] * 0.42 +
            values[1] * 0.28 +
            values[2] * 0.16 +
            values[3] * 0.08 +
            values[4] * 0.04 +
            values[5] * 0.02)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  int _severeLineageViolations(SongPhraseProducerAnalysis phrases) {
    var severe = 0;
    for (final phrase in phrases.phrases) {
      final lineage = phrase.lineage;
      if (lineage == null || lineage.isSource || lineage.insideGuardrail) continue;
      final similarity = lineage.sourceSimilarity;
      final window = lineage.targetWindow;
      final gap = similarity < window.minimum
          ? window.minimum - similarity
          : similarity - window.maximum;
      // Exact/near-exact copy-paste remains a hard veto even if the configured
      // upper window is relatively close to 1.0.
      if (similarity >= 0.985 || gap >= 0.075) severe++;
    }
    return severe;
  }

  bool _isPayoff(SongSectionPlan section) {
    final id = section.id.toLowerCase();
    return section.type == SongSectionType.chorus ||
        id.contains('hook') ||
        id.contains('drop') ||
        id.contains('climax') ||
        id.contains('final');
  }

  int _melodyPitch(MelodyNote note) {
    const pitchClasses = <String, int>{
      'C': 0,
      'C#': 1,
      'Db': 1,
      'D': 2,
      'D#': 3,
      'Eb': 3,
      'E': 4,
      'F': 5,
      'F#': 6,
      'Gb': 6,
      'G': 7,
      'G#': 8,
      'Ab': 8,
      'A': 9,
      'A#': 10,
      'Bb': 10,
      'B': 11,
    };
    final name = note.note;
    final normalized = name.length >= 2 &&
            (name[1] == '#' || name[1] == 'b')
        ? name.substring(0, 2)
        : name.substring(0, 1);
    return (note.octave + 1) * 12 + (pitchClasses[normalized] ?? 0);
  }

  double _range(List<double> values) {
    if (values.length < 2) return 0.0;
    return values.reduce(max) - values.reduce(min);
  }

  double _closeness(double value, double target, double tolerance) {
    if (tolerance <= 0) return value == target ? 100.0 : 0.0;
    final distance = (value - target).abs();
    return (100.0 - distance / tolerance * 100.0)
        .clamp(20.0, 100.0)
        .toDouble();
  }

  double _windowScore(double value, double low, double high) {
    if (value >= low && value <= high) return 100.0;
    final span = max(0.001, high - low);
    final distance = value < low ? low - value : value - high;
    return (100.0 - distance / span * 100.0)
        .clamp(20.0, 100.0)
        .toDouble();
  }

  List<GodJudgeMetric> get _emptyMetrics => const <GodJudgeMetric>[
        GodJudgeMetric(
          dimension: GodJudgeDimension.localCraft,
          label: 'Local Craft',
          score: 0,
          minimum: 72,
          weight: 0.12,
        ),
      ];
}
