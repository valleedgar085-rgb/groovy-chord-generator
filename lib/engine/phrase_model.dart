/// Phrase-level musical identity used by Song Memory and later composition stages.
///
/// Phase 5.8A deliberately models intent and ancestry before changing note
/// generation. These objects are immutable and transposition-friendly so later
/// Phrase Composer / Producer Brain passes can reason about musical sentences
/// instead of treating a section as one undifferentiated stream of notes.
enum PhraseRole {
  statement,
  question,
  answer,
  lift,
  hook,
  contrast,
  release,
  turnaround,
}

enum PhraseCadenceIntent {
  open,
  half,
  resolved,
  deceptive,
  suspended,
}

enum PhraseRelationship {
  source,
  response,
  variation,
  callback,
  contrast,
}

/// Similarity guardrail for one source -> developed phrase relationship.
class PhraseSimilarityWindow {
  const PhraseSimilarityWindow({
    required this.minimum,
    required this.maximum,
    required this.label,
  });

  final double minimum;
  final double maximum;
  final String label;

  bool contains(double value) => value >= minimum && value <= maximum;
}

/// Pitch/rhythm/accent identity of one phrase-sized musical sentence.
class PhraseFingerprint {
  PhraseFingerprint({
    required this.id,
    required this.sectionId,
    required this.index,
    required this.bars,
    required this.role,
    required this.cadenceIntent,
    required List<int> relativePitchPattern,
    required List<int> intervalContour,
    required List<int> durationTicks,
    required List<int> accentBuckets,
    required List<int> chordIndexPattern,
    required this.pitchRange,
    required this.averageVelocity,
    required this.noteDensity,
    required this.climaxPosition,
  })  : relativePitchPattern = List<int>.unmodifiable(relativePitchPattern),
        intervalContour = List<int>.unmodifiable(intervalContour),
        durationTicks = List<int>.unmodifiable(durationTicks),
        accentBuckets = List<int>.unmodifiable(accentBuckets),
        chordIndexPattern = List<int>.unmodifiable(chordIndexPattern);

  final String id;
  final String sectionId;
  final int index;
  final int bars;
  final PhraseRole role;
  final PhraseCadenceIntent cadenceIntent;

  /// Semitone offsets from the phrase's opening pitch. Absolute key is removed.
  final List<int> relativePitchPattern;

  /// Folded semitone motion between adjacent notes.
  final List<int> intervalContour;
  final List<int> durationTicks;
  final List<int> accentBuckets;

  /// Relative harmonic placement inside the section.
  final List<int> chordIndexPattern;
  final int pitchRange;
  final double averageVelocity;
  final double noteDensity;

  /// 0..1 normalized location of the phrase's highest pitch.
  final double climaxPosition;

  bool get isEmpty => durationTicks.isEmpty;
  int get noteCount => durationTicks.length;

  double similarityTo(PhraseFingerprint other) {
    if (isEmpty || other.isEmpty) return 0.0;
    final contour = _sequenceSimilarity(intervalContour, other.intervalContour);
    final rhythm = _sequenceSimilarity(durationTicks, other.durationTicks);
    final accent = _sequenceSimilarity(accentBuckets, other.accentBuckets);
    final pitchShape =
        _sequenceSimilarity(relativePitchPattern, other.relativePitchPattern);
    final harmonicPlacement =
        _sequenceSimilarity(chordIndexPattern, other.chordIndexPattern);
    final density = _ratioSimilarity(noteDensity, other.noteDensity);
    final range = _ratioSimilarity(pitchRange.toDouble(), other.pitchRange.toDouble());
    final climax = 1.0 - (climaxPosition - other.climaxPosition).abs();

    return (contour * 0.30 +
            rhythm * 0.24 +
            accent * 0.10 +
            pitchShape * 0.12 +
            harmonicPlacement * 0.10 +
            density * 0.06 +
            range * 0.05 +
            climax.clamp(0.0, 1.0) * 0.03)
        .clamp(0.0, 1.0)
        .toDouble();
  }
}

/// Explicit ancestry for a phrase. This is the graph edge later regeneration
/// and closed-loop repair will follow instead of guessing from section names.
class PhraseLineageNode {
  const PhraseLineageNode({
    required this.phraseId,
    required this.sourcePhraseId,
    required this.relationship,
    required this.sourceSimilarity,
    required this.targetWindow,
  });

  final String phraseId;
  final String sourcePhraseId;
  final PhraseRelationship relationship;
  final double sourceSimilarity;
  final PhraseSimilarityWindow targetWindow;

  bool get isSource => relationship == PhraseRelationship.source;
  bool get insideGuardrail => targetWindow.contains(sourceSimilarity);
}

/// Small reusable rhythm cell retained independently from pitch.
class RhythmCell {
  RhythmCell({
    required List<int> durationTicks,
    required List<int> accentBuckets,
  })  : durationTicks = List<int>.unmodifiable(durationTicks),
        accentBuckets = List<int>.unmodifiable(accentBuckets);

  final List<int> durationTicks;
  final List<int> accentBuckets;

  bool get isEmpty => durationTicks.isEmpty;
}

/// Song-level identity distilled from actual generated phrases.
///
/// This intentionally stores references to phrase ids instead of duplicating
/// note data. Song Memory remains the canonical owner of phrase fingerprints.
class SongMusicalDna {
  SongMusicalDna({
    required this.songSeed,
    required this.primaryPhraseId,
    required this.secondaryPhraseId,
    required this.hookSectionId,
    required this.hookPhraseId,
    required this.signatureInterval,
    required this.typicalPhraseBars,
    required this.primaryRhythmCell,
    required this.melodicRange,
    required this.confidence,
  });

  final int songSeed;
  final String? primaryPhraseId;
  final String? secondaryPhraseId;
  final String? hookSectionId;
  final String? hookPhraseId;
  final int? signatureInterval;
  final int typicalPhraseBars;
  final RhythmCell primaryRhythmCell;
  final int melodicRange;
  final double confidence;

  bool get hasIdentity => primaryPhraseId != null;
}

double _sequenceSimilarity(List<int> a, List<int> b) {
  if (a.isEmpty && b.isEmpty) return 1.0;
  if (a.isEmpty || b.isEmpty) return 0.0;
  final compared = a.length < b.length ? a.length : b.length;
  var closeness = 0.0;
  for (var i = 0; i < compared; i++) {
    final distance = (a[i] - b[i]).abs();
    if (distance == 0) {
      closeness += 1.0;
    } else if (distance == 1) {
      closeness += 0.55;
    }
  }
  final maxLength = a.length > b.length ? a.length : b.length;
  final lengthSimilarity = 1.0 - ((a.length - b.length).abs() / maxLength);
  return ((closeness / compared) * 0.82 + lengthSimilarity * 0.18)
      .clamp(0.0, 1.0)
      .toDouble();
}

double _ratioSimilarity(double a, double b) {
  final largest = a.abs() > b.abs() ? a.abs() : b.abs();
  if (largest == 0.0) return 1.0;
  return (1.0 - ((a - b).abs() / largest)).clamp(0.0, 1.0).toDouble();
}
