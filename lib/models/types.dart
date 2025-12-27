// ignore_for_file: constant_identifier_names
// Groovy Chord Generator
// Dart Type Definitions
// Version 2.5

/// Note names (chromatic scale)
enum NoteName { C, CSharp, D, DSharp, E, F, FSharp, G, GSharp, A, ASharp, B }

/// Note display names (with flats)
enum NoteDisplayName { C, Db, D, Eb, E, F, Gb, G, Ab, A, Bb, B }

/// Chord type names
enum ChordTypeName {
  major,
  minor,
  diminished,
  augmented,
  major7,
  minor7,
  dominant7,
  diminished7,
  halfDim7,
  sus2,
  sus4,
  add9,
  minor9,
  major9,
}

/// Scale names
enum ScaleName {
  major,
  minor,
  harmonicMinor,
  melodicMinor,
  dorian,
  phrygian,
  lydian,
  mixolydian,
  locrian,
  pentatonicMajor,
  pentatonicMinor,
  blues,
}

/// Genre keys
enum GenreKey {
  happyPop,
  chillLofi,
  energeticEdm,
  soulfulRnb,
  jazzFusion,
  darkTrap,
  cinematic,
  indieRock,
  reggae,
  blues,
  country,
  funk,
}

/// Complexity levels
enum ComplexityLevel { simple, medium, complex, advanced }

/// Rhythm levels
enum RhythmLevel { soft, moderate, strong, intense }

/// Sound types
enum SoundType { sine, triangle, square, sawtooth }

/// Harmony functions
enum HarmonyFunction { tonic, subdominant, dominant, passing }

/// Mood types
enum MoodType {
  happy,
  sad,
  dreamy,
  energetic,
  dark,
  mysterious,
  triumphant,
  relaxed,
}

/// Groove templates
enum GrooveTemplate {
  fourOnFloor,
  neoSoulSwing,
  funkSyncopation,
  straight,
  shuffle,
  halfTime,
}

/// Spice levels
enum SpiceLevel { mild, medium, hot, fire }

/// Key names
enum KeyName { C, G, D, A, E, F, Bb, Am, Em, Dm, Bm, Fm }

/// Tab names
enum TabName { generator, editor, bass, settings }

/// Bass styles
enum BassStyle { root, walking, syncopated, octave, fifths }

/// Chord type definition
class ChordType {
  final List<int> intervals;
  final String symbol;
  final String name;

  const ChordType({
    required this.intervals,
    required this.symbol,
    required this.name,
  });
}

/// Voiced note
class VoicedNote {
  final String note;
  final int octave;
  final int pitch;

  const VoicedNote({
    required this.note,
    required this.octave,
    required this.pitch,
  });

  VoicedNote copyWith({String? note, int? octave, int? pitch}) {
    return VoicedNote(
      note: note ?? this.note,
      octave: octave ?? this.octave,
      pitch: pitch ?? this.pitch,
    );
  }
}

/// Chord
class Chord {
  final String root;
  final ChordTypeName type;
  final String degree;
  final String numeral;
  final List<VoicedNote>? voicedNotes;
  final bool isSecondaryDominant;
  final bool isBorrowed;
  final bool isTritoneSubstitution;
  final String? borrowedDescription;
  final HarmonyFunction? harmonyFunction;
  final double? grooveIntensity;
  final double? swingOffset;

  const Chord({
    required this.root,
    required this.type,
    required this.degree,
    required this.numeral,
    this.voicedNotes,
    this.isSecondaryDominant = false,
    this.isBorrowed = false,
    this.isTritoneSubstitution = false,
    this.borrowedDescription,
    this.harmonyFunction,
    this.grooveIntensity,
    this.swingOffset,
  });

  Chord copyWith({
    String? root,
    ChordTypeName? type,
    String? degree,
    String? numeral,
    List<VoicedNote>? voicedNotes,
    bool? isSecondaryDominant,
    bool? isBorrowed,
    bool? isTritoneSubstitution,
    String? borrowedDescription,
    HarmonyFunction? harmonyFunction,
    double? grooveIntensity,
    double? swingOffset,
  }) {
    return Chord(
      root: root ?? this.root,
      type: type ?? this.type,
      degree: degree ?? this.degree,
      numeral: numeral ?? this.numeral,
      voicedNotes: voicedNotes ?? this.voicedNotes,
      isSecondaryDominant: isSecondaryDominant ?? this.isSecondaryDominant,
      isBorrowed: isBorrowed ?? this.isBorrowed,
      isTritoneSubstitution:
          isTritoneSubstitution ?? this.isTritoneSubstitution,
      borrowedDescription: borrowedDescription ?? this.borrowedDescription,
      harmonyFunction: harmonyFunction ?? this.harmonyFunction,
      grooveIntensity: grooveIntensity ?? this.grooveIntensity,
      swingOffset: swingOffset ?? this.swingOffset,
    );
  }
}

/// Melody note
class MelodyNote {
  final String note;
  final double duration;
  final double velocity;
  final int chordIndex;
  final int octave;

  const MelodyNote({
    required this.note,
    required this.duration,
    required this.velocity,
    required this.chordIndex,
    required this.octave,
  });
}

/// Bass note
class BassNote {
  final String note;
  final double duration;
  final double velocity;
  final int octave;
  final int chordIndex;
  final BassStyle style;

  const BassNote({
    required this.note,
    required this.duration,
    required this.velocity,
    required this.octave,
    required this.chordIndex,
    required this.style,
  });
}

/// Genre profile
class GenreProfile {
  final String name;
  final ScaleName scale;
  final List<List<String>> progressions;
  final List<ChordTypeName> chordTypes;
  final ScaleName melodyScale;
  final int tempo;

  const GenreProfile({
    required this.name,
    required this.scale,
    required this.progressions,
    required this.chordTypes,
    required this.melodyScale,
    required this.tempo,
  });
}

/// Complexity setting
class ComplexitySetting {
  final List<int> chordCount;
  final bool useExtensions;
  final int variations;

  const ComplexitySetting({
    required this.chordCount,
    required this.useExtensions,
    required this.variations,
  });
}

/// Rhythm pattern
class RhythmPattern {
  final String name;
  final List<double> durations;
  final List<double> dynamics;
  final double melodyDensity;

  const RhythmPattern({
    required this.name,
    required this.durations,
    required this.dynamics,
    required this.melodyDensity,
  });
}

/// Smart preset
class SmartPreset {
  final String name;
  final String emoji;
  final String description;
  final GenreKey genre;
  final KeyName key;
  final ComplexityLevel complexity;
  final RhythmLevel rhythm;
  final double swing;
  final bool useVoiceLeading;
  final bool useAdvancedTheory;

  const SmartPreset({
    required this.name,
    required this.emoji,
    required this.description,
    required this.genre,
    required this.key,
    required this.complexity,
    required this.rhythm,
    required this.swing,
    required this.useVoiceLeading,
    required this.useAdvancedTheory,
  });
}

/// Mood profile
class MoodProfile {
  final String name;
  final List<ScaleName> scales;
  final List<HarmonyFunction> preferredFunctions;
  final List<ChordTypeName> chordTypes;
  final List<double> tensionRange;
  final String description;

  const MoodProfile({
    required this.name,
    required this.scales,
    required this.preferredFunctions,
    required this.chordTypes,
    required this.tensionRange,
    required this.description,
  });
}

/// Groove pattern
class GroovePattern {
  final String name;
  final GrooveTemplate template;
  final List<double> beatPattern;
  final double swingAmount;
  final List<int> accentBeats;

  const GroovePattern({
    required this.name,
    required this.template,
    required this.beatPattern,
    required this.swingAmount,
    required this.accentBeats,
  });
}

/// Spice config
class SpiceConfig {
  final SpiceLevel level;
  final bool allowExtensions;
  final bool allowAlterations;
  final int maxExtension;

  const SpiceConfig({
    required this.level,
    required this.allowExtensions,
    required this.allowAlterations,
    required this.maxExtension,
  });
}

/// History entry
class HistoryEntry {
  final List<Chord> progression;
  final KeyName key;
  final GenreKey genre;
  final int timestamp;

  const HistoryEntry({
    required this.progression,
    required this.key,
    required this.genre,
    required this.timestamp,
  });
}

/// Locked chord
class LockedChord {
  final int index;
  final bool locked;

  const LockedChord({
    required this.index,
    required this.locked,
  });

  LockedChord copyWith({int? index, bool? locked}) {
    return LockedChord(
      index: index ?? this.index,
      locked: locked ?? this.locked,
    );
  }
}

/// Envelope
class Envelope {
  final double attack;
  final double decay;
  final double sustain;
  final double release;

  const Envelope({
    required this.attack,
    required this.decay,
    required this.sustain,
    required this.release,
  });

  Envelope copyWith({
    double? attack,
    double? decay,
    double? sustain,
    double? release,
  }) {
    return Envelope(
      attack: attack ?? this.attack,
      decay: decay ?? this.decay,
      sustain: sustain ?? this.sustain,
      release: release ?? this.release,
    );
  }
}
