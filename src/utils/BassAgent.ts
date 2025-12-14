/**
 * Groovy Chord Generator
 * BassAgent - Rhythm-Aware Bass Generator Module
 * Version 2.5 - Phase 2
 */

import type {
  Chord,
  BassNote,
  BassStyle,
  NoteName,
  RhythmLevel,
  GrooveTemplate,
  BassAgentConfig,
} from '../types';

import { BASS_AGENT_CONFIGS, RHYTHM_PATTERNS, GROOVE_PATTERNS } from '../constants';
import { transposeNote, getScaleNotes, randomChoice } from './musicTheory';

// ===================================
// Bass Agent Configuration
// ===================================

const BASS_OCTAVE = 2;

/**
 * Get the bass agent configuration for a given style
 */
export function getBassAgentConfig(style: BassStyle): BassAgentConfig {
  return BASS_AGENT_CONFIGS[style];
}

// ===================================
// Rhythm-Aware Bass Generation
// ===================================

/**
 * Generate a sophisticated bass line with rhythm awareness
 * This is the main entry point for the BassAgent module
 */
export function generateRhythmAwareBassLine(
  progression: Chord[],
  style: BassStyle,
  variety: number,
  rhythm: RhythmLevel,
  groove: GrooveTemplate = 'straight'
): BassNote[] {
  const config = getBassAgentConfig(style);
  const groovePattern = GROOVE_PATTERNS[groove];
  const rhythmPattern = RHYTHM_PATTERNS[rhythm];
  const varietyFactor = variety / 100;
  
  const bassLine: BassNote[] = [];
  
  progression.forEach((chord, chordIndex) => {
    const chordBass = generateChordBassNotes(
      chord,
      chordIndex,
      progression,
      config,
      groovePattern,
      rhythmPattern,
      varietyFactor
    );
    bassLine.push(...chordBass);
  });
  
  // Apply syncopation if configured
  if (config.syncopation > 0) {
    return applySyncopationToBass(bassLine, config.syncopation);
  }
  
  return bassLine;
}

/**
 * Generate bass notes for a single chord
 */
function generateChordBassNotes(
  chord: Chord,
  chordIndex: number,
  progression: Chord[],
  config: BassAgentConfig,
  groovePattern: typeof GROOVE_PATTERNS[GrooveTemplate],
  rhythmPattern: typeof RHYTHM_PATTERNS[RhythmLevel],
  varietyFactor: number
): BassNote[] {
  const notes: BassNote[] = [];
  const root = chord.root;
  const fifth = transposeNote(root, 7);
  const octaveRoot = root;
  
  // Calculate notes per chord based on variety
  const notesPerChord = Math.max(2, Math.min(6, 2 + Math.floor(varietyFactor * 4)));
  const noteDuration = 4 / notesPerChord;
  
  for (let i = 0; i < notesPerChord; i++) {
    const isDownbeat = i === 0;
    const isLastNote = i === notesPerChord - 1;
    const beatPosition = i % groovePattern.beatPattern.length;
    const isAccent = groovePattern.accentBeats.includes(beatPosition);
    
    let note: NoteName;
    let octave = BASS_OCTAVE;
    let style: BassStyle = 'root';
    
    if (isDownbeat) {
      // Downbeat: emphasize root based on config
      if (Math.random() < config.rootEmphasis) {
        note = root;
      } else {
        note = fifth;
        style = 'fifths';
      }
    } else if (isLastNote && config.chromaticApproach) {
      // Last note: chromatic approach to next chord
      note = generateApproachNote(chord, chordIndex, progression);
      style = 'walking';
    } else if (config.octaveJumps && Math.random() < 0.3 * varietyFactor) {
      // Octave jump
      note = octaveRoot;
      octave = BASS_OCTAVE + 1;
      style = 'octave';
    } else if (config.fifthApproach && Math.random() < 0.4 * varietyFactor) {
      // Fifth approach
      note = fifth;
      style = 'fifths';
    } else {
      // Default to root with occasional variation
      note = root;
    }
    
    // Calculate velocity
    let velocity = rhythmPattern.dynamics[i % rhythmPattern.dynamics.length];
    if (isDownbeat) velocity = Math.min(1, velocity * 1.2);
    if (isAccent) velocity = Math.min(1, velocity * 1.1);
    velocity *= groovePattern.beatPattern[beatPosition] || 0.7;
    
    notes.push({
      note,
      duration: noteDuration,
      velocity: Math.max(0.3, Math.min(1, velocity)),
      octave,
      chordIndex,
      style,
    });
  }
  
  return notes;
}

/**
 * Generate a chromatic approach note to the next chord
 */
function generateApproachNote(
  chordIndex: number,
  progression: Chord[]
): NoteName {
  const nextChord = progression[(chordIndex + 1) % progression.length];
  const nextRoot = nextChord.root;
  
  // Choose semitone above or below the next root
  const direction = Math.random() > 0.5 ? 1 : 11; // 1 = semitone above, 11 = semitone below
  return transposeNote(nextRoot, direction);
}

/**
 * Apply syncopation to bass notes
 */
function applySyncopationToBass(
  bassLine: BassNote[],
  syncopationAmount: number
): BassNote[] {
  return bassLine.map((note, index) => {
    // Don't syncopate downbeats (first note of each chord)
    const isDownbeat = index === 0 || 
      (index > 0 && bassLine[index - 1].chordIndex !== note.chordIndex);
    
    if (isDownbeat) return note;
    
    const shouldSyncopate = Math.random() < syncopationAmount;
    
    if (shouldSyncopate) {
      return {
        ...note,
        duration: note.duration * (0.6 + Math.random() * 0.4),
        velocity: Math.min(1, note.velocity * 1.15),
      };
    }
    
    return note;
  });
}

// ===================================
// Advanced Bass Patterns
// ===================================

/**
 * Generate a walking bass line with scale-based movement
 */
export function generateWalkingBassLine(
  progression: Chord[],
  _variety: number,
  rhythm: RhythmLevel
): BassNote[] {
  const bassLine: BassNote[] = [];
  const rhythmPattern = RHYTHM_PATTERNS[rhythm];
  
  progression.forEach((chord, chordIndex) => {
    const root = chord.root;
    const scaleNotes = getScaleNotes(root, 'major');
    const nextChord = progression[(chordIndex + 1) % progression.length];
    
    // 4 notes per chord for walking bass
    const notes: NoteName[] = [
      root,
      randomChoice(scaleNotes),
      randomChoice(scaleNotes),
      transposeNote(nextChord.root, Math.random() > 0.5 ? 1 : 11), // approach note
    ];
    
    notes.forEach((note, i) => {
      bassLine.push({
        note,
        duration: 1,
        velocity: rhythmPattern.dynamics[i % rhythmPattern.dynamics.length],
        octave: BASS_OCTAVE,
        chordIndex,
        style: 'walking',
      });
    });
  });
  
  return bassLine;
}

/**
 * Generate an octave-jumping bass line
 */
export function generateOctaveBassLine(
  progression: Chord[],
  variety: number,
  rhythm: RhythmLevel
): BassNote[] {
  const bassLine: BassNote[] = [];
  const rhythmPattern = RHYTHM_PATTERNS[rhythm];
  const varietyFactor = variety / 100;
  
  progression.forEach((chord, chordIndex) => {
    const root = chord.root;
    const fifth = transposeNote(root, 7);
    const notesPerChord = 2 + Math.floor(varietyFactor * 2);
    
    for (let i = 0; i < notesPerChord; i++) {
      const octave = i % 2 === 0 ? BASS_OCTAVE : BASS_OCTAVE + 1;
      const note = Math.random() < varietyFactor * 0.3 ? fifth : root;
      
      bassLine.push({
        note,
        duration: 4 / notesPerChord,
        velocity: rhythmPattern.dynamics[i % rhythmPattern.dynamics.length],
        octave,
        chordIndex,
        style: 'octave',
      });
    }
  });
  
  return bassLine;
}

/**
 * Generate a root-fifth bass line
 */
export function generateRootFifthBassLine(
  progression: Chord[],
  variety: number,
  rhythm: RhythmLevel
): BassNote[] {
  const bassLine: BassNote[] = [];
  const rhythmPattern = RHYTHM_PATTERNS[rhythm];
  const varietyFactor = variety / 100;
  
  progression.forEach((chord, chordIndex) => {
    const root = chord.root;
    const fifth = transposeNote(root, 7);
    
    // Pattern: root, fifth, root, fifth (or variations based on variety)
    const pattern = varietyFactor > 0.5
      ? [root, fifth, root, fifth]
      : [root, root, fifth, root];
    
    pattern.forEach((note, i) => {
      bassLine.push({
        note,
        duration: 1,
        velocity: rhythmPattern.dynamics[i % rhythmPattern.dynamics.length],
        octave: BASS_OCTAVE,
        chordIndex,
        style: 'fifths',
      });
    });
  });
  
  return bassLine;
}

// ===================================
// Bass Line Analysis
// ===================================

/**
 * Analyze a bass line for groove characteristics
 */
export function analyzeBassLine(bassLine: BassNote[]): {
  averageVelocity: number;
  rhythmicDensity: number;
  octaveRange: number;
  styleDistribution: Record<BassStyle, number>;
} {
  if (bassLine.length === 0) {
    return {
      averageVelocity: 0,
      rhythmicDensity: 0,
      octaveRange: 0,
      styleDistribution: { root: 0, walking: 0, syncopated: 0, octave: 0, fifths: 0 },
    };
  }
  
  const velocities = bassLine.map(n => n.velocity);
  const octaves = bassLine.map(n => n.octave);
  const styles = bassLine.map(n => n.style);
  
  const averageVelocity = velocities.reduce((a, b) => a + b, 0) / velocities.length;
  const rhythmicDensity = bassLine.length / (new Set(bassLine.map(n => n.chordIndex)).size);
  const octaveRange = Math.max(...octaves) - Math.min(...octaves);
  
  const styleDistribution: Record<BassStyle, number> = {
    root: 0,
    walking: 0,
    syncopated: 0,
    octave: 0,
    fifths: 0,
  };
  
  styles.forEach(style => {
    styleDistribution[style]++;
  });
  
  // Normalize to percentages
  Object.keys(styleDistribution).forEach(key => {
    styleDistribution[key as BassStyle] /= bassLine.length;
  });
  
  return {
    averageVelocity,
    rhythmicDensity,
    octaveRange,
    styleDistribution,
  };
}
