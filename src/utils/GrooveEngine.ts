/**
 * Groovy Chord Generator
 * GrooveEngine - Rhythmic Sequencing Module
 * Version 2.5 - Phase 2
 */

import type {
  Chord,
  GrooveTemplate,
  BassNote,
  NoteName,
  RhythmLevel,
} from '../types';

import { GROOVE_PATTERNS, RHYTHM_PATTERNS } from '../constants';
import { transposeNote } from './musicTheory';

// ===================================
// Groove Application Functions
// ===================================

/**
 * Apply a groove template to a chord progression
 * Modifies chord timing and dynamics based on the selected groove pattern
 */
export function applyGrooveToProgression(
  progression: Chord[],
  template: GrooveTemplate
): Chord[] {
  const groove = GROOVE_PATTERNS[template];
  
  return progression.map((chord, index) => {
    const beatPosition = (index * 4) % groove.beatPattern.length;
    const accentMultiplier = groove.accentBeats.includes(beatPosition) ? 1.2 : 1.0;
    
    return {
      ...chord,
      grooveIntensity: groove.beatPattern[beatPosition] * accentMultiplier,
      swingOffset: groove.swingAmount * (index % 2 === 1 ? 1 : 0),
    };
  });
}

/**
 * Calculate swing timing offset for a given beat
 */
export function calculateSwingOffset(
  beatIndex: number,
  swingAmount: number,
  tempo: number
): number {
  // Swing affects off-beats (odd-numbered beats in a pair)
  if (beatIndex % 2 === 1) {
    const beatDuration = 60 / tempo;
    return beatDuration * swingAmount * 0.33; // Max swing is 33% of beat duration
  }
  return 0;
}

/**
 * Generate rhythmic mask for chord slicing
 * Returns an array of velocity multipliers for each subdivision
 */
export function generateRhythmicMask(
  template: GrooveTemplate,
  beatsPerChord: number = 4,
  subdivisionsPerBeat: number = 4
): number[] {
  const groove = GROOVE_PATTERNS[template];
  const totalSubdivisions = beatsPerChord * subdivisionsPerBeat;
  const mask: number[] = [];
  
  for (let i = 0; i < totalSubdivisions; i++) {
    const patternIndex = i % groove.beatPattern.length;
    // Check if current subdivision index matches any accent beat position
    const isAccent = groove.accentBeats.includes(patternIndex);
    
    let velocity = groove.beatPattern[patternIndex];
    if (isAccent) {
      velocity = Math.min(1, velocity * 1.3);
    }
    
    mask.push(velocity);
  }
  
  return mask;
}

// ===================================
// Bass Line Interplay Functions
// ===================================

const BASS_OCTAVE = 2;

/**
 * Generate a groove-aware bass line with chromatic, octave, and 5th approaches
 */
export function generateGroovyBassLine(
  progression: Chord[],
  template: GrooveTemplate,
  variety: number,
  rhythm: RhythmLevel
): BassNote[] {
  const bassLine: BassNote[] = [];
  const groove = GROOVE_PATTERNS[template];
  const rhythmPattern = RHYTHM_PATTERNS[rhythm];
  const varietyFactor = variety / 100;

  progression.forEach((chord, chordIndex) => {
    const root = chord.root;
    const fifth = transposeNote(root, 7);
    const octaveUp = root;
    
    // Downbeat - always emphasize root
    bassLine.push({
      note: root,
      duration: 1,
      velocity: 0.9 + (groove.accentBeats[0] === 0 ? 0.1 : 0),
      octave: BASS_OCTAVE,
      chordIndex,
      style: 'root',
    });
    
    // Generate offbeat notes based on groove and variety
    const offbeatCount = 2 + Math.floor(varietyFactor * 2);
    
    for (let i = 1; i <= offbeatCount; i++) {
      const beatPosition = i;
      const isAccent = groove.accentBeats.includes(beatPosition);
      
      // Determine note choice based on variety and position
      let note: NoteName;
      let octave = BASS_OCTAVE;
      
      const random = Math.random();
      
      if (i === offbeatCount && varietyFactor > 0.3) {
        // Approach note to next chord (chromatic)
        const nextChord = progression[(chordIndex + 1) % progression.length];
        const approachDirection = Math.random() > 0.5 ? 1 : 12 - 1; // semitone above or below (12 - 1 = 11, a semitone below)
        note = transposeNote(nextChord.root, approachDirection);
      } else if (random < 0.3 * varietyFactor) {
        // Fifth approach
        note = fifth;
      } else if (random < 0.5 * varietyFactor) {
        // Octave jump
        note = octaveUp;
        octave = BASS_OCTAVE + 1;
      } else {
        // Root with slight variation
        note = root;
      }
      
      const velocity = rhythmPattern.dynamics[i % rhythmPattern.dynamics.length];
      const adjustedVelocity = isAccent ? Math.min(1, velocity * 1.2) : velocity;
      
      bassLine.push({
        note,
        duration: 4 / (offbeatCount + 1),
        velocity: adjustedVelocity,
        octave,
        chordIndex,
        style: octave > BASS_OCTAVE ? 'octave' : note === fifth ? 'fifths' : 'root',
      });
    }
  });

  return bassLine;
}

/**
 * Apply syncopation to a bass line
 */
export function applySyncopation(
  bassLine: BassNote[],
  syncopationAmount: number
): BassNote[] {
  if (syncopationAmount <= 0) return bassLine;
  
  return bassLine.map((note) => {
    // Skip first notes of each chord (downbeats)
    if (note.duration === 1) return note;
    
    const shouldSyncopate = Math.random() < syncopationAmount;
    
    if (shouldSyncopate) {
      return {
        ...note,
        duration: note.duration * (0.5 + Math.random() * 0.5), // Shorten note
        velocity: Math.min(1, note.velocity * 1.1), // Slight accent
      };
    }
    
    return note;
  });
}

// ===================================
// Groove Analysis Functions
// ===================================

/**
 * Analyze a groove template and return its characteristics
 */
export function analyzeGroove(template: GrooveTemplate): {
  complexity: number;
  energy: number;
  syncopation: number;
} {
  const groove = GROOVE_PATTERNS[template];
  
  // Calculate complexity based on pattern variation
  const uniqueValues = new Set(groove.beatPattern).size;
  const complexity = uniqueValues / groove.beatPattern.length;
  
  // Calculate energy based on average beat intensity
  const energy = groove.beatPattern.reduce((a, b) => a + b, 0) / groove.beatPattern.length;
  
  // Calculate syncopation based on off-beat accents
  const offbeatAccents = groove.accentBeats.filter(b => b % 4 !== 0).length;
  const syncopation = offbeatAccents / groove.accentBeats.length;
  
  return { complexity, energy, syncopation };
}

/**
 * Suggest a groove template based on genre
 */
export function suggestGrooveTemplate(
  genre: string
): GrooveTemplate {
  const suggestions: Record<string, GrooveTemplate> = {
    'funk': 'funk-syncopation',
    'soulful-rnb': 'neo-soul-swing',
    'energetic-edm': 'four-on-floor',
    'chill-lofi': 'neo-soul-swing',
    'jazz-fusion': 'shuffle',
    'dark-trap': 'half-time',
    'happy-pop': 'straight',
    'cinematic': 'half-time',
    'indie-rock': 'straight',
    'reggae': 'shuffle',
    'blues': 'shuffle',
    'country': 'straight',
  };
  
  return suggestions[genre] || 'straight';
}
