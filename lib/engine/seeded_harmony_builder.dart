import 'dart:math';

import '../models/constants.dart';
import '../models/types.dart';
import '../utils/music_theory.dart';
import 'seeded_music_generation.dart';
import 'song_request.dart';

/// UI-independent construction of one raw harmonic candidate.
///
/// Candidate ranking and canonical theory repair deliberately live outside this
/// class. Both single-progression generation and Song Architect call this same
/// builder so they cannot silently drift into different musical rule sets.
class SeededHarmonyBuilder {
  const SeededHarmonyBuilder({
    SeededMusicGeneration generation = const SeededMusicGeneration(),
  }) : _generation = generation;

  final SeededMusicGeneration _generation;

  List<Chord> build({
    required SongRequest request,
    required Random random,
    List<LockedChord> lockedChords = const <LockedChord>[],
    List<Chord> lockedProgression = const <Chord>[],
  }) {
    final keyInfo = parseKey(keyNameToString(request.key));
    final root = keyInfo['root'] as String;
    final isMinor = keyInfo['isMinor'] as bool;
    final profile = genreProfiles[request.genre]!;
    final complexityConfig = complexitySettings[request.complexity]!;

    List<Chord> chords;

    if (request.useFunctionalHarmony) {
      chords = _generation.generateFunctionalProgression(
        random: random,
        root: root,
        isMinorKey: isMinor,
        length: complexityConfig.chordCount[1],
        mood: request.mood,
      );
    } else {
      final baseProgression = _generation.choice(random, profile.progressions);
      final degreeSequence = _generation.buildDegreeSequence(
        random: random,
        baseProgression: baseProgression,
        config: complexityConfig,
        isMinor: isMinor,
        chordVariety: request.chordVariety,
      );
      final scale = isMinor ? ScaleName.minor : profile.scale;

      chords = degreeSequence.asMap().entries.map((entry) {
        final index = entry.key;
        final degree = entry.value;
        var chord = getChordFromDegree(root, degree, isMinor, scale);

        if (complexityConfig.useExtensions) {
          final extensionChance = 0.3 + ((request.chordVariety / 100.0) * 0.4);
          if (random.nextDouble() < extensionChance) {
            final extensions = profile.chordTypes
                .where((type) =>
                    type.name.contains('7') ||
                    type.name.contains('9') ||
                    type.name.contains('sus') ||
                    type.name.contains('add'))
                .toList(growable: false);
            if (extensions.isNotEmpty) {
              final weights = <ChordTypeName, double>{};
              for (final extension in extensions) {
                if (extension.name.contains('7') &&
                    !extension.name.contains('9')) {
                  weights[extension] = 0.5;
                } else if (extension.name.contains('9')) {
                  weights[extension] = 0.25;
                } else {
                  weights[extension] = 0.25;
                }
              }
              final total = weights.values.fold(0.0, (sum, value) => sum + value);
              var value = random.nextDouble() * total;
              for (final weighted in weights.entries) {
                value -= weighted.value;
                if (value <= 0) {
                  chord = chord.copyWith(type: weighted.key);
                  break;
                }
              }
            }
          }
        }

        chord = _generation.addStrategicExtensions(
          random: random,
          chord: chord,
          position: index,
          totalLength: degreeSequence.length,
          variety: request.chordVariety,
        );
        return applyGenreVoicing(chord, request.genre);
      }).toList(growable: false);
    }

    if (request.useModalInterchange &&
        (request.complexity == ComplexityLevel.complex ||
            request.complexity == ComplexityLevel.advanced)) {
      chords = _generation.applyModalInterchange(
        random: random,
        progression: chords,
        root: root,
        isMinorKey: isMinor,
      );
    }

    if (request.useAdvancedTheory &&
        (request.complexity == ComplexityLevel.complex ||
            request.complexity == ComplexityLevel.advanced)) {
      chords = _generation.applyAdvancedSubstitutions(
        random: random,
        progression: chords,
        root: root,
        isMinorKey: isMinor,
      );
    }

    chords = _generation.applySpice(
      random: random,
      progression: chords,
      level: request.spice,
    );

    // Locks are a UI/session concern, but accepting them as explicit immutable
    // inputs keeps the builder reusable without reaching into AppState.
    if (lockedChords.isNotEmpty && lockedProgression.isNotEmpty) {
      chords = List<Chord>.from(chords);
      for (final locked in lockedChords) {
        if (locked.locked &&
            locked.index >= 0 &&
            locked.index < lockedProgression.length &&
            locked.index < chords.length) {
          chords[locked.index] = lockedProgression[locked.index];
        }
      }
    }

    return List<Chord>.unmodifiable(chords);
  }
}
