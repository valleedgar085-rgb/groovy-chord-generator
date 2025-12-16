/**
 * Groovy Chord Generator
 * Constants - Music Theory Data
 * Version 2.5
 */

// ===================================
// Application Version
// ===================================

export const APP_VERSION = '2.5';

import type {
  NoteName,
  NoteDisplayName,
  ChordTypeName,
  ScaleName,
  GenreKey,
  ComplexityLevel,
  RhythmLevel,
  SoundType,
  ChordType,
  GenreProfile,
  ComplexitySetting,
  RhythmPattern,
  SmartPreset,
  ModalInterchangeChord,
  ShellVoicing,
  OpenVoicing,
  FunctionalChord,
  MoodProfile,
  MoodType,
  GroovePattern,
  GrooveTemplate,
  SpiceLevel,
  SpiceConfig,
  HarmonyFunction,
} from '../types';

// ===================================
// Music Theory Constants
// ===================================

export const NOTES: NoteName[] = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
export const NOTE_DISPLAY: NoteDisplayName[] = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];

// Roman numerals for chord degrees
export const ROMAN_NUMERALS = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];

/**
 * Maps scale degree symbols to semitone intervals from the root note.
 * Used for calculating the actual pitch of a chord root via chromatic transposition.
 * 
 * Theory:
 * - Intervals represent chromatic distance (12 semitones = octave)
 * - Major scale pattern: W-W-H-W-W-W-H (2-2-1-2-2-2-1 semitones)
 * 
 * Examples:
 * - 'I' (tonic) = 0 semitones → same as root
 * - 'V' (dominant) = 7 semitones → perfect fifth
 * - 'IV' (subdominant) = 5 semitones → perfect fourth
 * - 'bII' (Neapolitan) = 1 semitone → minor second
 * - 'bVII' (subtonic) = 10 semitones → minor seventh
 */
export const DEGREE_TO_SEMITONES: Record<string, number> = {
  'I': 0, 'i': 0,       // Tonic
  'II': 2, 'ii': 2,     // Supertonic
  'III': 4, 'iii': 4,   // Mediant
  'IV': 5, 'iv': 5,     // Subdominant
  'V': 7, 'v': 7,       // Dominant
  'VI': 9, 'vi': 9,     // Submediant
  'VII': 11, 'vii': 11, // Leading tone
  // Altered degrees (modal interchange, chromatic harmony)
  'bII': 1,   // Neapolitan sixth
  'bIII': 3,  // Minor mediant (borrowed from parallel minor)
  '#iv': 6,   // Lydian augmented fourth
  'bVI': 8,   // Minor submediant (borrowed from parallel minor)
  'bVII': 10, // Subtonic (borrowed from parallel minor/mixolydian)
} as const;

/**
 * Maps scale degree symbols to diatonic scale indices (0-6).
 * Used for looking up position in arrays like ROMAN_NUMERALS or scale-based chord qualities.
 * 
 * Theory:
 * - Indices represent position within a 7-note diatonic scale
 * - Altered degrees map to their nearest diatonic equivalent
 * 
 * Examples:
 * - 'I' (first degree) = 0 → ROMAN_NUMERALS[0] = 'I'
 * - 'V' (fifth degree) = 4 → ROMAN_NUMERALS[4] = 'V'
 * - 'II' (second degree) = 1 → ROMAN_NUMERALS[1] = 'II'
 * - 'bII' → 1 (resolves to II for display)
 * - 'bVII' → 6 (resolves to VII for display)
 */
export const DEGREE_TO_SCALE_INDEX: Record<string, number> = {
  'I': 0, 'i': 0,
  'II': 1, 'ii': 1,
  'III': 2, 'iii': 2,
  'IV': 3, 'iv': 3,
  'V': 4, 'v': 4,
  'VI': 5, 'vi': 5,
  'VII': 6, 'vii': 6,
  // Altered degrees map to nearest diatonic position
  'bII': 1,
  'bIII': 2,
  '#iv': 3,
  'bVI': 5,
  'bVII': 6,
} as const;

// Chord types with intervals (semitones from root)
export const CHORD_TYPES: Record<ChordTypeName, ChordType> = {
  major: { intervals: [0, 4, 7], symbol: '', name: 'Major' },
  minor: { intervals: [0, 3, 7], symbol: 'm', name: 'Minor' },
  diminished: { intervals: [0, 3, 6], symbol: 'dim', name: 'Diminished' },
  augmented: { intervals: [0, 4, 8], symbol: 'aug', name: 'Augmented' },
  major7: { intervals: [0, 4, 7, 11], symbol: 'maj7', name: 'Major 7th' },
  minor7: { intervals: [0, 3, 7, 10], symbol: 'm7', name: 'Minor 7th' },
  dominant7: { intervals: [0, 4, 7, 10], symbol: '7', name: 'Dominant 7th' },
  diminished7: { intervals: [0, 3, 6, 9], symbol: 'dim7', name: 'Diminished 7th' },
  halfDim7: { intervals: [0, 3, 6, 10], symbol: 'm7♭5', name: 'Half-Dim 7th' },
  sus2: { intervals: [0, 2, 7], symbol: 'sus2', name: 'Suspended 2nd' },
  sus4: { intervals: [0, 5, 7], symbol: 'sus4', name: 'Suspended 4th' },
  add9: { intervals: [0, 4, 7, 14], symbol: 'add9', name: 'Add 9' },
  minor9: { intervals: [0, 3, 7, 10, 14], symbol: 'm9', name: 'Minor 9th' },
  major9: { intervals: [0, 4, 7, 11, 14], symbol: 'maj9', name: 'Major 9th' },
};

// Scale patterns (intervals in semitones)
export const SCALES: Record<ScaleName, number[]> = {
  major: [0, 2, 4, 5, 7, 9, 11],
  minor: [0, 2, 3, 5, 7, 8, 10],
  harmonicMinor: [0, 2, 3, 5, 7, 8, 11],
  melodicMinor: [0, 2, 3, 5, 7, 9, 11],
  dorian: [0, 2, 3, 5, 7, 9, 10],
  phrygian: [0, 1, 3, 5, 7, 8, 10],
  lydian: [0, 2, 4, 6, 7, 9, 11],
  mixolydian: [0, 2, 4, 5, 7, 9, 10],
  locrian: [0, 1, 3, 5, 6, 8, 10],
  pentatonicMajor: [0, 2, 4, 7, 9],
  pentatonicMinor: [0, 3, 5, 7, 10],
  blues: [0, 3, 5, 6, 7, 10],
};

// Genre-specific progressions and characteristics
export const GENRE_PROFILES: Record<GenreKey, GenreProfile> = {
  'happy-pop': {
    name: 'Happy Upbeat Pop',
    scale: 'major',
    progressions: [
      ['I', 'V', 'vi', 'IV'],
      ['I', 'IV', 'V', 'I'],
      ['I', 'vi', 'IV', 'V'],
      ['I', 'IV', 'vi', 'V'],
      ['vi', 'IV', 'I', 'V'],
      ['I', 'V', 'IV', 'IV'],
      ['I', 'ii', 'IV', 'V'],
      ['IV', 'V', 'vi', 'I'],
    ],
    chordTypes: ['major', 'minor', 'sus2', 'add9', 'major7'],
    melodyScale: 'pentatonicMajor',
    tempo: 120,
  },
  'chill-lofi': {
    name: 'Chill Lo-Fi',
    scale: 'minor',
    progressions: [
      ['ii', 'V', 'I', 'vi'],
      ['I', 'vi', 'ii', 'V'],
      ['vi', 'ii', 'V', 'I'],
      ['I', 'IV', 'vi', 'V'],
      ['I', 'vi', 'IV', 'ii'],
      ['ii', 'iii', 'vi', 'IV'],
      ['I', 'iii', 'vi', 'IV'],
    ],
    chordTypes: ['major7', 'minor7', 'dominant7', 'minor9', 'add9'],
    melodyScale: 'pentatonicMinor',
    tempo: 85,
  },
  'energetic-edm': {
    name: 'Energetic EDM',
    scale: 'major',
    progressions: [
      ['I', 'V', 'vi', 'IV'],
      ['vi', 'IV', 'I', 'V'],
      ['I', 'IV', 'I', 'V'],
      ['vi', 'IV', 'V', 'I'],
      ['I', 'I', 'V', 'V', 'vi', 'vi', 'IV', 'IV'],
      ['vi', 'vi', 'IV', 'V'],
    ],
    chordTypes: ['major', 'minor', 'sus4', 'sus2'],
    melodyScale: 'major',
    tempo: 128,
  },
  'soulful-rnb': {
    name: 'Soulful R&B',
    scale: 'minor',
    progressions: [
      ['i', 'VII', 'VI', 'V'],
      ['i', 'iv', 'VII', 'III'],
      ['VI', 'VII', 'i', 'i'],
      ['i', 'VI', 'III', 'VII'],
      ['ii', 'V', 'I', 'vi'],
      ['i', 'IV', 'III', 'VII'],
      ['VI', 'VII', 'i', 'iv'],
    ],
    chordTypes: ['minor7', 'major7', 'dominant7', 'minor9', 'major9', 'add9'],
    melodyScale: 'pentatonicMinor',
    tempo: 90,
  },
  'jazz-fusion': {
    name: 'Jazz Fusion',
    scale: 'dorian',
    progressions: [
      ['ii', 'V', 'I', 'vi'],
      ['I', 'vi', 'ii', 'V'],
      ['iii', 'vi', 'ii', 'V'],
      ['I', 'IV', 'iii', 'vi', 'ii', 'V', 'I'],
      ['ii', 'V', 'I', 'I'],
      ['I', 'vi', 'ii', 'V', 'iii', 'vi', 'ii', 'V'],
      ['IV', 'iii', 'ii', 'V'],
    ],
    chordTypes: ['major7', 'minor7', 'dominant7', 'halfDim7', 'diminished7', 'minor9', 'major9'],
    melodyScale: 'dorian',
    tempo: 110,
  },
  'dark-trap': {
    name: 'Dark Deep Trap',
    scale: 'harmonicMinor',
    progressions: [
      ['i', 'VI', 'III', 'VII'],
      ['i', 'iv', 'VI', 'V'],
      ['i', 'VII', 'VI', 'VII'],
      ['i', 'v', 'VI', 'iv'],
      ['i', 'iv', 'i', 'V'],
      ['i', 'III', 'VII', 'iv'],
    ],
    chordTypes: ['minor', 'diminished', 'minor7', 'halfDim7', 'augmented'],
    melodyScale: 'harmonicMinor',
    tempo: 140,
  },
  cinematic: {
    name: 'Cinematic Epic',
    scale: 'minor',
    progressions: [
      ['i', 'VI', 'III', 'VII'],
      ['i', 'iv', 'V', 'i'],
      ['VI', 'VII', 'i', 'V'],
      ['i', 'III', 'VII', 'VI'],
      ['i', 'iv', 'VII', 'i'],
      ['VI', 'III', 'VII', 'i'],
      ['i', 'V', 'VI', 'III'],
    ],
    chordTypes: ['minor', 'major', 'sus4', 'augmented', 'minor7', 'major7'],
    melodyScale: 'minor',
    tempo: 100,
  },
  'indie-rock': {
    name: 'Indie Rock',
    scale: 'major',
    progressions: [
      ['I', 'iii', 'IV', 'V'],
      ['I', 'V', 'vi', 'iii', 'IV'],
      ['I', 'IV', 'ii', 'V'],
      ['vi', 'IV', 'I', 'V'],
      ['I', 'vi', 'iii', 'V'],
      ['IV', 'I', 'V', 'vi'],
      ['I', 'V', 'IV', 'IV'],
    ],
    chordTypes: ['major', 'minor', 'sus2', 'add9', 'major7'],
    melodyScale: 'major',
    tempo: 115,
  },
  reggae: {
    name: 'Reggae',
    scale: 'major',
    progressions: [
      ['I', 'IV', 'I', 'V'],
      ['I', 'V', 'vi', 'IV'],
      ['I', 'IV', 'V', 'IV'],
      ['vi', 'IV', 'I', 'V'],
      ['I', 'vi', 'IV', 'V'],
      ['I', 'ii', 'IV', 'V'],
    ],
    chordTypes: ['major', 'minor', 'dominant7', 'minor7', 'sus2'],
    melodyScale: 'pentatonicMajor',
    tempo: 80,
  },
  blues: {
    name: 'Blues',
    scale: 'mixolydian',
    progressions: [
      // Standard 12-bar blues form: 4 bars of I, 2 of IV, 2 of I, then V-IV-I-V turnaround
      ['I', 'I', 'I', 'I', 'IV', 'IV', 'I', 'I', 'V', 'IV', 'I', 'V'],
      ['I', 'IV', 'I', 'V'],
      ['i', 'iv', 'i', 'V'],
      ['I', 'I', 'IV', 'I', 'V', 'I'],
      ['I', 'IV', 'I', 'I', 'IV', 'IV', 'I', 'V'],
      ['I', 'iv', 'I', 'V'],
    ],
    chordTypes: ['dominant7', 'minor7', 'major', 'minor', 'diminished'],
    melodyScale: 'blues',
    tempo: 90,
  },
  country: {
    name: 'Country',
    scale: 'major',
    progressions: [
      ['I', 'IV', 'V', 'I'],
      ['I', 'V', 'vi', 'IV'],
      ['I', 'IV', 'I', 'V'],
      ['I', 'vi', 'IV', 'V'],
      ['I', 'ii', 'V', 'I'],
      ['vi', 'IV', 'I', 'V'],
    ],
    chordTypes: ['major', 'minor', 'sus4', 'add9', 'dominant7'],
    melodyScale: 'pentatonicMajor',
    tempo: 110,
  },
  funk: {
    name: 'Funk',
    scale: 'mixolydian',
    progressions: [
      ['I', 'IV', 'I', 'IV'],
      ['i', 'IV', 'i', 'IV'],
      ['I', 'I', 'IV', 'I'],
      ['i', 'VII', 'i', 'VII'],
      ['I', 'ii', 'IV', 'V'],
      ['i', 'iv', 'VII', 'III'],
    ],
    chordTypes: ['dominant7', 'minor7', 'major', 'minor9', 'sus4'],
    melodyScale: 'pentatonicMinor',
    tempo: 105,
  },
};

// Complexity settings
export const COMPLEXITY_SETTINGS: Record<ComplexityLevel, ComplexitySetting> = {
  simple: { chordCount: [3, 4], useExtensions: false, variations: 1 },
  medium: { chordCount: [4, 5], useExtensions: true, variations: 2 },
  complex: { chordCount: [6, 8], useExtensions: true, variations: 3 },
  advanced: { chordCount: [8, 12], useExtensions: true, variations: 4 },
};

// Rhythm patterns based on strength
export const RHYTHM_PATTERNS: Record<RhythmLevel, RhythmPattern> = {
  soft: {
    name: 'Soft & Gentle',
    durations: [4, 2, 2],
    dynamics: [0.5, 0.4, 0.6],
    melodyDensity: 0.3,
  },
  moderate: {
    name: 'Moderate',
    durations: [2, 2, 1, 1],
    dynamics: [0.7, 0.5, 0.8, 0.6],
    melodyDensity: 0.5,
  },
  strong: {
    name: 'Strong & Punchy',
    durations: [1, 1, 1, 1],
    dynamics: [0.9, 0.7, 0.85, 0.75],
    melodyDensity: 0.7,
  },
  intense: {
    name: 'Intense & Driving',
    durations: [0.5, 0.5, 1, 0.5, 0.5],
    dynamics: [1, 0.8, 0.95, 0.85, 0.9],
    melodyDensity: 0.9,
  },
};

// Smart Presets - v2.4
export const SMART_PRESETS: Record<string, SmartPreset> = {
  'lofi-chill-sunday': {
    name: 'Lo-Fi Chill Sunday',
    emoji: '☕',
    description: 'Relaxed jazzy vibes for lazy mornings',
    genre: 'chill-lofi',
    key: 'Dm',
    complexity: 'medium',
    rhythm: 'soft',
    swing: 0.3,
    useVoiceLeading: true,
    useAdvancedTheory: true,
  },
  'cyberpunk-drive': {
    name: 'Cyberpunk Drive',
    emoji: '🌃',
    description: 'Dark synth energy for night drives',
    genre: 'dark-trap',
    key: 'Em',
    complexity: 'complex',
    rhythm: 'strong',
    swing: 0.1,
    useVoiceLeading: false,
    useAdvancedTheory: true,
  },
  'summer-pop': {
    name: 'Summer Pop Hit',
    emoji: '☀️',
    description: 'Catchy and uplifting radio-ready vibes',
    genre: 'happy-pop',
    key: 'G',
    complexity: 'simple',
    rhythm: 'moderate',
    swing: 0,
    useVoiceLeading: false,
    useAdvancedTheory: false,
  },
  'midnight-jazz': {
    name: 'Midnight Jazz',
    emoji: '🎷',
    description: 'Sophisticated harmonies for late nights',
    genre: 'jazz-fusion',
    key: 'Fm',
    complexity: 'advanced',
    rhythm: 'moderate',
    swing: 0.4,
    useVoiceLeading: true,
    useAdvancedTheory: true,
  },
  'epic-cinema': {
    name: 'Epic Cinema',
    emoji: '🎬',
    description: 'Dramatic orchestral grandeur',
    genre: 'cinematic',
    key: 'Am',
    complexity: 'complex',
    rhythm: 'intense',
    swing: 0,
    useVoiceLeading: true,
    useAdvancedTheory: true,
  },
  'soul-groove': {
    name: 'Soul Groove',
    emoji: '🎤',
    description: 'Smooth R&B with rich harmonies',
    genre: 'soulful-rnb',
    key: 'Bm',
    complexity: 'medium',
    rhythm: 'moderate',
    swing: 0.25,
    useVoiceLeading: true,
    useAdvancedTheory: true,
  },
  'festival-drop': {
    name: 'Festival Drop',
    emoji: '🔥',
    description: 'High-energy EDM for the main stage',
    genre: 'energetic-edm',
    key: 'C',
    complexity: 'simple',
    rhythm: 'intense',
    swing: 0,
    useVoiceLeading: false,
    useAdvancedTheory: false,
  },
  'indie-sunset': {
    name: 'Indie Sunset',
    emoji: '🌅',
    description: 'Dreamy guitar-driven atmosphere',
    genre: 'indie-rock',
    key: 'D',
    complexity: 'medium',
    rhythm: 'soft',
    swing: 0.15,
    useVoiceLeading: true,
    useAdvancedTheory: false,
  },
  'island-vibes': {
    name: 'Island Vibes',
    emoji: '🏝️',
    description: 'Laid-back reggae rhythms for sunny days',
    genre: 'reggae',
    key: 'G',
    complexity: 'simple',
    rhythm: 'moderate',
    swing: 0.2,
    useVoiceLeading: false,
    useAdvancedTheory: false,
  },
  'delta-blues': {
    name: 'Delta Blues',
    emoji: '🎸',
    description: 'Soulful 12-bar blues progressions',
    genre: 'blues',
    key: 'E',
    complexity: 'medium',
    rhythm: 'moderate',
    swing: 0.35,
    useVoiceLeading: true,
    useAdvancedTheory: true,
  },
  'nashville-nights': {
    name: 'Nashville Nights',
    emoji: '🤠',
    description: 'Classic country with heartfelt chords',
    genre: 'country',
    key: 'G',
    complexity: 'simple',
    rhythm: 'moderate',
    swing: 0.1,
    useVoiceLeading: false,
    useAdvancedTheory: false,
  },
  'groovy-funk': {
    name: 'Groovy Funk',
    emoji: '🕺',
    description: 'Tight rhythms and syncopated grooves',
    genre: 'funk',
    key: 'Am',
    complexity: 'medium',
    rhythm: 'strong',
    swing: 0.25,
    useVoiceLeading: true,
    useAdvancedTheory: true,
  },
};

// Modal Interchange / Borrowed Chords - v2.4
export const MODAL_INTERCHANGE: {
  majorBorrowedFromMinor: Record<string, ModalInterchangeChord>;
  minorBorrowedFromMajor: Record<string, ModalInterchangeChord>;
} = {
  majorBorrowedFromMinor: {
    iv: { root: 3, type: 'minor', symbol: 'iv', description: 'Minor iv from parallel minor' },
    bVII: { root: 10, type: 'major', symbol: 'bVII', description: 'Flat VII from parallel minor' },
    bVI: { root: 8, type: 'major', symbol: 'bVI', description: 'Flat VI from parallel minor' },
    bIII: { root: 3, type: 'major', symbol: 'bIII', description: 'Flat III from parallel minor' },
    'viio7': { root: 11, type: 'diminished7', symbol: 'viio7', description: 'Diminished 7 from harmonic minor' },
  },
  minorBorrowedFromMajor: {
    IV: { root: 5, type: 'major', symbol: 'IV', description: 'Major IV from parallel major' },
    I: { root: 0, type: 'major', symbol: 'I', description: 'Major I (Picardy third)' },
    ii: { root: 2, type: 'minor', symbol: 'ii', description: 'Minor ii from parallel major' },
  },
};

// Shell voicing patterns - v2.4
export const SHELL_VOICINGS: Partial<Record<ChordTypeName, ShellVoicing>> = {
  major7: { intervals: [4, 11], name: 'Shell Maj7' },
  minor7: { intervals: [3, 10], name: 'Shell m7' },
  dominant7: { intervals: [4, 10], name: 'Shell 7' },
  halfDim7: { intervals: [3, 10], name: 'Shell m7b5' },
};

// Open voicing patterns (spread across octaves) - v2.4
export const OPEN_VOICINGS: Partial<Record<ChordTypeName, OpenVoicing>> = {
  major: { intervals: [0, 7, 16], name: 'Open Major' },
  minor: { intervals: [0, 7, 15], name: 'Open Minor' },
  major7: { intervals: [0, 11, 16], name: 'Open Maj7' },
  minor7: { intervals: [0, 10, 15], name: 'Open m7' },
  dominant7: { intervals: [0, 10, 16], name: 'Open 7' },
};

// ===================================
// Probability & Variation Constants - v2.4
// ===================================

export const MODAL_INTERCHANGE_PROBABILITY = 0.3;
export const SPICE_PROBABILITY_THRESHOLDS = {
  ADD_EXTENSION: 0.25,
  TRITONE_SUB: 0.5,
  MODAL_INTERCHANGE: 0.75,
  SUS_CHORD: 1.0,
};
export const TIMING_VARIATION_FACTOR = 0.1;
export const VELOCITY_VARIATION_FACTOR = 0.3;

// ===================================
// Default Values
// ===================================

export const DEFAULT_ENVELOPE = {
  attack: 0.05,
  decay: 0.1,
  sustain: 0.6,
  release: 0.5,
};

export const DEFAULT_STATE = {
  masterVolume: 0.8,
  soundType: 'sine' as SoundType,
  tempo: 120,
  genre: 'happy-pop' as GenreKey,
  complexity: 'medium' as ComplexityLevel,
  rhythm: 'moderate' as RhythmLevel,
  currentKey: 'C' as const,
  showNumerals: true,
  showTips: true,
  swing: 0,
  useVoiceLeading: false,
  useAdvancedTheory: false,
  useModalInterchange: false,
  includeMelody: true,
  includeBass: true,
  bassStyle: 'root' as const,
  bassVariety: 50,
  chordVariety: 50,
  rhythmVariety: 50,
  // Phase 1: Mood/Mode Selector defaults
  currentMood: 'happy' as MoodType,
  useFunctionalHarmony: false,
  // Phase 2: Groove Engine defaults
  grooveTemplate: 'straight' as GrooveTemplate,
  // Phase 3: Spice Control defaults
  spiceLevel: 'medium' as SpiceLevel,
};

export const MAX_HISTORY_LENGTH = 5;

// ===================================
// UI Options
// ===================================

export const GENRE_OPTIONS = [
  { value: 'happy-pop', label: 'Happy Pop' },
  { value: 'chill-lofi', label: 'Chill Lo-Fi' },
  { value: 'energetic-edm', label: 'EDM' },
  { value: 'soulful-rnb', label: 'R&B' },
  { value: 'jazz-fusion', label: 'Jazz' },
  { value: 'dark-trap', label: 'Trap' },
  { value: 'cinematic', label: 'Cinematic' },
  { value: 'indie-rock', label: 'Indie Rock' },
  { value: 'reggae', label: 'Reggae' },
  { value: 'blues', label: 'Blues' },
  { value: 'country', label: 'Country' },
  { value: 'funk', label: 'Funk' },
];

export const KEY_OPTIONS = [
  { value: 'C', label: 'C Major' },
  { value: 'G', label: 'G Major' },
  { value: 'D', label: 'D Major' },
  { value: 'A', label: 'A Major' },
  { value: 'E', label: 'E Major' },
  { value: 'F', label: 'F Major' },
  { value: 'Bb', label: 'Bb Major' },
  { value: 'Am', label: 'A Minor' },
  { value: 'Em', label: 'E Minor' },
  { value: 'Dm', label: 'D Minor' },
  { value: 'Bm', label: 'B Minor' },
  { value: 'Fm', label: 'F Minor' },
];

export const COMPLEXITY_OPTIONS = [
  { value: 'simple', label: 'Simple' },
  { value: 'medium', label: 'Medium' },
  { value: 'complex', label: 'Complex' },
  { value: 'advanced', label: 'Advanced' },
];

export const RHYTHM_OPTIONS = [
  { value: 'soft', label: 'Soft' },
  { value: 'moderate', label: 'Moderate' },
  { value: 'strong', label: 'Strong' },
  { value: 'intense', label: 'Intense' },
];

export const SOUND_TYPE_OPTIONS = [
  { value: 'sine', label: 'Sine (Smooth)' },
  { value: 'triangle', label: 'Triangle (Mellow)' },
  { value: 'square', label: 'Square (Retro)' },
  { value: 'sawtooth', label: 'Sawtooth (Bright)' },
];

export const BASS_STYLE_OPTIONS = [
  { value: 'root', label: 'Root Notes' },
  { value: 'walking', label: 'Walking Bass' },
  { value: 'syncopated', label: 'Syncopated' },
  { value: 'octave', label: 'Octave Jumps' },
  { value: 'fifths', label: 'Root & Fifth' },
];

// ===================================
// Phase 1: Functional Harmony Constants
// ===================================

// Functional harmony groups - defines which scale degrees belong to each function
export const FUNCTIONAL_HARMONY: Record<HarmonyFunction, FunctionalChord[]> = {
  tonic: [
    { degree: 'I', function: 'tonic', chordTypes: ['major', 'major7', 'add9'], tension: 0 },
    { degree: 'i', function: 'tonic', chordTypes: ['minor', 'minor7', 'minor9'], tension: 0 },
    { degree: 'vi', function: 'tonic', chordTypes: ['minor', 'minor7'], tension: 0.2 },
    { degree: 'iii', function: 'tonic', chordTypes: ['minor', 'minor7'], tension: 0.3 },
  ],
  subdominant: [
    { degree: 'IV', function: 'subdominant', chordTypes: ['major', 'major7', 'add9'], tension: 0.4 },
    { degree: 'iv', function: 'subdominant', chordTypes: ['minor', 'minor7'], tension: 0.5 },
    { degree: 'ii', function: 'subdominant', chordTypes: ['minor', 'minor7', 'halfDim7'], tension: 0.5 },
    { degree: 'II', function: 'subdominant', chordTypes: ['major', 'dominant7'], tension: 0.6 },
  ],
  dominant: [
    { degree: 'V', function: 'dominant', chordTypes: ['major', 'dominant7', 'sus4'], tension: 0.8 },
    { degree: 'v', function: 'dominant', chordTypes: ['minor', 'minor7'], tension: 0.6 },
    { degree: 'vii', function: 'dominant', chordTypes: ['diminished', 'halfDim7', 'diminished7'], tension: 0.9 },
    { degree: 'VII', function: 'dominant', chordTypes: ['major', 'dominant7'], tension: 0.7 },
  ],
  passing: [
    { degree: 'bVII', function: 'passing', chordTypes: ['major', 'dominant7'], tension: 0.5 },
    { degree: 'bVI', function: 'passing', chordTypes: ['major', 'major7'], tension: 0.4 },
    { degree: 'bIII', function: 'passing', chordTypes: ['major', 'major7'], tension: 0.3 },
    { degree: '#iv', function: 'passing', chordTypes: ['diminished', 'halfDim7'], tension: 0.7 },
  ],
};

// Common functional progressions (Tonic -> Subdominant -> Dominant -> Tonic)
export const FUNCTIONAL_PROGRESSIONS: HarmonyFunction[][] = [
  ['tonic', 'subdominant', 'dominant', 'tonic'],
  ['tonic', 'tonic', 'subdominant', 'dominant'],
  ['tonic', 'subdominant', 'subdominant', 'dominant'],
  ['subdominant', 'dominant', 'tonic', 'tonic'],
  ['tonic', 'passing', 'subdominant', 'dominant'],
  ['subdominant', 'tonic', 'subdominant', 'dominant'],
];

// Mood profiles with associated scales and chord preferences
export const MOOD_PROFILES: Record<MoodType, MoodProfile> = {
  happy: {
    name: 'Happy',
    scales: ['major', 'lydian', 'pentatonicMajor'],
    preferredFunctions: ['tonic', 'subdominant'],
    chordTypes: ['major', 'major7', 'add9', 'sus2'],
    tensionRange: [0, 0.5],
    description: 'Bright, uplifting progressions',
  },
  sad: {
    name: 'Sad',
    scales: ['minor', 'dorian', 'phrygian'],
    preferredFunctions: ['tonic', 'subdominant'],
    chordTypes: ['minor', 'minor7', 'minor9', 'sus4'],
    tensionRange: [0.2, 0.6],
    description: 'Melancholic, introspective progressions',
  },
  dreamy: {
    name: 'Dreamy',
    scales: ['lydian', 'dorian', 'pentatonicMajor'],
    preferredFunctions: ['tonic', 'passing'],
    chordTypes: ['major7', 'minor7', 'add9', 'sus2'],
    tensionRange: [0.1, 0.4],
    description: 'Ethereal, floating progressions',
  },
  energetic: {
    name: 'Energetic',
    scales: ['major', 'mixolydian'],
    preferredFunctions: ['dominant', 'subdominant'],
    chordTypes: ['major', 'dominant7', 'sus4'],
    tensionRange: [0.5, 0.9],
    description: 'Driving, powerful progressions',
  },
  dark: {
    name: 'Dark',
    scales: ['harmonicMinor', 'phrygian', 'locrian'],
    preferredFunctions: ['dominant', 'passing'],
    chordTypes: ['minor', 'diminished', 'halfDim7', 'augmented'],
    tensionRange: [0.6, 1.0],
    description: 'Tense, ominous progressions',
  },
  mysterious: {
    name: 'Mysterious',
    scales: ['dorian', 'phrygian', 'harmonicMinor'],
    preferredFunctions: ['passing', 'subdominant'],
    chordTypes: ['minor7', 'halfDim7', 'sus4', 'diminished7'],
    tensionRange: [0.4, 0.8],
    description: 'Enigmatic, suspenseful progressions',
  },
  triumphant: {
    name: 'Triumphant',
    scales: ['major', 'lydian'],
    preferredFunctions: ['dominant', 'tonic'],
    chordTypes: ['major', 'major7', 'sus4', 'add9'],
    tensionRange: [0.3, 0.8],
    description: 'Victorious, heroic progressions',
  },
  relaxed: {
    name: 'Relaxed',
    scales: ['major', 'dorian', 'pentatonicMajor'],
    preferredFunctions: ['tonic', 'subdominant'],
    chordTypes: ['major7', 'minor7', 'add9', 'sus2'],
    tensionRange: [0, 0.3],
    description: 'Calm, soothing progressions',
  },
};

// ===================================
// Phase 2: Groove Engine Constants
// ===================================

export const GROOVE_PATTERNS: Record<GrooveTemplate, GroovePattern> = {
  'four-on-floor': {
    name: 'Four on the Floor',
    template: 'four-on-floor',
    beatPattern: [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],
    swingAmount: 0,
    accentBeats: [0, 4, 8, 12],
  },
  'neo-soul-swing': {
    name: 'Neo-Soul Swing',
    template: 'neo-soul-swing',
    beatPattern: [1, 0, 0.5, 0, 1, 0, 0.7, 0.3, 1, 0, 0.5, 0, 1, 0, 0.7, 0],
    swingAmount: 0.3,
    accentBeats: [0, 6, 8, 14],
  },
  'funk-syncopation': {
    name: 'Funk Syncopation',
    template: 'funk-syncopation',
    beatPattern: [1, 0.3, 0, 0.8, 0, 0.5, 0.9, 0, 1, 0.3, 0, 0.8, 0, 0.5, 0.9, 0],
    swingAmount: 0.15,
    accentBeats: [0, 3, 6, 8, 11, 14],
  },
  'straight': {
    name: 'Straight',
    template: 'straight',
    beatPattern: [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],
    swingAmount: 0,
    accentBeats: [0, 4, 8, 12],
  },
  'shuffle': {
    name: 'Shuffle',
    template: 'shuffle',
    beatPattern: [1, 0, 0.6, 0, 1, 0, 0.6, 0, 1, 0, 0.6, 0, 1, 0, 0.6, 0],
    swingAmount: 0.4,
    accentBeats: [0, 2, 4, 6, 8, 10, 12, 14],
  },
  'half-time': {
    name: 'Half-Time',
    template: 'half-time',
    beatPattern: [1, 0, 0, 0, 0, 0, 0, 0, 0.8, 0, 0, 0, 0, 0, 0, 0],
    swingAmount: 0,
    accentBeats: [0, 8],
  },
};

// Bass agent configurations for different styles
export const BASS_AGENT_CONFIGS = {
  root: {
    rootEmphasis: 1.0,
    chromaticApproach: false,
    octaveJumps: false,
    fifthApproach: false,
    syncopation: 0,
  },
  walking: {
    rootEmphasis: 0.7,
    chromaticApproach: true,
    octaveJumps: false,
    fifthApproach: true,
    syncopation: 0.2,
  },
  syncopated: {
    rootEmphasis: 0.6,
    chromaticApproach: false,
    octaveJumps: false,
    fifthApproach: true,
    syncopation: 0.7,
  },
  octave: {
    rootEmphasis: 0.8,
    chromaticApproach: false,
    octaveJumps: true,
    fifthApproach: false,
    syncopation: 0.3,
  },
  fifths: {
    rootEmphasis: 0.6,
    chromaticApproach: false,
    octaveJumps: false,
    fifthApproach: true,
    syncopation: 0.1,
  },
};

// ===================================
// Phase 3: Spice Control Constants
// ===================================

export const SPICE_CONFIGS: Record<SpiceLevel, SpiceConfig> = {
  mild: {
    level: 'mild',
    allowExtensions: false,
    allowAlterations: false,
    maxExtension: 7,
  },
  medium: {
    level: 'medium',
    allowExtensions: true,
    allowAlterations: false,
    maxExtension: 7,
  },
  hot: {
    level: 'hot',
    allowExtensions: true,
    allowAlterations: true,
    maxExtension: 11,
  },
  fire: {
    level: 'fire',
    allowExtensions: true,
    allowAlterations: true,
    maxExtension: 13,
  },
};

// ===================================
// New UI Options
// ===================================

export const MOOD_OPTIONS = [
  { value: 'happy', label: '😊 Happy' },
  { value: 'sad', label: '😢 Sad' },
  { value: 'dreamy', label: '✨ Dreamy' },
  { value: 'energetic', label: '⚡ Energetic' },
  { value: 'dark', label: '🌑 Dark' },
  { value: 'mysterious', label: '🔮 Mysterious' },
  { value: 'triumphant', label: '🏆 Triumphant' },
  { value: 'relaxed', label: '😌 Relaxed' },
];

export const GROOVE_TEMPLATE_OPTIONS = [
  { value: 'straight', label: 'Straight' },
  { value: 'four-on-floor', label: 'Four on the Floor' },
  { value: 'neo-soul-swing', label: 'Neo-Soul Swing' },
  { value: 'funk-syncopation', label: 'Funk Syncopation' },
  { value: 'shuffle', label: 'Shuffle' },
  { value: 'half-time', label: 'Half-Time' },
];

export const SPICE_LEVEL_OPTIONS = [
  { value: 'mild', label: '🌶️ Mild (Triads)' },
  { value: 'medium', label: '🌶️🌶️ Medium (7ths)' },
  { value: 'hot', label: '🌶️🌶️🌶️ Hot (Extensions)' },
  { value: 'fire', label: '🔥 Fire (Altered)' },
];
