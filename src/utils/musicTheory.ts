/**
 * Groovy Chord Generator
 * Utility Functions - Music Theory
 * Version 2.5
 */

import type {
  NoteName,
  NoteDisplayName,
  ChordTypeName,
  ScaleName,
  Chord,
  VoicedNote,
  GenreKey,
  BassNote,
  BassStyle,
  RhythmLevel,
  HarmonyFunction,
  MoodType,
  SpiceLevel,
} from '../types';

import {
  NOTES,
  NOTE_DISPLAY,
  CHORD_TYPES,
  SCALES,
  ROMAN_NUMERALS,
  SHELL_VOICINGS,
  OPEN_VOICINGS,
  MODAL_INTERCHANGE,
  MODAL_INTERCHANGE_PROBABILITY,
  SPICE_PROBABILITY_THRESHOLDS,
  RHYTHM_PATTERNS,
  FUNCTIONAL_HARMONY,
  FUNCTIONAL_PROGRESSIONS,
  MOOD_PROFILES,
  SPICE_CONFIGS,
} from '../constants';

// ===================================
// Note Manipulation Functions
// ===================================

export function getNoteIndex(note: string): number {
  const cleanNote = note.replace('m', '');
  const notesIndex = NOTES.indexOf(cleanNote as NoteName);
  if (notesIndex !== -1) return notesIndex;
  return NOTE_DISPLAY.indexOf(cleanNote as NoteDisplayName);
}

export function transposeNote(rootNote: string, interval: number): NoteName {
  const rootIndex = getNoteIndex(rootNote);
  const newIndex = (rootIndex + interval) % 12;
  return NOTES[newIndex];
}

export function getScaleNotes(rootNote: string, scaleName: ScaleName): NoteName[] {
  const scale = SCALES[scaleName] || SCALES.major;
  return scale.map((interval) => transposeNote(rootNote, interval));
}

export function parseKey(keyString: string): { root: string; isMinor: boolean } {
  const isMinor = keyString.includes('m');
  const root = keyString.replace('m', '');
  return { root, isMinor };
}

// ===================================
// Chord Generation Functions
// ===================================

export function getChordFromDegree(
  root: string,
  degree: string,
  isMinorKey: boolean,
  scale: ScaleName
): Chord {
  const degreeMap: Record<string, number> = {
    I: 0, i: 0,
    II: 1, ii: 1,
    III: 2, iii: 2,
    IV: 3, iv: 3,
    V: 4, v: 4,
    VI: 5, vi: 5,
    VII: 6, vii: 6,
  };

  const scaleNotes = getScaleNotes(root, scale);
  const degreeIndex = degreeMap[degree];
  const chordRoot = scaleNotes[degreeIndex];

  // Determine chord quality based on degree and key
  const isUpperCase = degree === degree.toUpperCase();
  let chordType: ChordTypeName;

  if (isMinorKey) {
    const minorKeyQualities: ChordTypeName[] = ['minor', 'diminished', 'major', 'minor', 'minor', 'major', 'major'];
    chordType = isUpperCase ? 'major' : minorKeyQualities[degreeIndex];
  } else {
    const majorKeyQualities: ChordTypeName[] = ['major', 'minor', 'minor', 'major', 'major', 'minor', 'diminished'];
    chordType = isUpperCase ? 'major' : majorKeyQualities[degreeIndex];
  }

  return {
    root: chordRoot,
    type: chordType,
    degree: degree,
    numeral: ROMAN_NUMERALS[degreeIndex],
  };
}

// ===================================
// Voice Leading Functions
// ===================================

export function noteToPitch(note: NoteName, octave: number): number {
  const noteIndex = getNoteIndex(note);
  return (octave + 1) * 12 + noteIndex;
}

export function pitchToNote(pitch: number): { note: NoteName; octave: number } {
  const octave = Math.floor(pitch / 12) - 1;
  const noteIndex = pitch % 12;
  return { note: NOTES[noteIndex], octave };
}

export function getChordNotes(chord: Chord): NoteName[] {
  const intervals = CHORD_TYPES[chord.type]?.intervals || [0, 4, 7];
  return intervals.map((interval) => transposeNote(chord.root, interval));
}

export function findBestVoicing(
  chordNotes: NoteName[],
  previousVoicedNotes: VoicedNote[] | null,
  baseOctave = 4
): VoicedNote[] {
  if (!previousVoicedNotes || previousVoicedNotes.length === 0) {
    return chordNotes.map((note, index) => ({
      note,
      octave: baseOctave + Math.floor(index / 4),
      pitch: noteToPitch(note, baseOctave + Math.floor(index / 4)),
    }));
  }

  const prevCenterPitch =
    previousVoicedNotes.reduce((sum, n) => sum + n.pitch, 0) / previousVoicedNotes.length;

  const possibleVoicings: VoicedNote[][] = [];
  const minOctave = 3;
  const maxOctave = 5;

  for (let startOctave = minOctave; startOctave <= maxOctave; startOctave++) {
    for (let inversion = 0; inversion < chordNotes.length; inversion++) {
      const voicing: VoicedNote[] = [];
      for (let i = 0; i < chordNotes.length; i++) {
        const noteIndex = (i + inversion) % chordNotes.length;
        const octaveOffset = i < inversion ? 1 : 0;
        const octave = startOctave + octaveOffset;
        if (octave >= minOctave && octave <= maxOctave) {
          const pitch = noteToPitch(chordNotes[noteIndex], octave);
          voicing.push({
            note: chordNotes[noteIndex],
            octave,
            pitch,
          });
        }
      }
      if (voicing.length === chordNotes.length) {
        possibleVoicings.push(voicing);
      }
    }
  }

  let bestVoicing = possibleVoicings[0];
  let minDistance = Infinity;

  possibleVoicings.forEach((voicing) => {
    const voicingCenter = voicing.reduce((sum, n) => sum + n.pitch, 0) / voicing.length;
    const distance = Math.abs(voicingCenter - prevCenterPitch);

    let totalNoteDistance = 0;
    voicing.forEach((vNote) => {
      const closestPrev = previousVoicedNotes.reduce((closest, pNote) => {
        const dist = Math.abs(vNote.pitch - pNote.pitch);
        return dist < closest ? dist : closest;
      }, Infinity);
      totalNoteDistance += closestPrev;
    });

    const combinedDistance = distance + totalNoteDistance * 0.5;

    if (combinedDistance < minDistance) {
      minDistance = combinedDistance;
      bestVoicing = voicing;
    }
  });

  return bestVoicing;
}

export function applyVoiceLeading(progression: Chord[]): Chord[] {
  if (!progression || progression.length === 0) return progression;

  let previousVoicedNotes: VoicedNote[] | null = null;

  progression.forEach((chord) => {
    const chordNotes = getChordNotes(chord);
    const voicing = findBestVoicing(chordNotes, previousVoicedNotes, 4);
    chord.voicedNotes = voicing;
    previousVoicedNotes = voicing;
  });

  return progression;
}

// ===================================
// Advanced Chord Substitution Functions
// ===================================

export function applyAdvancedSubstitutions(
  progression: Chord[],
  root: string,
  isMinorKey: boolean
): Chord[] {
  const result: Chord[] = [];

  for (let i = 0; i < progression.length; i++) {
    const chord = progression[i];
    const nextChord = progression[i + 1];

    // Secondary Dominant
    if (nextChord && (nextChord.degree === 'V' || nextChord.degree === 'v') && Math.random() > 0.6) {
      const secondaryDomRoot = transposeNote(root, 2);
      const secondaryDom: Chord = {
        root: secondaryDomRoot,
        type: 'dominant7',
        degree: 'V/V',
        numeral: 'V/V',
        isSecondaryDominant: true,
      };
      result.push(chord);
      result.push(secondaryDom);
      continue;
    }

    // Borrowed Chord
    if (!isMinorKey && (chord.degree === 'IV' || chord.degree === 'iv') && Math.random() > 0.7) {
      const borrowedChord: Chord = {
        ...chord,
        type: 'minor',
        degree: 'iv',
        numeral: 'iv',
        isBorrowed: true,
      };
      result.push(borrowedChord);
      continue;
    }

    // Tritone Substitution
    if ((chord.degree === 'V' || chord.degree === 'v') && chord.type === 'dominant7' && Math.random() > 0.75) {
      const tritoneRoot = transposeNote(root, 1);
      const tritoneChord: Chord = {
        root: tritoneRoot,
        type: 'dominant7',
        degree: 'bII7',
        numeral: 'bII7',
        isTritoneSubstitution: true,
      };
      result.push(tritoneChord);
      continue;
    }

    result.push(chord);
  }

  return result;
}

// ===================================
// Modal Interchange Functions - v2.4
// ===================================

export function applyModalInterchange(
  progression: Chord[],
  root: string,
  isMinorKey: boolean
): Chord[] {
  const result: Chord[] = [];
  const borrowedChords = isMinorKey
    ? MODAL_INTERCHANGE.minorBorrowedFromMajor
    : MODAL_INTERCHANGE.majorBorrowedFromMinor;

  for (let i = 0; i < progression.length; i++) {
    const chord = progression[i];

    if (Math.random() < MODAL_INTERCHANGE_PROBABILITY) {
      const borrowOptions = Object.entries(borrowedChords);
      if (borrowOptions.length > 0) {
        const [symbol, borrowedInfo] = randomChoice(borrowOptions);
        const borrowedRoot = transposeNote(root, borrowedInfo.root);
        const borrowedChord: Chord = {
          root: borrowedRoot,
          type: borrowedInfo.type,
          degree: symbol,
          numeral: symbol,
          isBorrowed: true,
          borrowedDescription: borrowedInfo.description,
        };
        result.push(borrowedChord);
        continue;
      }
    }

    result.push(chord);
  }

  return result;
}

export function applyGenreVoicing(chord: Chord, genre: GenreKey): Chord {
  // Shell voicings for jazz
  if (genre === 'jazz-fusion' && SHELL_VOICINGS[chord.type]) {
    chord.shellVoicing = SHELL_VOICINGS[chord.type];
    chord.voicingType = 'shell';
  }
  // Open voicings for cinematic and indie rock
  else if ((genre === 'cinematic' || genre === 'indie-rock') && OPEN_VOICINGS[chord.type]) {
    chord.openVoicing = OPEN_VOICINGS[chord.type];
    chord.voicingType = 'open';
  }

  return chord;
}

// ===================================
// Spice It Up Functions - v2.4
// ===================================

export function spiceUpProgression(
  progression: Chord[],
  root: string,
  isMinor: boolean
): Chord[] {
  return progression.map((chord) => {
    const spicedChord = { ...chord };
    const spiceType = Math.random();

    if (spiceType < SPICE_PROBABILITY_THRESHOLDS.ADD_EXTENSION) {
      if (chord.type === 'major') {
        spicedChord.type = Math.random() > 0.5 ? 'major7' : 'add9';
      } else if (chord.type === 'minor') {
        spicedChord.type = Math.random() > 0.5 ? 'minor7' : 'minor9';
      }
    } else if (spiceType < SPICE_PROBABILITY_THRESHOLDS.TRITONE_SUB) {
      if (chord.type === 'dominant7' || chord.degree === 'V') {
        const tritoneRoot = transposeNote(chord.root, 6);
        spicedChord.root = tritoneRoot;
        spicedChord.type = 'dominant7';
        spicedChord.degree = 'bII7';
        spicedChord.numeral = 'bII7';
        spicedChord.isTritoneSubstitution = true;
      }
    } else if (spiceType < SPICE_PROBABILITY_THRESHOLDS.MODAL_INTERCHANGE) {
      if (!isMinor && chord.degree === 'IV') {
        spicedChord.type = 'minor7';
        spicedChord.degree = 'iv7';
        spicedChord.isBorrowed = true;
      } else if (!isMinor && Math.random() > 0.5) {
        const bViRoot = transposeNote(root, 8);
        spicedChord.root = bViRoot;
        spicedChord.type = 'major7';
        spicedChord.degree = 'bVImaj7';
        spicedChord.isBorrowed = true;
      }
    } else {
      if (chord.type === 'major' || chord.type === 'minor') {
        spicedChord.type = Math.random() > 0.5 ? 'sus4' : 'sus2';
      }
    }

    return spicedChord;
  });
}

// ===================================
// Bass Line Generation Functions - v2.5
// ===================================

// Bass generation constants
const BASS_CHROMATIC_PROBABILITY = 0.3;
const BASS_APPROACH_NOTE_PROBABILITY = 0.5;
const BASS_ALTERNATE_NOTE_PROBABILITY = 0.4;
const BASS_REST_PROBABILITY = 0.2;
const BASS_OCTAVE = 2;

export function generateBassLine(
  progression: Chord[],
  style: BassStyle,
  variety: number,
  rhythm: RhythmLevel
): BassNote[] {
  const bassLine: BassNote[] = [];
  const rhythmPattern = RHYTHM_PATTERNS[rhythm];
  const varietyFactor = variety / 100; // 0 to 1

  progression.forEach((chord, chordIndex) => {
    const chordNotes = getChordNotes(chord);
    const root = chord.root;
    const fifth = transposeNote(root, 7);

    switch (style) {
      case 'root': {
        // Simple root notes
        const notesPerChord = 1 + Math.floor(varietyFactor * 3);
        for (let i = 0; i < notesPerChord; i++) {
          bassLine.push({
            note: root,
            duration: 4 / notesPerChord,
            velocity: rhythmPattern.dynamics[i % rhythmPattern.dynamics.length],
            octave: BASS_OCTAVE,
            chordIndex,
            style,
          });
        }
        break;
      }

      case 'walking': {
        // Walking bass line - chromatic approach notes
        const scaleNotes = getScaleNotes(root, 'major');
        const notesPerChord = 4;
        for (let i = 0; i < notesPerChord; i++) {
          const useChromatic = Math.random() < varietyFactor * BASS_CHROMATIC_PROBABILITY;
          let note: NoteName;
          if (i === 0) {
            note = root;
          } else if (i === notesPerChord - 1 && Math.random() < BASS_APPROACH_NOTE_PROBABILITY) {
            // Approach note to next chord (semitone above or below)
            const nextChord = progression[(chordIndex + 1) % progression.length];
            note = transposeNote(nextChord.root, Math.random() > 0.5 ? 1 : 11);
          } else if (useChromatic) {
            note = transposeNote(root, randomInt(1, 11));
          } else {
            note = randomChoice(scaleNotes);
          }
          bassLine.push({
            note,
            duration: 1,
            velocity: rhythmPattern.dynamics[i % rhythmPattern.dynamics.length],
            octave: BASS_OCTAVE,
            chordIndex,
            style,
          });
        }
        break;
      }

      case 'syncopated': {
        // Syncopated rhythms with rests
        const patterns = [
          [1, 0.5, 0.5, 1, 1],
          [0.5, 0.5, 1, 0.5, 0.5, 1],
          [1.5, 0.5, 1, 1],
        ];
        const pattern = randomChoice(patterns);
        pattern.forEach((dur, i) => {
          const isRest = Math.random() < BASS_REST_PROBABILITY * (1 - varietyFactor);
          if (!isRest) {
            const useAlternate = Math.random() < varietyFactor * BASS_ALTERNATE_NOTE_PROBABILITY;
            const note = useAlternate ? randomChoice(chordNotes) : root;
            bassLine.push({
              note,
              duration: dur,
              velocity: rhythmPattern.dynamics[i % rhythmPattern.dynamics.length],
              octave: BASS_OCTAVE,
              chordIndex,
              style,
            });
          }
        });
        break;
      }

      case 'octave': {
        // Octave jumps
        const notesPerChord = 2 + Math.floor(varietyFactor * 2);
        for (let i = 0; i < notesPerChord; i++) {
          const octave = i % 2 === 0 ? BASS_OCTAVE : BASS_OCTAVE + 1;
          const useAlternate = Math.random() < varietyFactor * BASS_CHROMATIC_PROBABILITY;
          const note = useAlternate ? fifth : root;
          bassLine.push({
            note,
            duration: 4 / notesPerChord,
            velocity: rhythmPattern.dynamics[i % rhythmPattern.dynamics.length],
            octave,
            chordIndex,
            style,
          });
        }
        break;
      }

      case 'fifths': {
        // Root and fifth pattern
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
            style,
          });
        });
        break;
      }
    }
  });

  return bassLine;
}

// ===================================
// Phase 1: Functional Harmony Functions
// ===================================

/**
 * Generate a chord progression using functional harmony principles
 * Ensures smooth progressions following Tonic -> Subdominant -> Dominant -> Tonic patterns
 */
export function generateFunctionalProgression(
  root: string,
  isMinorKey: boolean,
  length: number = 4,
  mood: MoodType = 'happy'
): Chord[] {
  const moodProfile = MOOD_PROFILES[mood];
  const scale = randomChoice(moodProfile.scales);
  
  // Choose a functional progression template
  const template = randomChoice(FUNCTIONAL_PROGRESSIONS);
  
  // Extend or truncate template to match desired length
  const functions: HarmonyFunction[] = [];
  for (let i = 0; i < length; i++) {
    functions.push(template[i % template.length]);
  }
  
  // Generate chords based on functions
  const progression: Chord[] = [];
  
  functions.forEach((func) => {
    const chord = generateChordFromFunction(
      root,
      isMinorKey,
      func,
      scale,
      moodProfile.chordTypes,
      moodProfile.tensionRange
    );
    progression.push(chord);
  });
  
  return progression;
}

/**
 * Generate a chord from a harmonic function
 */
export function generateChordFromFunction(
  root: string,
  _isMinorKey: boolean,
  func: HarmonyFunction,
  _scale: ScaleName,
  allowedTypes: ChordTypeName[],
  tensionRange: [number, number]
): Chord {
  const functionalChords = FUNCTIONAL_HARMONY[func];
  
  // Filter by tension range
  const validChords = functionalChords.filter(
    fc => fc.tension >= tensionRange[0] && fc.tension <= tensionRange[1]
  );
  
  const chosenChord = validChords.length > 0
    ? randomChoice(validChords)
    : randomChoice(functionalChords);
  
  // Determine chord type
  const validTypes = chosenChord.chordTypes.filter(t => allowedTypes.includes(t));
  const chordType = validTypes.length > 0
    ? randomChoice(validTypes)
    : randomChoice(chosenChord.chordTypes);
  
  // Map each degree symbol to its semitone interval and display numeral
  // Note: semitoneInterval is used to calculate the chord root note,
  // while displayNumeral is used for UI display (falls back to the degree symbol itself)
  const degreeInfo: Record<string, { semitoneInterval: number; displayNumeral: string }> = {
    'I': { semitoneInterval: 0, displayNumeral: 'I' },
    'i': { semitoneInterval: 0, displayNumeral: 'I' },
    'II': { semitoneInterval: 2, displayNumeral: 'II' },
    'ii': { semitoneInterval: 2, displayNumeral: 'II' },
    'III': { semitoneInterval: 4, displayNumeral: 'III' },
    'iii': { semitoneInterval: 4, displayNumeral: 'III' },
    'IV': { semitoneInterval: 5, displayNumeral: 'IV' },
    'iv': { semitoneInterval: 5, displayNumeral: 'IV' },
    'V': { semitoneInterval: 7, displayNumeral: 'V' },
    'v': { semitoneInterval: 7, displayNumeral: 'V' },
    'VI': { semitoneInterval: 9, displayNumeral: 'VI' },
    'vi': { semitoneInterval: 9, displayNumeral: 'VI' },
    'VII': { semitoneInterval: 11, displayNumeral: 'VII' },
    'vii': { semitoneInterval: 11, displayNumeral: 'VII' },
    'bII': { semitoneInterval: 1, displayNumeral: 'bII' },
    'bVII': { semitoneInterval: 10, displayNumeral: 'bVII' },
    'bVI': { semitoneInterval: 8, displayNumeral: 'bVI' },
    'bIII': { semitoneInterval: 3, displayNumeral: 'bIII' },
    '#iv': { semitoneInterval: 6, displayNumeral: '#iv' },
  };
  
  const info = degreeInfo[chosenChord.degree] || { semitoneInterval: 0, displayNumeral: chosenChord.degree };
  const chordRoot = transposeNote(root, info.semitoneInterval);
  
  return {
    root: chordRoot,
    type: chordType,
    degree: chosenChord.degree,
    numeral: info.displayNumeral,
    harmonyFunction: func,
  };
}

/**
 * Analyze a progression's harmonic tension
 */
export function analyzeProgressionTension(progression: Chord[]): number[] {
  return progression.map((chord) => {
    // Find the chord in functional harmony groups
    for (const func of Object.keys(FUNCTIONAL_HARMONY) as HarmonyFunction[]) {
      const matches = FUNCTIONAL_HARMONY[func].filter(fc => fc.degree === chord.degree);
      if (matches.length > 0) {
        return matches[0].tension;
      }
    }
    return 0.5; // Default tension
  });
}

// ===================================
// Phase 3: Spice Level Control Functions
// ===================================

/**
 * Apply spice level to a chord, upgrading it based on complexity
 */
export function applySpiceToChord(chord: Chord, level: SpiceLevel): Chord {
  const config = SPICE_CONFIGS[level];
  const spicedChord = { ...chord };
  
  if (!config.allowExtensions) {
    // Mild: Keep as triads
    if (spicedChord.type.includes('7') || spicedChord.type.includes('9')) {
      // Downgrade to basic triad
      if (spicedChord.type.includes('minor')) {
        spicedChord.type = 'minor';
      } else if (spicedChord.type.includes('dim')) {
        spicedChord.type = 'diminished';
      } else if (spicedChord.type.includes('aug')) {
        spicedChord.type = 'augmented';
      } else {
        spicedChord.type = 'major';
      }
    }
    return spicedChord;
  }
  
  // Medium and above: Allow 7ths
  if (config.maxExtension >= 7) {
    if (chord.type === 'major' && Math.random() > 0.5) {
      spicedChord.type = 'major7';
    } else if (chord.type === 'minor' && Math.random() > 0.5) {
      spicedChord.type = 'minor7';
    }
  }
  
  // Hot and above: Allow 9ths and alterations
  if (config.maxExtension >= 9 && config.allowAlterations) {
    if (spicedChord.type === 'major7' && Math.random() > 0.6) {
      spicedChord.type = 'major9';
    } else if (spicedChord.type === 'minor7' && Math.random() > 0.6) {
      spicedChord.type = 'minor9';
    } else if (spicedChord.type === 'major' && Math.random() > 0.7) {
      spicedChord.type = 'add9';
    }
  }
  
  // Fire level: Maximum complexity
  if (level === 'fire' && Math.random() > 0.5) {
    // Add sus variations
    if (Math.random() > 0.7) {
      if (spicedChord.type === 'major') {
        spicedChord.type = Math.random() > 0.5 ? 'sus4' : 'sus2';
      }
    }
  }
  
  return spicedChord;
}

/**
 * Apply spice level to entire progression
 */
export function applySpiceToProgression(
  progression: Chord[],
  level: SpiceLevel
): Chord[] {
  return progression.map(chord => applySpiceToChord(chord, level));
}

/**
 * Enhanced voice leading with melodic top voice
 * Ensures the top note of each chord creates a smooth melodic line
 */
export function applyMelodicVoiceLeading(progression: Chord[]): Chord[] {
  if (!progression || progression.length === 0) return progression;
  
  let previousTopNote: VoicedNote | null = null;
  
  progression.forEach((chord) => {
    const chordNotes = getChordNotes(chord);
    const voicing = findBestVoicing(
      chordNotes,
      previousTopNote ? [previousTopNote] : null,
      4
    );
    
    // Sort by pitch to find top note
    const sortedVoicing = [...voicing].sort((a, b) => b.pitch - a.pitch);
    
    chord.voicedNotes = voicing;
    previousTopNote = sortedVoicing[0];
  });
  
  return progression;
}

// ===================================
// Helper Functions
// ===================================

export function randomChoice<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

export function randomInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

// ===================================
// Time Formatting
// ===================================

export function getTimeAgo(timestamp: number): string {
  const seconds = Math.floor((Date.now() - timestamp) / 1000);

  if (seconds < 60) return 'Just now';
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
  return `${Math.floor(seconds / 86400)}d ago`;
}
