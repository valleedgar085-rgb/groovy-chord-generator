import 'dart:math';

import '../models/types.dart';
import '../utils/music_theory.dart';
import 'phrase_producer_brain.dart';
import 'song_draft.dart';
import 'song_memory_extractor.dart';

/// A final deterministic rescue for descendants that have drifted too far from
/// their Musical DNA source.
///
/// Phase 5.8D's normal repair engine is intentionally conservative and requires
/// every candidate to improve the phrase score. That is correct for ordinary
/// editing, but a final God-gate candidate can still be musically strong while
/// missing its explicit A/A'/A'' identity floor by a small amount. This engine
/// only handles that under-similarity case. It progressively restores source
/// contour/rhythm/accent information inside the target harmony, re-extracts Song
/// Memory after every attempt, and stops as soon as the real lineage window is
/// reached. It never touches harmony, bass, another phrase, or another section.
class PhraseLineageRescueEngine {
  const PhraseLineageRescueEngine({
    this.memoryExtractor = const SongMemoryExtractor(),
    this.analyzer = const PhraseProducerAnalyzer(),
    this.maxRepairs = 6,
  });

  final SongMemoryExtractor memoryExtractor;
  final PhraseProducerAnalyzer analyzer;
  final int maxRepairs;

  SongDraft rescue(SongDraft draft) {
    if (draft.sections.isEmpty || maxRepairs <= 0) return draft;
    var current = draft;
    final blocked = <String>{};

    for (var pass = 0; pass < maxRepairs; pass++) {
      final memory = memoryExtractor.capture(current);
      final analysis = analyzer.analyze(draft: current, memory: memory);
      final targets = analysis.phrases.where((phrase) {
        final lineage = phrase.lineage;
        if (lineage == null || lineage.isSource || lineage.insideGuardrail) {
          return false;
        }
        if (blocked.contains(phrase.phraseId)) return false;
        return lineage.sourceSimilarity < lineage.targetWindow.minimum &&
            lineage.targetWindow.minimum - lineage.sourceSimilarity >= 0.075;
      }).toList()
        ..sort((a, b) => _distance(b).compareTo(_distance(a)));
      if (targets.isEmpty) break;

      final target = targets.first;
      final rescued = _rescueOne(
        draft: current,
        beforeAnalysis: analysis,
        target: target,
      );
      if (rescued == null) {
        blocked.add(target.phraseId);
        continue;
      }
      current = rescued;
    }

    return current;
  }

  SongDraft? _rescueOne({
    required SongDraft draft,
    required SongPhraseProducerAnalysis beforeAnalysis,
    required PhraseProducerAssessment target,
  }) {
    final lineage = target.lineage;
    if (lineage == null || lineage.isSource) return null;
    final sourceLocation = _parsePhraseId(lineage.sourcePhraseId);
    if (sourceLocation == null) return null;

    final targetSection = draft.sectionById(target.sectionId);
    final sourceSection = draft.sectionById(sourceLocation.$1);
    if (targetSection == null ||
        sourceSection == null ||
        targetSection.melody.isEmpty ||
        sourceSection.melody.isEmpty ||
        targetSection.progression.isEmpty) {
      return null;
    }

    final memory = memoryExtractor.capture(draft);
    final targetMemory = memory.section(target.sectionId);
    final sourceMemory = memory.section(sourceLocation.$1);
    if (targetMemory == null || sourceMemory == null) return null;

    final targetIndices = _phraseNoteIndices(
      targetSection,
      target.phraseIndex,
      targetMemory.phrases.length,
    );
    final sourceIndices = _phraseNoteIndices(
      sourceSection,
      sourceLocation.$2,
      sourceMemory.phrases.length,
    );
    if (targetIndices.length < 3 || sourceIndices.length < 2) return null;

    final sourceOrigin = _pitch(sourceSection.melody[sourceIndices.first]);
    final targetOrigin = _pitch(targetSection.melody[targetIndices.first]);
    final interior = <int>[
      for (var ordinal = 1; ordinal < targetIndices.length - 1; ordinal++)
        ordinal,
    ];
    if (interior.isEmpty) return null;

    // Spread identity restoration across the whole phrase rather than rewriting
    // the first half first. This keeps the musical sentence balanced and makes
    // each progressive stage genuinely more source-related.
    final ordered = <int>[];
    for (var stride = 2; stride >= 1; stride--) {
      for (final ordinal in interior) {
        if (ordinal % 2 == stride % 2 && !ordered.contains(ordinal)) {
          ordered.add(ordinal);
        }
      }
    }

    const stages = <double>[0.38, 0.52, 0.66, 0.80, 0.94, 1.0];
    SongDraft? bestDraft;
    PhraseProducerAssessment? bestAfter;
    var bestDistance = _distance(target);

    for (final stage in stages) {
      final rewriteCount =
          max(1, (ordered.length * stage).ceil()).clamp(1, ordered.length);
      final rewriteOrdinals = ordered.take(rewriteCount).toSet();
      final melody = List<MelodyNote>.from(targetSection.melody);

      for (var ordinal = 1; ordinal < targetIndices.length - 1; ordinal++) {
        if (!rewriteOrdinals.contains(ordinal)) continue;
        final targetIndex = targetIndices[ordinal];
        final current = melody[targetIndex];
        final sourceOrdinal = ((ordinal * (sourceIndices.length - 1)) /
                max(1, targetIndices.length - 1))
            .round()
            .clamp(0, sourceIndices.length - 1)
            .toInt();
        final source = sourceSection.melody[sourceIndices[sourceOrdinal]];
        final sourcePitch = _pitch(source);
        final desired = targetOrigin + (sourcePitch - sourceOrigin);
        final chord = targetSection.progression[
          current.chordIndex
              .clamp(0, targetSection.progression.length - 1)
              .toInt()
        ];
        final previousPitch = _pitch(melody[targetIndices[ordinal - 1]]);
        final pitch = _nearestPitch(
          getChordNotes(chord),
          desired,
          previousPitch: previousPitch,
          maxLeap: 9,
        );
        melody[targetIndex] = _melodyAtPitch(
          current,
          pitch,
          duration: source.duration,
          velocity: (current.velocity * 0.35 + source.velocity * 0.65)
              .clamp(0.32, 1.0)
              .toDouble(),
        );
      }

      final section = GeneratedSongSection(
        plan: targetSection.plan,
        candidate: targetSection.candidate,
        melody: melody,
        bass: targetSection.bass,
        development: targetSection.development,
      );
      final candidateDraft = draft.withSection(section);
      final afterMemory = memoryExtractor.capture(candidateDraft);
      final afterAnalysis = analyzer.analyze(
        draft: candidateDraft,
        memory: afterMemory,
      );
      final after = _assessment(afterAnalysis, target.phraseId);
      if (after == null || after.lineage == null) continue;
      if (after.lineage!.sourcePhraseId != lineage.sourcePhraseId) continue;

      final distance = _distance(after);
      final wholeSongDrop = beforeAnalysis.overallScore - afterAnalysis.overallScore;
      final phraseDrop = target.score - after.score;
      if (wholeSongDrop > 0.75 || phraseDrop > 4.0) continue;

      if (after.lineageInsideGuardrail) {
        // Prefer a strong phrase near the middle of its intended identity window
        // rather than barely scraping across the minimum.
        if (bestAfter == null ||
            !bestAfter.lineageInsideGuardrail ||
            after.score > bestAfter.score + 0.05 ||
            ((after.score - bestAfter.score).abs() <= 0.05 &&
                _centerDistance(after) < _centerDistance(bestAfter))) {
          bestDraft = candidateDraft;
          bestAfter = after;
          bestDistance = 0.0;
        }
        continue;
      }

      if (bestAfter?.lineageInsideGuardrail == true) continue;
      if (distance + 0.0001 < bestDistance ||
          ((distance - bestDistance).abs() <= 0.0001 &&
              (bestAfter == null || after.score > bestAfter.score))) {
        bestDraft = candidateDraft;
        bestAfter = after;
        bestDistance = distance;
      }
    }

    if (bestDraft == null || bestAfter == null) return null;
    if (bestDistance + 0.0001 >= _distance(target) &&
        !bestAfter.lineageInsideGuardrail) {
      return null;
    }
    return bestDraft;
  }

  List<int> _phraseNoteIndices(
    GeneratedSongSection section,
    int phraseIndex,
    int phraseCount,
  ) {
    if (section.progression.isEmpty || phraseCount <= 0) {
      return const <int>[];
    }
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

  PhraseProducerAssessment? _assessment(
    SongPhraseProducerAnalysis analysis,
    String phraseId,
  ) {
    for (final phrase in analysis.phrases) {
      if (phrase.phraseId == phraseId) return phrase;
    }
    return null;
  }

  (String, int)? _parsePhraseId(String phraseId) {
    final split = phraseId.lastIndexOf(':p');
    if (split <= 0) return null;
    final index = int.tryParse(phraseId.substring(split + 2));
    if (index == null) return null;
    return (phraseId.substring(0, split), index);
  }

  double _distance(PhraseProducerAssessment phrase) {
    final lineage = phrase.lineage;
    if (lineage == null || lineage.isSource || lineage.insideGuardrail) {
      return 0.0;
    }
    final value = lineage.sourceSimilarity;
    final window = lineage.targetWindow;
    return value < window.minimum
        ? window.minimum - value
        : value - window.maximum;
  }

  double _centerDistance(PhraseProducerAssessment phrase) {
    final lineage = phrase.lineage;
    if (lineage == null) return double.infinity;
    final center =
        (lineage.targetWindow.minimum + lineage.targetWindow.maximum) / 2.0;
    return (lineage.sourceSimilarity - center).abs();
  }

  int _pitch(MelodyNote note) => noteToPitch(note.note, note.octave);

  int _nearestPitch(
    List<String> noteNames,
    int desired, {
    required int previousPitch,
    required int maxLeap,
  }) {
    final candidates = <int>[];
    for (final name in noteNames.toSet()) {
      for (var octave = 2; octave <= 7; octave++) {
        final pitch = noteToPitch(name, octave);
        if (pitch < 48 || pitch > 96) continue;
        if ((pitch - previousPitch).abs() > maxLeap) continue;
        candidates.add(pitch);
      }
    }
    if (candidates.isEmpty) {
      return desired.clamp(48, 96).toInt();
    }
    candidates.sort((a, b) {
      final byDesired = (a - desired).abs().compareTo((b - desired).abs());
      if (byDesired != 0) return byDesired;
      return (a - previousPitch).abs().compareTo((b - previousPitch).abs());
    });
    return candidates.first;
  }

  MelodyNote _melodyAtPitch(
    MelodyNote source,
    int pitch, {
    required double duration,
    required double velocity,
  }) {
    final note = pitchToNote(pitch.clamp(48, 96).toInt());
    return MelodyNote(
      note: note['note'] as String,
      octave: note['octave'] as int,
      duration: duration.clamp(0.20, 4.5).toDouble(),
      velocity: velocity.clamp(0.0, 1.0).toDouble(),
      chordIndex: source.chordIndex,
    );
  }
}
