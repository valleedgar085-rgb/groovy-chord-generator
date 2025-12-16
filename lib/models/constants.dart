/// Groovy Chord Generator
/// Constants - Music Theory Data
/// Version 2.5
/// 
/// This file contains all the music theory constants used by the chord generator.
/// Genre profiles are derived from analysis of top songs in each genre to provide
/// authentic chord progressions, tempo ranges, and characteristic chord types.

import 'types.dart';

// ===================================
// Application Version
// ===================================

const String appVersion = '2.5';

// ===================================
// Music Theory Constants
// ===================================

/// The 12 chromatic notes using sharps for internal representation
const List<String> notes = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
];

/// The 12 chromatic notes using flats for display (more common in jazz/classical)
const List<String> noteDisplay = [
  'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'
];

/// Roman numerals for representing scale degrees in chord progressions
const List<String> romanNumerals = [
  'I', 'II', 'III', 'IV', 'V', 'VI', 'VII'
];

// ===================================
// Chord Types with Intervals
// ===================================
// Each chord type is defined by its intervals (in semitones from root),
// display symbol, and full name.

const Map<ChordTypeName, ChordType> chordTypes = {
  ChordTypeName.major: ChordType(intervals: [0, 4, 7], symbol: '', name: 'Major'),
  ChordTypeName.minor: ChordType(intervals: [0, 3, 7], symbol: 'm', name: 'Minor'),
  ChordTypeName.diminished: ChordType(intervals: [0, 3, 6], symbol: 'dim', name: 'Diminished'),
  ChordTypeName.augmented: ChordType(intervals: [0, 4, 8], symbol: 'aug', name: 'Augmented'),
  ChordTypeName.major7: ChordType(intervals: [0, 4, 7, 11], symbol: 'maj7', name: 'Major 7th'),
  ChordTypeName.minor7: ChordType(intervals: [0, 3, 7, 10], symbol: 'm7', name: 'Minor 7th'),
  ChordTypeName.dominant7: ChordType(intervals: [0, 4, 7, 10], symbol: '7', name: 'Dominant 7th'),
  ChordTypeName.diminished7: ChordType(intervals: [0, 3, 6, 9], symbol: 'dim7', name: 'Diminished 7th'),
  ChordTypeName.halfDim7: ChordType(intervals: [0, 3, 6, 10], symbol: 'm7♭5', name: 'Half-Dim 7th'),
  ChordTypeName.sus2: ChordType(intervals: [0, 2, 7], symbol: 'sus2', name: 'Suspended 2nd'),
  ChordTypeName.sus4: ChordType(intervals: [0, 5, 7], symbol: 'sus4', name: 'Suspended 4th'),
  ChordTypeName.add9: ChordType(intervals: [0, 4, 7, 14], symbol: 'add9', name: 'Add 9'),
  ChordTypeName.minor9: ChordType(intervals: [0, 3, 7, 10, 14], symbol: 'm9', name: 'Minor 9th'),
  ChordTypeName.major9: ChordType(intervals: [0, 4, 7, 11, 14], symbol: 'maj9', name: 'Major 9th'),
};

// ===================================
// Scale Patterns (intervals in semitones)
// ===================================
// Each scale is defined by its interval pattern from the root note.
// These patterns are used to build chords and generate melodies.

const Map<ScaleName, List<int>> scales = {
  ScaleName.major: [0, 2, 4, 5, 7, 9, 11],
  ScaleName.minor: [0, 2, 3, 5, 7, 8, 10],
  ScaleName.harmonicMinor: [0, 2, 3, 5, 7, 8, 11],
  ScaleName.melodicMinor: [0, 2, 3, 5, 7, 9, 11],
  ScaleName.dorian: [0, 2, 3, 5, 7, 9, 10],
  ScaleName.phrygian: [0, 1, 3, 5, 7, 8, 10],
  ScaleName.lydian: [0, 2, 4, 6, 7, 9, 11],
  ScaleName.mixolydian: [0, 2, 4, 5, 7, 9, 10],
  ScaleName.locrian: [0, 1, 3, 5, 6, 8, 10],
  ScaleName.pentatonicMajor: [0, 2, 4, 7, 9],
  ScaleName.pentatonicMinor: [0, 3, 5, 7, 10],
  ScaleName.blues: [0, 3, 5, 6, 7, 10],
};

// ===================================
// Genre Profiles
// ===================================
// Each genre profile is derived from analysis of top songs in that genre.
// The tempo ranges and chord progressions reflect common patterns found
// in popular music across these genres.

// Genre profiles
const Map<GenreKey, GenreProfile> genreProfiles = {
  // Happy Upbeat Pop: 100-130 BPM
  // Uses iconic progressions from hit songs: I–V–vi–IV (Axis of Awesome), I–vi–IV–V
  GenreKey.happyPop: GenreProfile(
    name: 'Happy Upbeat Pop',
    scale: ScaleName.major,
    progressions: [
      ['I', 'V', 'vi', 'IV'],   // The iconic "Axis of Awesome" progression
      ['I', 'vi', 'IV', 'V'],   // Classic 50s progression modernized
      ['I', 'IV', 'V', 'I'],
      ['I', 'IV', 'vi', 'V'],
    ],
    chordTypes: [ChordTypeName.major, ChordTypeName.minor, ChordTypeName.sus2, ChordTypeName.add9, ChordTypeName.major7],
    melodyScale: ScaleName.pentatonicMajor,
    tempo: 115, // Center of 100-130 BPM range
  ),
  
  // Chill Lo-Fi: 60-90 BPM
  // Focus on maj7/min7 chords with jazz-influenced ii-V-I progressions
  GenreKey.chillLofi: GenreProfile(
    name: 'Chill Lo-Fi',
    scale: ScaleName.minor,
    progressions: [
      ['ii', 'V', 'I'],         // Classic jazz ii-V-I
      ['I', 'vi', 'ii', 'V'],   // Turnaround progression
      ['ii', 'V', 'I', 'vi'],   // Extended turnaround
      ['vi', 'ii', 'V', 'I'],
    ],
    chordTypes: [ChordTypeName.major7, ChordTypeName.minor7, ChordTypeName.dominant7, ChordTypeName.minor9, ChordTypeName.add9],
    melodyScale: ScaleName.pentatonicMinor,
    tempo: 75, // Center of 60-90 BPM range
  ),
  
  // Energetic EDM: 120-130 BPM
  // Uses the anthemic vi-IV-I-V progression common in festival bangers
  GenreKey.energeticEdm: GenreProfile(
    name: 'Energetic EDM',
    scale: ScaleName.major,
    progressions: [
      ['vi', 'IV', 'I', 'V'],   // The anthemic EDM progression
      ['I', 'V', 'vi', 'IV'],
      ['I', 'IV', 'I', 'V'],
    ],
    chordTypes: [ChordTypeName.major, ChordTypeName.minor, ChordTypeName.sus4, ChordTypeName.sus2],
    melodyScale: ScaleName.major,
    tempo: 125, // Center of 120-130 BPM range
  ),
  
  // Soulful R&B: 70-100 BPM
  // Rich harmonies featuring 7th and 9th chords for smooth, warm sound
  GenreKey.soulfulRnb: GenreProfile(
    name: 'Soulful R&B',
    scale: ScaleName.minor,
    progressions: [
      ['i', 'VII', 'VI', 'V'],
      ['i', 'iv', 'VII', 'III'],
      ['VI', 'VII', 'i', 'i'],
    ],
    chordTypes: [ChordTypeName.minor7, ChordTypeName.major7, ChordTypeName.dominant7, ChordTypeName.minor9, ChordTypeName.major9],
    melodyScale: ScaleName.pentatonicMinor,
    tempo: 85, // Center of 70-100 BPM range
  ),
  
  // Jazz Fusion: 120-180 BPM
  // Complex ii-V-I variations with advanced voice leading
  GenreKey.jazzFusion: GenreProfile(
    name: 'Jazz Fusion',
    scale: ScaleName.dorian,
    progressions: [
      ['ii', 'V', 'I', 'vi'],   // Classic ii-V-I with vi extension
      ['I', 'vi', 'ii', 'V'],   // Rhythm changes style
      ['iii', 'vi', 'ii', 'V'], // Complex approach
    ],
    chordTypes: [ChordTypeName.major7, ChordTypeName.minor7, ChordTypeName.dominant7, ChordTypeName.halfDim7, ChordTypeName.diminished7],
    melodyScale: ScaleName.dorian,
    tempo: 150, // Center of 120-180 BPM range
  ),
  
  // Dark Deep Trap: 140 BPM (half-time feel)
  // Minor and diminished chords create dark, ominous atmosphere
  GenreKey.darkTrap: GenreProfile(
    name: 'Dark Deep Trap',
    scale: ScaleName.harmonicMinor,
    progressions: [
      ['i', 'VI', 'III', 'VII'],
      ['i', 'iv', 'VI', 'V'],
      ['i', 'VII', 'VI', 'VII'],
    ],
    chordTypes: [ChordTypeName.minor, ChordTypeName.diminished, ChordTypeName.minor7, ChordTypeName.halfDim7, ChordTypeName.augmented],
    melodyScale: ScaleName.harmonicMinor,
    tempo: 140, // Standard trap tempo with half-time feel
  ),
  
  // Cinematic Epic: Variable tempo
  // Minor keys with i-VI progressions for dramatic, emotional impact
  GenreKey.cinematic: GenreProfile(
    name: 'Cinematic Epic',
    scale: ScaleName.minor,
    progressions: [
      ['i', 'VI', 'III', 'VII'], // Dramatic minor progression
      ['i', 'iv', 'V', 'i'],
      ['VI', 'VII', 'i', 'V'],
    ],
    chordTypes: [ChordTypeName.minor, ChordTypeName.major, ChordTypeName.sus4, ChordTypeName.augmented, ChordTypeName.minor7],
    melodyScale: ScaleName.minor,
    tempo: 100, // Variable in practice, 100 as base
  ),
  
  // Indie Rock: 80-120 BPM
  // Mix of classic I-IV-V and modern vi-IV-I-V progressions
  GenreKey.indieRock: GenreProfile(
    name: 'Indie Rock',
    scale: ScaleName.major,
    progressions: [
      ['I', 'IV', 'V', 'I'],         // Classic rock progression
      ['vi', 'IV', 'I', 'V'],        // Modern indie sound
      ['I', 'V', 'vi', 'iii', 'IV'], // Extended progression for variety
      ['I', 'iii', 'IV', 'V'],
      ['I', 'IV', 'ii', 'V'],
    ],
    chordTypes: [ChordTypeName.major, ChordTypeName.minor, ChordTypeName.sus2, ChordTypeName.add9, ChordTypeName.major7],
    melodyScale: ScaleName.major,
    tempo: 100, // Center of 80-120 BPM range
  ),
  
  // Reggae: 80 BPM
  // Laid-back offbeat feel with classic Jamaican patterns
  GenreKey.reggae: GenreProfile(
    name: 'Reggae',
    scale: ScaleName.major,
    progressions: [
      ['I', 'IV', 'I', 'V'],
      ['I', 'V', 'vi', 'IV'],
      ['I', 'IV', 'V', 'IV'],
    ],
    chordTypes: [ChordTypeName.major, ChordTypeName.minor, ChordTypeName.dominant7, ChordTypeName.minor7, ChordTypeName.sus2],
    melodyScale: ScaleName.pentatonicMajor,
    tempo: 80,
  ),
  
  // Blues: 90 BPM
  // Traditional 12-bar structure with dominant 7th chords
  GenreKey.blues: GenreProfile(
    name: 'Blues',
    scale: ScaleName.mixolydian,
    progressions: [
      ['I', 'I', 'I', 'I', 'IV', 'IV', 'I', 'I', 'V', 'IV', 'I', 'V'], // 12-bar blues
      ['I', 'IV', 'I', 'V'],
      ['i', 'iv', 'i', 'V'],
    ],
    chordTypes: [ChordTypeName.dominant7, ChordTypeName.minor7, ChordTypeName.major, ChordTypeName.minor, ChordTypeName.diminished],
    melodyScale: ScaleName.blues,
    tempo: 90,
  ),
  
  // Country: 110 BPM
  // Nashville-style progressions with major key optimism
  GenreKey.country: GenreProfile(
    name: 'Country',
    scale: ScaleName.major,
    progressions: [
      ['I', 'IV', 'V', 'I'],
      ['I', 'V', 'vi', 'IV'],
      ['I', 'IV', 'I', 'V'],
    ],
    chordTypes: [ChordTypeName.major, ChordTypeName.minor, ChordTypeName.sus4, ChordTypeName.add9, ChordTypeName.dominant7],
    melodyScale: ScaleName.pentatonicMajor,
    tempo: 110,
  ),
  
  // Funk: 105 BPM
  // Syncopated grooves with dominant 7th and 9th chords
  GenreKey.funk: GenreProfile(
    name: 'Funk',
    scale: ScaleName.mixolydian,
    progressions: [
      ['I', 'IV', 'I', 'IV'],
      ['i', 'IV', 'i', 'IV'],
      ['I', 'I', 'IV', 'I'],
    ],
    chordTypes: [ChordTypeName.dominant7, ChordTypeName.minor7, ChordTypeName.major, ChordTypeName.minor9, ChordTypeName.sus4],
    melodyScale: ScaleName.pentatonicMinor,
    tempo: 105,
  ),
};

// ===================================
// Complexity Settings
// ===================================
// Controls the number of chords, use of extensions, and variation count
// based on the selected complexity level.

const Map<ComplexityLevel, ComplexitySetting> complexitySettings = {
  ComplexityLevel.simple: ComplexitySetting(chordCount: [3, 4], useExtensions: false, variations: 1),
  ComplexityLevel.medium: ComplexitySetting(chordCount: [4, 5], useExtensions: true, variations: 2),
  ComplexityLevel.complex: ComplexitySetting(chordCount: [6, 8], useExtensions: true, variations: 3),
  ComplexityLevel.advanced: ComplexitySetting(chordCount: [8, 12], useExtensions: true, variations: 4),
};

// ===================================
// Rhythm Patterns
// ===================================
// Defines rhythmic characteristics including note durations, dynamics,
// and melody density for different feel settings.

const Map<RhythmLevel, RhythmPattern> rhythmPatterns = {
  RhythmLevel.soft: RhythmPattern(
    name: 'Soft & Gentle',
    durations: [4, 2, 2],
    dynamics: [0.5, 0.4, 0.6],
    melodyDensity: 0.3,
  ),
  RhythmLevel.moderate: RhythmPattern(
    name: 'Moderate',
    durations: [2, 2, 1, 1],
    dynamics: [0.7, 0.5, 0.8, 0.6],
    melodyDensity: 0.5,
  ),
  RhythmLevel.strong: RhythmPattern(
    name: 'Strong & Punchy',
    durations: [1, 1, 1, 1],
    dynamics: [0.9, 0.7, 0.85, 0.75],
    melodyDensity: 0.7,
  ),
  RhythmLevel.intense: RhythmPattern(
    name: 'Intense & Driving',
    durations: [0.8, 0.8, 0.8, 0.8, 0.8], // quintuplet subdivision (5 notes over 4 beats)
    dynamics: [1, 0.8, 0.95, 0.85, 0.9],
    melodyDensity: 0.9,
  ),
};

// Smart Presets
const Map<String, SmartPreset> smartPresets = {
  'lofi-chill-sunday': SmartPreset(
    name: 'Lo-Fi Chill Sunday',
    emoji: '☕',
    description: 'Relaxed jazzy vibes for lazy mornings',
    genre: GenreKey.chillLofi,
    key: KeyName.Dm,
    complexity: ComplexityLevel.medium,
    rhythm: RhythmLevel.soft,
    swing: 0.3,
    useVoiceLeading: true,
    useAdvancedTheory: true,
  ),
  'cyberpunk-drive': SmartPreset(
    name: 'Cyberpunk Drive',
    emoji: '🌃',
    description: 'Dark synth energy for night drives',
    genre: GenreKey.darkTrap,
    key: KeyName.Em,
    complexity: ComplexityLevel.complex,
    rhythm: RhythmLevel.strong,
    swing: 0.1,
    useVoiceLeading: false,
    useAdvancedTheory: true,
  ),
  'summer-pop': SmartPreset(
    name: 'Summer Pop Hit',
    emoji: '☀️',
    description: 'Catchy and uplifting radio-ready vibes',
    genre: GenreKey.happyPop,
    key: KeyName.G,
    complexity: ComplexityLevel.simple,
    rhythm: RhythmLevel.moderate,
    swing: 0,
    useVoiceLeading: false,
    useAdvancedTheory: false,
  ),
  'midnight-jazz': SmartPreset(
    name: 'Midnight Jazz',
    emoji: '🎷',
    description: 'Sophisticated harmonies for late nights',
    genre: GenreKey.jazzFusion,
    key: KeyName.Fm,
    complexity: ComplexityLevel.advanced,
    rhythm: RhythmLevel.moderate,
    swing: 0.4,
    useVoiceLeading: true,
    useAdvancedTheory: true,
  ),
  'epic-cinema': SmartPreset(
    name: 'Epic Cinema',
    emoji: '🎬',
    description: 'Dramatic orchestral grandeur',
    genre: GenreKey.cinematic,
    key: KeyName.Am,
    complexity: ComplexityLevel.complex,
    rhythm: RhythmLevel.intense,
    swing: 0,
    useVoiceLeading: true,
    useAdvancedTheory: true,
  ),
  'soul-groove': SmartPreset(
    name: 'Soul Groove',
    emoji: '🎤',
    description: 'Smooth R&B with rich harmonies',
    genre: GenreKey.soulfulRnb,
    key: KeyName.Bm,
    complexity: ComplexityLevel.medium,
    rhythm: RhythmLevel.moderate,
    swing: 0.25,
    useVoiceLeading: true,
    useAdvancedTheory: true,
  ),
  'festival-drop': SmartPreset(
    name: 'Festival Drop',
    emoji: '🔥',
    description: 'High-energy EDM for the main stage',
    genre: GenreKey.energeticEdm,
    key: KeyName.C,
    complexity: ComplexityLevel.simple,
    rhythm: RhythmLevel.intense,
    swing: 0,
    useVoiceLeading: false,
    useAdvancedTheory: false,
  ),
  'indie-sunset': SmartPreset(
    name: 'Indie Sunset',
    emoji: '🌅',
    description: 'Dreamy guitar-driven atmosphere',
    genre: GenreKey.indieRock,
    key: KeyName.D,
    complexity: ComplexityLevel.medium,
    rhythm: RhythmLevel.soft,
    swing: 0.15,
    useVoiceLeading: true,
    useAdvancedTheory: false,
  ),
};

// Mood profiles
const Map<MoodType, MoodProfile> moodProfiles = {
  MoodType.happy: MoodProfile(
    name: 'Happy',
    scales: [ScaleName.major, ScaleName.lydian, ScaleName.pentatonicMajor],
    preferredFunctions: [HarmonyFunction.tonic, HarmonyFunction.subdominant],
    chordTypes: [ChordTypeName.major, ChordTypeName.major7, ChordTypeName.add9, ChordTypeName.sus2],
    tensionRange: [0, 0.5],
    description: 'Bright, uplifting progressions',
  ),
  MoodType.sad: MoodProfile(
    name: 'Sad',
    scales: [ScaleName.minor, ScaleName.dorian, ScaleName.phrygian],
    preferredFunctions: [HarmonyFunction.tonic, HarmonyFunction.subdominant],
    chordTypes: [ChordTypeName.minor, ChordTypeName.minor7, ChordTypeName.minor9, ChordTypeName.sus4],
    tensionRange: [0.2, 0.6],
    description: 'Melancholic, introspective progressions',
  ),
  MoodType.dreamy: MoodProfile(
    name: 'Dreamy',
    scales: [ScaleName.lydian, ScaleName.dorian, ScaleName.pentatonicMajor],
    preferredFunctions: [HarmonyFunction.tonic, HarmonyFunction.passing],
    chordTypes: [ChordTypeName.major7, ChordTypeName.minor7, ChordTypeName.add9, ChordTypeName.sus2],
    tensionRange: [0.1, 0.4],
    description: 'Ethereal, floating progressions',
  ),
  MoodType.energetic: MoodProfile(
    name: 'Energetic',
    scales: [ScaleName.major, ScaleName.mixolydian],
    preferredFunctions: [HarmonyFunction.dominant, HarmonyFunction.subdominant],
    chordTypes: [ChordTypeName.major, ChordTypeName.dominant7, ChordTypeName.sus4],
    tensionRange: [0.5, 0.9],
    description: 'Driving, powerful progressions',
  ),
  MoodType.dark: MoodProfile(
    name: 'Dark',
    scales: [ScaleName.harmonicMinor, ScaleName.phrygian, ScaleName.locrian],
    preferredFunctions: [HarmonyFunction.dominant, HarmonyFunction.passing],
    chordTypes: [ChordTypeName.minor, ChordTypeName.diminished, ChordTypeName.halfDim7, ChordTypeName.augmented],
    tensionRange: [0.6, 1.0],
    description: 'Tense, ominous progressions',
  ),
  MoodType.mysterious: MoodProfile(
    name: 'Mysterious',
    scales: [ScaleName.dorian, ScaleName.phrygian, ScaleName.harmonicMinor],
    preferredFunctions: [HarmonyFunction.passing, HarmonyFunction.subdominant],
    chordTypes: [ChordTypeName.minor7, ChordTypeName.halfDim7, ChordTypeName.sus4, ChordTypeName.diminished7],
    tensionRange: [0.4, 0.8],
    description: 'Enigmatic, suspenseful progressions',
  ),
  MoodType.triumphant: MoodProfile(
    name: 'Triumphant',
    scales: [ScaleName.major, ScaleName.lydian],
    preferredFunctions: [HarmonyFunction.dominant, HarmonyFunction.tonic],
    chordTypes: [ChordTypeName.major, ChordTypeName.major7, ChordTypeName.sus4, ChordTypeName.add9],
    tensionRange: [0.3, 0.8],
    description: 'Victorious, heroic progressions',
  ),
  MoodType.relaxed: MoodProfile(
    name: 'Relaxed',
    scales: [ScaleName.major, ScaleName.dorian, ScaleName.pentatonicMajor],
    preferredFunctions: [HarmonyFunction.tonic, HarmonyFunction.subdominant],
    chordTypes: [ChordTypeName.major7, ChordTypeName.minor7, ChordTypeName.add9, ChordTypeName.sus2],
    tensionRange: [0, 0.3],
    description: 'Calm, soothing progressions',
  ),
};

// Groove patterns
const Map<GrooveTemplate, GroovePattern> groovePatterns = {
  GrooveTemplate.fourOnFloor: GroovePattern(
    name: 'Four on the Floor',
    template: GrooveTemplate.fourOnFloor,
    beatPattern: [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],
    swingAmount: 0,
    accentBeats: [0, 4, 8, 12],
  ),
  GrooveTemplate.neoSoulSwing: GroovePattern(
    name: 'Neo-Soul Swing',
    template: GrooveTemplate.neoSoulSwing,
    beatPattern: [1, 0, 0.5, 0, 1, 0, 0.7, 0.3, 1, 0, 0.5, 0, 1, 0, 0.7, 0],
    swingAmount: 0.3,
    accentBeats: [0, 6, 8, 14],
  ),
  GrooveTemplate.funkSyncopation: GroovePattern(
    name: 'Funk Syncopation',
    template: GrooveTemplate.funkSyncopation,
    beatPattern: [1, 0.3, 0, 0.8, 0, 0.5, 0.9, 0, 1, 0.3, 0, 0.8, 0, 0.5, 0.9, 0],
    swingAmount: 0.15,
    accentBeats: [0, 3, 6, 8, 11, 14],
  ),
  GrooveTemplate.straight: GroovePattern(
    name: 'Straight',
    template: GrooveTemplate.straight,
    beatPattern: [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],
    swingAmount: 0,
    accentBeats: [0, 4, 8, 12],
  ),
  GrooveTemplate.shuffle: GroovePattern(
    name: 'Shuffle',
    template: GrooveTemplate.shuffle,
    beatPattern: [1, 0, 0.6, 0, 1, 0, 0.6, 0, 1, 0, 0.6, 0, 1, 0, 0.6, 0],
    swingAmount: 0.4,
    accentBeats: [0, 2, 4, 6, 8, 10, 12, 14],
  ),
  GrooveTemplate.halfTime: GroovePattern(
    name: 'Half-Time',
    template: GrooveTemplate.halfTime,
    beatPattern: [1, 0, 0, 0, 0, 0, 0, 0, 0.8, 0, 0, 0, 0, 0, 0, 0],
    swingAmount: 0,
    accentBeats: [0, 8],
  ),
};

// Spice configs
const Map<SpiceLevel, SpiceConfig> spiceConfigs = {
  SpiceLevel.mild: SpiceConfig(level: SpiceLevel.mild, allowExtensions: false, allowAlterations: false, maxExtension: 7),
  SpiceLevel.medium: SpiceConfig(level: SpiceLevel.medium, allowExtensions: true, allowAlterations: false, maxExtension: 9),
  SpiceLevel.hot: SpiceConfig(level: SpiceLevel.hot, allowExtensions: true, allowAlterations: true, maxExtension: 11),
  SpiceLevel.fire: SpiceConfig(level: SpiceLevel.fire, allowExtensions: true, allowAlterations: true, maxExtension: 13),
};

// Default state values
const double defaultMasterVolume = 0.8;
const SoundType defaultSoundType = SoundType.sine;
const int defaultTempo = 120;
const GenreKey defaultGenre = GenreKey.happyPop;
const ComplexityLevel defaultComplexity = ComplexityLevel.medium;
const RhythmLevel defaultRhythm = RhythmLevel.moderate;
const String defaultKey = 'C';
const bool defaultShowNumerals = true;
const bool defaultShowTips = true;
const double defaultSwing = 0;
const bool defaultUseVoiceLeading = false;
const bool defaultUseAdvancedTheory = false;
const bool defaultUseModalInterchange = false;
const bool defaultIncludeMelody = true;
const bool defaultIncludeBass = true;
const BassStyle defaultBassStyle = BassStyle.root;
const int defaultBassVariety = 50;
const int defaultChordVariety = 50;
const int defaultRhythmVariety = 50;
const MoodType defaultMood = MoodType.happy;
const bool defaultUseFunctionalHarmony = false;
const GrooveTemplate defaultGrooveTemplate = GrooveTemplate.straight;
const SpiceLevel defaultSpiceLevel = SpiceLevel.medium;
const int maxHistoryLength = 5;

// Default envelope
const Envelope defaultEnvelope = Envelope(
  attack: 0.05,
  decay: 0.1,
  sustain: 0.6,
  release: 0.5,
);

// UI Options for dropdowns
const List<Map<String, dynamic>> genreOptions = [
  {'value': GenreKey.happyPop, 'label': 'Happy Pop'},
  {'value': GenreKey.chillLofi, 'label': 'Chill Lo-Fi'},
  {'value': GenreKey.energeticEdm, 'label': 'EDM'},
  {'value': GenreKey.soulfulRnb, 'label': 'R&B'},
  {'value': GenreKey.jazzFusion, 'label': 'Jazz'},
  {'value': GenreKey.darkTrap, 'label': 'Trap'},
  {'value': GenreKey.cinematic, 'label': 'Cinematic'},
  {'value': GenreKey.indieRock, 'label': 'Indie Rock'},
  {'value': GenreKey.reggae, 'label': 'Reggae'},
  {'value': GenreKey.blues, 'label': 'Blues'},
  {'value': GenreKey.country, 'label': 'Country'},
  {'value': GenreKey.funk, 'label': 'Funk'},
];

const List<Map<String, dynamic>> keyOptions = [
  {'value': KeyName.C, 'label': 'C Major'},
  {'value': KeyName.G, 'label': 'G Major'},
  {'value': KeyName.D, 'label': 'D Major'},
  {'value': KeyName.A, 'label': 'A Major'},
  {'value': KeyName.E, 'label': 'E Major'},
  {'value': KeyName.F, 'label': 'F Major'},
  {'value': KeyName.Bb, 'label': 'Bb Major'},
  {'value': KeyName.Am, 'label': 'A Minor'},
  {'value': KeyName.Em, 'label': 'E Minor'},
  {'value': KeyName.Dm, 'label': 'D Minor'},
  {'value': KeyName.Bm, 'label': 'B Minor'},
  {'value': KeyName.Fm, 'label': 'F Minor'},
];

const List<Map<String, dynamic>> complexityOptions = [
  {'value': ComplexityLevel.simple, 'label': 'Simple'},
  {'value': ComplexityLevel.medium, 'label': 'Medium'},
  {'value': ComplexityLevel.complex, 'label': 'Complex'},
  {'value': ComplexityLevel.advanced, 'label': 'Advanced'},
];

const List<Map<String, dynamic>> rhythmOptions = [
  {'value': RhythmLevel.soft, 'label': 'Soft'},
  {'value': RhythmLevel.moderate, 'label': 'Moderate'},
  {'value': RhythmLevel.strong, 'label': 'Strong'},
  {'value': RhythmLevel.intense, 'label': 'Intense'},
];

const List<Map<String, dynamic>> soundTypeOptions = [
  {'value': SoundType.sine, 'label': 'Sine (Smooth)'},
  {'value': SoundType.triangle, 'label': 'Triangle (Mellow)'},
  {'value': SoundType.square, 'label': 'Square (Retro)'},
  {'value': SoundType.sawtooth, 'label': 'Sawtooth (Bright)'},
];

const List<Map<String, dynamic>> bassStyleOptions = [
  {'value': BassStyle.root, 'label': 'Root Notes'},
  {'value': BassStyle.walking, 'label': 'Walking Bass'},
  {'value': BassStyle.syncopated, 'label': 'Syncopated'},
  {'value': BassStyle.octave, 'label': 'Octave Jumps'},
  {'value': BassStyle.fifths, 'label': 'Root & Fifth'},
];

const List<Map<String, dynamic>> moodOptions = [
  {'value': MoodType.happy, 'label': '😊 Happy'},
  {'value': MoodType.sad, 'label': '😢 Sad'},
  {'value': MoodType.dreamy, 'label': '✨ Dreamy'},
  {'value': MoodType.energetic, 'label': '⚡ Energetic'},
  {'value': MoodType.dark, 'label': '🌑 Dark'},
  {'value': MoodType.mysterious, 'label': '🔮 Mysterious'},
  {'value': MoodType.triumphant, 'label': '🏆 Triumphant'},
  {'value': MoodType.relaxed, 'label': '😌 Relaxed'},
];

const List<Map<String, dynamic>> grooveTemplateOptions = [
  {'value': GrooveTemplate.straight, 'label': 'Straight'},
  {'value': GrooveTemplate.fourOnFloor, 'label': 'Four on the Floor'},
  {'value': GrooveTemplate.neoSoulSwing, 'label': 'Neo-Soul Swing'},
  {'value': GrooveTemplate.funkSyncopation, 'label': 'Funk Syncopation'},
  {'value': GrooveTemplate.shuffle, 'label': 'Shuffle'},
  {'value': GrooveTemplate.halfTime, 'label': 'Half-Time'},
];

const List<Map<String, dynamic>> spiceLevelOptions = [
  {'value': SpiceLevel.mild, 'label': '🌶️ Mild (Triads)'},
  {'value': SpiceLevel.medium, 'label': '🌶️🌶️ Medium (7ths)'},
  {'value': SpiceLevel.hot, 'label': '🌶️🌶️🌶️ Hot (Extensions)'},
  {'value': SpiceLevel.fire, 'label': '🔥 Fire (Altered)'},
];
