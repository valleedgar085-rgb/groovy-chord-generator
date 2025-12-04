/**
 * Groovy Chord Generator
 * TypeScript Type Definitions
 * Version 2.4
 */

// ===================================
// Music Theory Types
// ===================================

export type NoteName = 'C' | 'C#' | 'D' | 'D#' | 'E' | 'F' | 'F#' | 'G' | 'G#' | 'A' | 'A#' | 'B';

export type NoteDisplayName = 'C' | 'Db' | 'D' | 'Eb' | 'E' | 'F' | 'Gb' | 'G' | 'Ab' | 'A' | 'Bb' | 'B';

export type ChordTypeName = 
  | 'major' 
  | 'minor' 
  | 'diminished' 
  | 'augmented'
  | 'major7' 
  | 'minor7' 
  | 'dominant7' 
  | 'diminished7' 
  | 'halfDim7'
  | 'sus2' 
  | 'sus4' 
  | 'add9' 
  | 'minor9' 
  | 'major9';

export type ScaleName = 
  | 'major' 
  | 'minor' 
  | 'harmonicMinor' 
  | 'melodicMinor'
  | 'dorian' 
  | 'phrygian' 
  | 'lydian' 
  | 'mixolydian' 
  | 'locrian'
  | 'pentatonicMajor' 
  | 'pentatonicMinor' 
  | 'blues';

export type GenreKey = 
  | 'happy-pop' 
  | 'chill-lofi' 
  | 'energetic-edm' 
  | 'soulful-rnb'
  | 'jazz-fusion' 
  | 'dark-trap' 
  | 'cinematic' 
  | 'indie-rock'
  | 'reggae'
  | 'blues'
  | 'country'
  | 'funk';

export type ComplexityLevel = 'simple' | 'medium' | 'complex' | 'advanced';

export type RhythmLevel = 'soft' | 'moderate' | 'strong' | 'intense';

export type SoundType = 'sine' | 'triangle' | 'square' | 'sawtooth';

export type KeyName = 
  | 'C' | 'G' | 'D' | 'A' | 'E' | 'F' | 'Bb'
  | 'Am' | 'Em' | 'Dm' | 'Bm' | 'Fm';

export type TabName = 'generator' | 'editor' | 'settings';

// ===================================
// Data Structure Interfaces
// ===================================

export interface ChordType {
  intervals: number[];
  symbol: string;
  name: string;
}

export interface Scale {
  intervals: number[];
}

export interface VoicedNote {
  note: NoteName;
  octave: number;
  pitch: number;
}

export interface Chord {
  root: NoteName;
  type: ChordTypeName;
  degree: string;
  numeral: string;
  voicedNotes?: VoicedNote[];
  isSecondaryDominant?: boolean;
  isBorrowed?: boolean;
  isTritoneSubstitution?: boolean;
  borrowedDescription?: string;
  shellVoicing?: ShellVoicing;
  openVoicing?: OpenVoicing;
  voicingType?: 'shell' | 'open';
}

export interface MelodyNote {
  note: NoteName;
  duration: number;
  velocity: number;
  chordIndex: number;
  octave: number;
}

export interface GenreProfile {
  name: string;
  scale: ScaleName;
  progressions: string[][];
  chordTypes: ChordTypeName[];
  melodyScale: ScaleName;
  tempo: number;
}

export interface ComplexitySetting {
  chordCount: [number, number];
  useExtensions: boolean;
  variations: number;
}

export interface RhythmPattern {
  name: string;
  durations: number[];
  dynamics: number[];
  melodyDensity: number;
}

export interface SmartPreset {
  name: string;
  emoji: string;
  description: string;
  genre: GenreKey;
  key: KeyName;
  complexity: ComplexityLevel;
  rhythm: RhythmLevel;
  swing: number;
  useVoiceLeading: boolean;
  useAdvancedTheory: boolean;
}

export interface ModalInterchangeChord {
  root: number;
  type: ChordTypeName;
  symbol: string;
  description: string;
}

export interface ShellVoicing {
  intervals: number[];
  name: string;
}

export interface OpenVoicing {
  intervals: number[];
  name: string;
}

export interface Envelope {
  attack: number;
  decay: number;
  sustain: number;
  release: number;
}

export interface HistoryEntry {
  progression: Chord[];
  key: KeyName;
  genre: GenreKey;
  timestamp: number;
}

export interface PianoRollNote {
  x: number;
  y: number;
  width: number;
  noteIndex: number;
  beat: number;
}

// ===================================
// Application State Interface
// ===================================

export interface AppState {
  currentProgression: Chord[];
  currentMelody: MelodyNote[];
  currentKey: KeyName;
  isMinorKey: boolean;
  genre: GenreKey;
  complexity: ComplexityLevel;
  rhythm: RhythmLevel;
  tempo: number;
  isPlaying: boolean;
  pianoRollNotes: PianoRollNote[];
  audioContext: AudioContext | null;
  masterVolume: number;
  soundType: SoundType;
  showNumerals: boolean;
  showTips: boolean;
  currentTab: TabName;
  onboardingComplete: boolean;
  pianoRollZoom: number;
  useVoiceLeading: boolean;
  useAdvancedTheory: boolean;
  envelope: Envelope;
  swing: number;
  useModalInterchange: boolean;
  includeMelody: boolean;
  currentPreset: string | null;
  progressionHistory: HistoryEntry[];
}

// ===================================
// Component Props Interfaces
// ===================================

export interface ChordCardProps {
  chord: Chord;
  index: number;
  showNumerals: boolean;
  onPlayChord: (chord: Chord) => void;
}

export interface PresetCardProps {
  presetKey: string;
  preset: SmartPreset;
  isSelected: boolean;
  onSelect: (presetKey: string) => void;
}

export interface HistoryItemProps {
  entry: HistoryEntry;
  index: number;
  onRestore: (index: number) => void;
}

export interface ControlSelectProps {
  id: string;
  label: string;
  value: string;
  options: { value: string; label: string }[];
  onChange: (value: string) => void;
}

export interface SliderProps {
  id: string;
  label: string;
  value: number;
  min: number;
  max: number;
  step?: number;
  displayValue?: string;
  onChange: (value: number) => void;
}

export interface ToggleProps {
  id: string;
  label: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
}

// ===================================
// Context Types
// ===================================

export interface AppContextType {
  state: AppState;
  actions: {
    setGenre: (genre: GenreKey) => void;
    setKey: (key: KeyName) => void;
    setComplexity: (complexity: ComplexityLevel) => void;
    setRhythm: (rhythm: RhythmLevel) => void;
    setTempo: (tempo: number) => void;
    setVolume: (volume: number) => void;
    setSoundType: (type: SoundType) => void;
    setEnvelope: (envelope: Envelope) => void;
    setShowNumerals: (show: boolean) => void;
    setShowTips: (show: boolean) => void;
    setSwing: (swing: number) => void;
    setUseVoiceLeading: (use: boolean) => void;
    setUseAdvancedTheory: (use: boolean) => void;
    setUseModalInterchange: (use: boolean) => void;
    setIncludeMelody: (include: boolean) => void;
    setCurrentTab: (tab: TabName) => void;
    setOnboardingComplete: (complete: boolean) => void;
    generateProgression: () => void;
    regenerateProgression: () => void;
    spiceItUp: () => void;
    applyPreset: (presetKey: string) => void;
    restoreFromHistory: (index: number) => void;
    playProgression: () => void;
    stopPlayback: () => void;
    playChord: (chord: Chord) => void;
    exportToMIDI: () => void;
    clearPianoRoll: () => void;
  };
}
