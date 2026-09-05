import 'dart:math';

import '../models/types.dart';
import '../utils/music_theory.dart';
import 'phrase_model.dart';
import 'phrase_producer_brain.dart';
import 'song_draft.dart';
import 'song_memory.dart';
import 'song_memory_extractor.dart';

enum PhraseRepairStyle {
  identityBalance(
    'IDENTITY BALANCE',
    'Move the phrase toward its Musical DNA similarity window without copying it literally.',
  ),
  cadenceTarget(
    'CADENCE TARGET',
    'Retarget the final melodic landing to match the phrase cadence intent.',
  ),
  contourSmooth(
    'CONTOUR SMOOTH',
    'Reduce awkward leaps and repeated-note fatigue while keeping harmonic anchors.',
  ),
  arcShape(
    'ARC SHAPE',
    'Move the phrase peak and register toward its intended question, answer, lift, hook or release arc.',
  ),
  rhythmRefresh(
    'RHYTHM REFRESH',
    'Strengthen rhythmic identity with a controlled interior duration pattern.',
  );

  const PhraseRepairStyle(this.label, this.description);

  final String label;
  final String description;
}

class PhraseRepairVariant {
  PhraseRepairVariant({
    required this.style,
    required this.draft,
    required this.before,
    required this.after,
    required this.beforeSongScore,
    required this.afterSongScore,
    required this.changedNoteCount,
    required this.summary,
  });

  final PhraseRepairStyle style;
  final SongDraft draft;
  final PhraseProducerAssessment before;
  final PhraseProducerAssessment after;
  final double beforeSongScore;
  final double afterSongScore;
  final int changedNoteCount;
  final String summary;

  String get phraseId => before.phraseId;
  String get sectionId => before.sectionId;
  double get scoreDelta => after.score - before.score;
  double get songScoreDelta => afterSongScore - beforeSongScore;
  bool get improved => scoreDelta > 0.05 && songScoreDelta >= -0.01;
}

/// Phase 5.8D closed-loop phrase repair.
///
/// The engine mutates exactly one phrase bucket at a time. Harmony, bass,
/// unrelated phrase notes and unrelated sections remain untouched. Every
/// candidate is re-extracted through Song Memory and re-scored by the 5.8C
/// Phrase Producer Brain. Candidates that regress phrase quality, whole-song
/// phrase quality, or Musical DNA lineage guardrails are rejected.
class PhraseRepairEngine {
  const PhraseRepairEngine({
    this.memoryExtractor = const SongMemoryExtractor(),
    this.analyzer = const PhraseProducerAnalyzer(),
  });

  final SongMemoryExtractor memoryExtractor;
  final PhraseProducerAnalyzer analyzer;

  List<PhraseRepairVariant> build({
    required SongDraft draft,
    String? phraseId,
  }) {
    final beforeMemory = memoryExtractor.capture(draft);
    final beforeAnalysis = analyzer.analyze(
      draft: draft,
      memory: beforeMemory,
    );
    final target = phraseId == null
        ? beforeAnalysis.weakestPhrase
        : _assessment(beforeAnalysis, phraseId);
    if (target == null) return const <PhraseRepairVariant>[];

    final section = draft.sectionById(target.sectionId);
    final sectionMemory = beforeMemory.section(target.sectionId);
    if (section == null || sectionMemory == null || section.melody.isEmpty) {
      return const <PhraseRepairVariant>[];
    }
    if (target.phraseIndex < 0 || target.phraseIndex >= sectionMemory.phrases.length) {
      return const <PhraseRepairVariant>[];
    }
    final targetFingerprint = sectionMemory.phrase(target.phraseIndex);
    if (targetFingerprint == null || targetFingerprint.isEmpty) {
      return const <PhraseRepairVariant>[];
    }

    final phraseIndices = _phraseNoteIndices(
      section,
      target.phraseIndex,
      sectionMemory.phrases.length,
    );
    if (phraseIndices.isEmpty) return const <PhraseRepairVariant>[];

    final variants = <PhraseRepairVariant>[];
    for (final style in PhraseRepairStyle.values) {
      final repairedSection = _apply(
        style,
        draft: draft,
        memory: beforeMemory,
        section: section,
        target: target,
        targetFingerprint: targetFingerprint,
        phraseIndices: phraseIndices,
      );
      if (_melodySignature(repairedSection.melody) ==
          _melodySignature(section.melody)) {
        continue;
      }
      if (!_unaffectedPhraseNotesPreserved(
        before: section,
        after: repairedSection,
        targetIndices: phraseIndices,
      )) {
        continue;
      }

      final repairedDraft = draft.withSection(repairedSection);
      final afterMemory = memoryExtractor.capture(repairedDraft);
      final afterAnalysis = analyzer.analyze(
        draft: repairedDraft,
        memory: afterMemory,
      );
      final after = _assessment(afterAnalysis, target.phraseId);
      if (after == null) continue;
      if (after.score <= target.score + 0.05) continue;
      if (afterAnalysis.overallScore + 0.01 < beforeAnalysis.overallScore) continue;
      if (!_lineageNonRegressing(target.lineage, after.lineage)) continue;

      final changed = _changedNoteCount(section.melody, repairedSection.melody);
      variants.add(
        PhraseRepairVariant(
          style: style,
          draft: repairedDraft,
          before: target,
          after: after,
          beforeSongScore: beforeAnalysis.overallScore,
          afterSongScore: afterAnalysis.overallScore,
          changedNoteCount: changed,
          summary: _summary(style, target, after, changed),
        ),
      );
    }

    variants.sort((a, b) {
      final byScore = b.after.score.compareTo(a.after.score);
      if (byScore != 0) return byScore;
      final byDelta = b.scoreDelta.compareTo(a.scoreDelta);
      if (byDelta != 0) return byDelta;
      final byScope = a.changedNoteCount.compareTo(b.changedNoteCount);
      if (byScope != 0) return byScope;
      return a.style.index.compareTo(b.style.index);
    });
    return List<PhraseRepairVariant>.unmodifiable(variants);
  }

  GeneratedSongSection _apply(
    PhraseRepairStyle style, {
    required SongDraft draft,
    required SongMemory memory,
    required GeneratedSongSection section,
    required PhraseProducerAssessment target,
    required PhraseFingerprint targetFingerprint,
    required List<int> phraseIndices,
  }) {
    final melody = List<MelodyNote>.from(section.melody);
    switch (style) {
      case PhraseRepairStyle.identityBalance:
        _identityBalance(
          melody,
          draft: draft,
          memory: memory,
          section: section,
          target: target,
          phraseIndices: phraseIndices,
        );
      case PhraseRepairStyle.cadenceTarget:
        _cadenceTarget(
          melody,
          section,
          targetFingerprint,
          phraseIndices,
        );
      case PhraseRepairStyle.contourSmooth:
        _contourSmooth(melody, section, phraseIndices);
      case PhraseRepairStyle.arcShape:
        _arcShape(melody, section, target, phraseIndices);
      case PhraseRepairStyle.rhythmRefresh:
        _rhythmRefresh(melody, phraseIndices);
    }

    return GeneratedSongSection(
      plan: section.plan,
      candidate: section.candidate,
      melody: melody,
      bass: section.bass,
      development: section.development,
    );
  }

  void _identityBalance(
    List<MelodyNote> melody, {
    required SongDraft draft,
    required SongMemory memory,
    required GeneratedSongSection section,
    required PhraseProducerAssessment target,
    required List<int> phraseIndices,
  }) {
    final lineage = target.lineage;
    if (lineage == null || lineage.isSource) return;
    final sourceLocation = _parsePhraseId(lineage.sourcePhraseId);
    if (sourceLocation == null) return;
    final sourceSection = draft.sectionById(sourceLocation.$1);
    final sourceMemory = memory.section(sourceLocation.$1);
    if (sourceSection == null || sourceMemory == null) return;
    final sourceIndices = _phraseNoteIndices(
      sourceSection,
      sourceLocation.$2,
      sourceMemory.phrases.length,
    );
    if (sourceIndices.isEmpty) return;

    final value = lineage.sourceSimilarity;
    final window = lineage.targetWindow;
    if (value < window.minimum) {
      final sourceOrigin = noteToPitch(
        sourceSection.melody[sourceIndices.first].note,
        sourceSection.melody[sourceIndices.first].octave,
      );
      final targetOrigin = noteToPitch(
        melody[phraseIndices.first].note,
        melody[phraseIndices.first].octave,
      );
      for (var ordinal = 0; ordinal < phraseIndices.length; ordinal++) {
        if (ordinal == phraseIndices.length - 1) continue;
        if (ordinal.isOdd && ordinal > 1) continue;
        final sourceOrdinal = ((ordinal * sourceIndices.length) /
                max(1, phraseIndices.length))
            .floor()
            .clamp(0, sourceIndices.length - 1)
            .toInt();
        final source = sourceSection.melody[sourceIndices[sourceOrdinal]];
        final sourcePitch = noteToPitch(source.note, source.octave);
        final desired = targetOrigin + (sourcePitch - sourceOrigin);
        final targetIndex = phraseIndices[ordinal];
        final current = melody[targetIndex];
        final chord = section.progression[
          current.chordIndex.clamp(0, section.progression.length - 1).toInt()
        ];
        final pitch = _nearestPitch(
          getChordNotes(chord),
          desired,
          previousPitch: ordinal == 0
              ? null
              : noteToPitch(
                  melody[phraseIndices[ordinal - 1]].note,
                  melody[phraseIndices[ordinal - 1]].octave,
                ),
          maxLeap: 9,
        );
        melody[targetIndex] = _melodyAtPitch(
          current,
          pitch,
          duration: source.duration,
        );
      }
      return;
    }

    if (value > window.maximum && phraseIndices.length > 2) {
      for (var ordinal = 1; ordinal < phraseIndices.length - 1; ordinal += 2) {
        final targetIndex = phraseIndices[ordinal];
        final current = melody[targetIndex];
        final currentPitch = noteToPitch(current.note, current.octave);
        final chord = section.progression[
          current.chordIndex.clamp(0, section.progression.length - 1).toInt()
        ];
        final previousPitch = noteToPitch(
          melody[phraseIndices[ordinal - 1]].note,
          melody[phraseIndices[ordinal - 1]].octave,
        );
        final direction = ordinal % 4 == 1 ? 3 : -3;
        final pitch = _nearestPitch(
          getChordNotes(chord),
          currentPitch + direction,
          previousPitch: previousPitch,
          maxLeap: 8,
          excludePitch: currentPitch,
        );
        final duration = ordinal % 4 == 1
            ? (current.duration * 0.75).clamp(0.25, 2.0).toDouble()
            : (current.duration * 1.25).clamp(0.25, 2.0).toDouble();
        melody[targetIndex] = _melodyAtPitch(
          current,
          pitch,
          duration: duration,
        );
      }
    }
  }

  void _cadenceTarget(
    List<MelodyNote> melody,
    GeneratedSongSection section,
    PhraseFingerprint fingerprint,
    List<int> phraseIndices,
  ) {
    final index = phraseIndices.last;
    final current = melody[index];
    final chord = section.progression[
      current.chordIndex.clamp(0, section.progression.length - 1).toInt()
    ];
    final currentPitch = noteToPitch(current.note, current.octave);
    final tones = getChordNotes(chord);
    String targetName;
    switch (fingerprint.cadenceIntent) {
      case PhraseCadenceIntent.resolved:
        targetName = chord.root;
      case PhraseCadenceIntent.half:
        targetName = chord.root;
      case PhraseCadenceIntent.open:
        targetName = tones.firstWhere(
          (note) => note != chord.root,
          orElse: () => transposeNote(chord.root, 7),
        );
      case PhraseCadenceIntent.deceptive:
        targetName = tones.length > 1 ? tones[1] : chord.root;
      case PhraseCadenceIntent.suspended:
        targetName = transposeNote(chord.root, 2);
    }
    final pitch = _nearestPitch(
      <String>[targetName],
      currentPitch,
      previousPitch: phraseIndices.length > 1
          ? noteToPitch(
              melody[phraseIndices[phraseIndices.length - 2]].note,
              melody[phraseIndices[phraseIndices.length - 2]].octave,
            )
          : null,
      maxLeap: 9,
    );
    melody[index] = _melodyAtPitch(
      current,
      pitch,
      velocity: max(current.velocity, 0.62),
    );
  }

  void _contourSmooth(
    List<MelodyNote> melody,
    GeneratedSongSection section,
    List<int> phraseIndices,
  ) {
    int? previousPitch;
    var repeatedRun = 0;
    for (var ordinal = 0; ordinal < phraseIndices.length; ordinal++) {
      final index = phraseIndices[ordinal];
      final current = melody[index];
      final currentPitch = noteToPitch(current.note, current.octave);
      if (previousPitch == null) {
        previousPitch = currentPitch;
        continue;
      }
      final previousBefore = previousPitch;
      final leap = (currentPitch - previousBefore).abs();
      repeatedRun = currentPitch == previousBefore ? repeatedRun + 1 : 0;
      if (leap <= 8 && repeatedRun < 2) {
        previousPitch = currentPitch;
        continue;
      }
      final chord = section.progression[
        current.chordIndex.clamp(0, section.progression.length - 1).toInt()
      ];
      final desired = leap > 8
          ? previousBefore + (currentPitch > previousBefore ? 5 : -5)
          : previousBefore + (ordinal.isEven ? 3 : -3);
      final pitch = _nearestPitch(
        getChordNotes(chord),
        desired,
        previousPitch: previousBefore,
        maxLeap: 7,
        excludePitch: repeatedRun >= 2 ? previousBefore : null,
      );
      melody[index] = _melodyAtPitch(current, pitch);
      repeatedRun = pitch == previousBefore ? repeatedRun + 1 : 0;
      previousPitch = pitch;
    }
  }

  void _arcShape(
    List<MelodyNote> melody,
    GeneratedSongSection section,
    PhraseProducerAssessment target,
    List<int> phraseIndices,
  ) {
    if (phraseIndices.length < 2) return;
    final desiredClimax = switch (target.role) {
      PhraseRole.statement => 0.58,
      PhraseRole.question => 0.80,
      PhraseRole.answer => 0.34,
      PhraseRole.lift => 0.88,
      PhraseRole.hook => 0.62,
      PhraseRole.contrast => 0.48,
      PhraseRole.release => 0.22,
      PhraseRole.turnaround => 0.72,
    };
    final targetOrdinal =
        (desiredClimax * (phraseIndices.length - 1)).round().clamp(0, phraseIndices.length - 1);
    final targetIndex = phraseIndices[targetOrdinal];
    final current = melody[targetIndex];
    final currentPitch = noteToPitch(current.note, current.octave);
    final chord = section.progression[
      current.chordIndex.clamp(0, section.progression.length - 1).toInt()
    ];
    final lifted = _nearestPitch(
      getChordNotes(chord),
      currentPitch + (target.role == PhraseRole.release ? 2 : 7),
      previousPitch: targetOrdinal == 0
          ? null
          : noteToPitch(
              melody[phraseIndices[targetOrdinal - 1]].note,
              melody[phraseIndices[targetOrdinal - 1]].octave,
            ),
      maxLeap: 9,
    );
    melody[targetIndex] = _melodyAtPitch(
      current,
      lifted,
      velocity: (current.velocity + 0.08).clamp(0.0, 1.0).toDouble(),
    );

    for (var ordinal = 0; ordinal < phraseIndices.length; ordinal++) {
      if (ordinal == targetOrdinal) continue;
      final index = phraseIndices[ordinal];
      final note = melody[index];
      final pitch = noteToPitch(note.note, note.octave);
      if (pitch < lifted) continue;
      final localChord = section.progression[
        note.chordIndex.clamp(0, section.progression.length - 1).toInt()
      ];
      final lowered = _nearestPitch(
        getChordNotes(localChord),
        lifted - 3,
        previousPitch: ordinal == 0
            ? null
            : noteToPitch(
                melody[phraseIndices[ordinal - 1]].note,
                melody[phraseIndices[ordinal - 1]].octave,
              ),
        maxLeap: 9,
      );
      melody[index] = _melodyAtPitch(note, min(lowered, lifted - 1));
    }
  }

  void _rhythmRefresh(List<MelodyNote> melody, List<int> phraseIndices) {
    if (phraseIndices.length < 3) return;
    const pattern = <double>[0.5, 1.0, 0.75, 1.5];
    for (var ordinal = 1; ordinal < phraseIndices.length - 1; ordinal++) {
      final index = phraseIndices[ordinal];
      final current = melody[index];
      final desired = pattern[(ordinal - 1) % pattern.length];
      if ((desired - current.duration).abs() < 0.001) continue;
      melody[index] = MelodyNote(
        note: current.note,
        octave: current.octave,
        duration: desired,
        velocity: current.velocity,
        chordIndex: current.chordIndex,
      );
    }
  }

  PhraseProducerAssessment? _assessment(
    SongPhraseProducerAnalysis analysis,
    String phraseId,
  ) {
    for (final phrase in analysis.phrases) {
      if (phrase.phraseId == phraseId) return phrase;
    }
    return null;
  }

  List<int> _phraseNoteIndices(
    GeneratedSongSection section,
    int phraseIndex,
    int phraseCount,
  ) {
    if (section.progression.isEmpty || phraseCount <= 0) return const <int>[];
    final output = <int>[];
    final chordCount = section.progression.length;
    for (var i = 0; i < section.melody.length; i++) {
      final note = section.melody[i];
      final safeChord = note.chordIndex.clamp(0, chordCount - 1).toInt();
      final normalized =
          ((safeChord + 0.5) / chordCount.toDouble()).clamp(0.0, 0.999999);
      final bucket =
          (normalized * phraseCount).floor().clamp(0, phraseCount - 1).toInt();
      if (bucket == phraseIndex) output.add(i);
    }
    return output;
  }

  (String, int)? _parsePhraseId(String phraseId) {
    final split = phraseId.lastIndexOf(':p');
    if (split <= 0) return null;
    final index = int.tryParse(phraseId.substring(split + 2));
    if (index == null) return null;
    return (phraseId.substring(0, split), index);
  }

  bool _lineageNonRegressing(
    PhraseLineageNode? before,
    PhraseLineageNode? after,
  ) {
    if (before == null) return true;
    if (after == null || before.sourcePhraseId != after.sourcePhraseId) return false;
    if (before.insideGuardrail) return after.insideGuardrail;
    final beforeDistance = _guardrailDistance(before);
    final afterDistance = _guardrailDistance(after);
    return after.insideGuardrail || afterDistance <= beforeDistance + 0.0001;
  }

  double _guardrailDistance(PhraseLineageNode node) {
    final value = node.sourceSimilarity;
    final window = node.targetWindow;
    if (window.contains(value)) return 0.0;
    return value < window.minimum
        ? window.minimum - value
        : value - window.maximum;
  }

  bool _unaffectedPhraseNotesPreserved({
    required GeneratedSongSection before,
    required GeneratedSongSection after,
    required List<int> targetIndices,
  }) {
    if (before.melody.length != after.melody.length) return false;
    final targetSet = targetIndices.toSet();
    for (var i = 0; i < before.melody.length; i++) {
      if (targetSet.contains(i)) continue;
      if (_noteSignature(before.melody[i]) != _noteSignature(after.melody[i])) {
        return false;
      }
    }
    return _bassSignature(before.bass) == _bassSignature(after.bass) &&
        before.progression == after.progression;
  }

  int _changedNoteCount(List<MelodyNote> before, List<MelodyNote> after) {
    final compared = min(before.length, after.length);
    var changed = (before.length - after.length).abs();
    for (var i = 0; i < compared; i++) {
      if (_noteSignature(before[i]) != _noteSignature(after[i])) changed++;
    }
    return changed;
  }

  int _nearestPitch(
    List<String> noteNames,
    int desired, {
    int? previousPitch,
    int maxLeap = 12,
    int? excludePitch,
  }) {
    final candidates = <int>[];
    for (final name in noteNames.toSet()) {
      for (var octave = 2; octave <= 7; octave++) {
        final pitch = noteToPitch(name, octave);
        if (pitch < 48 || pitch > 96) continue;
        if (excludePitch != null && pitch == excludePitch) continue;
        if (previousPitch != null && (pitch - previousPitch).abs() > maxLeap) {
          continue;
        }
        candidates.add(pitch);
      }
    }
    if (candidates.isEmpty) {
      return desired.clamp(48, 96).toInt();
    }
    candidates.sort((a, b) {
      final aDistance = (a - desired).abs();
      final bDistance = (b - desired).abs();
      if (aDistance != bDistance) return aDistance.compareTo(bDistance);
      return a.compareTo(b);
    });
    return candidates.first;
  }

  MelodyNote _melodyAtPitch(
    MelodyNote source,
    int pitch, {
    double? duration,
    double? velocity,
  }) {
    final note = pitchToNote(pitch.clamp(48, 96).toInt());
    return MelodyNote(
      note: note['note'] as String,
      octave: note['octave'] as int,
      duration: duration ?? source.duration,
      velocity: (velocity ?? source.velocity).clamp(0.0, 1.0).toDouble(),
      chordIndex: source.chordIndex,
    );
  }

  String _summary(
    PhraseRepairStyle style,
    PhraseProducerAssessment before,
    PhraseProducerAssessment after,
    int changed,
  ) =>
      '${style.label}: ${before.phraseId} ${before.score.toStringAsFixed(1)} → ${after.score.toStringAsFixed(1)}; $changed note${changed == 1 ? '' : 's'} changed.';

  String _melodySignature(List<MelodyNote> melody) =>
      melody.map(_noteSignature).join('|');

  String _noteSignature(MelodyNote note) =>
      '${note.note}${note.octave}:${note.duration.toStringAsFixed(4)}:${note.velocity.toStringAsFixed(4)}:${note.chordIndex}';

  String _bassSignature(List<BassNote> bass) => bass
      .map((note) =>
          '${note.note}${note.octave}:${note.duration.toStringAsFixed(4)}:${note.velocity.toStringAsFixed(4)}:${note.chordIndex}:${note.style.name}')
      .join('|');
}
