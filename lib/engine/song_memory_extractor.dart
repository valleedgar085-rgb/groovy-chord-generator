import '../models/types.dart';
import '../utils/music_theory.dart';
import 'song_draft.dart';
import 'song_memory.dart';

/// Captures reusable musical identity from a generated SongDraft.
///
/// This layer does not generate or mutate music. It converts absolute notes
/// and concrete chord voicings into relative fingerprints that future Phase 3
/// transformation logic can safely reuse across sections and keys.
class SongMemoryExtractor {
  const SongMemoryExtractor({this.motifNoteLimit = 8});

  final int motifNoteLimit;

  SongMemory capture(SongDraft draft) {
    final memories = <String, SectionMemory>{};
    final repetitionSources = <String, String>{};

    for (final section in draft.sections) {
      final group = section.plan.repetitionGroup;
      final sourceId = group == null
          ? section.plan.id
          : repetitionSources.putIfAbsent(group, () => section.plan.id);

      memories[section.plan.id] = SectionMemory(
        sectionId: section.plan.id,
        repetitionGroup: group,
        sourceSectionId: sourceId,
        harmony: _harmonicFingerprint(section),
        melody: _melodicMotif(section.melody),
        rhythm: _rhythmFingerprint(
          section.melody,
          section.progression.length,
        ),
        bass: _bassContour(section),
      );
    }

    return SongMemory(
      songSeed: draft.plan.seed,
      sections: memories,
      repetitionSources: repetitionSources,
    );
  }

  HarmonicFingerprint _harmonicFingerprint(GeneratedSongSection section) {
    final progression = section.progression;
    return HarmonicFingerprint(
      degreePattern: progression.map((chord) => chord.degree).toList(),
      functionPattern: progression.map(_functionOf).toList(),
      colorPattern: progression.map((chord) => chord.type).toList(),
      cadence: _cadenceOf(progression),
      sectionBars: section.plan.bars,
    );
  }

  MelodicMotif _melodicMotif(List<MelodyNote> melody) {
    final sample = melody.take(motifNoteLimit).toList(growable: false);
    final contour = <int>[];
    for (var i = 1; i < sample.length; i++) {
      final previous = _absolutePitch(sample[i - 1].note, sample[i - 1].octave);
      final current = _absolutePitch(sample[i].note, sample[i].octave);
      contour.add(_foldToNearestOctave(current - previous));
    }

    return MelodicMotif(
      intervalContour: contour,
      durationTicks: sample.map((note) => _durationTicks(note.duration)).toList(),
      accentBuckets: sample.map((note) => _accentBucket(note.velocity)).toList(),
    );
  }

  RhythmFingerprint _rhythmFingerprint(
    List<MelodyNote> melody,
    int chordCount,
  ) {
    final sample = melody.take(motifNoteLimit).toList(growable: false);
    return RhythmFingerprint(
      durationTicks: sample.map((note) => _durationTicks(note.duration)).toList(),
      accentBuckets: sample.map((note) => _accentBucket(note.velocity)).toList(),
      notesPerChord: chordCount == 0 ? 0.0 : melody.length / chordCount,
    );
  }

  BassContour _bassContour(GeneratedSongSection section) {
    final sample = section.bass.take(motifNoteLimit).toList(growable: false);
    final intervals = <int>[];
    for (var i = 1; i < sample.length; i++) {
      final previous = _absolutePitch(sample[i - 1].note, sample[i - 1].octave);
      final current = _absolutePitch(sample[i].note, sample[i].octave);
      intervals.add((current - previous).clamp(-12, 12).toInt());
    }

    final rootOffsets = <int>[];
    for (final note in sample) {
      if (note.chordIndex < 0 || note.chordIndex >= section.progression.length) {
        rootOffsets.add(0);
        continue;
      }
      final chord = section.progression[note.chordIndex];
      final notePitch = getNoteIndex(note.note);
      final rootPitch = getNoteIndex(chord.root);
      rootOffsets.add((notePitch - rootPitch) % 12);
    }

    return BassContour(
      intervalSteps: intervals,
      rootOffsets: rootOffsets,
    );
  }

  HarmonyFunction _functionOf(Chord chord) {
    if (chord.harmonyFunction != null) return chord.harmonyFunction!;
    final degree = chord.degree;

    if (_isPrimaryTonic(degree) ||
        degree == 'iii' ||
        degree == 'III' ||
        degree == 'vi' ||
        degree == 'VI') {
      return HarmonyFunction.tonic;
    }
    if (degree == 'ii' ||
        degree == 'II' ||
        degree == 'IV' ||
        degree == 'iv') {
      return HarmonyFunction.subdominant;
    }
    if (_isDominant(degree) || degree == 'vii' || degree == 'VII') {
      return HarmonyFunction.dominant;
    }
    return HarmonyFunction.passing;
  }

  CadenceIdentity _cadenceOf(List<Chord> progression) {
    if (progression.isEmpty) return CadenceIdentity.unresolved;
    final last = progression.last.degree;
    if (progression.length == 1) {
      return _isDominant(last) ? CadenceIdentity.half : CadenceIdentity.unresolved;
    }

    final previous = progression[progression.length - 2].degree;
    if (_isDominant(previous) && _isPrimaryTonic(last)) {
      return CadenceIdentity.authentic;
    }
    if (_isSubdominant(previous) && _isPrimaryTonic(last)) {
      return CadenceIdentity.plagal;
    }
    if (_isDominant(previous) && (last == 'vi' || last == 'VI')) {
      return CadenceIdentity.deceptive;
    }
    if (_isDominant(last)) return CadenceIdentity.half;
    return CadenceIdentity.unresolved;
  }

  bool _isPrimaryTonic(String degree) => degree == 'I' || degree == 'i';

  bool _isDominant(String degree) =>
      degree == 'V' ||
      degree == 'v' ||
      degree == 'V7' ||
      degree == 'V/V';

  bool _isSubdominant(String degree) =>
      degree == 'IV' ||
      degree == 'iv' ||
      degree == 'ii' ||
      degree == 'II';

  int _absolutePitch(String note, int octave) =>
      getNoteIndex(note) + octave * 12;

  int _foldToNearestOctave(int interval) {
    var folded = interval;
    while (folded > 6) {
      folded -= 12;
    }
    while (folded < -6) {
      folded += 12;
    }
    return folded;
  }

  int _durationTicks(double duration) =>
      (duration * 4).round().clamp(1, 64).toInt();

  int _accentBucket(double velocity) {
    if (velocity < 0.50) return 0;
    if (velocity < 0.78) return 1;
    return 2;
  }
}
