import 'dart:math';

import '../models/types.dart';
import 'harmony_engine.dart';
import 'song_candidate.dart';
import 'song_draft.dart';
import 'song_memory.dart';

/// Controlled relationship between a canonical section and its later return.
///
/// A′ keeps most of the source identity while allowing selected target material
/// through. A″ is more developed, but still anchors the first and final harmony
/// so the section remains recognizably part of the same repetition family.
enum SectionVariationLevel { aPrime, aDoublePrime }

class SectionVariationEngine {
  SectionVariationEngine({HarmonyEngine? harmonyEngine})
      : _harmonyEngine = harmonyEngine ?? HarmonyEngine(seed: 0);

  final HarmonyEngine _harmonyEngine;

  GeneratedSongSection transform({
    required GeneratedSongSection source,
    required GeneratedSongSection target,
    required SectionMemory sourceMemory,
    required SectionMemory targetMemory,
    required int seed,
    required SectionVariationLevel level,
  }) {
    final random = Random(seed);
    final profile = _profileFor(level);
    final progression = _blendProgression(
      source.progression,
      target.progression,
      random,
      sourceRetention: profile.harmonySourceRetention,
    );

    final changedChordIndexes = _changedChordIndexes(
      source.progression,
      progression,
    );

    final melody = _blendMelody(
      source.melody,
      target.melody,
      progression.length,
      random,
      sourceRetention: profile.melodySourceRetention,
      forceTargetChordIndexes: changedChordIndexes,
    );
    final bass = _blendBass(
      source.bass,
      target.bass,
      progression.length,
      random,
      sourceRetention: profile.bassSourceRetention,
      forceTargetChordIndexes: changedChordIndexes,
    );

    final identityBefore = targetMemory.identitySimilarityTo(sourceMemory);
    final identityBias = level == SectionVariationLevel.aPrime ? 2.0 : 0.5;
    final score = (_harmonyEngine.score(
              progression,
              section: target.plan.harmonySection,
            ) +
            identityBefore * identityBias)
        .clamp(0.0, 100.0)
        .toDouble();

    return GeneratedSongSection(
      plan: target.plan,
      candidate: SongCandidate(
        progression: progression,
        score: score,
        seed: target.candidate.seed,
        candidateIndex: target.candidate.candidateIndex,
        section: target.candidate.section,
      ),
      melody: melody,
      bass: bass,
    );
  }

  List<Chord> _blendProgression(
    List<Chord> source,
    List<Chord> target,
    Random random, {
    required double sourceRetention,
  }) {
    if (source.isEmpty) return List<Chord>.unmodifiable(target);
    if (target.isEmpty) return List<Chord>.unmodifiable(source);

    final output = <Chord>[];
    for (var index = 0; index < target.length; index++) {
      final sourceChord = _sourceChordForPosition(
        source,
        target.length,
        index,
      );
      final targetChord = target[index];

      // First and final harmony are explicit identity anchors. The final target
      // slot always maps to source.last, even when A′/A″ has a different chord
      // count from its source. This preserves the source cadence semantically,
      // not merely by positional index.
      final isIdentityAnchor = index == 0 || index == target.length - 1;
      final keepSource = isIdentityAnchor || random.nextDouble() < sourceRetention;
      final selected = keepSource ? sourceChord : targetChord;

      // Groove belongs to the destination section's performance intent. When a
      // source harmony chord is retained, inherit the target groove metadata.
      output.add(selected.copyWith(
        grooveIntensity: targetChord.grooveIntensity,
        swingOffset: targetChord.swingOffset,
      ));
    }
    return List<Chord>.unmodifiable(output);
  }

  Set<int> _changedChordIndexes(List<Chord> source, List<Chord> output) {
    final changed = <int>{};
    if (source.isEmpty) {
      return {for (var index = 0; index < output.length; index++) index};
    }
    for (var index = 0; index < output.length; index++) {
      final a = _sourceChordForPosition(source, output.length, index);
      final b = output[index];
      if (a.root != b.root || a.degree != b.degree || a.type != b.type) {
        changed.add(index);
      }
    }
    return changed;
  }

  Chord _sourceChordForPosition(
    List<Chord> source,
    int targetLength,
    int index,
  ) {
    if (index <= 0) return source.first;
    if (index >= targetLength - 1) return source.last;
    final sourceIndex = index < source.length ? index : source.length - 1;
    return source[sourceIndex];
  }

  List<MelodyNote> _blendMelody(
    List<MelodyNote> source,
    List<MelodyNote> target,
    int chordCount,
    Random random, {
    required double sourceRetention,
    required Set<int> forceTargetChordIndexes,
  }) {
    if (source.isEmpty) return List<MelodyNote>.unmodifiable(target);
    if (target.isEmpty) {
      return List<MelodyNote>.unmodifiable(
        source.map((note) => _safeMelodyNote(note, chordCount)),
      );
    }

    final output = <MelodyNote>[];
    final length = target.length > source.length ? target.length : source.length;
    for (var index = 0; index < length; index++) {
      final sourceNote = source[index % source.length];
      final targetNote = target[index % target.length];
      final sourceChordIndex = _safeChordIndex(sourceNote.chordIndex, chordCount);
      final forceTarget = forceTargetChordIndexes.contains(sourceChordIndex);
      final keepSource = !forceTarget && random.nextDouble() < sourceRetention;
      output.add(_safeMelodyNote(
        keepSource ? sourceNote : targetNote,
        chordCount,
      ));
    }
    return List<MelodyNote>.unmodifiable(output);
  }

  List<BassNote> _blendBass(
    List<BassNote> source,
    List<BassNote> target,
    int chordCount,
    Random random, {
    required double sourceRetention,
    required Set<int> forceTargetChordIndexes,
  }) {
    if (source.isEmpty) return List<BassNote>.unmodifiable(target);
    if (target.isEmpty) {
      return List<BassNote>.unmodifiable(
        source.map((note) => _safeBassNote(note, chordCount)),
      );
    }

    final output = <BassNote>[];
    final length = target.length > source.length ? target.length : source.length;
    for (var index = 0; index < length; index++) {
      final sourceNote = source[index % source.length];
      final targetNote = target[index % target.length];
      final sourceChordIndex = _safeChordIndex(sourceNote.chordIndex, chordCount);
      final forceTarget = forceTargetChordIndexes.contains(sourceChordIndex);
      final keepSource = !forceTarget && random.nextDouble() < sourceRetention;
      output.add(_safeBassNote(
        keepSource ? sourceNote : targetNote,
        chordCount,
      ));
    }
    return List<BassNote>.unmodifiable(output);
  }

  MelodyNote _safeMelodyNote(MelodyNote note, int chordCount) {
    return MelodyNote(
      note: note.note,
      duration: note.duration,
      velocity: note.velocity,
      chordIndex: _safeChordIndex(note.chordIndex, chordCount),
      octave: note.octave,
    );
  }

  BassNote _safeBassNote(BassNote note, int chordCount) {
    return BassNote(
      note: note.note,
      duration: note.duration,
      velocity: note.velocity,
      octave: note.octave,
      chordIndex: _safeChordIndex(note.chordIndex, chordCount),
      style: note.style,
    );
  }

  int _safeChordIndex(int chordIndex, int chordCount) {
    if (chordCount <= 0) return 0;
    return chordIndex.clamp(0, chordCount - 1).toInt();
  }

  _VariationProfile _profileFor(SectionVariationLevel level) {
    switch (level) {
      case SectionVariationLevel.aPrime:
        return const _VariationProfile(
          harmonySourceRetention: 0.78,
          melodySourceRetention: 0.74,
          bassSourceRetention: 0.80,
        );
      case SectionVariationLevel.aDoublePrime:
        return const _VariationProfile(
          harmonySourceRetention: 0.56,
          melodySourceRetention: 0.54,
          bassSourceRetention: 0.62,
        );
    }
  }
}

class _VariationProfile {
  const _VariationProfile({
    required this.harmonySourceRetention,
    required this.melodySourceRetention,
    required this.bassSourceRetention,
  });

  final double harmonySourceRetention;
  final double melodySourceRetention;
  final double bassSourceRetention;
}
