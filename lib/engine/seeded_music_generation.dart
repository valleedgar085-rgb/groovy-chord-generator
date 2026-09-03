import 'dart:math';

import '../models/constants.dart';
import '../models/types.dart';
import '../utils/music_theory.dart';

/// Deterministic counterparts for the stochastic music-generation stages.
///
/// Every method receives a [Random] owned by one generation stream. This avoids
/// hidden global RNG state and makes requests safe to replay or run in parallel.
class SeededMusicGeneration {
  const SeededMusicGeneration();

  T choice<T>(Random random, List<T> items) {
    if (items.isEmpty) throw StateError('Cannot choose from an empty list.');
    return items[random.nextInt(items.length)];
  }

  int intInRange(Random random, int min, int max) {
    return min + random.nextInt(max - min + 1);
  }

  List<Chord> generateFunctionalProgression({
    required Random random,
    required String root,
    required bool isMinorKey,
    required int length,
    required MoodType mood,
  }) {
    final moodProfile = moodProfiles[mood]!;
    final scale = choice(random, moodProfile.scales);
    final template = choice(random, functionalProgressions);
    final functions = List<HarmonyFunction>.generate(
      length,
      (index) => template[index % template.length],
      growable: false,
    );

    return functions.map((function) {
      return _generateChordFromFunction(
        random: random,
        root: root,
        isMinorKey: isMinorKey,
        function: function,
        scale: scale,
        allowedTypes: moodProfile.chordTypes,
        tensionRange: moodProfile.tensionRange,
      );
    }).toList(growable: false);
  }

  Chord _generateChordFromFunction({
    required Random random,
    required String root,
    required bool isMinorKey,
    required HarmonyFunction function,
    required ScaleName scale,
    required List<ChordTypeName> allowedTypes,
    required List<double> tensionRange,
  }) {
    final options = functionalHarmony[function] ??
        functionalHarmony[HarmonyFunction.tonic]!;
    final valid = options
        .where((entry) =>
            (entry['tension'] as double) >= tensionRange[0] &&
            (entry['tension'] as double) <= tensionRange[1])
        .toList(growable: false);
    final selected = choice(random, valid.isNotEmpty ? valid : options);
    final degree = selected['degree'] as String;
    final type = choice(random, allowedTypes);

    const semitones = <String, int>{
      'I': 0,
      'i': 0,
      'II': 2,
      'ii': 2,
      'III': 4,
      'iii': 4,
      'IV': 5,
      'iv': 5,
      'V': 7,
      'v': 7,
      'VI': 9,
      'vi': 9,
      'VII': 11,
      'vii': 11,
      'bII': 1,
      'bVII': 10,
      'bVI': 8,
      'bIII': 3,
    };
    const degreeIndex = <String, int>{
      'I': 0,
      'i': 0,
      'II': 1,
      'ii': 1,
      'III': 2,
      'iii': 2,
      'IV': 3,
      'iv': 3,
      'V': 4,
      'v': 4,
      'VI': 5,
      'vi': 5,
      'VII': 6,
      'vii': 6,
      'bII': 1,
      'bVII': 6,
      'bVI': 5,
      'bIII': 2,
    };

    final index = degreeIndex[degree] ?? 0;
    return Chord(
      root: transposeNote(root, semitones[degree] ?? 0),
      type: type,
      degree: degree,
      numeral: romanNumerals[index.clamp(0, romanNumerals.length - 1)],
      harmonyFunction: function,
    );
  }

  List<String> buildDegreeSequence({
    required Random random,
    required List<String> baseProgression,
    required ComplexitySetting config,
    required bool isMinor,
    required int chordVariety,
  }) {
    final progression = List<String>.from(baseProgression);
    final targetLength = intInRange(
      random,
      config.chordCount[0],
      config.chordCount[1],
    );

    if (chordVariety > 0) {
      var enhanced = _addPassingChords(random, progression, chordVariety);
      enhanced = _addApproachChords(random, enhanced, chordVariety);
      enhanced = _applySubstitutions(random, enhanced, chordVariety, isMinor);
      enhanced = _optimizeTensionFlow(random, enhanced, isMinor);

      while (enhanced.length > targetLength && enhanced.length > 3) {
        enhanced.removeAt(intInRange(random, 1, enhanced.length - 2));
      }
      return enhanced;
    }

    while (progression.length < targetLength) {
      final insertIndex = intInRange(random, 0, progression.length);
      progression.insert(
        insertIndex,
        choice(
          random,
          isMinor
              ? const ['ii', 'iv', 'V', 'VI', 'III', 'VII']
              : const ['ii', 'IV', 'V', 'vi', 'iii'],
        ),
      );
    }
    return progression;
  }

  List<String> _addPassingChords(
      Random random, List<String> progression, int variety) {
    if (variety < 30 || progression.length >= 12) return progression;
    final result = List<String>.from(progression);
    final count = ((variety / 100.0) * 3).round();
    const options = <String, List<String>>{
      'I': ['iii', 'vi', 'V'],
      'ii': ['iii', 'V', 'IV'],
      'iii': ['IV', 'vi', 'ii'],
      'IV': ['ii', 'V', 'vi'],
      'V': ['vi', 'IV', 'I'],
      'vi': ['ii', 'IV', 'iii'],
      'VII': ['V', 'iii', 'I'],
      'i': ['III', 'VI', 'V'],
      'III': ['VI', 'iv', 'VII'],
      'iv': ['VII', 'V', 'VI'],
      'VI': ['VII', 'iv', 'III'],
    };

    for (var i = 0; i < count && result.length < 12; i++) {
      if (result.length < 2) break;
      final insertAfter = random.nextInt(result.length - 1);
      final base = result[insertAfter].replaceAll(RegExp(r'[^IVXivx]+'), '');
      final candidates = options[base];
      if (candidates != null && candidates.isNotEmpty) {
        result.insert(insertAfter + 1, choice(random, candidates));
      }
    }
    return result;
  }

  List<String> _addApproachChords(
      Random random, List<String> progression, int variety) {
    if (variety < 50) return progression;
    final result = List<String>.from(progression);
    for (var i = 0; i < result.length - 1; i++) {
      if ((result[i + 1] == 'V' || result[i + 1] == 'v') &&
          random.nextDouble() < 0.3) {
        result.insert(i + 1, random.nextBool() ? 'vii' : 'V/V');
        i++;
      }
    }
    return result;
  }

  List<String> _applySubstitutions(
      Random random, List<String> progression, int variety, bool isMinor) {
    if (variety < 40) return progression;
    final chance = (variety / 100.0) * 0.4;
    const substitutions = <String, List<String>>{
      'I': ['iii', 'vi'],
      'i': ['III', 'VI'],
      'IV': ['ii', 'vi'],
      'iv': ['ii', 'VI'],
      'V': ['vii', 'iii'],
      'vi': ['I', 'IV'],
    };
    return progression.map((degree) {
      final candidates = substitutions[degree];
      if (candidates != null && random.nextDouble() < chance) {
        return choice(random, candidates);
      }
      return degree;
    }).toList(growable: false);
  }

  List<String> _optimizeTensionFlow(
      Random random, List<String> progression, bool isMinor) {
    if (progression.length < 3) return progression;
    final result = List<String>.from(progression);
    const major = <String, double>{
      'I': 0.0, 'ii': 0.4, 'iii': 0.5, 'IV': 0.3,
      'V': 0.8, 'vi': 0.4, 'vii': 0.9, 'VII': 0.7,
    };
    const minor = <String, double>{
      'i': 0.0, 'ii': 0.5, 'III': 0.3, 'iv': 0.4,
      'v': 0.6, 'V': 0.8, 'VI': 0.3, 'VII': 0.7, 'vii': 0.9,
    };
    final tensions = isMinor ? minor : major;
    String base(String value) => value.replaceAll(RegExp(r'[^IVXivx]+'), '');

    for (var i = 1; i < result.length - 1; i++) {
      if ((tensions[base(result[i - 1])] ?? 0.5) > 0.6 &&
          (tensions[base(result[i])] ?? 0.5) > 0.6 &&
          (tensions[base(result[i + 1])] ?? 0.5) > 0.6) {
        final low = tensions.entries
            .where((entry) => entry.value < 0.4)
            .map((entry) => entry.key)
            .toList(growable: false);
        if (low.isNotEmpty) result[i] = choice(random, low);
      }
    }

    if (result.isNotEmpty &&
        (tensions[base(result.last)] ?? 0.5) > 0.6 &&
        random.nextDouble() < 0.7) {
      result[result.length - 1] = isMinor ? 'i' : 'I';
    }
    return result;
  }

  Chord addStrategicExtensions({
    required Random random,
    required Chord chord,
    required int position,
    required int totalLength,
    required int variety,
  }) {
    if (variety < 30) return chord;
    final progress = position / totalLength;
    final chance = (variety / 100.0) *
        (0.4 + (0.4 * (1 - (progress - 0.5).abs() * 2)));
    if (random.nextDouble() >= chance) return chord;

    if (chord.type == ChordTypeName.major) {
      final options = <ChordTypeName>[
        ChordTypeName.major7,
        ChordTypeName.add9,
        if (variety > 60) ChordTypeName.major9,
      ];
      return chord.copyWith(type: choice(random, options));
    }
    if (chord.type == ChordTypeName.minor) {
      return chord.copyWith(
        type: choice(random, const [ChordTypeName.minor7, ChordTypeName.minor9]),
      );
    }
    return chord;
  }

  List<Chord> applyModalInterchange({
    required Random random,
    required List<Chord> progression,
    required String root,
    required bool isMinorKey,
  }) {
    const borrowedFromMinor = <String, Map<String, Object>>{
      'iv': {'root': 3, 'type': ChordTypeName.minor},
      'bVII': {'root': 10, 'type': ChordTypeName.major},
      'bVI': {'root': 8, 'type': ChordTypeName.major},
    };
    const borrowedFromMajor = <String, Map<String, Object>>{
      'IV': {'root': 5, 'type': ChordTypeName.major},
      'I': {'root': 0, 'type': ChordTypeName.major},
    };
    final borrowed = isMinorKey ? borrowedFromMajor : borrowedFromMinor;

    return progression.map((chord) {
      if (random.nextDouble() >= 0.3 || borrowed.isEmpty) return chord;
      final symbol = choice(random, borrowed.keys.toList(growable: false));
      final info = borrowed[symbol]!;
      return Chord(
        root: transposeNote(root, info['root'] as int),
        type: info['type'] as ChordTypeName,
        degree: symbol,
        numeral: symbol,
        isBorrowed: true,
      );
    }).toList(growable: false);
  }

  List<Chord> applyAdvancedSubstitutions({
    required Random random,
    required List<Chord> progression,
    required String root,
    required bool isMinorKey,
  }) {
    final result = <Chord>[];
    for (var i = 0; i < progression.length; i++) {
      final chord = progression[i];
      final next = i + 1 < progression.length ? progression[i + 1] : null;
      if (next != null &&
          (next.degree == 'V' || next.degree == 'v') &&
          random.nextDouble() > 0.6) {
        result
          ..add(chord)
          ..add(Chord(
            root: transposeNote(root, 2),
            type: ChordTypeName.dominant7,
            degree: 'V/V',
            numeral: 'V/V',
            isSecondaryDominant: true,
          ));
        continue;
      }
      if (!isMinorKey &&
          (chord.degree == 'IV' || chord.degree == 'iv') &&
          random.nextDouble() > 0.7) {
        result.add(chord.copyWith(
          type: ChordTypeName.minor,
          degree: 'iv',
          numeral: 'iv',
          isBorrowed: true,
        ));
        continue;
      }
      if ((chord.degree == 'V' || chord.degree == 'v') &&
          chord.type == ChordTypeName.dominant7 &&
          random.nextDouble() > 0.75) {
        result.add(Chord(
          root: transposeNote(root, 1),
          type: ChordTypeName.dominant7,
          degree: 'bII7',
          numeral: 'bII7',
          isTritoneSubstitution: true,
        ));
        continue;
      }
      result.add(chord);
    }
    return result;
  }

  List<Chord> applySpice({
    required Random random,
    required List<Chord> progression,
    required SpiceLevel level,
  }) {
    return progression
        .map((chord) => _applySpiceToChord(random, chord, level))
        .toList(growable: false);
  }

  Chord _applySpiceToChord(Random random, Chord chord, SpiceLevel level) {
    final config = spiceConfigs[level]!;
    if (!config.allowExtensions) {
      if (chord.type.name.contains('7') || chord.type.name.contains('9')) {
        if (chord.type.name.contains('minor')) {
          return chord.copyWith(type: ChordTypeName.minor);
        }
        if (chord.type.name.contains('dim')) {
          return chord.copyWith(type: ChordTypeName.diminished);
        }
        if (chord.type.name.contains('aug')) {
          return chord.copyWith(type: ChordTypeName.augmented);
        }
        return chord.copyWith(type: ChordTypeName.major);
      }
      return chord;
    }

    var result = chord;
    if (config.maxExtension >= 7) {
      if (result.type == ChordTypeName.major && random.nextBool()) {
        result = result.copyWith(type: ChordTypeName.major7);
      } else if (result.type == ChordTypeName.minor && random.nextBool()) {
        result = result.copyWith(type: ChordTypeName.minor7);
      }
    }
    if (config.maxExtension >= 9 && config.allowAlterations) {
      if (result.type == ChordTypeName.major7 && random.nextDouble() > 0.6) {
        result = result.copyWith(type: ChordTypeName.major9);
      } else if (result.type == ChordTypeName.minor7 &&
          random.nextDouble() > 0.6) {
        result = result.copyWith(type: ChordTypeName.minor9);
      } else if (result.type == ChordTypeName.major &&
          random.nextDouble() > 0.7) {
        result = result.copyWith(type: ChordTypeName.add9);
      }
    }
    if (level == SpiceLevel.fire &&
        random.nextBool() &&
        random.nextDouble() > 0.7 &&
        result.type == ChordTypeName.major) {
      result = result.copyWith(
        type: random.nextBool() ? ChordTypeName.sus4 : ChordTypeName.sus2,
      );
    }
    return result;
  }

  List<MelodyNote> generateMelody({
    required Random random,
    required List<Chord> progression,
    required GenreKey genre,
    required RhythmLevel rhythm,
    required KeyName key,
  }) {
    final profile = genreProfiles[genre]!;
    final rhythmPattern = rhythmPatterns[rhythm]!;
    final keyInfo = parseKey(keyNameToString(key));
    final scaleNotes = getScaleNotes(
      keyInfo['root'] as String,
      profile.melodyScale,
    );
    final melody = <MelodyNote>[];

    for (var chordIndex = 0; chordIndex < progression.length; chordIndex++) {
      final chord = progression[chordIndex];
      final notesPerChord = (4 * rhythmPattern.melodyDensity).ceil() + 1;
      final chordTones = chordTypes[chord.type]!
          .intervals
          .map((interval) => transposeNote(chord.root, interval))
          .toList(growable: false);
      for (var i = 0; i < notesPerChord; i++) {
        final pool = random.nextDouble() > 0.3 ? chordTones : scaleNotes;
        melody.add(MelodyNote(
          note: choice(random, pool),
          duration: choice(random, rhythmPattern.durations),
          velocity: rhythmPattern.dynamics[i % rhythmPattern.dynamics.length],
          chordIndex: chordIndex,
          octave: intInRange(random, 4, 5),
        ));
      }
    }
    return melody;
  }

  List<BassNote> generateBass({
    required Random random,
    required List<Chord> progression,
    required BassStyle style,
    required int variety,
    required RhythmLevel rhythm,
  }) {
    final bass = <BassNote>[];
    final rhythmPattern = rhythmPatterns[rhythm]!;
    final varietyFactor = variety / 100.0;
    const bassOctave = 2;

    for (var chordIndex = 0; chordIndex < progression.length; chordIndex++) {
      final chord = progression[chordIndex];
      final chordNotes = getChordNotes(chord);
      final root = chord.root;
      final fifth = transposeNote(root, 7);
      switch (style) {
        case BassStyle.root:
          final count = 1 + (varietyFactor * 3).floor();
          for (var i = 0; i < count; i++) {
            bass.add(BassNote(
              note: root,
              duration: 4 / count,
              velocity: rhythmPattern.dynamics[i % rhythmPattern.dynamics.length],
              octave: bassOctave,
              chordIndex: chordIndex,
              style: style,
            ));
          }
          break;
        case BassStyle.walking:
          final scaleNotes = getScaleNotes(root, ScaleName.major);
          for (var i = 0; i < 4; i++) {
            String note;
            if (i == 0) {
              note = root;
            } else if (i == 3 && random.nextDouble() < 0.5) {
              final next = progression[(chordIndex + 1) % progression.length];
              note = transposeNote(next.root, random.nextBool() ? 1 : 11);
            } else if (random.nextDouble() < varietyFactor * 0.3) {
              note = transposeNote(root, random.nextInt(11) + 1);
            } else {
              note = choice(random, scaleNotes);
            }
            bass.add(BassNote(
              note: note,
              duration: 1,
              velocity: rhythmPattern.dynamics[i % rhythmPattern.dynamics.length],
              octave: bassOctave,
              chordIndex: chordIndex,
              style: style,
            ));
          }
          break;
        case BassStyle.syncopated:
          const patterns = <List<double>>[
            [1.0, 0.5, 0.5, 1.0, 1.0],
            [0.5, 0.5, 1.0, 0.5, 0.5, 1.0],
            [1.5, 0.5, 1.0, 1.0],
          ];
          final pattern = choice(random, patterns);
          for (var i = 0; i < pattern.length; i++) {
            if (random.nextDouble() >= 0.2 * (1 - varietyFactor)) {
              bass.add(BassNote(
                note: random.nextDouble() < varietyFactor * 0.4
                    ? choice(random, chordNotes)
                    : root,
                duration: pattern[i],
                velocity:
                    rhythmPattern.dynamics[i % rhythmPattern.dynamics.length],
                octave: bassOctave,
                chordIndex: chordIndex,
                style: style,
              ));
            }
          }
          break;
        case BassStyle.octave:
          final count = 2 + (varietyFactor * 2).floor();
          for (var i = 0; i < count; i++) {
            bass.add(BassNote(
              note: random.nextDouble() < varietyFactor * 0.3 ? fifth : root,
              duration: 4 / count,
              velocity: rhythmPattern.dynamics[i % rhythmPattern.dynamics.length],
              octave: i.isEven ? bassOctave : bassOctave + 1,
              chordIndex: chordIndex,
              style: style,
            ));
          }
          break;
        case BassStyle.fifths:
          final pattern = varietyFactor > 0.5
              ? [root, fifth, root, fifth]
              : [root, root, fifth, root];
          for (var i = 0; i < pattern.length; i++) {
            bass.add(BassNote(
              note: pattern[i],
              duration: 1,
              velocity: rhythmPattern.dynamics[i % rhythmPattern.dynamics.length],
              octave: bassOctave,
              chordIndex: chordIndex,
              style: style,
            ));
          }
          break;
      }
    }
    return bass;
  }
}
