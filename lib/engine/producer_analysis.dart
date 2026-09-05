import 'dart:math';

import '../models/constants.dart';
import '../models/types.dart';
import '../utils/music_theory.dart';
import 'harmony_engine.dart';

enum ProducerDimension {
  harmony,
  melody,
  bass,
  motifCoherence,
  rhythm,
  genreAuthenticity,
  tension,
  repetition,
  playability,
  surprise,
}

class ProducerMetric {
  const ProducerMetric({
    required this.dimension,
    required this.label,
    required this.score,
    required this.weight,
    required this.insight,
    required this.action,
    this.active = true,
  });

  final ProducerDimension dimension;
  final String label;
  final double score;
  final double weight;
  final String insight;
  final String action;
  final bool active;

  bool get needsAttention => active && score < 72.0;
  bool get isStrength => active && score >= 84.0;
}

class ProducerAnalysis {
  const ProducerAnalysis({
    required this.overallScore,
    required this.metrics,
  });

  factory ProducerAnalysis.empty() => const ProducerAnalysis(
        overallScore: 0,
        metrics: <ProducerMetric>[],
      );

  final double overallScore;
  final List<ProducerMetric> metrics;

  ProducerMetric? metricFor(ProducerDimension dimension) {
    for (final metric in metrics) {
      if (metric.dimension == dimension) return metric;
    }
    return null;
  }

  List<ProducerMetric> get priorities {
    final result = metrics.where((metric) => metric.active).toList()
      ..sort((a, b) => a.score.compareTo(b.score));
    return List<ProducerMetric>.unmodifiable(result.take(3));
  }

  List<ProducerMetric> get strengths {
    final result = metrics.where((metric) => metric.isStrength).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return List<ProducerMetric>.unmodifiable(result.take(3));
  }
}

/// Producer Brain 2.0 quality model.
///
/// Unlike the original harmony-only confidence value, this analyzer judges the
/// generated musical result as a system. Inactive layers (for example melody
/// when melody generation is disabled) remain visible to the UI but are not
/// allowed to lower the weighted overall score.
class ProducerAnalyzer {
  ProducerAnalyzer({HarmonyEngine? harmonyEngine})
      : _harmonyEngine = harmonyEngine ?? HarmonyEngine(seed: 0);

  final HarmonyEngine _harmonyEngine;

  ProducerAnalysis analyze({
    required List<Chord> progression,
    required List<MelodyNote> melody,
    required List<BassNote> bass,
    required GenreKey genre,
    required RhythmLevel rhythm,
    required HarmonySection section,
    required SpiceLevel spice,
    required int tempo,
    required double swing,
    required GrooveTemplate grooveTemplate,
  }) {
    if (progression.isEmpty) return ProducerAnalysis.empty();

    final metrics = <ProducerMetric>[
      _harmonyMetric(progression, section),
      _melodyMetric(progression, melody),
      _bassMetric(progression, bass),
      _motifMetric(progression, melody),
      _rhythmMetric(progression, melody, bass, rhythm, swing),
      _genreMetric(
        progression,
        melody,
        bass,
        genre,
        tempo,
        swing,
        grooveTemplate,
      ),
      _tensionMetric(progression, melody, section),
      _repetitionMetric(progression, melody),
      _playabilityMetric(progression, melody, bass),
      _surpriseMetric(progression, melody, spice),
    ];

    var weighted = 0.0;
    var weightTotal = 0.0;
    for (final metric in metrics) {
      if (!metric.active) continue;
      weighted += metric.score * metric.weight;
      weightTotal += metric.weight;
    }

    final overall = weightTotal == 0 ? 0.0 : weighted / weightTotal;
    return ProducerAnalysis(
      overallScore: _score(overall),
      metrics: List<ProducerMetric>.unmodifiable(metrics),
    );
  }

  ProducerMetric _harmonyMetric(
    List<Chord> progression,
    HarmonySection section,
  ) {
    final value = _harmonyEngine.score(progression, section: section);
    final finalDegree = progression.last.degree;
    final insight = value >= 84
        ? 'Strong harmonic grammar and section-aware resolution.'
        : value >= 70
            ? 'Harmony is functional, but its directional pull can be clearer.'
            : 'The progression lacks enough functional motion or convincing resolution.';
    final action = value >= 84
        ? 'Keep the harmonic skeleton; spend variation budget on other layers.'
        : finalDegree.startsWith('V') || finalDegree.startsWith('v')
            ? 'Use the unresolved dominant deliberately, or resolve it in the next section.'
            : 'Strengthen predominant → dominant → tonic motion and reduce redundant roots.';
    return ProducerMetric(
      dimension: ProducerDimension.harmony,
      label: 'Harmony',
      score: value,
      weight: 0.16,
      insight: insight,
      action: action,
    );
  }

  ProducerMetric _melodyMetric(
    List<Chord> progression,
    List<MelodyNote> melody,
  ) {
    if (melody.isEmpty) {
      return const ProducerMetric(
        dimension: ProducerDimension.melody,
        label: 'Melody',
        score: 0,
        weight: 0.12,
        insight: 'Melody generation is disabled for this result.',
        action: 'Enable melody to include melodic fit, contour, range, and phrasing in Producer Brain scoring.',
        active: false,
      );
    }

    final chordToneRatio = _chordToneRatio(progression, melody);
    final pitches = melody.map(_melodyPitch).toList(growable: false);
    final leapStats = _leapStats(pitches);
    final range = pitches.reduce(max) - pitches.reduce(min);
    final rangeScore = range <= 4
        ? 62.0
        : range <= 17
            ? 100.0
            : range <= 24
                ? 78.0
                : 48.0;
    final durationVariety = _normalizedVariety(
      melody.map((note) => note.duration.toStringAsFixed(3)),
      ideal: 0.32,
    );
    final dynamicSpread = _dynamicSpread(melody.map((note) => note.velocity));
    final dynamicScore = _closeness(dynamicSpread, 0.28, tolerance: 0.32);

    final value = _score(
      chordToneRatio * 42 +
          leapStats.controlledRatio * 23 +
          rangeScore * 0.15 +
          durationVariety * 0.10 +
          dynamicScore * 0.10,
    );

    String action;
    if (chordToneRatio < 0.58) {
      action = 'Land more phrase accents on chord tones, especially on chord changes.';
    } else if (leapStats.largeLeapRatio > 0.22) {
      action = 'Reduce repeated leaps larger than a fifth and connect peaks with stepwise motion.';
    } else if (range > 24) {
      action = 'Compress the melodic register so the line reads as one singable phrase.';
    } else {
      action = 'Preserve the contour; add one controlled variation at the phrase ending.';
    }

    return ProducerMetric(
      dimension: ProducerDimension.melody,
      label: 'Melody',
      score: value,
      weight: 0.12,
      insight:
          '${(chordToneRatio * 100).round()}% chord-tone fit, ${range.round()}-semitone range, ${(leapStats.largeLeapRatio * 100).round()}% large leaps.',
      action: action,
    );
  }

  ProducerMetric _bassMetric(
    List<Chord> progression,
    List<BassNote> bass,
  ) {
    if (bass.isEmpty) {
      return const ProducerMetric(
        dimension: ProducerDimension.bass,
        label: 'Bass',
        score: 0,
        weight: 0.10,
        insight: 'Bass generation is disabled for this result.',
        action: 'Enable bass to include harmonic anchoring, register, and movement in Producer Brain scoring.',
        active: false,
      );
    }

    var chordTones = 0;
    var roots = 0;
    for (final note in bass) {
      if (note.chordIndex < 0 || note.chordIndex >= progression.length) continue;
      final chord = progression[note.chordIndex];
      final pitchClass = getNoteIndex(note.note);
      if (pitchClass == getNoteIndex(chord.root)) roots++;
      final chordPitchClasses = getChordNotes(chord).map(getNoteIndex).toSet();
      if (chordPitchClasses.contains(pitchClass)) chordTones++;
    }

    final chordToneRatio = chordTones / max(1, bass.length);
    final rootRatio = roots / max(1, bass.length);
    final pitches = bass.map(_bassPitch).toList(growable: false);
    final leaps = _leapStats(pitches);
    final range = pitches.reduce(max) - pitches.reduce(min);
    final registerScore = pitches.every((pitch) => pitch >= 24 && pitch <= 55)
        ? 100.0
        : 68.0;
    final rootBalance = _closeness(rootRatio, 0.58, tolerance: 0.48);
    final rangeScore = range <= 19 ? 100.0 : (range <= 28 ? 76.0 : 52.0);

    final value = _score(
      chordToneRatio * 38 +
          rootBalance * 0.20 +
          leaps.controlledRatio * 20 +
          registerScore * 0.12 +
          rangeScore * 0.10,
    );

    String action;
    if (chordToneRatio < 0.68) {
      action = 'Anchor strong beats to roots or chord tones before using passing notes.';
    } else if (rootRatio > 0.88) {
      action = 'Keep the anchors but add fifths, octaves, or stepwise approach tones for movement.';
    } else if (leaps.largeLeapRatio > 0.28) {
      action = 'Smooth the bass contour and reserve octave jumps for structural accents.';
    } else {
      action = 'Bass support is balanced; preserve the anchor-to-motion ratio.';
    }

    return ProducerMetric(
      dimension: ProducerDimension.bass,
      label: 'Bass',
      score: value,
      weight: 0.10,
      insight:
          '${(chordToneRatio * 100).round()}% chord tones, ${(rootRatio * 100).round()}% roots, ${(leaps.largeLeapRatio * 100).round()}% large leaps.',
      action: action,
    );
  }

  ProducerMetric _motifMetric(
    List<Chord> progression,
    List<MelodyNote> melody,
  ) {
    if (melody.length >= 6) {
      final pitches = melody.map(_melodyPitch).toList(growable: false);
      final intervals = <int>[];
      for (var i = 1; i < pitches.length; i++) {
        intervals.add((pitches[i] - pitches[i - 1]).clamp(-12, 12));
      }
      final grams = <String>[];
      for (var i = 1; i < intervals.length; i++) {
        grams.add('${intervals[i - 1]},${intervals[i]}');
      }
      final repeatCoverage = _repeatCoverage(grams);
      final returnRate = _pitchClassReturnRate(melody);
      final value = _score(
        _closeness(repeatCoverage, 0.38, tolerance: 0.42) * 0.72 +
            _closeness(returnRate, 0.30, tolerance: 0.34) * 0.28,
      );
      return ProducerMetric(
        dimension: ProducerDimension.motifCoherence,
        label: 'Motif Coherence',
        score: value,
        weight: 0.11,
        insight:
            '${(repeatCoverage * 100).round()}% interval-motif recurrence with ${(returnRate * 100).round()}% anchor-note returns.',
        action: repeatCoverage < 0.18
            ? 'Repeat a short interval shape across the phrase, then vary its ending.'
            : repeatCoverage > 0.72
                ? 'Keep the motif identity but mutate rhythm, ending note, or register on later returns.'
                : 'Motif recurrence is healthy; retain one recognizable cell across section changes.',
      );
    }

    if (progression.length >= 6) {
      final degrees = progression.map((chord) => _degreeToken(chord.degree)).toList();
      final grams = <String>[];
      for (var i = 1; i < degrees.length; i++) {
        grams.add('${degrees[i - 1]}>${degrees[i]}');
      }
      final repeatCoverage = _repeatCoverage(grams);
      final value = _closeness(repeatCoverage, 0.30, tolerance: 0.42);
      return ProducerMetric(
        dimension: ProducerDimension.motifCoherence,
        label: 'Motif Coherence',
        score: value,
        weight: 0.11,
        insight: 'Harmony supplies the current motif signal because the melody is too short.',
        action: repeatCoverage < 0.15
            ? 'Create a recognizable two-chord cell or enable melody for stronger motif analysis.'
            : 'Preserve the recurring harmonic cell while varying one arrival point.',
      );
    }

    return const ProducerMetric(
      dimension: ProducerDimension.motifCoherence,
      label: 'Motif Coherence',
      score: 0,
      weight: 0.11,
      insight: 'Not enough phrase material exists to measure motif recurrence reliably.',
      action: 'Generate a longer phrase or enable melody to unlock motif analysis.',
      active: false,
    );
  }

  ProducerMetric _rhythmMetric(
    List<Chord> progression,
    List<MelodyNote> melody,
    List<BassNote> bass,
    RhythmLevel rhythm,
    double swing,
  ) {
    final durations = <double>[
      ...melody.map((note) => note.duration),
      ...bass.map((note) => note.duration),
    ];
    final velocities = <double>[
      ...melody.map((note) => note.velocity),
      ...bass.map((note) => note.velocity),
    ];

    if (durations.isEmpty) {
      return const ProducerMetric(
        dimension: ProducerDimension.rhythm,
        label: 'Rhythm',
        score: 0,
        weight: 0.10,
        insight: 'No note-level rhythmic material is available for analysis.',
        action: 'Enable melody or bass so rhythmic density, accents, and duration variety can be evaluated.',
        active: false,
      );
    }

    final durationVariety = _normalizedVariety(
      durations.map((duration) => duration.toStringAsFixed(3)),
      ideal: _rhythmVarietyTarget(rhythm),
    );
    final dynamicSpread = _dynamicSpread(velocities);
    final targetSpread = switch (rhythm) {
      RhythmLevel.soft => 0.16,
      RhythmLevel.moderate => 0.24,
      RhythmLevel.strong => 0.32,
      RhythmLevel.intense => 0.40,
    };
    final dynamicScore = _closeness(dynamicSpread, targetSpread, tolerance: 0.36);
    final density = durations.length / max(1, progression.length);
    final targetDensity = switch (rhythm) {
      RhythmLevel.soft => 2.5,
      RhythmLevel.moderate => 3.5,
      RhythmLevel.strong => 4.5,
      RhythmLevel.intense => 5.5,
    };
    final densityScore = _closeness(density, targetDensity, tolerance: 4.5);
    final swingScore = swing <= 0.52 ? 100.0 : 76.0;

    final value = _score(
      durationVariety * 0.34 +
          dynamicScore * 0.30 +
          densityScore * 0.26 +
          swingScore * 0.10,
    );

    return ProducerMetric(
      dimension: ProducerDimension.rhythm,
      label: 'Rhythm',
      score: value,
      weight: 0.10,
      insight:
          '${density.toStringAsFixed(1)} notes/chord, ${(dynamicSpread * 100).round()}% dynamic spread, ${(swing * 100).round()}% swing.',
      action: densityScore < 70
          ? density < targetDensity
              ? 'Increase rhythmic activity or add pickup notes to match the selected intensity.'
              : 'Create more space; remove low-value subdivisions that blur the groove.'
          : dynamicScore < 70
              ? 'Shape stronger accent contrast instead of keeping every hit at similar velocity.'
              : 'Rhythmic density and accents fit the requested intensity; preserve the groove hierarchy.',
    );
  }

  ProducerMetric _genreMetric(
    List<Chord> progression,
    List<MelodyNote> melody,
    List<BassNote> bass,
    GenreKey genre,
    int tempo,
    double swing,
    GrooveTemplate grooveTemplate,
  ) {
    final profile = genreProfiles[genre];
    final expectedTempo = profile?.tempo ?? tempo;
    final tempoScore = _closeness(
      tempo.toDouble(),
      expectedTempo.toDouble(),
      tolerance: 32.0,
    );

    var progressionScore = 70.0;
    if (profile != null && profile.progressions.isNotEmpty) {
      progressionScore = 0.0;
      final degrees = progression.map((chord) => _degreeToken(chord.degree)).toList();
      for (final pattern in profile.progressions) {
        final normalized = pattern.map(_degreeToken).toList();
        progressionScore = max(
          progressionScore,
          _progressionSimilarity(degrees, normalized),
        );
      }
    }

    final alteredRatio = progression.where(_isAlteredChord).length / progression.length;
    final genreAlterationTarget = switch (genre) {
      GenreKey.jazzFusion || GenreKey.soulfulRnb => 0.28,
      GenreKey.darkTrap || GenreKey.cinematic => 0.18,
      GenreKey.blues || GenreKey.funk => 0.14,
      _ => 0.08,
    };
    final alterationScore = _closeness(
      alteredRatio,
      genreAlterationTarget,
      tolerance: 0.34,
    );

    final grooveBonus = _genreGrooveFit(genre, grooveTemplate, swing);
    final layerPresence = (melody.isNotEmpty ? 1 : 0) + (bass.isNotEmpty ? 1 : 0);
    final arrangementScore = layerPresence == 2 ? 100.0 : (layerPresence == 1 ? 82.0 : 66.0);

    final value = _score(
      tempoScore * 0.28 +
          progressionScore * 0.34 +
          alterationScore * 0.16 +
          grooveBonus * 0.14 +
          arrangementScore * 0.08,
    );

    String action;
    if (tempoScore < 68) {
      action = 'Move tempo closer to the genre center (${expectedTempo} BPM) unless the mismatch is intentional.';
    } else if (progressionScore < 62) {
      action = 'Use a more genre-native harmonic backbone, then add color tones without losing that identity.';
    } else if (grooveBonus < 68) {
      action = 'Choose a groove/swing profile that better matches the selected genre before adding more notes.';
    } else {
      action = 'Genre identity is readable; keep one signature trait while allowing controlled cross-genre color.';
    }

    return ProducerMetric(
      dimension: ProducerDimension.genreAuthenticity,
      label: 'Genre Authenticity',
      score: value,
      weight: 0.12,
      insight:
          '$tempo BPM vs ${expectedTempo} BPM center; ${progressionScore.round()}% progression-profile fit.',
      action: action,
    );
  }

  ProducerMetric _tensionMetric(
    List<Chord> progression,
    List<MelodyNote> melody,
    HarmonySection section,
  ) {
    final alteredRatio = progression.where(_isAlteredChord).length / progression.length;
    final dominantEnding = _degreeToken(progression.last.degree).toUpperCase() == 'V';
    final resolvesHome = progression.length >= 2 &&
        _degreeToken(progression[progression.length - 2].degree).toUpperCase() == 'V' &&
        {'I', 'i'}.contains(_degreeToken(progression.last.degree));
    final nonChordToneRatio = melody.isEmpty ? 0.0 : 1.0 - _chordToneRatio(progression, melody);

    var tension = 0.30 + alteredRatio * 0.35 + nonChordToneRatio * 0.24;
    if (dominantEnding) tension += 0.24;
    if (resolvesHome) tension -= 0.18;
    tension = tension.clamp(0.0, 1.0).toDouble();

    final target = switch (section) {
      HarmonySection.verse => 0.38,
      HarmonySection.preChorus => 0.72,
      HarmonySection.chorus => 0.45,
      HarmonySection.bridge => 0.62,
      HarmonySection.neutral => 0.48,
    };
    final value = _closeness(tension, target, tolerance: 0.52);

    return ProducerMetric(
      dimension: ProducerDimension.tension,
      label: 'Tension',
      score: value,
      weight: 0.09,
      insight:
          '${(tension * 100).round()}% estimated tension against a ${(target * 100).round()}% ${section.name} target.',
      action: tension < target - 0.12
          ? 'Increase forward pull with dominant preparation, suspensions, or a controlled non-chord tone.'
          : tension > target + 0.12
              ? 'Release some pressure with a clearer consonant landing or fewer simultaneous color devices.'
              : 'Tension matches the section role; preserve the release point that follows it.',
    );
  }

  ProducerMetric _repetitionMetric(
    List<Chord> progression,
    List<MelodyNote> melody,
  ) {
    final chordTokens = progression.map((chord) => _degreeToken(chord.degree)).toList();
    final chordUniqueRatio = chordTokens.toSet().length / chordTokens.length;
    var consecutiveRepeats = 0;
    for (var i = 1; i < chordTokens.length; i++) {
      if (chordTokens[i] == chordTokens[i - 1]) consecutiveRepeats++;
    }

    final chordBalance = _closeness(chordUniqueRatio, 0.62, tolerance: 0.52);
    final repeatPenalty = (consecutiveRepeats * 12).clamp(0, 36).toDouble();

    var melodyBalance = 78.0;
    if (melody.isNotEmpty) {
      final pitchClasses = melody.map((note) => getNoteIndex(note.note).toString()).toList();
      final uniqueRatio = pitchClasses.toSet().length / pitchClasses.length;
      melodyBalance = _closeness(uniqueRatio, 0.42, tolerance: 0.42);
    }

    final value = _score(chordBalance * 0.58 + melodyBalance * 0.42 - repeatPenalty);
    return ProducerMetric(
      dimension: ProducerDimension.repetition,
      label: 'Repetition',
      score: value,
      weight: 0.08,
      insight:
          '${(chordUniqueRatio * 100).round()}% harmonic uniqueness with $consecutiveRepeats immediate chord repeats.',
      action: chordUniqueRatio > 0.88
          ? 'Repeat one structural idea sooner so the listener gets a stronger memory anchor.'
          : chordUniqueRatio < 0.34 || consecutiveRepeats > 1
              ? 'Replace low-information repeats with a substitution, inversion, or rhythmic variation.'
              : 'Repetition and variation are balanced; preserve the recognizable returns.',
    );
  }

  ProducerMetric _playabilityMetric(
    List<Chord> progression,
    List<MelodyNote> melody,
    List<BassNote> bass,
  ) {
    final parts = <double>[];

    if (melody.length >= 2) {
      final pitches = melody.map(_melodyPitch).toList();
      final leaps = _leapStats(pitches);
      final range = pitches.reduce(max) - pitches.reduce(min);
      parts.add(_score(leaps.controlledRatio * 72 + (range <= 24 ? 28 : 12)));
    }

    if (bass.length >= 2) {
      final pitches = bass.map(_bassPitch).toList();
      final leaps = _leapStats(pitches);
      final range = pitches.reduce(max) - pitches.reduce(min);
      parts.add(_score(leaps.controlledRatio * 76 + (range <= 24 ? 24 : 10)));
    }

    if (progression.length >= 2) {
      var smooth = 0.0;
      var transitions = 0;
      for (var i = 1; i < progression.length; i++) {
        final a = getChordNotes(progression[i - 1]).map(getNoteIndex).toList();
        final b = getChordNotes(progression[i]).map(getNoteIndex).toList();
        if (a.isEmpty || b.isEmpty) continue;
        var nearestTotal = 0.0;
        for (final pitch in b) {
          var nearest = 12;
          for (final previous in a) {
            final raw = (pitch - previous).abs();
            nearest = min(nearest, min(raw, 12 - raw));
          }
          nearestTotal += nearest;
        }
        final average = nearestTotal / b.length;
        smooth += _closeness(average, 1.6, tolerance: 3.6);
        transitions++;
      }
      if (transitions > 0) parts.add(smooth / transitions);
    }

    if (parts.isEmpty) {
      return const ProducerMetric(
        dimension: ProducerDimension.playability,
        label: 'Playability',
        score: 0,
        weight: 0.06,
        insight: 'Not enough performed-note data exists for playability analysis.',
        action: 'Generate at least two musical events in a performed layer.',
        active: false,
      );
    }

    final value = _score(parts.reduce((a, b) => a + b) / parts.length);
    return ProducerMetric(
      dimension: ProducerDimension.playability,
      label: 'Playability',
      score: value,
      weight: 0.06,
      insight: 'Register, interval size, and harmonic movement are scored together for practical performance.',
      action: value < 68
          ? 'Reduce extreme register jumps and connect difficult transitions with closer voice leading.'
          : 'The material is physically plausible; keep expressive jumps as intentional accents.',
    );
  }

  ProducerMetric _surpriseMetric(
    List<Chord> progression,
    List<MelodyNote> melody,
    SpiceLevel spice,
  ) {
    final alteredRatio = progression.where(_isAlteredChord).length / progression.length;
    var nonChordRatio = 0.0;
    var largeLeapRatio = 0.0;
    if (melody.isNotEmpty) {
      nonChordRatio = 1.0 - _chordToneRatio(progression, melody);
      final pitches = melody.map(_melodyPitch).toList();
      largeLeapRatio = _leapStats(pitches).largeLeapRatio;
    }

    final surprise = (alteredRatio * 0.56 + nonChordRatio * 0.28 + largeLeapRatio * 0.16)
        .clamp(0.0, 1.0)
        .toDouble();
    final target = switch (spice) {
      SpiceLevel.mild => 0.10,
      SpiceLevel.medium => 0.20,
      SpiceLevel.hot => 0.32,
      SpiceLevel.fire => 0.45,
    };
    final value = _closeness(surprise, target, tolerance: 0.42);

    return ProducerMetric(
      dimension: ProducerDimension.surprise,
      label: 'Surprise',
      score: value,
      weight: 0.06,
      insight:
          '${(surprise * 100).round()}% surprise against a ${(target * 100).round()}% ${spice.name} target.',
      action: surprise < target - 0.10
          ? 'Add one high-value surprise: borrowed harmony, a delayed resolution, or a melodic outside tone.'
          : surprise > target + 0.12
              ? 'Remove one competing novelty so the strongest surprise can read clearly.'
              : 'Novelty matches the selected spice level; avoid adding decoration that dilutes it.',
    );
  }

  double _chordToneRatio(
    List<Chord> progression,
    List<MelodyNote> melody,
  ) {
    var valid = 0;
    var matches = 0;
    for (final note in melody) {
      if (note.chordIndex < 0 || note.chordIndex >= progression.length) continue;
      valid++;
      final chordPitches = getChordNotes(progression[note.chordIndex])
          .map(getNoteIndex)
          .toSet();
      if (chordPitches.contains(getNoteIndex(note.note))) matches++;
    }
    return valid == 0 ? 0.0 : matches / valid;
  }

  int _melodyPitch(MelodyNote note) => note.octave * 12 + getNoteIndex(note.note);
  int _bassPitch(BassNote note) => note.octave * 12 + getNoteIndex(note.note);

  _LeapStats _leapStats(List<int> pitches) {
    if (pitches.length < 2) return const _LeapStats(1.0, 0.0);
    var controlled = 0;
    var large = 0;
    for (var i = 1; i < pitches.length; i++) {
      final distance = (pitches[i] - pitches[i - 1]).abs();
      if (distance <= 7) controlled++;
      if (distance > 7) large++;
    }
    final total = pitches.length - 1;
    return _LeapStats(controlled / total, large / total);
  }

  double _dynamicSpread(Iterable<double> values) {
    if (values.isEmpty) return 0.0;
    final list = values.toList();
    final low = list.reduce(min);
    final high = list.reduce(max);
    return (high - low).abs().clamp(0.0, 1.0).toDouble();
  }

  double _normalizedVariety(Iterable<String> tokens, {required double ideal}) {
    final list = tokens.toList();
    if (list.isEmpty) return 0.0;
    final ratio = list.toSet().length / list.length;
    return _closeness(ratio, ideal, tolerance: 0.48);
  }

  double _pitchClassReturnRate(List<MelodyNote> melody) {
    if (melody.length < 2) return 0.0;
    final counts = <int, int>{};
    for (final note in melody) {
      final pitch = getNoteIndex(note.note);
      counts[pitch] = (counts[pitch] ?? 0) + 1;
    }
    final returned = melody.where((note) => (counts[getNoteIndex(note.note)] ?? 0) > 1).length;
    return returned / melody.length;
  }

  double _repeatCoverage(List<String> grams) {
    if (grams.isEmpty) return 0.0;
    final counts = <String, int>{};
    for (final gram in grams) {
      counts[gram] = (counts[gram] ?? 0) + 1;
    }
    final repeated = grams.where((gram) => (counts[gram] ?? 0) > 1).length;
    return repeated / grams.length;
  }

  double _progressionSimilarity(List<String> actual, List<String> expected) {
    if (actual.isEmpty || expected.isEmpty) return 0.0;
    final compared = min(actual.length, expected.length);
    var positional = 0;
    for (var i = 0; i < compared; i++) {
      if (actual[i] == expected[i]) positional++;
    }
    final positionalScore = positional / max(actual.length, expected.length);
    final expectedSet = expected.toSet();
    final coverage = actual.where(expectedSet.contains).length / actual.length;
    return _score((positionalScore * 0.68 + coverage * 0.32) * 100);
  }

  double _genreGrooveFit(
    GenreKey genre,
    GrooveTemplate grooveTemplate,
    double swing,
  ) {
    final preferred = switch (genre) {
      GenreKey.energeticEdm => <GrooveTemplate>{GrooveTemplate.fourOnFloor, GrooveTemplate.straight},
      GenreKey.soulfulRnb => <GrooveTemplate>{GrooveTemplate.neoSoulSwing, GrooveTemplate.halfTime},
      GenreKey.jazzFusion => <GrooveTemplate>{GrooveTemplate.shuffle, GrooveTemplate.neoSoulSwing},
      GenreKey.darkTrap => <GrooveTemplate>{GrooveTemplate.halfTime, GrooveTemplate.straight},
      GenreKey.funk => <GrooveTemplate>{GrooveTemplate.funkSyncopation},
      GenreKey.reggae => <GrooveTemplate>{GrooveTemplate.straight, GrooveTemplate.funkSyncopation},
      GenreKey.blues => <GrooveTemplate>{GrooveTemplate.shuffle},
      _ => <GrooveTemplate>{GrooveTemplate.straight, GrooveTemplate.fourOnFloor},
    };
    var value = preferred.contains(grooveTemplate) ? 100.0 : 72.0;
    if ((genre == GenreKey.soulfulRnb || genre == GenreKey.jazzFusion || genre == GenreKey.blues) &&
        swing >= 0.12 && swing <= 0.48) {
      value += 8.0;
    }
    return _score(value);
  }

  double _rhythmVarietyTarget(RhythmLevel rhythm) => switch (rhythm) {
        RhythmLevel.soft => 0.22,
        RhythmLevel.moderate => 0.30,
        RhythmLevel.strong => 0.36,
        RhythmLevel.intense => 0.42,
      };

  String _degreeToken(String degree) {
    final trimmed = degree.trim();
    final beforeSlash = trimmed.split('/').first;
    final match = RegExp(r'([b#]?[IViv]+)').firstMatch(beforeSlash);
    return match?.group(1) ?? beforeSlash;
  }

  bool _isAlteredChord(Chord chord) =>
      chord.isBorrowed || chord.isSecondaryDominant || chord.isTritoneSubstitution;

  double _closeness(double value, double target, {required double tolerance}) {
    if (tolerance <= 0) return value == target ? 100.0 : 0.0;
    final normalized = 1.0 - ((value - target).abs() / tolerance);
    return _score(normalized * 100);
  }

  double _score(num value) => value.clamp(0.0, 100.0).toDouble();
}

class _LeapStats {
  const _LeapStats(this.controlledRatio, this.largeLeapRatio);

  final double controlledRatio;
  final double largeLeapRatio;
}
