/// Groovy Chord Generator
/// Music Theory Utility Functions
/// Version 2.5

import 'dart:math';
import '../models/types.dart';
import '../models/constants.dart';

final _random = Random();

// ===================================
// Note Manipulation Functions
// ===================================

int getNoteIndex(String note) {
  final cleanNote = note.replaceAll('m', '');
  final notesIndex = notes.indexOf(cleanNote);
  if (notesIndex != -1) return notesIndex;
  return noteDisplay.indexOf(cleanNote);
}

String transposeNote(String rootNote, int interval) {
  final rootIndex = getNoteIndex(rootNote);
  final newIndex = (rootIndex + interval) % 12;
  return notes[newIndex];
}

List<String> getScaleNotes(String rootNote, ScaleName scaleName) {
  final scale = scales[scaleName] ?? scales[ScaleName.major]!;
  return scale.map((interval) => transposeNote(rootNote, interval)).toList();
}

Map<String, dynamic> parseKey(String keyString) {
  final isMinor = keyString.contains('m');
  final root = keyString.replaceAll('m', '');
  return {'root': root, 'isMinor': isMinor};
}

String keyNameToString(KeyName key) {
  switch (key) {
    case KeyName.C: return 'C';
    case KeyName.G: return 'G';
    case KeyName.D: return 'D';
    case KeyName.A: return 'A';
    case KeyName.E: return 'E';
    case KeyName.F: return 'F';
    case KeyName.Bb: return 'Bb';
    case KeyName.Am: return 'Am';
    case KeyName.Em: return 'Em';
    case KeyName.Dm: return 'Dm';
    case KeyName.Bm: return 'Bm';
    case KeyName.Fm: return 'Fm';
  }
}

// ===================================
// Chord Generation Functions
// ===================================

Chord getChordFromDegree(String root, String degree, bool isMinorKey, ScaleName scale) {
  const degreeMap = {
    'I': 0, 'i': 0,
    'II': 1, 'ii': 1,
    'III': 2, 'iii': 2,
    'IV': 3, 'iv': 3,
    'V': 4, 'v': 4,
    'VI': 5, 'vi': 5,
    'VII': 6, 'vii': 6,
  };

  final scaleNotes = getScaleNotes(root, scale);
  final degreeIndex = degreeMap[degree] ?? 0;
  final chordRoot = scaleNotes[degreeIndex < scaleNotes.length ? degreeIndex : 0];

  // Determine chord quality based on degree and key
  final isUpperCase = degree == degree.toUpperCase();
  ChordTypeName chordType;

  if (isMinorKey) {
    const minorKeyQualities = [
      ChordTypeName.minor, ChordTypeName.diminished, ChordTypeName.major,
      ChordTypeName.minor, ChordTypeName.minor, ChordTypeName.major, ChordTypeName.major
    ];
    chordType = isUpperCase ? ChordTypeName.major : (degreeIndex < minorKeyQualities.length ? minorKeyQualities[degreeIndex] : ChordTypeName.major);
  } else {
    const majorKeyQualities = [
      ChordTypeName.major, ChordTypeName.minor, ChordTypeName.minor,
      ChordTypeName.major, ChordTypeName.major, ChordTypeName.minor, ChordTypeName.diminished
    ];
    chordType = isUpperCase ? ChordTypeName.major : (degreeIndex < majorKeyQualities.length ? majorKeyQualities[degreeIndex] : ChordTypeName.major);
  }

  return Chord(
    root: chordRoot,
    type: chordType,
    degree: degree,
    numeral: romanNumerals[degreeIndex < romanNumerals.length ? degreeIndex : 0],
  );
}

// ===================================
// Voice Leading Functions
// ===================================

int noteToPitch(String note, int octave) {
  final noteIndex = getNoteIndex(note);
  return (octave + 1) * 12 + noteIndex;
}

Map<String, dynamic> pitchToNote(int pitch) {
  final octave = (pitch ~/ 12) - 1;
  final noteIndex = pitch % 12;
  return {'note': notes[noteIndex], 'octave': octave};
}

List<String> getChordNotes(Chord chord) {
  final intervals = chordTypes[chord.type]?.intervals ?? [0, 4, 7];
  return intervals.map((interval) => transposeNote(chord.root, interval)).toList();
}

List<VoicedNote> findBestVoicing(
  List<String> chordNotes,
  List<VoicedNote>? previousVoicedNotes,
  [int baseOctave = 4]
) {
  if (previousVoicedNotes == null || previousVoicedNotes.isEmpty) {
    return chordNotes.asMap().entries.map((entry) {
      final index = entry.key;
      final note = entry.value;
      final octave = baseOctave + (index ~/ 4);
      return VoicedNote(
        note: note,
        octave: octave,
        pitch: noteToPitch(note, octave),
      );
    }).toList();
  }

  final prevCenterPitch = previousVoicedNotes.fold<int>(0, (sum, n) => sum + n.pitch) / previousVoicedNotes.length;

  final possibleVoicings = <List<VoicedNote>>[];
  const minOctave = 3;
  const maxOctave = 5;

  for (var startOctave = minOctave; startOctave <= maxOctave; startOctave++) {
    for (var inversion = 0; inversion < chordNotes.length; inversion++) {
      final voicing = <VoicedNote>[];
      for (var i = 0; i < chordNotes.length; i++) {
        final noteIndex = (i + inversion) % chordNotes.length;
        final octaveOffset = i < inversion ? 1 : 0;
        final octave = startOctave + octaveOffset;
        if (octave >= minOctave && octave <= maxOctave) {
          final pitch = noteToPitch(chordNotes[noteIndex], octave);
          voicing.add(VoicedNote(
            note: chordNotes[noteIndex],
            octave: octave,
            pitch: pitch,
          ));
        }
      }
      if (voicing.length == chordNotes.length) {
        possibleVoicings.add(voicing);
      }
    }
  }

  var bestVoicing = possibleVoicings.isNotEmpty ? possibleVoicings[0] : <VoicedNote>[];
  var minDistance = double.infinity;

  for (final voicing in possibleVoicings) {
    final voicingCenter = voicing.fold<int>(0, (sum, n) => sum + n.pitch) / voicing.length;
    final distance = (voicingCenter - prevCenterPitch).abs();

    var totalNoteDistance = 0.0;
    for (final vNote in voicing) {
      final closestPrev = previousVoicedNotes.fold<double>(double.infinity, (closest, pNote) {
        final dist = (vNote.pitch - pNote.pitch).abs().toDouble();
        return dist < closest ? dist : closest;
      });
      totalNoteDistance += closestPrev;
    }

    final combinedDistance = distance + totalNoteDistance * 0.5;

    if (combinedDistance < minDistance) {
      minDistance = combinedDistance;
      bestVoicing = voicing;
    }
  }

  return bestVoicing;
}

List<Chord> applyVoiceLeading(List<Chord> progression) {
  if (progression.isEmpty) return progression;

  List<VoicedNote>? previousVoicedNotes;
  final result = <Chord>[];

  for (final chord in progression) {
    final chordNotes = getChordNotes(chord);
    final voicing = findBestVoicing(chordNotes, previousVoicedNotes, 4);
    result.add(chord.copyWith(voicedNotes: voicing));
    previousVoicedNotes = voicing;
  }

  return result;
}

// ===================================
// Advanced Chord Substitution Functions
// ===================================

List<Chord> applyAdvancedSubstitutions(List<Chord> progression, String root, bool isMinorKey) {
  final result = <Chord>[];

  for (var i = 0; i < progression.length; i++) {
    final chord = progression[i];
    final nextChord = i + 1 < progression.length ? progression[i + 1] : null;

    // Secondary Dominant
    if (nextChord != null && (nextChord.degree == 'V' || nextChord.degree == 'v') && _random.nextDouble() > 0.6) {
      final secondaryDomRoot = transposeNote(root, 2);
      final secondaryDom = Chord(
        root: secondaryDomRoot,
        type: ChordTypeName.dominant7,
        degree: 'V/V',
        numeral: 'V/V',
        isSecondaryDominant: true,
      );
      result.add(chord);
      result.add(secondaryDom);
      continue;
    }

    // Borrowed Chord
    if (!isMinorKey && (chord.degree == 'IV' || chord.degree == 'iv') && _random.nextDouble() > 0.7) {
      final borrowedChord = chord.copyWith(
        type: ChordTypeName.minor,
        degree: 'iv',
        numeral: 'iv',
        isBorrowed: true,
      );
      result.add(borrowedChord);
      continue;
    }

    // Tritone Substitution
    if ((chord.degree == 'V' || chord.degree == 'v') && chord.type == ChordTypeName.dominant7 && _random.nextDouble() > 0.75) {
      final tritoneRoot = transposeNote(root, 1);
      final tritoneChord = Chord(
        root: tritoneRoot,
        type: ChordTypeName.dominant7,
        degree: 'bII7',
        numeral: 'bII7',
        isTritoneSubstitution: true,
      );
      result.add(tritoneChord);
      continue;
    }

    result.add(chord);
  }

  return result;
}

// ===================================
// Modal Interchange Functions
// ===================================

List<Chord> applyModalInterchange(List<Chord> progression, String root, bool isMinorKey) {
  const modalInterchangeProbability = 0.3;
  final result = <Chord>[];

  // Borrowed chords definitions
  const borrowedFromMinor = {
    'iv': {'root': 3, 'type': ChordTypeName.minor, 'symbol': 'iv'},
    'bVII': {'root': 10, 'type': ChordTypeName.major, 'symbol': 'bVII'},
    'bVI': {'root': 8, 'type': ChordTypeName.major, 'symbol': 'bVI'},
  };

  const borrowedFromMajor = {
    'IV': {'root': 5, 'type': ChordTypeName.major, 'symbol': 'IV'},
    'I': {'root': 0, 'type': ChordTypeName.major, 'symbol': 'I'},
  };

  final borrowedChords = isMinorKey ? borrowedFromMajor : borrowedFromMinor;

  for (final chord in progression) {
    if (_random.nextDouble() < modalInterchangeProbability && borrowedChords.isNotEmpty) {
      final borrowedKeys = borrowedChords.keys.toList();
      final symbol = borrowedKeys[_random.nextInt(borrowedKeys.length)];
      final borrowedInfo = borrowedChords[symbol]!;
      final borrowedRoot = transposeNote(root, borrowedInfo['root'] as int);
      final borrowedChord = Chord(
        root: borrowedRoot,
        type: borrowedInfo['type'] as ChordTypeName,
        degree: symbol,
        numeral: symbol,
        isBorrowed: true,
      );
      result.add(borrowedChord);
      continue;
    }

    result.add(chord);
  }

  return result;
}

Chord applyGenreVoicing(Chord chord, GenreKey genre) {
  // Apply genre-specific voicings
  if (genre == GenreKey.jazzFusion) {
    // Shell voicings for jazz
    return chord.copyWith();
  } else if (genre == GenreKey.cinematic || genre == GenreKey.indieRock) {
    // Open voicings
    return chord.copyWith();
  }
  return chord;
}

// ===================================
// Spice Functions
// ===================================

List<Chord> spiceUpProgression(List<Chord> progression, String root, bool isMinor) {
  return progression.map((chord) {
    final spiceType = _random.nextDouble();

    if (spiceType < 0.25) {
      if (chord.type == ChordTypeName.major) {
        return chord.copyWith(type: _random.nextBool() ? ChordTypeName.major7 : ChordTypeName.add9);
      } else if (chord.type == ChordTypeName.minor) {
        return chord.copyWith(type: _random.nextBool() ? ChordTypeName.minor7 : ChordTypeName.minor9);
      }
    } else if (spiceType < 0.5) {
      if (chord.type == ChordTypeName.dominant7 || chord.degree == 'V') {
        final tritoneRoot = transposeNote(chord.root, 6);
        return chord.copyWith(
          root: tritoneRoot,
          type: ChordTypeName.dominant7,
          degree: 'bII7',
          numeral: 'bII7',
          isTritoneSubstitution: true,
        );
      }
    } else if (spiceType < 0.75) {
      if (!isMinor && chord.degree == 'IV') {
        return chord.copyWith(
          type: ChordTypeName.minor7,
          degree: 'iv7',
          isBorrowed: true,
        );
      } else if (!isMinor && _random.nextBool()) {
        final bViRoot = transposeNote(root, 8);
        return chord.copyWith(
          root: bViRoot,
          type: ChordTypeName.major7,
          degree: 'bVImaj7',
          isBorrowed: true,
        );
      }
    } else {
      if (chord.type == ChordTypeName.major || chord.type == ChordTypeName.minor) {
        return chord.copyWith(type: _random.nextBool() ? ChordTypeName.sus4 : ChordTypeName.sus2);
      }
    }

    return chord;
  }).toList();
}

// ===================================
// Spice Level Control Functions
// ===================================

Chord applySpiceToChord(Chord chord, SpiceLevel level) {
  final config = spiceConfigs[level]!;

  if (!config.allowExtensions) {
    // Mild: Keep as triads
    if (chord.type.name.contains('7') || chord.type.name.contains('9')) {
      if (chord.type.name.contains('minor')) {
        return chord.copyWith(type: ChordTypeName.minor);
      } else if (chord.type.name.contains('dim')) {
        return chord.copyWith(type: ChordTypeName.diminished);
      } else if (chord.type.name.contains('aug')) {
        return chord.copyWith(type: ChordTypeName.augmented);
      } else {
        return chord.copyWith(type: ChordTypeName.major);
      }
    }
    return chord;
  }

  // Medium and above: Allow 7ths
  if (config.maxExtension >= 7) {
    if (chord.type == ChordTypeName.major && _random.nextBool()) {
      return chord.copyWith(type: ChordTypeName.major7);
    } else if (chord.type == ChordTypeName.minor && _random.nextBool()) {
      return chord.copyWith(type: ChordTypeName.minor7);
    }
  }

  // Hot and above: Allow 9ths and alterations
  if (config.maxExtension >= 9 && config.allowAlterations) {
    if (chord.type == ChordTypeName.major7 && _random.nextDouble() > 0.6) {
      return chord.copyWith(type: ChordTypeName.major9);
    } else if (chord.type == ChordTypeName.minor7 && _random.nextDouble() > 0.6) {
      return chord.copyWith(type: ChordTypeName.minor9);
    } else if (chord.type == ChordTypeName.major && _random.nextDouble() > 0.7) {
      return chord.copyWith(type: ChordTypeName.add9);
    }
  }

  // Fire level: Maximum complexity
  if (level == SpiceLevel.fire && _random.nextBool()) {
    if (_random.nextDouble() > 0.7) {
      if (chord.type == ChordTypeName.major) {
        return chord.copyWith(type: _random.nextBool() ? ChordTypeName.sus4 : ChordTypeName.sus2);
      }
    }
  }

  return chord;
}

List<Chord> applySpiceToProgression(List<Chord> progression, SpiceLevel level) {
  return progression.map((chord) => applySpiceToChord(chord, level)).toList();
}

// ===================================
// Bass Line Generation Functions
// ===================================

List<BassNote> generateBassLine(
  List<Chord> progression,
  BassStyle style,
  int variety,
  RhythmLevel rhythm,
) {
  final bassLine = <BassNote>[];
  final rhythmPattern = rhythmPatterns[rhythm]!;
  final varietyFactor = variety / 100;
  const bassOctave = 2;

  for (var chordIndex = 0; chordIndex < progression.length; chordIndex++) {
    final chord = progression[chordIndex];
    final chordNotes = getChordNotes(chord);
    final root = chord.root;
    final fifth = transposeNote(root, 7);

    switch (style) {
      case BassStyle.root:
        final notesPerChord = 1 + (varietyFactor * 3).floor();
        for (var i = 0; i < notesPerChord; i++) {
          bassLine.add(BassNote(
            note: root,
            duration: 4 / notesPerChord,
            velocity: rhythmPattern.dynamics[i % rhythmPattern.dynamics.length],
            octave: bassOctave,
            chordIndex: chordIndex,
            style: style,
          ));
        }
        break;

      case BassStyle.walking:
        final scaleNotes = getScaleNotes(root, ScaleName.major);
        const notesPerChord = 4;
        for (var i = 0; i < notesPerChord; i++) {
          final useChromatic = _random.nextDouble() < varietyFactor * 0.3;
          String note;
          if (i == 0) {
            note = root;
          } else if (i == notesPerChord - 1 && _random.nextDouble() < 0.5) {
            final nextChord = progression[(chordIndex + 1) % progression.length];
            note = transposeNote(nextChord.root, _random.nextBool() ? 1 : 11);
          } else if (useChromatic) {
            note = transposeNote(root, _random.nextInt(11) + 1);
          } else {
            note = scaleNotes[_random.nextInt(scaleNotes.length)];
          }
          bassLine.add(BassNote(
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
        final patterns = [
          [1.0, 0.5, 0.5, 1.0, 1.0],
          [0.5, 0.5, 1.0, 0.5, 0.5, 1.0],
          [1.5, 0.5, 1.0, 1.0],
        ];
        final pattern = patterns[_random.nextInt(patterns.length)];
        for (var i = 0; i < pattern.length; i++) {
          final dur = pattern[i];
          final isRest = _random.nextDouble() < 0.2 * (1 - varietyFactor);
          if (!isRest) {
            final useAlternate = _random.nextDouble() < varietyFactor * 0.4;
            final note = useAlternate ? chordNotes[_random.nextInt(chordNotes.length)] : root;
            bassLine.add(BassNote(
              note: note,
              duration: dur,
              velocity: rhythmPattern.dynamics[i % rhythmPattern.dynamics.length],
              octave: bassOctave,
              chordIndex: chordIndex,
              style: style,
            ));
          }
        }
        break;

      case BassStyle.octave:
        final notesPerChord = 2 + (varietyFactor * 2).floor();
        for (var i = 0; i < notesPerChord; i++) {
          final octave = i % 2 == 0 ? bassOctave : bassOctave + 1;
          final useAlternate = _random.nextDouble() < varietyFactor * 0.3;
          final note = useAlternate ? fifth : root;
          bassLine.add(BassNote(
            note: note,
            duration: 4 / notesPerChord,
            velocity: rhythmPattern.dynamics[i % rhythmPattern.dynamics.length],
            octave: octave,
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
          bassLine.add(BassNote(
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

  return bassLine;
}

// ===================================
// Functional Harmony Functions
// ===================================

const functionalHarmony = {
  HarmonyFunction.tonic: [
    {'degree': 'I', 'tension': 0.0},
    {'degree': 'vi', 'tension': 0.2},
    {'degree': 'iii', 'tension': 0.3},
  ],
  HarmonyFunction.subdominant: [
    {'degree': 'IV', 'tension': 0.4},
    {'degree': 'ii', 'tension': 0.5},
  ],
  HarmonyFunction.dominant: [
    {'degree': 'V', 'tension': 0.8},
    {'degree': 'vii', 'tension': 0.9},
  ],
  HarmonyFunction.passing: [
    {'degree': 'bVII', 'tension': 0.5},
    {'degree': 'bVI', 'tension': 0.4},
  ],
};

const functionalProgressions = [
  [HarmonyFunction.tonic, HarmonyFunction.subdominant, HarmonyFunction.dominant, HarmonyFunction.tonic],
  [HarmonyFunction.tonic, HarmonyFunction.tonic, HarmonyFunction.subdominant, HarmonyFunction.dominant],
  [HarmonyFunction.tonic, HarmonyFunction.subdominant, HarmonyFunction.subdominant, HarmonyFunction.dominant],
  [HarmonyFunction.subdominant, HarmonyFunction.dominant, HarmonyFunction.tonic, HarmonyFunction.tonic],
];

List<Chord> generateFunctionalProgression(
  String root,
  bool isMinorKey,
  int length,
  MoodType mood,
) {
  final moodProfile = moodProfiles[mood]!;
  final scale = moodProfile.scales[_random.nextInt(moodProfile.scales.length)];
  
  // Choose a functional progression template
  final template = functionalProgressions[_random.nextInt(functionalProgressions.length)];
  
  // Build functions list
  final functions = <HarmonyFunction>[];
  for (var i = 0; i < length; i++) {
    functions.add(template[i % template.length]);
  }
  
  // Generate chords based on functions
  return functions.map((func) {
    return generateChordFromFunction(
      root,
      isMinorKey,
      func,
      scale,
      moodProfile.chordTypes,
      moodProfile.tensionRange,
    );
  }).toList();
}

Chord generateChordFromFunction(
  String root,
  bool isMinorKey,
  HarmonyFunction func,
  ScaleName scale,
  List<ChordTypeName> allowedTypes,
  List<double> tensionRange,
) {
  final functionalChords = functionalHarmony[func] ?? functionalHarmony[HarmonyFunction.tonic]!;
  
  // Filter by tension range
  final validChords = functionalChords.where(
    (fc) => (fc['tension'] as double) >= tensionRange[0] && (fc['tension'] as double) <= tensionRange[1]
  ).toList();
  
  final chosenChord = validChords.isNotEmpty
      ? validChords[_random.nextInt(validChords.length)]
      : functionalChords[_random.nextInt(functionalChords.length)];
  
  final chordType = allowedTypes[_random.nextInt(allowedTypes.length)];
  
  const degreeMap = {
    'I': 0, 'i': 0,
    'II': 2, 'ii': 2,
    'III': 4, 'iii': 4,
    'IV': 5, 'iv': 5,
    'V': 7, 'v': 7,
    'VI': 9, 'vi': 9,
    'VII': 11, 'vii': 11,
    'bII': 1, 'bVII': 10, 'bVI': 8, 'bIII': 3,
  };
  
  const degreeToIndex = {
    'I': 0, 'i': 0,
    'II': 1, 'ii': 1,
    'III': 2, 'iii': 2,
    'IV': 3, 'iv': 3,
    'V': 4, 'v': 4,
    'VI': 5, 'vi': 5,
    'VII': 6, 'vii': 6,
    'bII': 1, 'bVII': 6, 'bVI': 5, 'bIII': 2,
  };
  
  final degree = chosenChord['degree'] as String;
  final interval = degreeMap[degree] ?? 0;
  final chordRoot = transposeNote(root, interval);
  final degreeIndex = degreeToIndex[degree] ?? 0;
  
  return Chord(
    root: chordRoot,
    type: chordType,
    degree: degree,
    numeral: romanNumerals[degreeIndex < romanNumerals.length ? degreeIndex : 0],
    harmonyFunction: func,
  );
}

// ===================================
// Groove Engine Functions
// ===================================

List<Chord> applyGrooveToProgression(List<Chord> progression, GrooveTemplate template) {
  final pattern = groovePatterns[template]!;
  
  return progression.asMap().entries.map((entry) {
    final index = entry.key;
    final chord = entry.value;
    final beatIndex = index % pattern.beatPattern.length;
    
    return chord.copyWith(
      grooveIntensity: pattern.beatPattern[beatIndex],
      swingOffset: pattern.swingAmount,
    );
  }).toList();
}

// ===================================
// Helper Functions
// ===================================

T randomChoice<T>(List<T> list) {
  return list[_random.nextInt(list.length)];
}

int randomInt(int min, int max) {
  return min + _random.nextInt(max - min + 1);
}

String getTimeAgo(int timestamp) {
  final seconds = ((DateTime.now().millisecondsSinceEpoch - timestamp) / 1000).floor();

  if (seconds < 60) return 'Just now';
  if (seconds < 3600) return '${(seconds / 60).floor()}m ago';
  if (seconds < 86400) return '${(seconds / 3600).floor()}h ago';
  return '${(seconds / 86400).floor()}d ago';
}

// Get chord symbol for display
String getChordSymbol(Chord chord) {
  final typeSymbol = chordTypes[chord.type]?.symbol ?? '';
  return '${chord.root}$typeSymbol';
}

// Get chord type name
String getChordTypeName(ChordTypeName type) {
  return chordTypes[type]?.name ?? 'Unknown';
}
