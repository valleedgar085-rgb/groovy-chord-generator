import '../models/types.dart';

/// Cadential identity retained as part of a section's harmonic memory.
enum CadenceIdentity {
  authentic,
  plagal,
  deceptive,
  half,
  unresolved,
}

/// Relative harmonic identity of one section.
///
/// Roman degrees are retained instead of absolute roots so the memory survives
/// transposition. Chord colors are stored separately so future transformations
/// can preserve harmonic function while changing voicing/extension color.
class HarmonicFingerprint {
  HarmonicFingerprint({
    required List<String> degreePattern,
    required List<HarmonyFunction> functionPattern,
    required List<ChordTypeName> colorPattern,
    required this.cadence,
    required this.sectionBars,
  })  : degreePattern = List<String>.unmodifiable(degreePattern),
        functionPattern = List<HarmonyFunction>.unmodifiable(functionPattern),
        colorPattern = List<ChordTypeName>.unmodifiable(colorPattern);

  final List<String> degreePattern;
  final List<HarmonyFunction> functionPattern;
  final List<ChordTypeName> colorPattern;
  final CadenceIdentity cadence;
  final int sectionBars;

  int get chordCount => degreePattern.length;

  /// Arrangement-level harmonic density, useful later when a transformation
  /// wants to make a section busier or simpler without changing its duration.
  double get chordsPerBar =>
      sectionBars <= 0 ? 0.0 : chordCount / sectionBars.toDouble();

  double similarityTo(HarmonicFingerprint other) {
    if (degreePattern.isEmpty || other.degreePattern.isEmpty) return 0.0;
    final compared = degreePattern.length < other.degreePattern.length
        ? degreePattern.length
        : other.degreePattern.length;

    var degreeMatches = 0.0;
    var functionMatches = 0.0;
    var colorMatches = 0.0;
    for (var i = 0; i < compared; i++) {
      if (degreePattern[i] == other.degreePattern[i]) degreeMatches += 1.0;
      if (functionPattern[i] == other.functionPattern[i]) {
        functionMatches += 1.0;
      }
      if (colorPattern[i] == other.colorPattern[i]) colorMatches += 1.0;
    }

    final lengthSimilarity = 1.0 -
        ((degreePattern.length - other.degreePattern.length).abs() /
                (degreePattern.length > other.degreePattern.length
                    ? degreePattern.length
                    : other.degreePattern.length))
            .clamp(0.0, 1.0);
    final cadenceMatch = cadence == other.cadence ? 1.0 : 0.0;

    return ((degreeMatches / compared) * 0.40 +
            (functionMatches / compared) * 0.25 +
            (colorMatches / compared) * 0.10 +
            lengthSimilarity * 0.10 +
            cadenceMatch * 0.15)
        .clamp(0.0, 1.0)
        .toDouble();
  }
}

/// Short relative melodic idea extracted from the beginning of a section.
///
/// [intervalContour] stores semitone movement between adjacent notes rather
/// than absolute pitches, so the identity can be reused over new harmony or in
/// another key. Rhythm and accent are retained as separate dimensions.
class MelodicMotif {
  MelodicMotif({
    required List<int> intervalContour,
    required List<int> durationTicks,
    required List<int> accentBuckets,
  })  : intervalContour = List<int>.unmodifiable(intervalContour),
        durationTicks = List<int>.unmodifiable(durationTicks),
        accentBuckets = List<int>.unmodifiable(accentBuckets);

  final List<int> intervalContour;
  final List<int> durationTicks;
  final List<int> accentBuckets;

  bool get isEmpty => durationTicks.isEmpty;

  double similarityTo(MelodicMotif other) {
    if (isEmpty || other.isEmpty) return 0.0;
    return (_sequenceSimilarity(intervalContour, other.intervalContour) * 0.55 +
            _sequenceSimilarity(durationTicks, other.durationTicks) * 0.30 +
            _sequenceSimilarity(accentBuckets, other.accentBuckets) * 0.15)
        .clamp(0.0, 1.0)
        .toDouble();
  }
}

/// Rhythmic identity independent of pitch content.
class RhythmFingerprint {
  RhythmFingerprint({
    required List<int> durationTicks,
    required List<int> accentBuckets,
    required this.notesPerChord,
  })  : durationTicks = List<int>.unmodifiable(durationTicks),
        accentBuckets = List<int>.unmodifiable(accentBuckets);

  final List<int> durationTicks;
  final List<int> accentBuckets;
  final double notesPerChord;

  double similarityTo(RhythmFingerprint other) {
    final duration = _sequenceSimilarity(durationTicks, other.durationTicks);
    final accent = _sequenceSimilarity(accentBuckets, other.accentBuckets);
    final densityDenominator = notesPerChord > other.notesPerChord
        ? notesPerChord
        : other.notesPerChord;
    final density = densityDenominator == 0
        ? 1.0
        : 1.0 -
            ((notesPerChord - other.notesPerChord).abs() / densityDenominator)
                .clamp(0.0, 1.0);
    return (duration * 0.55 + accent * 0.20 + density * 0.25)
        .clamp(0.0, 1.0)
        .toDouble();
  }
}

/// Relative low-end shape. Semitone movement captures contour while
/// [rootOffsets] describes how the bass relates to the active chord root.
class BassContour {
  BassContour({
    required List<int> intervalSteps,
    required List<int> rootOffsets,
  })  : intervalSteps = List<int>.unmodifiable(intervalSteps),
        rootOffsets = List<int>.unmodifiable(rootOffsets);

  final List<int> intervalSteps;
  final List<int> rootOffsets;

  bool get isEmpty => rootOffsets.isEmpty;

  double similarityTo(BassContour other) {
    if (isEmpty || other.isEmpty) return 0.0;
    return (_sequenceSimilarity(intervalSteps, other.intervalSteps) * 0.55 +
            _sequenceSimilarity(rootOffsets, other.rootOffsets) * 0.45)
        .clamp(0.0, 1.0)
        .toDouble();
  }
}

/// Captured identity for one generated section.
class SectionMemory {
  const SectionMemory({
    required this.sectionId,
    required this.repetitionGroup,
    required this.sourceSectionId,
    required this.harmony,
    required this.melody,
    required this.rhythm,
    required this.bass,
  });

  final String sectionId;
  final String? repetitionGroup;

  /// Earliest section in this repetition family. Verse 2, for example, points
  /// to Verse 1. A source section points to itself.
  final String sourceSectionId;
  final HarmonicFingerprint harmony;
  final MelodicMotif melody;
  final RhythmFingerprint rhythm;
  final BassContour bass;

  double identitySimilarityTo(SectionMemory other) {
    return (harmony.similarityTo(other.harmony) * 0.45 +
            melody.similarityTo(other.melody) * 0.25 +
            rhythm.similarityTo(other.rhythm) * 0.15 +
            bass.similarityTo(other.bass) * 0.15)
        .clamp(0.0, 1.0)
        .toDouble();
  }
}

/// Immutable musical identity captured from a complete or partial SongDraft.
class SongMemory {
  SongMemory({
    required this.songSeed,
    required Map<String, SectionMemory> sections,
    required Map<String, String> repetitionSources,
  })  : sections = Map<String, SectionMemory>.unmodifiable(sections),
        repetitionSources = Map<String, String>.unmodifiable(repetitionSources);

  final int songSeed;
  final Map<String, SectionMemory> sections;

  /// repetitionGroup -> canonical source section id.
  final Map<String, String> repetitionSources;

  SectionMemory? section(String sectionId) => sections[sectionId];

  SectionMemory? sourceFor(String sectionId) {
    final memory = sections[sectionId];
    if (memory == null) return null;
    return sections[memory.sourceSectionId];
  }

  double similarity(String firstSectionId, String secondSectionId) {
    final first = sections[firstSectionId];
    final second = sections[secondSectionId];
    if (first == null || second == null) return 0.0;
    return first.identitySimilarityTo(second);
  }
}

double _sequenceSimilarity(List<int> a, List<int> b) {
  if (a.isEmpty && b.isEmpty) return 1.0;
  if (a.isEmpty || b.isEmpty) return 0.0;
  final compared = a.length < b.length ? a.length : b.length;
  var matches = 0.0;
  for (var i = 0; i < compared; i++) {
    if (a[i] == b[i]) matches += 1.0;
  }
  final maxLength = a.length > b.length ? a.length : b.length;
  final lengthSimilarity = 1.0 - ((a.length - b.length).abs() / maxLength);
  return ((matches / compared) * 0.8 + lengthSimilarity * 0.2)
      .clamp(0.0, 1.0)
      .toDouble();
}
