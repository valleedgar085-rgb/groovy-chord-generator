import 'dart:math';

import '../models/types.dart';
import 'emotion_director.dart';
import 'phrase_producer_brain.dart';
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

    final localCraft = _localCraftScore(draft);
    final arrangement = director.overallScore;
    final phraseScore = phrases.overallScore;
    final emotionScore = emotion.overallScore;
    final transitionFloor = director.weakestTransition?.score ?? 88.0;
    final hookPayoff = _hookPayoffScore(director, draft);
    final performance = _performanceScore(timeline);
    final consistency = _consistencyScore(director, phrases, emotion);

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
    if (phrases.guardrailViolations > 0) {
      blockers.add('${phrases.guardrailViolations} phrase lineage guardrail violation(s).');
    }
    final weakestPhrase = phrases.weakestPhrase;
    if (request.includeMelody && weakestPhrase != null && weakestPhrase.score < 58) {
      blockers.add('Weakest phrase falls below the absolute musical floor (${weakestPhrase.score.round()}).');
    }
    final weakestDirector = director.weakestMetric;
    if (weakestDirector != null && weakestDirector.active && weakestDirector.score < 55) {
      blockers.add('${weakestDirector.label} is critically weak (${weakestDirector.score.round()}).');
    }
    final weakestEmotion = emotion.weakestMetric;
    if (request.includeMelody && weakestEmotion != null && weakestEmotion.score < 48) {
      blockers.add('${weakestEmotion.label} is emotionally flat or contradictory (${weakestEmotion.score.round()}).');
    }
    for (final metric in metrics) {
      if (!metric.passesFloor) {
        blockers.add('${metric.label} ${metric.score.round()} < ${metric.minimum.round()}.');
      }
    }

    final active = metrics.where((metric) => metric.weight > 0).toList(growable: false);
    final weighted = active.fold<double>(
          0.0,
          (sum, metric) => sum + metric.score * metric.weight,
        ) /
        max(0.0001, active.fold<double>(0.0, (sum, metric) => sum + metric.weight));
    final weakestScore = active.map((metric) => metric.score).reduce(min);
    final weakLinkPenalty = weakestScore < 72 ? (72 - weakestScore) * 0.20 : 0.0;
    final score = (weighted - weakLinkPenalty).clamp(0.0, 100.0).toDouble();
    final approved = blockers.isEmpty && score >= approvalThreshold;
    if (!approved && blockers.isEmpty) {
      blockers.add('Final score ${score.toStringAsFixed(1)} < ${approvalThreshold.toStringAsFixed(1)} approval threshold.');
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

  double _localCraftScore(SongDraft draft) {
    final values = <double>[];
    for (final section in draft.sections) {
      final producer = section.candidate.producerAnalysis?.overallScore;
      values.add((producer ?? section.candidate.score).clamp(0.0, 100.0).toDouble());
    }
    if (values.isEmpty) return 0.0;
    values.sort();
    final average = values.reduce((a, b) => a + b) / values.length;
    final lowerQuartile = values[max(0, (values.length * 0.25).floor() - 1)];
    return (average * 0.74 + lowerQuartile * 0.26).clamp(0.0, 100.0).toDouble();
  }

  double _hookPayoffScore(SongDirectorAnalysis director, SongDraft draft) {
    final metric = director.metricFor(SongDirectorDimension.chorusPayoff);
    if (metric != null && metric.active) return metric.score;

    // Genre forms such as Blues/Jazz may intentionally have no chorus. In that
    // case use the strongest named hook/drop/head/climax section plus energy arc.
    final namedPayoff = draft.sections.where((section) {
      final id = section.plan.id.toLowerCase();
      return id.contains('hook') ||
          id.contains('drop') ||
          id.contains('head') ||
          id.contains('climax') ||
          id.contains('solo');
    }).toList(growable: false);
    if (namedPayoff.isEmpty) return 72.0;
    final best = namedPayoff
        .map((section) => section.plan.targetEnergy * 100.0)
        .reduce(max);
    return (68.0 + best * 0.30).clamp(0.0, 100.0).toDouble();
  }

  double _performanceScore(SongTimeline timeline) {
    if (timeline.events.isEmpty) return 0.0;
    var unsafe = 0;
    var clipped = 0;
    final melodyVelocities = <double>[];
    final bassVelocities = <double>[];

    for (final event in timeline.events) {
      final duration = event.performedDurationBeats;
      if (duration <= 0 || event.startBeat < 0 || event.endBeat > timeline.totalBeats + 0.001) {
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

    final unsafePenalty = min(70.0, unsafe * 16.0);
    final clipRatio = clipped / timeline.events.length;
    final clipPenalty = max(0.0, (clipRatio - 0.06) * 180.0);
    final melodyRange = _range(melodyVelocities);
    final bassRange = _range(bassVelocities);
    final expression = melodyVelocities.length < 4
        ? 82.0
        : (_windowScore(melodyRange, 0.07, 0.62) * 0.72 +
            (bassVelocities.length < 4 ? 90.0 : _windowScore(bassRange, 0.035, 0.55)) * 0.28);
    return (100.0 - unsafePenalty - clipPenalty) * 0.74 + expression * 0.26;
  }

  double _consistencyScore(
    SongDirectorAnalysis director,
    SongPhraseProducerAnalysis phrases,
    EmotionSongAnalysis emotion,
  ) {
    final values = <double>[
      director.weakestMetric?.score ?? director.overallScore,
      director.weakestTransition?.score ?? 88.0,
      phrases.weakestPhrase?.score ?? (phrases.phrases.isEmpty ? 82.0 : phrases.overallScore),
      emotion.weakestMetric?.score ?? emotion.overallScore,
    ];
    values.sort();
    // God Judge cares more about the two weakest systems than the best ones.
    return (values[0] * 0.58 + values[1] * 0.30 + values[2] * 0.08 + values[3] * 0.04)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _range(List<double> values) {
    if (values.length < 2) return 0.0;
    return values.reduce(max) - values.reduce(min);
  }

  double _windowScore(double value, double low, double high) {
    if (value >= low && value <= high) return 100.0;
    final span = max(0.001, high - low);
    final distance = value < low ? low - value : value - high;
    return (100.0 - distance / span * 100.0).clamp(20.0, 100.0).toDouble();
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
