import 'dart:math';

import '../models/types.dart';
import '../utils/music_theory.dart';
import 'phrase_model.dart';
import 'song_draft.dart';
import 'song_memory.dart';

/// Phrase-level quality dimensions used by the 5.8C Producer Brain.
enum PhraseProducerDimension {
  lineage,
  roleIntent,
  cadence,
  contour,
  rhythm,
  rangeClimax,
  playability,
}

extension PhraseProducerDimensionX on PhraseProducerDimension {
  String get label => switch (this) {
        PhraseProducerDimension.lineage => 'LINEAGE',
        PhraseProducerDimension.roleIntent => 'ROLE',
        PhraseProducerDimension.cadence => 'CADENCE',
        PhraseProducerDimension.contour => 'CONTOUR',
        PhraseProducerDimension.rhythm => 'RHYTHM',
        PhraseProducerDimension.rangeClimax => 'ARC',
        PhraseProducerDimension.playability => 'SAFE',
      };
}

class PhraseProducerMetric {
  const PhraseProducerMetric({
    required this.dimension,
    required this.score,
  });

  final PhraseProducerDimension dimension;
  final double score;
}

/// Immutable diagnosis of one phrase-sized musical sentence.
class PhraseProducerAssessment {
  PhraseProducerAssessment({
    required this.phraseId,
    required this.sectionId,
    required this.phraseIndex,
    required this.role,
    required this.score,
    required List<PhraseProducerMetric> metrics,
    required this.lineage,
    required this.issue,
    required this.action,
  }) : metrics = List<PhraseProducerMetric>.unmodifiable(metrics);

  final String phraseId;
  final String sectionId;
  final int phraseIndex;
  final PhraseRole role;
  final double score;
  final List<PhraseProducerMetric> metrics;
  final PhraseLineageNode? lineage;
  final String issue;
  final String action;

  bool get lineageInsideGuardrail => lineage?.insideGuardrail ?? true;

  PhraseProducerMetric metricFor(PhraseProducerDimension dimension) =>
      metrics.firstWhere((metric) => metric.dimension == dimension);
}

/// Whole-song phrase intelligence summary.
class SongPhraseProducerAnalysis {
  SongPhraseProducerAnalysis({
    required List<PhraseProducerAssessment> phrases,
    required this.overallScore,
    required this.weakestPhrase,
  }) : phrases = List<PhraseProducerAssessment>.unmodifiable(phrases);

  factory SongPhraseProducerAnalysis.empty() => SongPhraseProducerAnalysis(
        phrases: const <PhraseProducerAssessment>[],
        overallScore: 0.0,
        weakestPhrase: null,
      );

  final List<PhraseProducerAssessment> phrases;
  final double overallScore;
  final PhraseProducerAssessment? weakestPhrase;

  int get guardrailViolations =>
      phrases.where((phrase) => !phrase.lineageInsideGuardrail).length;

  bool get isHealthy =>
      phrases.isNotEmpty && overallScore >= 82.0 && guardrailViolations == 0;
}

/// Phase 5.8C phrase-level Producer Brain.
///
/// This pass is intentionally diagnostic. 5.8B already writes phrases; this
/// analyzer measures whether each sentence fulfills its intended musical job
/// before 5.8D is allowed to mutate weak phrases. It uses Song Memory's explicit
/// ancestry and similarity windows so later repair has a concrete, deterministic
/// objective instead of relying on vague section-level heuristics.
class PhraseProducerAnalyzer {
  const PhraseProducerAnalyzer();

  SongPhraseProducerAnalysis analyze({
    required SongDraft draft,
    required SongMemory? memory,
  }) {
    if (memory == null || draft.sections.isEmpty) {
      return SongPhraseProducerAnalysis.empty();
    }

    final assessments = <PhraseProducerAssessment>[];
    for (final section in draft.sections) {
      final sectionMemory = memory.section(section.plan.id);
      if (sectionMemory == null || sectionMemory.phrases.isEmpty) continue;

      for (final phrase in sectionMemory.phrases) {
        if (phrase.isEmpty) continue;
        final notes = _notesForPhrase(
          section,
          phrase.index,
          sectionMemory.phrases.length,
        );
        final previous = phrase.index <= 0
            ? null
            : sectionMemory.phrase(phrase.index - 1);
        final lineage = memory.lineageFor(phrase.id);
        final metrics = <PhraseProducerMetric>[
          PhraseProducerMetric(
            dimension: PhraseProducerDimension.lineage,
            score: _lineageScore(lineage),
          ),
          PhraseProducerMetric(
            dimension: PhraseProducerDimension.roleIntent,
            score: _roleScore(phrase, previous),
          ),
          PhraseProducerMetric(
            dimension: PhraseProducerDimension.cadence,
            score: _cadenceScore(section, phrase, notes),
          ),
          PhraseProducerMetric(
            dimension: PhraseProducerDimension.contour,
            score: _contourScore(notes),
          ),
          PhraseProducerMetric(
            dimension: PhraseProducerDimension.rhythm,
            score: _rhythmScore(phrase),
          ),
          PhraseProducerMetric(
            dimension: PhraseProducerDimension.rangeClimax,
            score: _rangeClimaxScore(phrase),
          ),
          PhraseProducerMetric(
            dimension: PhraseProducerDimension.playability,
            score: _playabilityScore(notes),
          ),
        ];
        final score = _weightedScore(metrics);
        final diagnosis = _diagnosis(phrase, lineage, metrics);

        assessments.add(
          PhraseProducerAssessment(
            phraseId: phrase.id,
            sectionId: phrase.sectionId,
            phraseIndex: phrase.index,
            role: phrase.role,
            score: score,
            metrics: metrics,
            lineage: lineage,
            issue: diagnosis.$1,
            action: diagnosis.$2,
          ),
        );
      }
    }

    if (assessments.isEmpty) return SongPhraseProducerAnalysis.empty();

    var weightedTotal = 0.0;
    var weightTotal = 0.0;
    PhraseProducerAssessment? weakest;
    var weakestRank = double.infinity;
    for (final phrase in assessments) {
      final weight = switch (phrase.role) {
        PhraseRole.hook => 1.30,
        PhraseRole.lift => 1.12,
        PhraseRole.answer => 1.06,
        _ => 1.0,
      };
      weightedTotal += phrase.score * weight;
      weightTotal += weight;

      // A lineage violation is deliberately promoted in the weakness ranking.
      // A phrase can sound locally smooth and still damage song identity.
      final rank = phrase.score - (phrase.lineageInsideGuardrail ? 0.0 : 8.0);
      if (rank < weakestRank) {
        weakestRank = rank;
        weakest = phrase;
      }
    }

    return SongPhraseProducerAnalysis(
      phrases: assessments,
      overallScore: (weightedTotal / max(0.0001, weightTotal))
          .clamp(0.0, 100.0)
          .toDouble(),
      weakestPhrase: weakest,
    );
  }

  List<MelodyNote> _notesForPhrase(
    GeneratedSongSection section,
    int phraseIndex,
    int phraseCount,
  ) {
    if (section.melody.isEmpty ||
        section.progression.isEmpty ||
        phraseCount <= 0) {
      return const <MelodyNote>[];
    }
    final chordCount = section.progression.length;
    return section.melody.where((note) {
      final safeChord = note.chordIndex.clamp(0, chordCount - 1).toInt();
      final normalized =
          ((safeChord + 0.5) / chordCount.toDouble()).clamp(0.0, 0.999999);
      final bucket =
          (normalized * phraseCount).floor().clamp(0, phraseCount - 1).toInt();
      return bucket == phraseIndex;
    }).toList(growable: false);
  }

  double _lineageScore(PhraseLineageNode? lineage) {
    if (lineage == null) return 58.0;
    if (lineage.isSource) return 100.0;

    final value = lineage.sourceSimilarity;
    final window = lineage.targetWindow;
    if (window.contains(value)) {
      final center = (window.minimum + window.maximum) / 2.0;
      final halfWidth = max(0.001, (window.maximum - window.minimum) / 2.0);
      final centeredness =
          (1.0 - ((value - center).abs() / halfWidth)).clamp(0.0, 1.0);
      return (92.0 + centeredness * 8.0).clamp(0.0, 100.0).toDouble();
    }

    final gap = value < window.minimum
        ? window.minimum - value
        : value - window.maximum;
    return (88.0 - gap * 260.0).clamp(20.0, 88.0).toDouble();
  }

  double _roleScore(PhraseFingerprint phrase, PhraseFingerprint? previous) {
    final components = <double>[];
    switch (phrase.role) {
      case PhraseRole.statement:
        components
          ..add(_windowScore(phrase.pitchRange.toDouble(), 5.0, 12.0))
          ..add(_windowScore(phrase.noteDensity, 1.2, 4.5))
          ..add(_windowScore(phrase.climaxPosition, 0.35, 0.75));
      case PhraseRole.question:
        components
          ..add(_windowScore(phrase.pitchRange.toDouble(), 6.0, 14.0))
          ..add(_windowScore(phrase.noteDensity, 1.6, 5.5))
          ..add(_windowScore(phrase.climaxPosition, 0.58, 0.95));
      case PhraseRole.answer:
        components
          ..add(_windowScore(phrase.pitchRange.toDouble(), 4.0, 12.0))
          ..add(_windowScore(phrase.noteDensity, 1.2, 5.0))
          ..add(_windowScore(phrase.climaxPosition, 0.12, 0.58));
        if (previous != null && previous.role == PhraseRole.question) {
          final separation = previous.climaxPosition - phrase.climaxPosition;
          components.add(
            separation >= 0.12
                ? 100.0
                : (64.0 + separation * 180.0).clamp(30.0, 96.0).toDouble(),
          );
        }
      case PhraseRole.lift:
        components
          ..add(_windowScore(phrase.pitchRange.toDouble(), 7.0, 16.0))
          ..add(_windowScore(phrase.noteDensity, 2.0, 6.2))
          ..add(_windowScore(phrase.climaxPosition, 0.68, 0.98))
          ..add(_windowScore(phrase.averageVelocity, 0.52, 1.0));
      case PhraseRole.hook:
        components
          ..add(_windowScore(phrase.pitchRange.toDouble(), 7.0, 17.0))
          ..add(_windowScore(phrase.noteDensity, 2.0, 6.5))
          ..add(_windowScore(phrase.climaxPosition, 0.35, 0.82))
          ..add(_windowScore(phrase.averageVelocity, 0.50, 1.0));
      case PhraseRole.contrast:
        components
          ..add(_windowScore(phrase.pitchRange.toDouble(), 7.0, 18.0))
          ..add(_windowScore(phrase.noteDensity, 0.8, 5.2))
          ..add(_windowScore(phrase.climaxPosition, 0.22, 0.78));
      case PhraseRole.release:
        components
          ..add(_windowScore(phrase.pitchRange.toDouble(), 3.0, 10.0))
          ..add(_windowScore(phrase.noteDensity, 0.5, 3.5))
          ..add(_windowScore(phrase.climaxPosition, 0.0, 0.45))
          ..add(_windowScore(phrase.averageVelocity, 0.20, 0.82));
      case PhraseRole.turnaround:
        components
          ..add(_windowScore(phrase.pitchRange.toDouble(), 5.0, 13.0))
          ..add(_windowScore(phrase.noteDensity, 1.5, 5.5))
          ..add(_windowScore(phrase.climaxPosition, 0.48, 0.92));
    }
    return _average(components);
  }

  double _cadenceScore(
    GeneratedSongSection section,
    PhraseFingerprint phrase,
    List<MelodyNote> notes,
  ) {
    if (notes.isEmpty || section.progression.isEmpty) return 0.0;
    final last = notes.last;
    final chordIndex =
        last.chordIndex.clamp(0, section.progression.length - 1).toInt();
    final chord = section.progression[chordIndex];
    final chordTones = getChordNotes(chord);
    final isChordTone = chordTones.contains(last.note);
    final isRoot = last.note == chord.root;
    final degree = chord.degree;
    final isTonic = degree == 'I' || degree == 'i';
    final isDominant = chord.harmonyFunction == HarmonyFunction.dominant ||
        degree == 'V' ||
        degree == 'v' ||
        degree == 'V7' ||
        degree.startsWith('V/');
    final interval = (getNoteIndex(last.note) - getNoteIndex(chord.root)) % 12;

    return switch (phrase.cadenceIntent) {
      PhraseCadenceIntent.resolved => isRoot
          ? 100.0
          : isChordTone
              ? 90.0
              : 42.0,
      PhraseCadenceIntent.half => isDominant && isRoot
          ? 100.0
          : isDominant && isChordTone
              ? 91.0
              : isChordTone
                  ? 70.0
                  : 44.0,
      PhraseCadenceIntent.open => isTonic && isRoot
          ? 46.0
          : isRoot
              ? 62.0
              : isChordTone
                  ? 84.0
                  : 94.0,
      PhraseCadenceIntent.deceptive =>
        (degree == 'vi' || degree == 'VI') && isChordTone
            ? 98.0
            : isChordTone
                ? 70.0
                : 45.0,
      PhraseCadenceIntent.suspended => interval == 2 || interval == 5
          ? 98.0
          : !isChordTone
              ? 88.0
              : 62.0,
    };
  }

  double _contourScore(List<MelodyNote> notes) {
    if (notes.length < 2) return notes.isEmpty ? 0.0 : 60.0;
    final pitches = notes
        .map((note) => noteToPitch(note.note, note.octave))
        .toList(growable: false);
    var score = 100.0;
    var repeated = 0;
    for (var i = 1; i < pitches.length; i++) {
      final leap = (pitches[i] - pitches[i - 1]).abs();
      if (leap > 12) {
        score -= 22.0;
      } else if (leap > 9) {
        score -= 8.0;
      } else if (leap > 7) {
        score -= 3.0;
      }
      if (leap == 0) repeated++;
    }
    final repeatAllowance = max(1, (pitches.length * 0.34).floor());
    if (repeated > repeatAllowance) {
      score -= (repeated - repeatAllowance) * 5.0;
    }
    return score.clamp(18.0, 100.0).toDouble();
  }

  double _rhythmScore(PhraseFingerprint phrase) {
    if (phrase.durationTicks.isEmpty) return 0.0;
    final distinctDurations = phrase.durationTicks.toSet().length;
    final durationDiversity =
        (distinctDurations / min(4, phrase.durationTicks.length)).clamp(0.0, 1.0);
    final accentDiversity =
        (phrase.accentBuckets.toSet().length / 3.0).clamp(0.0, 1.0);

    var longestRun = 1;
    var run = 1;
    for (var i = 1; i < phrase.durationTicks.length; i++) {
      if (phrase.durationTicks[i] == phrase.durationTicks[i - 1]) {
        run++;
        longestRun = max(longestRun, run);
      } else {
        run = 1;
      }
    }
    final runPenalty = phrase.durationTicks.length <= 2
        ? 0.0
        : ((longestRun - 2) * 4.0).clamp(0.0, 24.0).toDouble();
    final densitySafety = _windowScore(phrase.noteDensity, 0.5, 7.0);
    return (55.0 +
            durationDiversity * 24.0 +
            accentDiversity * 11.0 +
            densitySafety * 0.10 -
            runPenalty)
        .clamp(18.0, 100.0)
        .toDouble();
  }

  double _rangeClimaxScore(PhraseFingerprint phrase) {
    final (rangeMin, rangeMax, climaxMin, climaxMax) = switch (phrase.role) {
      PhraseRole.statement => (5.0, 12.0, 0.35, 0.75),
      PhraseRole.question => (6.0, 14.0, 0.58, 0.95),
      PhraseRole.answer => (4.0, 12.0, 0.12, 0.58),
      PhraseRole.lift => (7.0, 16.0, 0.68, 0.98),
      PhraseRole.hook => (7.0, 17.0, 0.35, 0.82),
      PhraseRole.contrast => (7.0, 18.0, 0.22, 0.78),
      PhraseRole.release => (3.0, 10.0, 0.0, 0.45),
      PhraseRole.turnaround => (5.0, 13.0, 0.48, 0.92),
    };
    return (_windowScore(phrase.pitchRange.toDouble(), rangeMin, rangeMax) * 0.58 +
            _windowScore(phrase.climaxPosition, climaxMin, climaxMax) * 0.42)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  double _playabilityScore(List<MelodyNote> notes) {
    if (notes.isEmpty) return 0.0;
    var score = 100.0;
    int? previousPitch;
    for (final note in notes) {
      final pitch = noteToPitch(note.note, note.octave);
      if (pitch < 48 || pitch > 96) score -= 16.0;
      if (note.velocity < 0.0 || note.velocity > 1.0) score -= 22.0;
      if (note.duration <= 0.0) score -= 26.0;
      if (previousPitch != null && (pitch - previousPitch).abs() > 12) {
        score -= 13.0;
      }
      previousPitch = pitch;
    }
    return score.clamp(0.0, 100.0).toDouble();
  }

  double _weightedScore(List<PhraseProducerMetric> metrics) {
    const weights = <PhraseProducerDimension, double>{
      PhraseProducerDimension.lineage: 0.28,
      PhraseProducerDimension.roleIntent: 0.18,
      PhraseProducerDimension.cadence: 0.16,
      PhraseProducerDimension.contour: 0.12,
      PhraseProducerDimension.rhythm: 0.10,
      PhraseProducerDimension.rangeClimax: 0.10,
      PhraseProducerDimension.playability: 0.06,
    };
    var total = 0.0;
    for (final metric in metrics) {
      total += metric.score * weights[metric.dimension]!;
    }
    return total.clamp(0.0, 100.0).toDouble();
  }

  (String, String) _diagnosis(
    PhraseFingerprint phrase,
    PhraseLineageNode? lineage,
    List<PhraseProducerMetric> metrics,
  ) {
    if (lineage != null && !lineage.insideGuardrail) {
      final similarity = lineage.sourceSimilarity;
      final window = lineage.targetWindow;
      if (similarity < window.minimum) {
        return (
          '${phrase.role.name} lost source identity',
          'Restore recognizable contour and rhythm from ${lineage.sourcePhraseId} without copying it verbatim.',
        );
      }
      return (
        '${phrase.role.name} is too literal',
        'Develop interior contour or rhythm while preserving the recognizable source anchors.',
      );
    }

    var weakest = metrics.first;
    for (final metric in metrics.skip(1)) {
      if (metric.score < weakest.score) weakest = metric;
    }

    return switch (weakest.dimension) {
      PhraseProducerDimension.lineage => (
          'Phrase ancestry is unclear',
          'Re-establish a deliberate relationship to the remembered source phrase.'
        ),
      PhraseProducerDimension.roleIntent => (
          '${phrase.role.name} role is not clear enough',
          'Reshape density, register and climax so the phrase performs its section job.'
        ),
      PhraseProducerDimension.cadence => (
          '${phrase.cadenceIntent.name} cadence is weak',
          'Retarget the final melodic landing to match the phrase cadence intent.'
        ),
      PhraseProducerDimension.contour => (
          'Melodic contour is awkward',
          'Smooth oversized leaps and reduce accidental repeated-note fatigue.'
        ),
      PhraseProducerDimension.rhythm => (
          'Rhythmic identity is weak',
          'Strengthen the phrase rhythm cell without changing its structural role.'
        ),
      PhraseProducerDimension.rangeClimax => (
          'Phrase arc misses its target',
          'Move the melodic peak and range toward the intended phrase arc.'
        ),
      PhraseProducerDimension.playability => (
          'Phrase exceeds safe performance bounds',
          'Constrain pitch, velocity, duration and leap size before accepting the phrase.'
        ),
    };
  }

  double _windowScore(double value, double minimum, double maximum) {
    if (value >= minimum && value <= maximum) return 100.0;
    final span = max(0.001, maximum - minimum);
    final distance = value < minimum ? minimum - value : value - maximum;
    return (100.0 - (distance / span) * 100.0)
        .clamp(20.0, 100.0)
        .toDouble();
  }

  double _average(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.fold<double>(0.0, (sum, value) => sum + value) /
        values.length;
  }
}
