import 'dart:math';

import '../models/types.dart';
import '../utils/music_theory.dart';
import 'song_architecture.dart';
import 'song_draft.dart';

/// The emotional coordinates Chord Flow carries through composition.
enum EmotionDimension {
  moodFidelity,
  emotionalMotion,
  tensionRelease,
  dynamicExpression,
  registerContour,
  payoff,
  breathingSpace,
}

class EmotionMetric {
  const EmotionMetric({
    required this.dimension,
    required this.score,
    required this.label,
    required this.insight,
  });

  final EmotionDimension dimension;
  final double score;
  final String label;
  final String insight;
}

/// A normalized emotional target. These values are intentionally musical rather
/// than psychological claims: they are composition controls for register,
/// density, velocity, tension and cadence behavior.
class EmotionIntent {
  const EmotionIntent({
    required this.valence,
    required this.arousal,
    required this.tension,
    required this.intimacy,
    required this.brightness,
    required this.resolution,
    required this.densityMultiplier,
    required this.velocityBias,
    required this.registerShift,
    required this.rangeDelta,
    required this.contourLift,
    required this.space,
  });

  final double valence;
  final double arousal;
  final double tension;
  final double intimacy;
  final double brightness;
  final double resolution;

  /// Multipliers/offsets consumed by note generation.
  final double densityMultiplier;
  final double velocityBias;
  final int registerShift;
  final int rangeDelta;
  final double contourLift;
  final double space;
}

class EmotionSongAnalysis {
  EmotionSongAnalysis({
    required this.overallScore,
    required List<EmotionMetric> metrics,
    required this.peakSectionId,
    required this.dynamicRange,
  }) : metrics = List<EmotionMetric>.unmodifiable(metrics);

  factory EmotionSongAnalysis.empty() => EmotionSongAnalysis(
        overallScore: 0,
        metrics: const <EmotionMetric>[],
        peakSectionId: null,
        dynamicRange: 0,
      );

  final double overallScore;
  final List<EmotionMetric> metrics;
  final String? peakSectionId;
  final double dynamicRange;

  EmotionMetric? get weakestMetric {
    if (metrics.isEmpty) return null;
    return metrics.reduce((a, b) => a.score <= b.score ? a : b);
  }

  EmotionMetric metricFor(EmotionDimension dimension) =>
      metrics.firstWhere((metric) => metric.dimension == dimension);
}

class _MoodProfile {
  const _MoodProfile({
    required this.valence,
    required this.arousal,
    required this.tension,
    required this.intimacy,
    required this.brightness,
    required this.resolution,
  });

  final double valence;
  final double arousal;
  final double tension;
  final double intimacy;
  final double brightness;
  final double resolution;
}

class _SectionEmotionSample {
  const _SectionEmotionSample({
    required this.sectionId,
    required this.type,
    required this.valence,
    required this.arousal,
    required this.tension,
    required this.brightness,
    required this.resolution,
    required this.space,
  });

  final String sectionId;
  final SongSectionType type;
  final double valence;
  final double arousal;
  final double tension;
  final double brightness;
  final double resolution;
  final double space;
}

/// Phase 5.10 emotion layer.
///
/// Mood is converted into deterministic, section-aware musical intent. The same
/// object also analyzes the generated notes afterward, which lets the final
/// quality judge verify that emotional intent survived actual composition.
class EmotionDirector {
  const EmotionDirector();

  EmotionIntent intentFor({
    required MoodType mood,
    required SongSectionPlan section,
  }) {
    final profile = _profile(mood);
    final role = _roleShape(section);
    final arousal = _unit(profile.arousal * 0.60 + section.targetEnergy * 0.40);
    final tension = _unit(profile.tension * 0.58 + section.targetTension * 0.42);
    final payoff = role.payoff;
    final release = role.release;

    final valence = _unit(
      profile.valence +
          payoff * (mood == MoodType.dark || mood == MoodType.mysterious ? 0.03 : 0.10) -
          role.shadow * 0.08,
    );
    final resolution = _unit(
      profile.resolution + payoff * 0.14 + release * 0.10 - tension * 0.09,
    );
    final intimacy = _unit(profile.intimacy + role.intimacy * 0.12 - payoff * 0.08);
    final brightness = _unit(
      profile.brightness + payoff * 0.12 - role.shadow * 0.12,
    );

    final densityMultiplier = (0.80 + arousal * 0.34 - intimacy * 0.08 - release * 0.12)
        .clamp(0.64, 1.20)
        .toDouble();
    final velocityBias = ((arousal - 0.50) * 0.14 + payoff * 0.055 - release * 0.06)
        .clamp(-0.12, 0.14)
        .toDouble();
    final registerShift = (((brightness - 0.50) * 7.0) + payoff * 2.2 - release * 2.0)
        .round()
        .clamp(-5, 6)
        .toInt();
    final rangeDelta = (((arousal + tension - 1.0) * 4.0) + payoff * 2.0 - intimacy * 1.2)
        .round()
        .clamp(-3, 4)
        .toInt();
    final contourLift = ((arousal - 0.45) * 0.30 + payoff * 0.22 - release * 0.24)
        .clamp(-0.20, 0.34)
        .toDouble();
    final space = _unit(0.56 + intimacy * 0.20 - arousal * 0.18 + release * 0.14);

    return EmotionIntent(
      valence: valence,
      arousal: arousal,
      tension: tension,
      intimacy: intimacy,
      brightness: brightness,
      resolution: resolution,
      densityMultiplier: densityMultiplier,
      velocityBias: velocityBias,
      registerShift: registerShift,
      rangeDelta: rangeDelta,
      contourLift: contourLift,
      space: space,
    );
  }

  EmotionSongAnalysis analyze({
    required SongDraft draft,
    required MoodType mood,
  }) {
    if (draft.sections.isEmpty) return EmotionSongAnalysis.empty();
    final target = _profile(mood);
    final samples = draft.sections.map(_sampleSection).toList(growable: false);

    final avgValence = _average(samples.map((sample) => sample.valence));
    final avgArousal = _average(samples.map((sample) => sample.arousal));
    final avgTension = _average(samples.map((sample) => sample.tension));
    final avgBrightness = _average(samples.map((sample) => sample.brightness));
    final avgResolution = _average(samples.map((sample) => sample.resolution));
    final avgSpace = _average(samples.map((sample) => sample.space));

    final moodFidelity = _scoreAverage(<double>[
      _closeness(avgValence, target.valence, 0.48),
      _closeness(avgArousal, target.arousal, 0.50),
      _closeness(avgTension, target.tension, 0.52),
      _closeness(avgBrightness, target.brightness, 0.50),
      _closeness(avgResolution, target.resolution, 0.52),
    ]);

    final arousalValues = samples.map((sample) => sample.arousal).toList(growable: false);
    final tensionValues = samples.map((sample) => sample.tension).toList(growable: false);
    final dynamicRange = _range(arousalValues);
    final tensionRange = _range(tensionValues);
    final expectedMotion = switch (mood) {
      MoodType.relaxed => 0.16,
      MoodType.dreamy => 0.18,
      MoodType.sad => 0.20,
      MoodType.mysterious => 0.24,
      MoodType.dark => 0.25,
      MoodType.happy => 0.27,
      MoodType.energetic => 0.31,
      MoodType.triumphant => 0.34,
    };
    final emotionalMotion = _scoreAverage(<double>[
      _windowScore(dynamicRange, expectedMotion * 0.62, expectedMotion * 1.85),
      _windowScore(tensionRange, max(0.10, expectedMotion * 0.52), 0.72),
    ]);

    final tensionRelease = _tensionReleaseScore(samples, mood);
    final dynamicExpression = _dynamicExpressionScore(draft, mood);
    final registerContour = _registerContourScore(draft, mood);
    final payoff = _payoffScore(samples, mood);
    final breathing = _breathingScore(avgSpace, mood);

    final metrics = <EmotionMetric>[
      EmotionMetric(
        dimension: EmotionDimension.moodFidelity,
        score: moodFidelity,
        label: 'Mood Fidelity',
        insight: 'Actual valence/arousal/tension profile follows ${mood.name} intent.',
      ),
      EmotionMetric(
        dimension: EmotionDimension.emotionalMotion,
        score: emotionalMotion,
        label: 'Emotional Motion',
        insight: 'Section-to-section energy range ${(dynamicRange * 100).round()}%, tension range ${(tensionRange * 100).round()}%.',
      ),
      EmotionMetric(
        dimension: EmotionDimension.tensionRelease,
        score: tensionRelease,
        label: 'Tension / Release',
        insight: 'Builds and releases are judged as a narrative rather than isolated sections.',
      ),
      EmotionMetric(
        dimension: EmotionDimension.dynamicExpression,
        score: dynamicExpression,
        label: 'Dynamic Expression',
        insight: 'Velocity movement and section contrast avoid emotionally flat playback.',
      ),
      EmotionMetric(
        dimension: EmotionDimension.registerContour,
        score: registerContour,
        label: 'Register Contour',
        insight: 'Melodic height and range reinforce the intended emotional lift.',
      ),
      EmotionMetric(
        dimension: EmotionDimension.payoff,
        score: payoff,
        label: 'Emotional Payoff',
        insight: 'Peak intensity lands in a musically meaningful payoff section.',
      ),
      EmotionMetric(
        dimension: EmotionDimension.breathingSpace,
        score: breathing,
        label: 'Breathing Space',
        insight: 'Density leaves enough room for the selected mood to read clearly.',
      ),
    ];

    const weights = <EmotionDimension, double>{
      EmotionDimension.moodFidelity: 0.18,
      EmotionDimension.emotionalMotion: 0.15,
      EmotionDimension.tensionRelease: 0.16,
      EmotionDimension.dynamicExpression: 0.14,
      EmotionDimension.registerContour: 0.12,
      EmotionDimension.payoff: 0.17,
      EmotionDimension.breathingSpace: 0.08,
    };
    var weighted = 0.0;
    for (final metric in metrics) {
      weighted += metric.score * weights[metric.dimension]!;
    }
    final weakest = metrics.reduce((a, b) => a.score <= b.score ? a : b).score;
    // A pretty average cannot hide one emotionally dead subsystem.
    final bottleneckPenalty = weakest < 62 ? (62 - weakest) * 0.22 : 0.0;
    final overall = (weighted - bottleneckPenalty).clamp(0.0, 100.0).toDouble();

    final peak = samples.reduce((a, b) => a.arousal >= b.arousal ? a : b);
    return EmotionSongAnalysis(
      overallScore: overall,
      metrics: metrics,
      peakSectionId: peak.sectionId,
      dynamicRange: dynamicRange,
    );
  }

  _SectionEmotionSample _sampleSection(GeneratedSongSection section) {
    final melody = section.melody;
    final progression = section.progression;
    final noteCount = melody.length;
    final avgVelocity = noteCount == 0
        ? 0.42
        : melody.fold<double>(0.0, (sum, note) => sum + note.velocity) / noteCount;
    final pitches = melody
        .map((note) => noteToPitch(note.note, note.octave))
        .toList(growable: false);
    final avgPitch = pitches.isEmpty
        ? 64.0
        : pitches.fold<double>(0.0, (sum, pitch) => sum + pitch) / pitches.length;
    final pitchRange = pitches.isEmpty
        ? 0.0
        : (pitches.reduce(max) - pitches.reduce(min)).toDouble();
    final bars = max(1, section.plan.bars);
    final density = noteCount / bars.toDouble();

    var majorish = 0;
    var minorish = 0;
    var tensionChords = 0;
    for (final chord in progression) {
      if (_isMajorish(chord.type)) majorish++;
      if (_isMinorish(chord.type)) minorish++;
      if (chord.harmonyFunction == HarmonyFunction.dominant ||
          chord.isBorrowed ||
          chord.isSecondaryDominant ||
          chord.isTritoneSubstitution ||
          chord.type == ChordTypeName.diminished ||
          chord.type == ChordTypeName.diminished7 ||
          chord.type == ChordTypeName.halfDim7) {
        tensionChords++;
      }
    }
    final harmonicCount = max(1, progression.length);
    final harmonicValence = (0.50 + (majorish - minorish) / harmonicCount * 0.28)
        .clamp(0.08, 0.92)
        .toDouble();
    final valence = _unit(harmonicValence * 0.68 + ((avgPitch - 55) / 30).clamp(0.0, 1.0) * 0.32);
    final arousal = _unit(avgVelocity * 0.53 + (density / 6.0).clamp(0.0, 1.0) * 0.29 + section.plan.targetEnergy * 0.18);
    final tension = _unit((tensionChords / harmonicCount) * 0.48 + section.plan.targetTension * 0.36 + (pitchRange / 24).clamp(0.0, 1.0) * 0.16);
    final brightness = _unit(((avgPitch - 54) / 32).clamp(0.0, 1.0) * 0.74 + harmonicValence * 0.26);

    var resolution = 0.46;
    if (progression.isNotEmpty) {
      final last = progression.last;
      if (last.harmonyFunction == HarmonyFunction.tonic ||
          last.degree == 'I' ||
          last.degree == 'i') {
        resolution += 0.34;
      }
      if (last.harmonyFunction == HarmonyFunction.dominant ||
          last.degree.startsWith('V')) {
        resolution -= 0.20;
      }
    }
    if (melody.isNotEmpty && progression.isNotEmpty) {
      final lastNote = melody.last;
      final chordIndex = lastNote.chordIndex.clamp(0, progression.length - 1).toInt();
      final chord = progression[chordIndex];
      if (getChordNotes(chord).contains(lastNote.note)) resolution += 0.12;
      if (lastNote.note == chord.root) resolution += 0.08;
    }
    resolution = _unit(resolution);
    final space = _unit(1.0 - (density / 6.5).clamp(0.0, 0.92));

    return _SectionEmotionSample(
      sectionId: section.plan.id,
      type: section.plan.type,
      valence: valence,
      arousal: arousal,
      tension: tension,
      brightness: brightness,
      resolution: resolution,
      space: space,
    );
  }

  double _tensionReleaseScore(List<_SectionEmotionSample> samples, MoodType mood) {
    if (samples.length < 2) return 62.0;
    final changes = <double>[];
    var meaningfulReleases = 0;
    var releaseOpportunities = 0;
    for (var i = 1; i < samples.length; i++) {
      final previous = samples[i - 1];
      final current = samples[i];
      changes.add((current.tension - previous.tension).abs());
      if (_isPayoffType(current.type) || current.type == SongSectionType.outro) {
        releaseOpportunities++;
        if (current.resolution > previous.resolution + 0.04 ||
            current.tension < previous.tension - 0.04) {
          meaningfulReleases++;
        }
      }
    }
    final motion = _average(changes);
    final motionScore = _windowScore(
      motion,
      mood == MoodType.relaxed ? 0.035 : 0.055,
      mood == MoodType.mysterious ? 0.42 : 0.34,
    );
    final releaseScore = releaseOpportunities == 0
        ? 78.0
        : (meaningfulReleases / releaseOpportunities * 100).clamp(35.0, 100.0).toDouble();
    return motionScore * 0.46 + releaseScore * 0.54;
  }

  double _dynamicExpressionScore(SongDraft draft, MoodType mood) {
    final velocities = <double>[];
    final sectionMeans = <double>[];
    for (final section in draft.sections) {
      if (section.melody.isEmpty) continue;
      final values = section.melody.map((note) => note.velocity).toList(growable: false);
      velocities.addAll(values);
      sectionMeans.add(_average(values));
    }
    if (velocities.length < 4) return 45.0;
    final globalRange = _range(velocities);
    final sectionRange = sectionMeans.length < 2 ? 0.0 : _range(sectionMeans);
    final minGlobal = switch (mood) {
      MoodType.relaxed => 0.07,
      MoodType.dreamy => 0.08,
      MoodType.sad => 0.09,
      _ => 0.12,
    };
    return _scoreAverage(<double>[
      _windowScore(globalRange, minGlobal, 0.62),
      _windowScore(sectionRange, minGlobal * 0.50, 0.42),
    ]);
  }

  double _registerContourScore(SongDraft draft, MoodType mood) {
    final centers = <double>[];
    final ranges = <double>[];
    for (final section in draft.sections) {
      if (section.melody.isEmpty) continue;
      final pitches = section.melody
          .map((note) => noteToPitch(note.note, note.octave))
          .toList(growable: false);
      centers.add(_average(pitches));
      ranges.add((pitches.reduce(max) - pitches.reduce(min)).toDouble());
    }
    if (centers.length < 2) return 62.0;
    final centerRange = _range(centers);
    final avgRange = _average(ranges);
    final desiredCenterMotion = switch (mood) {
      MoodType.relaxed => 1.4,
      MoodType.dreamy => 1.8,
      MoodType.sad => 1.8,
      MoodType.dark => 2.0,
      MoodType.mysterious => 2.2,
      MoodType.happy => 2.5,
      MoodType.energetic => 3.0,
      MoodType.triumphant => 3.4,
    };
    return _scoreAverage(<double>[
      _windowScore(centerRange, desiredCenterMotion * 0.55, desiredCenterMotion * 3.0),
      _windowScore(avgRange, 4.0, mood == MoodType.dark ? 14.0 : 18.0),
    ]);
  }

  double _payoffScore(List<_SectionEmotionSample> samples, MoodType mood) {
    if (samples.isEmpty) return 0.0;
    final peak = samples.reduce((a, b) => a.arousal >= b.arousal ? a : b);
    final peakIsPayoff = _isPayoffType(peak.type) ||
        peak.sectionId.toLowerCase().contains('drop') ||
        peak.sectionId.toLowerCase().contains('hook') ||
        peak.sectionId.toLowerCase().contains('climax');
    final maxArousal = peak.arousal;
    final minArousal = samples.map((sample) => sample.arousal).reduce(min);
    final lift = maxArousal - minArousal;
    final liftTarget = switch (mood) {
      MoodType.relaxed => 0.10,
      MoodType.dreamy => 0.12,
      MoodType.sad => 0.13,
      MoodType.mysterious => 0.16,
      MoodType.dark => 0.17,
      MoodType.happy => 0.19,
      MoodType.energetic => 0.23,
      MoodType.triumphant => 0.25,
    };
    final locationScore = peakIsPayoff ? 100.0 : (mood == MoodType.relaxed ? 82.0 : 54.0);
    return locationScore * 0.58 + _windowScore(lift, liftTarget * 0.55, 0.70) * 0.42;
  }

  double _breathingScore(double avgSpace, MoodType mood) {
    final (low, high) = switch (mood) {
      MoodType.relaxed => (0.42, 0.92),
      MoodType.dreamy => (0.36, 0.88),
      MoodType.sad => (0.34, 0.86),
      MoodType.mysterious => (0.28, 0.80),
      MoodType.dark => (0.22, 0.74),
      MoodType.happy => (0.18, 0.66),
      MoodType.energetic => (0.10, 0.52),
      MoodType.triumphant => (0.12, 0.56),
    };
    return _windowScore(avgSpace, low, high);
  }

  _MoodProfile _profile(MoodType mood) => switch (mood) {
        MoodType.happy => const _MoodProfile(
            valence: 0.86,
            arousal: 0.68,
            tension: 0.35,
            intimacy: 0.44,
            brightness: 0.76,
            resolution: 0.76,
          ),
        MoodType.sad => const _MoodProfile(
            valence: 0.22,
            arousal: 0.38,
            tension: 0.54,
            intimacy: 0.74,
            brightness: 0.34,
            resolution: 0.58,
          ),
        MoodType.dreamy => const _MoodProfile(
            valence: 0.62,
            arousal: 0.34,
            tension: 0.43,
            intimacy: 0.76,
            brightness: 0.63,
            resolution: 0.54,
          ),
        MoodType.energetic => const _MoodProfile(
            valence: 0.72,
            arousal: 0.94,
            tension: 0.55,
            intimacy: 0.32,
            brightness: 0.76,
            resolution: 0.70,
          ),
        MoodType.dark => const _MoodProfile(
            valence: 0.16,
            arousal: 0.65,
            tension: 0.79,
            intimacy: 0.44,
            brightness: 0.20,
            resolution: 0.36,
          ),
        MoodType.mysterious => const _MoodProfile(
            valence: 0.38,
            arousal: 0.52,
            tension: 0.84,
            intimacy: 0.60,
            brightness: 0.34,
            resolution: 0.28,
          ),
        MoodType.triumphant => const _MoodProfile(
            valence: 0.92,
            arousal: 0.88,
            tension: 0.62,
            intimacy: 0.30,
            brightness: 0.86,
            resolution: 0.92,
          ),
        MoodType.relaxed => const _MoodProfile(
            valence: 0.72,
            arousal: 0.22,
            tension: 0.24,
            intimacy: 0.84,
            brightness: 0.60,
            resolution: 0.74,
          ),
      };

  _RoleShape _roleShape(SongSectionPlan section) {
    final id = section.id.toLowerCase();
    if (id.contains('final') || id.contains('climax')) {
      return const _RoleShape(payoff: 1.0, release: 0.08, intimacy: -0.2, shadow: 0.0);
    }
    if (id.contains('drop') || id.contains('hook') || section.type == SongSectionType.chorus) {
      return _RoleShape(
        payoff: 0.72 + section.variation.clamp(0, 2) * 0.10,
        release: 0.06,
        intimacy: -0.08,
        shadow: 0.0,
      );
    }
    if (id.contains('build') || section.type == SongSectionType.preChorus) {
      return const _RoleShape(payoff: 0.18, release: 0.0, intimacy: -0.06, shadow: 0.10);
    }
    if (id.contains('breakdown') || section.type == SongSectionType.bridge) {
      return const _RoleShape(payoff: 0.05, release: 0.18, intimacy: 0.20, shadow: 0.24);
    }
    if (section.type == SongSectionType.outro) {
      return const _RoleShape(payoff: 0.0, release: 0.92, intimacy: 0.20, shadow: 0.06);
    }
    if (section.type == SongSectionType.verse) {
      return const _RoleShape(payoff: 0.02, release: 0.08, intimacy: 0.24, shadow: 0.08);
    }
    return const _RoleShape(payoff: 0.0, release: 0.18, intimacy: 0.12, shadow: 0.06);
  }

  bool _isMajorish(ChordTypeName type) =>
      type == ChordTypeName.major ||
      type == ChordTypeName.major7 ||
      type == ChordTypeName.major9 ||
      type == ChordTypeName.add9 ||
      type == ChordTypeName.sus2 ||
      type == ChordTypeName.sus4;

  bool _isMinorish(ChordTypeName type) =>
      type == ChordTypeName.minor ||
      type == ChordTypeName.minor7 ||
      type == ChordTypeName.minor9 ||
      type == ChordTypeName.diminished ||
      type == ChordTypeName.diminished7 ||
      type == ChordTypeName.halfDim7;

  bool _isPayoffType(SongSectionType type) => type == SongSectionType.chorus;

  double _scoreAverage(Iterable<double> values) {
    final list = values.toList(growable: false);
    if (list.isEmpty) return 0.0;
    return _average(list).clamp(0.0, 100.0).toDouble();
  }

  double _average(Iterable<num> values) {
    final list = values.toList(growable: false);
    if (list.isEmpty) return 0.0;
    return list.fold<double>(0.0, (sum, value) => sum + value.toDouble()) /
        list.length;
  }

  double _range(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce(max) - values.reduce(min);
  }

  double _closeness(double value, double target, double tolerance) =>
      (100.0 - ((value - target).abs() / max(0.001, tolerance)) * 100.0)
          .clamp(20.0, 100.0)
          .toDouble();

  double _windowScore(double value, double low, double high) {
    if (value >= low && value <= high) return 100.0;
    final span = max(0.001, high - low);
    final distance = value < low ? low - value : value - high;
    return (100.0 - distance / span * 100.0).clamp(20.0, 100.0).toDouble();
  }

  double _unit(num value) => value.clamp(0.0, 1.0).toDouble();
}

class _RoleShape {
  const _RoleShape({
    required this.payoff,
    required this.release,
    required this.intimacy,
    required this.shadow,
  });

  final double payoff;
  final double release;
  final double intimacy;
  final double shadow;
}
