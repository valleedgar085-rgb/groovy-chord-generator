import 'dart:math';

import '../models/constants.dart';
import '../models/types.dart';
import '../utils/music_theory.dart';
import 'phrase_model.dart';
import 'song_architecture.dart';

/// One phrase-sized compositional target used before note generation.
class PhraseCompositionPlan {
  const PhraseCompositionPlan({
    required this.index,
    required this.bars,
    required this.startChordIndex,
    required this.endChordIndexExclusive,
    required this.role,
    required this.cadenceIntent,
    required this.targetDensity,
    required this.targetRange,
    required this.climaxPosition,
    required this.usesSourceIdentity,
  });

  final int index;
  final int bars;
  final int startChordIndex;
  final int endChordIndexExclusive;
  final PhraseRole role;
  final PhraseCadenceIntent cadenceIntent;
  final double targetDensity;
  final int targetRange;
  final double climaxPosition;
  final bool usesSourceIdentity;

  int get chordCount => max(0, endChordIndexExclusive - startChordIndex);
}

class PhraseCompositionResult {
  PhraseCompositionResult({
    required List<MelodyNote> melody,
    required List<PhraseCompositionPlan> phrases,
  })  : melody = List<MelodyNote>.unmodifiable(melody),
        phrases = List<PhraseCompositionPlan>.unmodifiable(phrases);

  final List<MelodyNote> melody;
  final List<PhraseCompositionPlan> phrases;
}

/// Phase 5.8B phrase-first melody writer.
///
/// The legacy melody path chooses notes independently inside each chord. This
/// engine instead plans phrase roles, cadence intent, range, density and climax
/// first, then realizes notes against the active harmony. Repetition families
/// can reuse the actual earlier section as A′ / A″ source material without
/// copying it verbatim.
class PhraseComposer {
  const PhraseComposer({this.phraseBars = 4});

  final int phraseBars;

  PhraseCompositionResult compose({
    required Random random,
    required List<Chord> progression,
    required GenreKey genre,
    required RhythmLevel rhythm,
    required KeyName key,
    required SongSectionPlan section,
    List<MelodyNote> sourceMelody = const <MelodyNote>[],
    int sourceChordCount = 0,
  }) {
    if (progression.isEmpty) {
      return PhraseCompositionResult(
        melody: const <MelodyNote>[],
        phrases: const <PhraseCompositionPlan>[],
      );
    }

    final safePhraseBars = phraseBars <= 0 ? 4 : phraseBars;
    final phraseCount = max(1, (section.bars + safePhraseBars - 1) ~/ safePhraseBars);
    final profile = genreProfiles[genre]!;
    final rhythmPattern = rhythmPatterns[rhythm]!;
    final keyInfo = parseKey(keyNameToString(key));
    final scaleNotes = getScaleNotes(
      keyInfo['root'] as String,
      profile.melodyScale,
    );

    final output = <MelodyNote>[];
    final plans = <PhraseCompositionPlan>[];
    List<MelodyNote> previousPhrase = const <MelodyNote>[];

    for (var phraseIndex = 0; phraseIndex < phraseCount; phraseIndex++) {
      final startChord = ((phraseIndex * progression.length) / phraseCount).floor();
      var endChord = (((phraseIndex + 1) * progression.length) / phraseCount).floor();
      if (phraseIndex == phraseCount - 1) endChord = progression.length;
      if (endChord <= startChord && startChord < progression.length) {
        endChord = min(progression.length, startChord + 1);
      }

      final startBar = phraseIndex * safePhraseBars;
      final bars = min(safePhraseBars, max(1, section.bars - startBar));
      final role = _roleFor(section, phraseIndex);
      final cadence = _cadenceFor(section, phraseIndex, phraseCount);
      final sourcePhrase = _sourcePhrase(
        sourceMelody,
        sourceChordCount: sourceChordCount,
        phraseIndex: phraseIndex,
        phraseCount: phraseCount,
      );
      final answerReference = role == PhraseRole.answer && sourcePhrase.isEmpty
          ? previousPhrase
          : const <MelodyNote>[];
      final reference = sourcePhrase.isNotEmpty ? sourcePhrase : answerReference;
      final density = _targetDensity(
        role,
        rhythmPattern.melodyDensity,
        genre,
      );
      final range = _targetRange(section, role, genre);
      final climax = _climaxFor(section, role, phraseIndex, phraseCount);
      final plan = PhraseCompositionPlan(
        index: phraseIndex,
        bars: bars,
        startChordIndex: startChord,
        endChordIndexExclusive: endChord,
        role: role,
        cadenceIntent: cadence,
        targetDensity: density,
        targetRange: range,
        climaxPosition: climax,
        usesSourceIdentity: reference.isNotEmpty,
      );
      plans.add(plan);

      final phrase = _composePhrase(
        random: random,
        progression: progression,
        scaleNotes: scaleNotes,
        rhythmPattern: rhythmPattern,
        section: section,
        genre: genre,
        plan: plan,
        reference: reference,
        isRepeatedSource: sourcePhrase.isNotEmpty,
      );
      output.addAll(phrase);
      previousPhrase = phrase;
    }

    return PhraseCompositionResult(melody: output, phrases: plans);
  }

  List<MelodyNote> _composePhrase({
    required Random random,
    required List<Chord> progression,
    required List<String> scaleNotes,
    required RhythmPattern rhythmPattern,
    required SongSectionPlan section,
    required GenreKey genre,
    required PhraseCompositionPlan plan,
    required List<MelodyNote> reference,
    required bool isRepeatedSource,
  }) {
    if (plan.chordCount <= 0) return const <MelodyNote>[];

    final phrase = <MelodyNote>[];
    final referencePitches = reference
        .map((note) => noteToPitch(note.note, note.octave))
        .toList(growable: false);
    final referenceOrigin = referencePitches.isEmpty ? 0 : referencePitches.first;
    final referenceOffsets = referencePitches
        .map((pitch) => (pitch - referenceOrigin).clamp(-24, 24).toInt())
        .toList(growable: false);
    final referenceDurations = reference
        .map((note) => note.duration)
        .where((duration) => duration > 0.0)
        .toList(growable: false);

    final center = _registerCenter(section, genre);
    int? previousPitch;
    var ordinal = 0;
    final estimatedNoteCount = max(
      1,
      (plan.chordCount * plan.targetDensity).round(),
    );

    for (var chordIndex = plan.startChordIndex;
        chordIndex < plan.endChordIndexExclusive;
        chordIndex++) {
      final chord = progression[chordIndex];
      final chordTones = getChordNotes(chord);
      final noteCount = _notesForChord(
        random,
        plan,
        rhythmPattern.melodyDensity,
        genre,
      );

      for (var localIndex = 0; localIndex < noteCount; localIndex++) {
        final position = estimatedNoteCount <= 1
            ? 0.0
            : (ordinal / max(1, estimatedNoteCount - 1)).clamp(0.0, 1.0).toDouble();
        final desired = _desiredPitch(
          center: center,
          range: plan.targetRange,
          position: position,
          climax: plan.climaxPosition,
          role: plan.role,
          referenceOffsets: referenceOffsets,
          ordinal: ordinal,
          variation: section.variation,
          isRepeatedSource: isRepeatedSource,
        );
        final strongTarget = localIndex == 0 || localIndex == noteCount - 1;
        final allowedNames = strongTarget || random.nextDouble() < 0.72
            ? chordTones
            : <String>{...chordTones, ...scaleNotes}.toList(growable: false);
        final pitch = _nearestPitch(
          allowedNames,
          desired,
          previousPitch: previousPitch,
          maxLeap: _maxLeap(plan.role),
        );
        final note = pitchToNote(pitch);
        final duration = _durationFor(
          random,
          rhythmPattern,
          plan.role,
          ordinal,
          referenceDurations,
          isRepeatedSource,
        );
        final velocity = _velocityFor(
          rhythmPattern,
          section.targetEnergy,
          plan.role,
          localIndex,
          noteCount,
          ordinal,
        );
        phrase.add(
          MelodyNote(
            note: note['note'] as String,
            duration: duration,
            velocity: velocity,
            chordIndex: chordIndex,
            octave: note['octave'] as int,
          ),
        );
        previousPitch = pitch;
        ordinal++;
      }
    }

    if (phrase.isNotEmpty) {
      _applyCadenceTarget(
        phrase,
        progression,
        plan,
        center: center,
      );
      if (section.variation >= 2 && section.type == SongSectionType.chorus) {
        _escalateFinalCallback(phrase, progression, plan);
      }
    }

    return phrase;
  }

  PhraseRole _roleFor(SongSectionPlan plan, int index) {
    final id = plan.id.toLowerCase();
    if (id.contains('turnaround')) return PhraseRole.turnaround;
    if (id.contains('build')) return PhraseRole.lift;
    if (id.contains('drop') || id.contains('hook')) {
      return index.isEven ? PhraseRole.hook : PhraseRole.answer;
    }
    if (id.contains('breakdown') || id.contains('solo') || id.contains('bridge')) {
      return PhraseRole.contrast;
    }
    switch (plan.type) {
      case SongSectionType.intro:
        return PhraseRole.statement;
      case SongSectionType.verse:
        return index.isEven ? PhraseRole.question : PhraseRole.answer;
      case SongSectionType.preChorus:
        return PhraseRole.lift;
      case SongSectionType.chorus:
        return index.isEven ? PhraseRole.hook : PhraseRole.answer;
      case SongSectionType.bridge:
        return PhraseRole.contrast;
      case SongSectionType.outro:
        return PhraseRole.release;
    }
  }

  PhraseCadenceIntent _cadenceFor(
    SongSectionPlan plan,
    int index,
    int phraseCount,
  ) {
    if (index < phraseCount - 1) return PhraseCadenceIntent.open;
    switch (plan.type) {
      case SongSectionType.preChorus:
        return PhraseCadenceIntent.half;
      case SongSectionType.chorus:
      case SongSectionType.outro:
        return PhraseCadenceIntent.resolved;
      case SongSectionType.bridge:
        return PhraseCadenceIntent.suspended;
      case SongSectionType.intro:
      case SongSectionType.verse:
        return PhraseCadenceIntent.open;
    }
  }

  List<MelodyNote> _sourcePhrase(
    List<MelodyNote> source, {
    required int sourceChordCount,
    required int phraseIndex,
    required int phraseCount,
  }) {
    if (source.isEmpty || sourceChordCount <= 0 || phraseCount <= 0) {
      return const <MelodyNote>[];
    }
    return source.where((note) {
      final normalized = note.chordIndex / sourceChordCount.toDouble();
      final index = (normalized * phraseCount)
          .floor()
          .clamp(0, phraseCount - 1)
          .toInt();
      return index == phraseIndex;
    }).toList(growable: false);
  }

  double _targetDensity(PhraseRole role, double base, GenreKey genre) {
    var multiplier = switch (role) {
      PhraseRole.statement => 0.90,
      PhraseRole.question => 0.96,
      PhraseRole.answer => 0.88,
      PhraseRole.lift => 1.14,
      PhraseRole.hook => 1.08,
      PhraseRole.contrast => 0.84,
      PhraseRole.release => 0.62,
      PhraseRole.turnaround => 1.00,
    };
    multiplier *= switch (genre) {
      GenreKey.chillLofi => 0.78,
      GenreKey.darkTrap => 0.76,
      GenreKey.soulfulRnb => 0.92,
      GenreKey.funk => 1.18,
      GenreKey.energeticEdm => 1.08,
      GenreKey.cinematic => 0.82,
      _ => 1.0,
    };
    return (1.35 + base * 2.8) * multiplier;
  }

  int _targetRange(SongSectionPlan section, PhraseRole role, GenreKey genre) {
    var value = switch (role) {
      PhraseRole.statement => 8,
      PhraseRole.question => 9,
      PhraseRole.answer => 8,
      PhraseRole.lift => 11,
      PhraseRole.hook => 12,
      PhraseRole.contrast => 13,
      PhraseRole.release => 7,
      PhraseRole.turnaround => 9,
    };
    if (section.variation >= 2 && section.type == SongSectionType.chorus) {
      value += 2;
    }
    value += switch (genre) {
      GenreKey.soulfulRnb => 2,
      GenreKey.jazzFusion => 2,
      GenreKey.cinematic => 3,
      GenreKey.darkTrap => -2,
      GenreKey.chillLofi => -1,
      _ => 0,
    };
    return value.clamp(5, 17).toInt();
  }

  double _climaxFor(
    SongSectionPlan section,
    PhraseRole role,
    int index,
    int phraseCount,
  ) {
    var value = switch (role) {
      PhraseRole.statement => 0.58,
      PhraseRole.question => 0.80,
      PhraseRole.answer => 0.34,
      PhraseRole.lift => 0.88,
      PhraseRole.hook => 0.62,
      PhraseRole.contrast => 0.48,
      PhraseRole.release => 0.22,
      PhraseRole.turnaround => 0.72,
    };
    if (section.variation >= 2 && section.type == SongSectionType.chorus) {
      value = max(value, 0.72);
    }
    if (index == phraseCount - 1 && section.type == SongSectionType.outro) {
      value = 0.18;
    }
    return value.clamp(0.05, 0.95).toDouble();
  }

  int _registerCenter(SongSectionPlan section, GenreKey genre) {
    var center = 67 + (section.targetEnergy * 5).round();
    center += switch (genre) {
      GenreKey.darkTrap => -4,
      GenreKey.chillLofi => -2,
      GenreKey.soulfulRnb => 1,
      GenreKey.energeticEdm => 2,
      GenreKey.cinematic => 1,
      _ => 0,
    };
    if (section.type == SongSectionType.chorus) center += 2;
    if (section.type == SongSectionType.outro) center -= 3;
    return center.clamp(58, 78).toInt();
  }

  int _notesForChord(
    Random random,
    PhraseCompositionPlan plan,
    double baseDensity,
    GenreKey genre,
  ) {
    var count = (plan.targetDensity + baseDensity * 1.2).round();
    if (plan.role == PhraseRole.hook && random.nextBool()) count += 1;
    if (plan.role == PhraseRole.release) count = min(count, 2);
    if (genre == GenreKey.funk && random.nextDouble() < 0.45) count += 1;
    return count.clamp(1, 6).toInt();
  }

  double _desiredPitch({
    required int center,
    required int range,
    required double position,
    required double climax,
    required PhraseRole role,
    required List<int> referenceOffsets,
    required int ordinal,
    required int variation,
    required bool isRepeatedSource,
  }) {
    final clampedPosition = position.clamp(0.0, 1.0);
    final peakDistance = (clampedPosition - climax).abs();
    final peakShape = (1.0 - peakDistance / max(0.08, max(climax, 1.0 - climax)))
        .clamp(0.0, 1.0);
    final directional = switch (role) {
      PhraseRole.question => clampedPosition * 0.55,
      PhraseRole.answer => (1.0 - clampedPosition) * 0.35,
      PhraseRole.lift => clampedPosition * 0.70,
      PhraseRole.hook => peakShape * 0.45,
      PhraseRole.contrast => sin(clampedPosition * pi * 2) * 0.28 + 0.35,
      PhraseRole.release => (1.0 - clampedPosition) * 0.45,
      PhraseRole.turnaround => clampedPosition * 0.30,
      PhraseRole.statement => peakShape * 0.34,
    };
    var desired = center + ((directional - 0.18) * range).round();

    if (referenceOffsets.isNotEmpty) {
      final sourceOffset = referenceOffsets[ordinal % referenceOffsets.length];
      final preserve = variation >= 2 ? 0.82 : 0.72;
      desired = (center + sourceOffset * preserve + (desired - center) * (1.0 - preserve))
          .round();
      if (isRepeatedSource && variation >= 2 && peakShape > 0.72) {
        desired += 4;
      }
    } else if (role == PhraseRole.hook) {
      const hookCell = <int>[0, 3, 5, 3, 0, 5];
      desired += hookCell[ordinal % hookCell.length];
    }

    return desired.clamp(55, 88).toDouble();
  }

  int _nearestPitch(
    List<String> noteNames,
    double desired, {
    required int? previousPitch,
    required int maxLeap,
  }) {
    final names = noteNames.isEmpty ? const <String>['C'] : noteNames;
    final candidates = <int>[];
    for (var octave = 3; octave <= 6; octave++) {
      for (final name in names) {
        final pitch = noteToPitch(name, octave);
        if (pitch >= 52 && pitch <= 91) candidates.add(pitch);
      }
    }
    if (candidates.isEmpty) {
      return desired.round().clamp(52, 91).toInt();
    }

    candidates.sort((a, b) {
      double cost(int pitch) {
        var value = (pitch - desired).abs();
        if (previousPitch != null) {
          final leap = (pitch - previousPitch).abs();
          value += leap * 0.22;
          if (leap > maxLeap) value += (leap - maxLeap) * 1.8;
        }
        return value;
      }
      return cost(a).compareTo(cost(b));
    });
    return candidates.first;
  }

  int _maxLeap(PhraseRole role) => switch (role) {
        PhraseRole.contrast => 10,
        PhraseRole.hook => 7,
        PhraseRole.lift => 7,
        PhraseRole.turnaround => 8,
        _ => 6,
      };

  double _durationFor(
    Random random,
    RhythmPattern rhythmPattern,
    PhraseRole role,
    int ordinal,
    List<double> referenceDurations,
    bool preserveSource,
  ) {
    if (preserveSource && referenceDurations.isNotEmpty) {
      final base = referenceDurations[ordinal % referenceDurations.length];
      if (random.nextDouble() < 0.78) return base.clamp(0.25, 4.0).toDouble();
    }
    if (role == PhraseRole.hook) {
      const hookRhythm = <double>[0.5, 0.5, 1.0, 1.0, 0.5, 1.5];
      return hookRhythm[ordinal % hookRhythm.length];
    }
    if (role == PhraseRole.release) {
      const release = <double>[2.0, 1.5, 2.0, 1.0];
      return release[ordinal % release.length];
    }
    if (role == PhraseRole.lift) {
      const lift = <double>[1.0, 0.5, 0.5, 1.0, 0.5];
      return lift[ordinal % lift.length];
    }
    final durations = rhythmPattern.durations.isEmpty
        ? const <double>[1.0]
        : rhythmPattern.durations;
    return durations[random.nextInt(durations.length)].clamp(0.25, 4.0).toDouble();
  }

  double _velocityFor(
    RhythmPattern rhythmPattern,
    double energy,
    PhraseRole role,
    int localIndex,
    int noteCount,
    int ordinal,
  ) {
    final dynamic = rhythmPattern.dynamics.isEmpty
        ? 0.72
        : rhythmPattern.dynamics[ordinal % rhythmPattern.dynamics.length];
    var velocity = dynamic * 0.62 + (0.42 + energy * 0.42) * 0.38;
    if (localIndex == 0) velocity += 0.04;
    if (localIndex == noteCount - 1) velocity += 0.02;
    if (role == PhraseRole.hook || role == PhraseRole.lift) velocity += 0.05;
    if (role == PhraseRole.release) velocity -= 0.08;
    return velocity.clamp(0.38, 0.98).toDouble();
  }

  void _applyCadenceTarget(
    List<MelodyNote> phrase,
    List<Chord> progression,
    PhraseCompositionPlan plan, {
    required int center,
  }) {
    final last = phrase.last;
    if (last.chordIndex < 0 || last.chordIndex >= progression.length) return;
    final chord = progression[last.chordIndex];
    final chordTones = getChordNotes(chord);
    if (chordTones.isEmpty) return;

    List<String> preferred;
    switch (plan.cadenceIntent) {
      case PhraseCadenceIntent.resolved:
        preferred = <String>[chord.root, ...chordTones];
        break;
      case PhraseCadenceIntent.half:
        preferred = chordTones.length > 1
            ? <String>[chordTones.last, chord.root]
            : <String>[chord.root];
        break;
      case PhraseCadenceIntent.open:
        preferred = chordTones.where((note) => note != chord.root).toList(growable: false);
        if (preferred.isEmpty) preferred = chordTones;
        break;
      case PhraseCadenceIntent.deceptive:
        preferred = chordTones.reversed.toList(growable: false);
        break;
      case PhraseCadenceIntent.suspended:
        preferred = chordTones.length >= 2
            ? <String>[chordTones[1], chordTones.last]
            : chordTones;
        break;
    }

    final previous = phrase.length > 1
        ? noteToPitch(phrase[phrase.length - 2].note, phrase[phrase.length - 2].octave)
        : null;
    final pitch = _nearestPitch(
      preferred,
      center.toDouble(),
      previousPitch: previous,
      maxLeap: 7,
    );
    final note = pitchToNote(pitch);
    phrase[phrase.length - 1] = MelodyNote(
      note: note['note'] as String,
      duration: last.duration,
      velocity: max(last.velocity, 0.72),
      chordIndex: last.chordIndex,
      octave: note['octave'] as int,
    );
  }

  void _escalateFinalCallback(
    List<MelodyNote> phrase,
    List<Chord> progression,
    PhraseCompositionPlan plan,
  ) {
    if (phrase.length < 3) return;
    final targetIndex = ((phrase.length - 1) * plan.climaxPosition)
        .round()
        .clamp(1, phrase.length - 2)
        .toInt();
    final original = phrase[targetIndex];
    if (original.chordIndex < 0 || original.chordIndex >= progression.length) return;
    final chord = progression[original.chordIndex];
    final current = noteToPitch(original.note, original.octave);
    final raised = _nearestPitch(
      getChordNotes(chord),
      min(88, current + 7).toDouble(),
      previousPitch: targetIndex > 0
          ? noteToPitch(phrase[targetIndex - 1].note, phrase[targetIndex - 1].octave)
          : null,
      maxLeap: 10,
    );
    final note = pitchToNote(raised);
    phrase[targetIndex] = MelodyNote(
      note: note['note'] as String,
      duration: original.duration,
      velocity: max(original.velocity, 0.88),
      chordIndex: original.chordIndex,
      octave: note['octave'] as int,
    );
  }
}
