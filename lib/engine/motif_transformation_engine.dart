import 'dart:math';

import '../models/types.dart';
import '../utils/music_theory.dart';

/// How aggressively a repeated section may reinterpret its remembered motif.
enum MotifVariationIntensity { subtle, developed }

/// Musical operations applied by [MotifTransformationEngine].
enum MotifOperation {
  rhythmicDisplacement,
  embellishment,
  simplification,
  contourInversion,
  sequence,
  cadenceIntensification,
}

/// Immutable result of one deterministic motif-development pass.
class MotifTransformationResult {
  MotifTransformationResult({
    required List<Chord> progression,
    required List<MelodyNote> melody,
    required List<BassNote> bass,
    required List<MotifOperation> operations,
  })  : progression = List<Chord>.unmodifiable(progression),
        melody = List<MelodyNote>.unmodifiable(melody),
        bass = List<BassNote>.unmodifiable(bass),
        operations = List<MotifOperation>.unmodifiable(operations);

  final List<Chord> progression;
  final List<MelodyNote> melody;
  final List<BassNote> bass;
  final List<MotifOperation> operations;
}

/// Deterministic, theory-constrained development of remembered musical ideas.
///
/// This sits after source/target A′ / A″ blending. It does not create a new
/// unrelated motif: it reshapes the blended material while preserving phrase
/// duration and snapping pitch-changing operations back onto the active chord.
class MotifTransformationEngine {
  const MotifTransformationEngine();

  MotifTransformationResult transform({
    required List<Chord> progression,
    required List<MelodyNote> melody,
    required List<BassNote> bass,
    required int seed,
    required MotifVariationIntensity intensity,
    bool emphasizeCadence = false,
  }) {
    final random = Random(seed);
    var developedProgression = List<Chord>.from(progression);
    var developedMelody = List<MelodyNote>.from(melody);
    final developedBass = List<BassNote>.from(bass);
    final operations = <MotifOperation>[];

    if (intensity == MotifVariationIntensity.subtle) {
      final available = <MotifOperation>[
        if (developedMelody.length >= 4) MotifOperation.rhythmicDisplacement,
        if (_hasEmbellishableNote(developedMelody)) MotifOperation.embellishment,
        if (developedMelody.length >= 5) MotifOperation.simplification,
      ];
      if (available.isNotEmpty) {
        final chosen = available[random.nextInt(available.length)];
        developedMelody = _applyMelodyOperation(
          chosen,
          developedMelody,
          developedProgression,
          random,
        );
        operations.add(chosen);
      }
    } else {
      if (developedMelody.length >= 4) {
        developedMelody = _rhythmicDisplacement(developedMelody);
        operations.add(MotifOperation.rhythmicDisplacement);
      }

      if (developedMelody.length >= 4 && developedProgression.isNotEmpty) {
        final pitchOperation = random.nextBool()
            ? MotifOperation.contourInversion
            : MotifOperation.sequence;
        developedMelody = _applyMelodyOperation(
          pitchOperation,
          developedMelody,
          developedProgression,
          random,
        );
        operations.add(pitchOperation);
      }

      if (_hasEmbellishableNote(developedMelody) && random.nextBool()) {
        developedMelody = _embellish(
          developedMelody,
          developedProgression,
          random,
        );
        operations.add(MotifOperation.embellishment);
      } else if (developedMelody.length >= 6) {
        developedMelody = _simplify(developedMelody, random);
        operations.add(MotifOperation.simplification);
      }
    }

    if (emphasizeCadence && _canIntensifyCadence(developedProgression)) {
      developedProgression = _intensifyCadence(developedProgression);
      operations.add(MotifOperation.cadenceIntensification);
    }

    return MotifTransformationResult(
      progression: developedProgression,
      melody: developedMelody,
      bass: developedBass,
      operations: operations,
    );
  }

  List<MelodyNote> _applyMelodyOperation(
    MotifOperation operation,
    List<MelodyNote> melody,
    List<Chord> progression,
    Random random,
  ) {
    switch (operation) {
      case MotifOperation.rhythmicDisplacement:
        return _rhythmicDisplacement(melody);
      case MotifOperation.embellishment:
        return _embellish(melody, progression, random);
      case MotifOperation.simplification:
        return _simplify(melody, random);
      case MotifOperation.contourInversion:
        return _invertContour(melody, progression);
      case MotifOperation.sequence:
        return _sequence(melody, progression, random);
      case MotifOperation.cadenceIntensification:
        return melody;
    }
  }

  /// Redistributes rhythm/accent across interior notes without changing phrase
  /// duration or the opening/closing note identity.
  List<MelodyNote> _rhythmicDisplacement(List<MelodyNote> melody) {
    if (melody.length < 4) return List<MelodyNote>.from(melody);
    final output = List<MelodyNote>.from(melody);
    final interior = melody.sublist(1, melody.length - 1);
    for (var i = 0; i < interior.length; i++) {
      final rhythmSource = interior[(i + 1) % interior.length];
      final original = interior[i];
      output[i + 1] = MelodyNote(
        note: original.note,
        duration: rhythmSource.duration,
        velocity: rhythmSource.velocity,
        chordIndex: original.chordIndex,
        octave: original.octave,
      );
    }
    return output;
  }

  bool _hasEmbellishableNote(List<MelodyNote> melody) =>
      melody.any((note) => note.duration >= 1.0);

  /// Splits one long note into a chord-tone approach plus its original target.
  /// Total duration is preserved exactly.
  List<MelodyNote> _embellish(
    List<MelodyNote> melody,
    List<Chord> progression,
    Random random,
  ) {
    if (melody.isEmpty || progression.isEmpty) {
      return List<MelodyNote>.from(melody);
    }
    final candidates = <int>[];
    for (var i = 0; i < melody.length - 1; i++) {
      final note = melody[i];
      if (note.duration >= 1.0 &&
          note.chordIndex >= 0 &&
          note.chordIndex < progression.length) {
        candidates.add(i);
      }
    }
    if (candidates.isEmpty) return List<MelodyNote>.from(melody);

    final index = candidates[random.nextInt(candidates.length)];
    final original = melody[index];
    final chord = progression[original.chordIndex];
    final approachPitch = _nearestDifferentChordTone(
      noteToPitch(original.note, original.octave),
      chord,
    );
    final approach = pitchToNote(approachPitch);
    final firstDuration = original.duration * 0.35;
    final secondDuration = original.duration - firstDuration;

    final output = <MelodyNote>[];
    for (var i = 0; i < melody.length; i++) {
      if (i != index) {
        output.add(melody[i]);
        continue;
      }
      output.add(MelodyNote(
        note: approach['note'] as String,
        duration: firstDuration,
        velocity: (original.velocity * 0.82).clamp(0.0, 1.0).toDouble(),
        chordIndex: original.chordIndex,
        octave: approach['octave'] as int,
      ));
      output.add(MelodyNote(
        note: original.note,
        duration: secondDuration,
        velocity: original.velocity,
        chordIndex: original.chordIndex,
        octave: original.octave,
      ));
    }
    return output;
  }

  /// Reduces density only when adjacent notes belong to the same chord. Removed
  /// duration is merged into the previous retained note so phrase length stays
  /// unchanged and no note is stretched across a harmony boundary by design.
  List<MelodyNote> _simplify(List<MelodyNote> melody, Random random) {
    if (melody.length < 5) return List<MelodyNote>.from(melody);
    final output = <MelodyNote>[];
    final parity = random.nextInt(2);

    for (var i = 0; i < melody.length; i++) {
      final note = melody[i];
      final isAnchor = i == 0 || i == melody.length - 1;
      final canMerge = !isAnchor &&
          output.isNotEmpty &&
          i % 2 == parity &&
          output.last.chordIndex == note.chordIndex;
      if (!canMerge) {
        output.add(note);
        continue;
      }

      final previous = output.removeLast();
      output.add(MelodyNote(
        note: previous.note,
        duration: previous.duration + note.duration,
        velocity: max(previous.velocity, note.velocity),
        chordIndex: previous.chordIndex,
        octave: previous.octave,
      ));
    }
    return output;
  }

  /// Mirrors interior melodic motion around the opening pitch, then quantizes
  /// each result to the active chord to avoid chromatic collisions.
  List<MelodyNote> _invertContour(
    List<MelodyNote> melody,
    List<Chord> progression,
  ) {
    if (melody.length < 4 || progression.isEmpty) {
      return List<MelodyNote>.from(melody);
    }
    final pivot = noteToPitch(melody.first.note, melody.first.octave);
    final output = <MelodyNote>[melody.first];

    for (var i = 1; i < melody.length - 1; i++) {
      final original = melody[i];
      final originalPitch = noteToPitch(original.note, original.octave);
      final desired = pivot - (originalPitch - pivot);
      output.add(_snapMelodyNote(original, desired, progression));
    }
    output.add(melody.last);
    return output;
  }

  /// Sequences the latter half of the motif up/down a step, quantized onto the
  /// active harmony. Rhythm and accents are retained.
  List<MelodyNote> _sequence(
    List<MelodyNote> melody,
    List<Chord> progression,
    Random random,
  ) {
    if (melody.length < 4 || progression.isEmpty) {
      return List<MelodyNote>.from(melody);
    }
    final direction = random.nextBool() ? 2 : -2;
    final start = melody.length ~/ 2;
    final output = List<MelodyNote>.from(melody);
    for (var i = start; i < melody.length - 1; i++) {
      final original = melody[i];
      final desired = noteToPitch(original.note, original.octave) + direction;
      output[i] = _snapMelodyNote(original, desired, progression);
    }
    return output;
  }

  MelodyNote _snapMelodyNote(
    MelodyNote original,
    int desiredPitch,
    List<Chord> progression,
  ) {
    if (original.chordIndex < 0 || original.chordIndex >= progression.length) {
      return original;
    }
    final snapped = _nearestChordTone(desiredPitch, progression[original.chordIndex]);
    final note = pitchToNote(snapped);
    return MelodyNote(
      note: note['note'] as String,
      duration: original.duration,
      velocity: original.velocity,
      chordIndex: original.chordIndex,
      octave: note['octave'] as int,
    );
  }

  int _nearestDifferentChordTone(int pitch, Chord chord) {
    final chordPitches = _nearbyChordTonePitches(pitch, chord)
        .where((candidate) => candidate != pitch)
        .toList(growable: false);
    if (chordPitches.isEmpty) return pitch;
    chordPitches.sort((a, b) => (a - pitch).abs().compareTo((b - pitch).abs()));
    return chordPitches.first;
  }

  int _nearestChordTone(int pitch, Chord chord) {
    final candidates = _nearbyChordTonePitches(pitch, chord);
    candidates.sort((a, b) => (a - pitch).abs().compareTo((b - pitch).abs()));
    return candidates.first;
  }

  List<int> _nearbyChordTonePitches(int aroundPitch, Chord chord) {
    final result = <int>[];
    for (final note in getChordNotes(chord)) {
      final pitchClass = getNoteIndex(note);
      final baseOctave = (aroundPitch ~/ 12) - 1;
      for (var octave = baseOctave - 1; octave <= baseOctave + 1; octave++) {
        result.add(noteToPitch(note, octave));
      }
      // Ensure the pitch class is represented even if octave math changes in
      // future utility implementations.
      if (result.every((pitch) => pitch % 12 != pitchClass)) {
        result.add(aroundPitch - (aroundPitch % 12) + pitchClass);
      }
    }
    return result;
  }

  bool _canIntensifyCadence(List<Chord> progression) {
    if (progression.length < 2) return false;
    final tonic = progression.last.degree;
    return tonic == 'I' || tonic == 'i';
  }

  /// Strengthens a tonic-ending A″ return to an explicit V7 -> I/i arrival.
  List<Chord> _intensifyCadence(List<Chord> progression) {
    final output = List<Chord>.from(progression);
    final tonic = output.last;
    final previous = output[output.length - 2];
    output[output.length - 2] = Chord(
      root: transposeNote(tonic.root, 7),
      type: ChordTypeName.dominant7,
      degree: 'V',
      numeral: 'V7',
      harmonyFunction: HarmonyFunction.dominant,
      grooveIntensity: previous.grooveIntensity,
      swingOffset: previous.swingOffset,
    );
    return output;
  }
}
