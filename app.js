/**
 * Groovy Chord Progression Generator
 * app.js - Main Application Logic
 * Created by Edgar Valle
 * Version 2.4 - Next-Level Performance, UI, and Unique Chord Progression Features
 */

// ===================================
// Music Theory Constants & Data
// ===================================

const NOTES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
const NOTE_DISPLAY = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];

// Chord types with intervals (semitones from root)
const CHORD_TYPES = {
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
    major9: { intervals: [0, 4, 7, 11, 14], symbol: 'maj9', name: 'Major 9th' }
};

// Scale patterns (intervals in semitones)
const SCALES = {
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
    blues: [0, 3, 5, 6, 7, 10]
};

// Roman numerals for chord degrees
const ROMAN_NUMERALS = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];

// Genre-specific progressions and characteristics
const GENRE_PROFILES = {
    'happy-pop': {
        name: 'Happy Upbeat Pop',
        scale: 'major',
        progressions: [
            ['I', 'V', 'vi', 'IV'],
            ['I', 'IV', 'V', 'I'],
            ['I', 'vi', 'IV', 'V'],
            ['I', 'IV', 'vi', 'V'],
            ['vi', 'IV', 'I', 'V']
        ],
        chordTypes: ['major', 'minor', 'sus2', 'add9'],
        melodyScale: 'pentatonicMajor',
        tempo: 120
    },
    'chill-lofi': {
        name: 'Chill Lo-Fi',
        scale: 'minor',
        progressions: [
            ['ii', 'V', 'I', 'vi'],
            ['I', 'vi', 'ii', 'V'],
            ['vi', 'ii', 'V', 'I'],
            ['I', 'IV', 'vi', 'V']
        ],
        chordTypes: ['major7', 'minor7', 'dominant7', 'minor9'],
        melodyScale: 'pentatonicMinor',
        tempo: 85
    },
    'energetic-edm': {
        name: 'Energetic EDM',
        scale: 'major',
        progressions: [
            ['I', 'V', 'vi', 'IV'],
            ['vi', 'IV', 'I', 'V'],
            ['I', 'IV', 'I', 'V'],
            ['vi', 'IV', 'V', 'I']
        ],
        chordTypes: ['major', 'minor', 'sus4'],
        melodyScale: 'major',
        tempo: 128
    },
    'soulful-rnb': {
        name: 'Soulful R&B',
        scale: 'minor',
        progressions: [
            ['i', 'VII', 'VI', 'V'],
            ['i', 'iv', 'VII', 'III'],
            ['VI', 'VII', 'i', 'i'],
            ['i', 'VI', 'III', 'VII']
        ],
        chordTypes: ['minor7', 'major7', 'dominant7', 'minor9', 'major9'],
        melodyScale: 'pentatonicMinor',
        tempo: 90
    },
    'jazz-fusion': {
        name: 'Jazz Fusion',
        scale: 'dorian',
        progressions: [
            ['ii', 'V', 'I', 'vi'],
            ['I', 'vi', 'ii', 'V'],
            ['iii', 'vi', 'ii', 'V'],
            ['I', 'IV', 'iii', 'vi', 'ii', 'V', 'I']
        ],
        chordTypes: ['major7', 'minor7', 'dominant7', 'halfDim7', 'diminished7', 'minor9', 'major9'],
        melodyScale: 'dorian',
        tempo: 110
    },
    'dark-trap': {
        name: 'Dark Deep Trap',
        scale: 'harmonicMinor',
        progressions: [
            ['i', 'VI', 'III', 'VII'],
            ['i', 'iv', 'VI', 'V'],
            ['i', 'VII', 'VI', 'VII'],
            ['i', 'v', 'VI', 'iv']
        ],
        chordTypes: ['minor', 'diminished', 'minor7', 'halfDim7'],
        melodyScale: 'harmonicMinor',
        tempo: 140
    },
    'cinematic': {
        name: 'Cinematic Epic',
        scale: 'minor',
        progressions: [
            ['i', 'VI', 'III', 'VII'],
            ['i', 'iv', 'V', 'i'],
            ['VI', 'VII', 'i', 'V'],
            ['i', 'III', 'VII', 'VI']
        ],
        chordTypes: ['minor', 'major', 'sus4', 'augmented'],
        melodyScale: 'minor',
        tempo: 100
    },
    'indie-rock': {
        name: 'Indie Rock',
        scale: 'major',
        progressions: [
            ['I', 'iii', 'IV', 'V'],
            ['I', 'V', 'vi', 'iii', 'IV'],
            ['I', 'IV', 'ii', 'V'],
            ['vi', 'IV', 'I', 'V']
        ],
        chordTypes: ['major', 'minor', 'sus2', 'add9'],
        melodyScale: 'major',
        tempo: 115
    }
};

// Complexity settings
const COMPLEXITY_SETTINGS = {
    simple: { chordCount: [3, 4], useExtensions: false, variations: 1 },
    medium: { chordCount: [4, 5], useExtensions: true, variations: 2 },
    complex: { chordCount: [6, 8], useExtensions: true, variations: 3 },
    advanced: { chordCount: [8, 12], useExtensions: true, variations: 4 }
};

// Rhythm patterns based on strength
const RHYTHM_PATTERNS = {
    soft: {
        name: 'Soft & Gentle',
        durations: [4, 2, 2],
        dynamics: [0.5, 0.4, 0.6],
        melodyDensity: 0.3
    },
    moderate: {
        name: 'Moderate',
        durations: [2, 2, 1, 1],
        dynamics: [0.7, 0.5, 0.8, 0.6],
        melodyDensity: 0.5
    },
    strong: {
        name: 'Strong & Punchy',
        durations: [1, 1, 1, 1],
        dynamics: [0.9, 0.7, 0.85, 0.75],
        melodyDensity: 0.7
    },
    intense: {
        name: 'Intense & Driving',
        durations: [0.5, 0.5, 1, 0.5, 0.5],
        dynamics: [1, 0.8, 0.95, 0.85, 0.9],
        melodyDensity: 0.9
    }
};

// ===================================
// Smart Presets - v2.4
// ===================================

const SMART_PRESETS = {
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
        useAdvancedTheory: true
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
        useAdvancedTheory: true
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
        useAdvancedTheory: false
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
        useAdvancedTheory: true
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
        useAdvancedTheory: true
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
        useAdvancedTheory: true
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
        useAdvancedTheory: false
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
        useAdvancedTheory: false
    }
};

// Modal Interchange / Borrowed Chords - v2.4
const MODAL_INTERCHANGE = {
    // Chords borrowed from parallel minor into major key
    majorBorrowedFromMinor: {
        'iv': { root: 3, type: 'minor', symbol: 'iv', description: 'Minor iv from parallel minor' },
        'bVII': { root: 10, type: 'major', symbol: 'bVII', description: 'Flat VII from parallel minor' },
        'bVI': { root: 8, type: 'major', symbol: 'bVI', description: 'Flat VI from parallel minor' },
        'bIII': { root: 3, type: 'major', symbol: 'bIII', description: 'Flat III from parallel minor' },
        'viio7': { root: 11, type: 'diminished7', symbol: 'viio7', description: 'Diminished 7 from harmonic minor' }
    },
    // Chords borrowed from parallel major into minor key
    minorBorrowedFromMajor: {
        'IV': { root: 5, type: 'major', symbol: 'IV', description: 'Major IV from parallel major' },
        'I': { root: 0, type: 'major', symbol: 'I', description: 'Major I (Picardy third)' },
        'ii': { root: 2, type: 'minor', symbol: 'ii', description: 'Minor ii from parallel major' }
    }
};

// Shell voicing patterns - v2.4
const SHELL_VOICINGS = {
    // Shell voicings use only 3rds and 7ths (omitting root and 5th)
    major7: { intervals: [4, 11], name: 'Shell Maj7' },
    minor7: { intervals: [3, 10], name: 'Shell m7' },
    dominant7: { intervals: [4, 10], name: 'Shell 7' },
    halfDim7: { intervals: [3, 10], name: 'Shell m7b5' }
};

// Open voicing patterns (spread across octaves) - v2.4
const OPEN_VOICINGS = {
    major: { intervals: [0, 7, 16], name: 'Open Major' },
    minor: { intervals: [0, 7, 15], name: 'Open Minor' },
    major7: { intervals: [0, 11, 16], name: 'Open Maj7' },
    minor7: { intervals: [0, 10, 15], name: 'Open m7' },
    dominant7: { intervals: [0, 10, 16], name: 'Open 7' }
};

// ===================================
// Application State
// ===================================

const AppState = {
    currentProgression: [],
    currentMelody: [],
    currentKey: 'C',
    isMinorKey: false,
    genre: 'happy-pop',
    complexity: 'medium',
    rhythm: 'moderate',
    tempo: 120,
    isPlaying: false,
    pianoRollNotes: [],
    audioContext: null,
    oscillators: [],
    masterVolume: 0.8,
    soundType: 'sine',
    showNumerals: true,
    showTips: true,
    currentTab: 'generator',
    onboardingComplete: false,
    pianoRollZoom: 1,
    useVoiceLeading: false,
    useAdvancedTheory: false,
    envelope: {
        attack: 0.05,
        decay: 0.1,
        sustain: 0.6,
        release: 0.5
    },
    // v2.4 New State Properties
    swing: 0,  // 0-1, humanization amount
    useModalInterchange: false,
    useShellVoicing: false,
    currentPreset: null,
    progressionHistory: [],  // Last 5 progressions
    wizardStep: 0,
    wizardActive: false
};

// ===================================
// Utility Functions
// ===================================

function getNoteIndex(note) {
    const cleanNote = note.replace('m', '');
    return NOTES.indexOf(cleanNote) !== -1 ? 
        NOTES.indexOf(cleanNote) : 
        NOTE_DISPLAY.indexOf(cleanNote);
}

function transposeNote(rootNote, interval) {
    const rootIndex = getNoteIndex(rootNote);
    const newIndex = (rootIndex + interval) % 12;
    return NOTES[newIndex];
}

function getScaleNotes(rootNote, scaleName) {
    const scale = SCALES[scaleName] || SCALES.major;
    return scale.map(interval => transposeNote(rootNote, interval));
}

function randomChoice(arr) {
    return arr[Math.floor(Math.random() * arr.length)];
}

function randomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

// LocalStorage helpers
function saveToStorage(key, value) {
    try {
        localStorage.setItem(key, JSON.stringify(value));
    } catch (e) {
        console.warn('LocalStorage not available:', e);
    }
}

function loadFromStorage(key, defaultValue) {
    try {
        const stored = localStorage.getItem(key);
        return stored ? JSON.parse(stored) : defaultValue;
    } catch (e) {
        return defaultValue;
    }
}

// ===================================
// Chord Generation Logic
// ===================================

function parseKey(keyString) {
    const isMinor = keyString.includes('m');
    const root = keyString.replace('m', '');
    return { root, isMinor };
}

function getChordFromDegree(root, degree, isMinorKey, scale) {
    const degreeMap = {
        'I': 0, 'i': 0,
        'II': 1, 'ii': 1,
        'III': 2, 'iii': 2,
        'IV': 3, 'iv': 3,
        'V': 4, 'v': 4,
        'VI': 5, 'vi': 5,
        'VII': 6, 'vii': 6
    };

    const scaleNotes = getScaleNotes(root, scale);
    const degreeIndex = degreeMap[degree];
    const chordRoot = scaleNotes[degreeIndex];
    
    // Determine chord quality based on degree and key
    const isUpperCase = degree === degree.toUpperCase();
    let chordType;
    
    if (isMinorKey) {
        // Minor key chord qualities
        const minorKeyQualities = ['minor', 'diminished', 'major', 'minor', 'minor', 'major', 'major'];
        chordType = isUpperCase ? 'major' : minorKeyQualities[degreeIndex];
    } else {
        // Major key chord qualities
        const majorKeyQualities = ['major', 'minor', 'minor', 'major', 'major', 'minor', 'diminished'];
        chordType = isUpperCase ? 'major' : majorKeyQualities[degreeIndex];
    }

    return {
        root: chordRoot,
        type: chordType,
        degree: degree,
        numeral: ROMAN_NUMERALS[degreeIndex]
    };
}

// ===================================
// Voice Leading Functions
// ===================================

/**
 * Convert a note name and octave to a MIDI-like pitch number
 * C4 = 60, C#4 = 61, etc.
 */
function noteToPitch(note, octave) {
    const noteIndex = getNoteIndex(note);
    return (octave + 1) * 12 + noteIndex;
}

/**
 * Convert a pitch number back to note name and octave
 */
function pitchToNote(pitch) {
    const octave = Math.floor(pitch / 12) - 1;
    const noteIndex = pitch % 12;
    return { note: NOTES[noteIndex], octave };
}

/**
 * Get the base notes of a chord (without octave information)
 */
function getChordNotes(chord) {
    const intervals = CHORD_TYPES[chord.type]?.intervals || [0, 4, 7];
    return intervals.map(interval => transposeNote(chord.root, interval));
}

/**
 * Find the best inversion of a chord to minimize voice leading distance
 * from the previous chord's voiced notes
 */
function findBestVoicing(chordNotes, previousVoicedNotes, baseOctave = 4) {
    if (!previousVoicedNotes || previousVoicedNotes.length === 0) {
        // First chord: use root position centered around baseOctave
        return chordNotes.map((note, index) => ({
            note,
            octave: baseOctave + Math.floor(index / 4),
            pitch: noteToPitch(note, baseOctave + Math.floor(index / 4))
        }));
    }
    
    // Calculate center pitch of previous chord
    const prevCenterPitch = previousVoicedNotes.reduce((sum, n) => sum + n.pitch, 0) / previousVoicedNotes.length;
    
    // Generate all possible voicings within a reasonable range (octave 3-5)
    const possibleVoicings = [];
    const minOctave = 3;
    const maxOctave = 5;
    
    // Try different starting octaves and inversions
    for (let startOctave = minOctave; startOctave <= maxOctave; startOctave++) {
        // Generate all inversions
        for (let inversion = 0; inversion < chordNotes.length; inversion++) {
            const voicing = [];
            for (let i = 0; i < chordNotes.length; i++) {
                const noteIndex = (i + inversion) % chordNotes.length;
                const octaveOffset = i < inversion ? 1 : 0;
                const octave = startOctave + octaveOffset;
                if (octave >= minOctave && octave <= maxOctave) {
                    const pitch = noteToPitch(chordNotes[noteIndex], octave);
                    voicing.push({
                        note: chordNotes[noteIndex],
                        octave,
                        pitch
                    });
                }
            }
            if (voicing.length === chordNotes.length) {
                possibleVoicings.push(voicing);
            }
        }
    }
    
    // Find the voicing with minimum total distance from previous chord
    let bestVoicing = possibleVoicings[0];
    let minDistance = Infinity;
    
    possibleVoicings.forEach(voicing => {
        // Calculate total movement distance
        const voicingCenter = voicing.reduce((sum, n) => sum + n.pitch, 0) / voicing.length;
        const distance = Math.abs(voicingCenter - prevCenterPitch);
        
        // Also consider individual note distances
        let totalNoteDistance = 0;
        voicing.forEach(vNote => {
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

/**
 * Apply voice leading to an entire chord progression
 * Modifies the progression in-place by adding voicedNotes to each chord
 */
function applyVoiceLeading(progression) {
    if (!progression || progression.length === 0) return progression;
    
    let previousVoicedNotes = null;
    
    progression.forEach(chord => {
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

/**
 * Apply secondary dominants, borrowed chords, and tritone substitutions
 * Only applies when complexity is 'complex' or 'advanced'
 */
function applyAdvancedSubstitutions(progression, root, isMinorKey) {
    const result = [];
    
    for (let i = 0; i < progression.length; i++) {
        const chord = progression[i];
        const nextChord = progression[i + 1];
        
        // Secondary Dominant: Insert V/V before V chord
        if (nextChord && (nextChord.degree === 'V' || nextChord.degree === 'v') && Math.random() > 0.6) {
            // V/V is a dominant 7th built on the 2nd scale degree (II7)
            const secondaryDomRoot = transposeNote(root, 2); // Major 2nd up from root
            const secondaryDom = {
                root: secondaryDomRoot,
                type: 'dominant7',
                degree: 'V/V',
                numeral: 'V/V',
                isSecondaryDominant: true
            };
            result.push(chord);
            result.push(secondaryDom);
            continue;
        }
        
        // Borrowed Chord: Swap major IV for minor iv (modal interchange)
        if (!isMinorKey && (chord.degree === 'IV' || chord.degree === 'iv') && Math.random() > 0.7) {
            const borrowedChord = {
                ...chord,
                type: 'minor',
                degree: 'iv',
                numeral: 'iv',
                isBorrowed: true
            };
            result.push(borrowedChord);
            continue;
        }
        
        // Tritone Substitution: Swap V7 for bII7
        // bII7 is the tritone substitution - it's a minor 2nd up from the root (or a tritone from V)
        if ((chord.degree === 'V' || chord.degree === 'v') && chord.type === 'dominant7' && Math.random() > 0.75) {
            const tritoneRoot = transposeNote(root, 1); // bII is a minor 2nd up from root
            const tritoneChord = {
                root: tritoneRoot,
                type: 'dominant7',
                degree: 'bII7',
                numeral: 'bII7',
                isTritoneSubstitution: true
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

/**
 * Apply modal interchange (borrowed chords from parallel key)
 * Returns a modified chord progression with borrowed chords
 */
function applyModalInterchange(progression, root, isMinorKey) {
    const result = [];
    const borrowedChords = isMinorKey 
        ? MODAL_INTERCHANGE.minorBorrowedFromMajor 
        : MODAL_INTERCHANGE.majorBorrowedFromMinor;
    
    for (let i = 0; i < progression.length; i++) {
        const chord = progression[i];
        
        // Randomly decide to apply modal interchange (30% chance)
        if (Math.random() > 0.7) {
            const borrowOptions = Object.entries(borrowedChords);
            if (borrowOptions.length > 0) {
                const [symbol, borrowedInfo] = randomChoice(borrowOptions);
                const borrowedRoot = transposeNote(root, borrowedInfo.root);
                const borrowedChord = {
                    root: borrowedRoot,
                    type: borrowedInfo.type,
                    degree: symbol,
                    numeral: symbol,
                    isBorrowed: true,
                    borrowedDescription: borrowedInfo.description
                };
                result.push(borrowedChord);
                continue;
            }
        }
        
        result.push(chord);
    }
    
    return result;
}

/**
 * Apply genre-specific voicing (shell voicings for jazz, open voicings for cinematic)
 */
function applyGenreVoicing(chord, genre) {
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
// Spice It Up - Chord Substitutions v2.4
// ===================================

/**
 * "Spice It Up" - Apply jazzy/interesting chord substitutions to the current progression
 */
function spiceItUp() {
    if (AppState.currentProgression.length === 0) {
        return;
    }
    
    const { root, isMinor } = parseKey(AppState.currentKey);
    const newProgression = AppState.currentProgression.map((chord, index) => {
        // Create a copy of the chord
        const spicedChord = { ...chord };
        
        // Apply different substitution types based on random selection
        const spiceType = Math.random();
        
        if (spiceType < 0.25) {
            // Add 7th extension
            if (chord.type === 'major') {
                spicedChord.type = Math.random() > 0.5 ? 'major7' : 'add9';
            } else if (chord.type === 'minor') {
                spicedChord.type = Math.random() > 0.5 ? 'minor7' : 'minor9';
            }
        } else if (spiceType < 0.5) {
            // Tritone substitution for dominant chords
            if (chord.type === 'dominant7' || chord.degree === 'V') {
                const tritoneRoot = transposeNote(chord.root, 6); // Tritone = 6 semitones
                spicedChord.root = tritoneRoot;
                spicedChord.type = 'dominant7';
                spicedChord.degree = 'bII7';
                spicedChord.numeral = 'bII7';
                spicedChord.isTritoneSubstitution = true;
            }
        } else if (spiceType < 0.75) {
            // Modal interchange - borrow from parallel key
            if (!isMinor && chord.degree === 'IV') {
                spicedChord.type = 'minor7';
                spicedChord.degree = 'iv7';
                spicedChord.isBorrowed = true;
            } else if (!isMinor && Math.random() > 0.5) {
                // Add bVI or bVII
                const bViRoot = transposeNote(root, 8);
                spicedChord.root = bViRoot;
                spicedChord.type = 'major7';
                spicedChord.degree = 'bVImaj7';
                spicedChord.isBorrowed = true;
            }
        } else {
            // Add sus4 or sus2 as passing chord
            if (chord.type === 'major' || chord.type === 'minor') {
                spicedChord.type = Math.random() > 0.5 ? 'sus4' : 'sus2';
            }
        }
        
        return spicedChord;
    });
    
    // Save to history before replacing
    saveToHistory(AppState.currentProgression);
    
    AppState.currentProgression = newProgression;
    
    // Re-apply voice leading if enabled
    if (AppState.useVoiceLeading) {
        applyVoiceLeading(newProgression);
    }
    
    // Update UI
    renderChordDisplay();
    PianoRoll.loadFromProgression();
    
    // Play spicy sound effect
    playSpiceSound();
}

/**
 * Play a fun sound effect when spicing up chords
 */
function playSpiceSound() {
    const ctx = initAudio();
    
    // Ascending arpeggio with slight randomness
    const notes = [261.63, 329.63, 392.00, 523.25, 659.25]; // C4, E4, G4, C5, E5
    notes.forEach((freq, i) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(freq * (1 + Math.random() * 0.02), ctx.currentTime + i * 0.08);
        gain.gain.setValueAtTime(0.12 * AppState.masterVolume, ctx.currentTime + i * 0.08);
        gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + i * 0.08 + 0.25);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(ctx.currentTime + i * 0.08);
        osc.stop(ctx.currentTime + i * 0.08 + 0.25);
    });
}

// ===================================
// History/Saved Progressions - v2.4
// ===================================

const MAX_HISTORY_LENGTH = 5;

/**
 * Save current progression to history
 */
function saveToHistory(progression) {
    if (!progression || progression.length === 0) return;
    
    // Create a deep copy of the progression
    const historyCopy = JSON.parse(JSON.stringify(progression));
    
    // Add metadata
    const historyEntry = {
        progression: historyCopy,
        key: AppState.currentKey,
        genre: AppState.genre,
        timestamp: Date.now()
    };
    
    // Add to front of history
    AppState.progressionHistory.unshift(historyEntry);
    
    // Keep only last 5 entries
    if (AppState.progressionHistory.length > MAX_HISTORY_LENGTH) {
        AppState.progressionHistory = AppState.progressionHistory.slice(0, MAX_HISTORY_LENGTH);
    }
    
    // Save to localStorage
    saveToStorage('progressionHistory', AppState.progressionHistory);
}

/**
 * Load history from localStorage
 */
function loadHistory() {
    AppState.progressionHistory = loadFromStorage('progressionHistory', []);
}

/**
 * Restore a progression from history
 */
function restoreFromHistory(index) {
    if (index < 0 || index >= AppState.progressionHistory.length) return;
    
    const entry = AppState.progressionHistory[index];
    AppState.currentProgression = JSON.parse(JSON.stringify(entry.progression));
    AppState.currentKey = entry.key;
    AppState.genre = entry.genre;
    
    // Update UI
    document.getElementById('key-select').value = entry.key;
    document.getElementById('genre-select').value = entry.genre;
    
    // Re-apply voice leading if enabled
    if (AppState.useVoiceLeading) {
        applyVoiceLeading(AppState.currentProgression);
    }
    
    renderChordDisplay();
    renderHistoryPanel();
    PianoRoll.loadFromProgression();
    
    // Visual feedback
    const chordDisplay = document.getElementById('chord-display');
    if (chordDisplay) {
        chordDisplay.classList.add('pulse');
        setTimeout(() => chordDisplay.classList.remove('pulse'), 500);
    }
}

/**
 * Render the history panel
 */
function renderHistoryPanel() {
    const container = document.getElementById('history-list');
    if (!container) return;
    
    if (AppState.progressionHistory.length === 0) {
        container.innerHTML = '<div class="history-empty">No saved progressions yet</div>';
        return;
    }
    
    container.innerHTML = AppState.progressionHistory.map((entry, index) => {
        const chords = entry.progression.map(c => c.root + (CHORD_TYPES[c.type]?.symbol || '')).join(' - ');
        const timeAgo = getTimeAgo(entry.timestamp);
        const genreProfile = GENRE_PROFILES[entry.genre];
        
        return `
            <div class="history-item" onclick="restoreFromHistory(${index})">
                <div class="history-item-header">
                    <span class="history-key">${entry.key}</span>
                    <span class="history-genre">${genreProfile?.name || entry.genre}</span>
                </div>
                <div class="history-chords">${chords}</div>
                <div class="history-time">${timeAgo}</div>
            </div>
        `;
    }).join('');
}

/**
 * Helper function to format time ago
 */
function getTimeAgo(timestamp) {
    const seconds = Math.floor((Date.now() - timestamp) / 1000);
    
    if (seconds < 60) return 'Just now';
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
    if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
    return `${Math.floor(seconds / 86400)}d ago`;
}

// ===================================
// Smart Presets Functions - v2.4
// ===================================

/**
 * Apply a smart preset
 */
function applyPreset(presetKey) {
    const preset = SMART_PRESETS[presetKey];
    if (!preset) return;
    
    // Update state
    AppState.genre = preset.genre;
    AppState.currentKey = preset.key;
    AppState.complexity = preset.complexity;
    AppState.rhythm = preset.rhythm;
    AppState.swing = preset.swing;
    AppState.useVoiceLeading = preset.useVoiceLeading;
    AppState.useAdvancedTheory = preset.useAdvancedTheory;
    AppState.currentPreset = presetKey;
    
    // Update UI controls
    document.getElementById('genre-select').value = preset.genre;
    document.getElementById('key-select').value = preset.key;
    document.getElementById('complexity-select').value = preset.complexity;
    document.getElementById('rhythm-select').value = preset.rhythm;
    
    const swingSlider = document.getElementById('swing-slider');
    if (swingSlider) swingSlider.value = preset.swing * 100;
    
    const voiceLeadingToggle = document.getElementById('voice-leading');
    if (voiceLeadingToggle) voiceLeadingToggle.checked = preset.useVoiceLeading;
    
    const advancedTheoryToggle = document.getElementById('advanced-theory');
    if (advancedTheoryToggle) advancedTheoryToggle.checked = preset.useAdvancedTheory;
    
    // Update tempo based on genre
    const profile = GENRE_PROFILES[preset.genre];
    document.getElementById('tempo-input').value = profile.tempo;
    AppState.tempo = profile.tempo;
    
    // Update preset cards UI
    updatePresetCardSelection(presetKey);
    
    // Generate new progression with preset settings
    handleGenerate();
}

/**
 * Update preset card visual selection
 */
function updatePresetCardSelection(selectedKey) {
    document.querySelectorAll('.preset-card').forEach(card => {
        card.classList.toggle('selected', card.dataset.preset === selectedKey);
    });
}

/**
 * Render smart presets grid
 */
function renderSmartPresets() {
    const container = document.getElementById('presets-grid');
    if (!container) return;
    
    container.innerHTML = Object.entries(SMART_PRESETS).map(([key, preset]) => `
        <div class="preset-card ${AppState.currentPreset === key ? 'selected' : ''}" 
             data-preset="${key}" 
             onclick="applyPreset('${key}')">
            <div class="preset-emoji">${preset.emoji}</div>
            <div class="preset-name">${preset.name}</div>
            <div class="preset-description">${preset.description}</div>
        </div>
    `).join('');
}

// ===================================
// Swing/Humanization Functions - v2.4
// ===================================

/**
 * Apply swing/humanization to note timing
 */
function applySwing(time, swingAmount) {
    if (swingAmount === 0) return time;
    
    // Apply subtle timing variation for humanization
    const variation = (Math.random() - 0.5) * swingAmount * 0.1;
    return time + variation;
}

/**
 * Get humanized velocity
 */
function getHumanizedVelocity(baseVelocity, swingAmount) {
    if (swingAmount === 0) return baseVelocity;
    
    const variation = 1 + (Math.random() - 0.5) * swingAmount * 0.3;
    return Math.max(0.1, Math.min(1, baseVelocity * variation));
}

function generateProgression() {
    const { root, isMinor } = parseKey(AppState.currentKey);
    AppState.isMinorKey = isMinor;
    
    const profile = GENRE_PROFILES[AppState.genre];
    const complexity = COMPLEXITY_SETTINGS[AppState.complexity];
    
    // Save current progression to history before generating new one
    if (AppState.currentProgression.length > 0) {
        saveToHistory(AppState.currentProgression);
    }
    
    // Select a base progression
    const baseProgression = randomChoice(profile.progressions);
    
    // Extend or modify based on complexity
    let progression = [...baseProgression];
    
    // Add more chords for higher complexity
    const targetLength = randomInt(complexity.chordCount[0], complexity.chordCount[1]);
    while (progression.length < targetLength) {
        const insertIndex = randomInt(0, progression.length);
        const newChord = randomChoice(['ii', 'IV', 'V', 'vi', 'iii']);
        progression.splice(insertIndex, 0, newChord);
    }
    
    // Convert degrees to actual chords
    const scale = isMinor ? 'minor' : profile.scale;
    let chords = progression.map(degree => {
        let chord = getChordFromDegree(root, degree, isMinor, scale);
        
        // Apply chord extensions for complex settings
        if (complexity.useExtensions && Math.random() > 0.5) {
            const extensions = profile.chordTypes.filter(t => 
                t.includes('7') || t.includes('9') || t.includes('sus') || t.includes('add')
            );
            if (extensions.length > 0 && Math.random() > 0.6) {
                chord.type = randomChoice(extensions);
            }
        }
        
        // Apply genre-specific voicing - v2.4
        chord = applyGenreVoicing(chord, AppState.genre);
        
        return chord;
    });
    
    // Apply modal interchange if enabled - v2.4
    if (AppState.useModalInterchange && (AppState.complexity === 'complex' || AppState.complexity === 'advanced')) {
        chords = applyModalInterchange(chords, root, isMinor);
    }
    
    // Apply advanced chord substitutions if enabled and complexity is high enough
    if (AppState.useAdvancedTheory && (AppState.complexity === 'complex' || AppState.complexity === 'advanced')) {
        chords = applyAdvancedSubstitutions(chords, root, isMinor);
    }
    
    // Apply voice leading if enabled
    if (AppState.useVoiceLeading) {
        applyVoiceLeading(chords);
    }
    
    AppState.currentProgression = chords;
    
    // Update history panel
    renderHistoryPanel();
    
    return chords;
}

// ===================================
// Melody Generation Logic
// ===================================

function generateMelody() {
    const profile = GENRE_PROFILES[AppState.genre];
    const rhythm = RHYTHM_PATTERNS[AppState.rhythm];
    const { root } = parseKey(AppState.currentKey);
    
    const scaleNotes = getScaleNotes(root, profile.melodyScale);
    const melody = [];
    
    // Generate melody notes based on chord tones and passing tones
    AppState.currentProgression.forEach((chord, chordIndex) => {
        const notesPerChord = Math.ceil(4 * rhythm.melodyDensity) + 1;
        const chordTones = CHORD_TYPES[chord.type].intervals.map(i => 
            transposeNote(chord.root, i)
        );
        
        for (let i = 0; i < notesPerChord; i++) {
            // Prefer chord tones, occasionally use scale notes
            const useChordTone = Math.random() > 0.3;
            const note = useChordTone ? 
                randomChoice(chordTones) : 
                randomChoice(scaleNotes);
            
            const duration = randomChoice(rhythm.durations);
            const velocity = rhythm.dynamics[i % rhythm.dynamics.length];
            
            melody.push({
                note,
                duration,
                velocity,
                chordIndex,
                octave: randomInt(4, 5)
            });
        }
    });
    
    AppState.currentMelody = melody;
    return melody;
}

// ===================================
// UI Rendering Functions
// ===================================

function renderChordDisplay() {
    const container = document.getElementById('chord-display');
    
    if (AppState.currentProgression.length === 0) {
        container.innerHTML = '<div class="chord-placeholder">Tap "Generate" to create a progression</div>';
        return;
    }
    
    container.innerHTML = AppState.currentProgression.map((chord, index) => {
        const chordSymbol = CHORD_TYPES[chord.type]?.symbol || '';
        const displayName = chord.root + chordSymbol;
        const numeralHTML = AppState.showNumerals ? 
            `<div class="chord-numeral">${chord.degree}</div>` : '';
        
        return `
            <div class="chord-card" data-index="${index}" onclick="toggleChordActive(${index})">
                <div class="chord-name">${displayName}</div>
                <div class="chord-type">${CHORD_TYPES[chord.type]?.name || chord.type}</div>
                ${numeralHTML}
            </div>
        `;
    }).join('');
}

function renderMelodyDisplay() {
    const container = document.getElementById('melody-display');
    
    if (AppState.currentMelody.length === 0) {
        container.innerHTML = '<div class="melody-placeholder">Melody appears after generation</div>';
        return;
    }
    
    container.innerHTML = AppState.currentMelody.map((note, index) => `
        <span class="melody-note" style="animation-delay: ${index * 0.05}s">
            ${note.note}${note.octave}
        </span>
    `).join('');
}

function toggleChordActive(index) {
    const cards = document.querySelectorAll('.chord-card');
    cards.forEach((card, i) => {
        card.classList.toggle('active', i === index);
    });
    
    // Play the chord
    if (AppState.currentProgression[index]) {
        playChord(AppState.currentProgression[index]);
    }
}

// ===================================
// Tab Navigation
// ===================================

function switchTab(tabName) {
    AppState.currentTab = tabName;
    
    // Update tab content visibility
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.remove('active');
    });
    document.getElementById(`tab-${tabName}`).classList.add('active');
    
    // Update nav items
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.toggle('active', item.dataset.tab === tabName);
    });
    
    // Reinitialize piano roll if switching to editor
    if (tabName === 'editor') {
        setTimeout(() => PianoRoll.init(), 100);
    }
}

// ===================================
// Collapsible Sections
// ===================================

function initCollapsibles() {
    document.querySelectorAll('.collapsible-header').forEach(header => {
        header.addEventListener('click', () => {
            const section = header.parentElement;
            const isExpanded = section.classList.contains('expanded');
            
            section.classList.toggle('expanded');
            header.setAttribute('aria-expanded', !isExpanded);
        });
    });
    
    // Initialize expanded sections
    document.querySelectorAll('.collapsible-section.expanded').forEach(section => {
        section.querySelector('.collapsible-header').setAttribute('aria-expanded', 'true');
    });
}

// ===================================
// Floating Action Button
// ===================================

function initFAB() {
    const fabMain = document.getElementById('fab-main');
    const fabContainer = document.querySelector('.fab-container');
    const fabMenu = document.querySelector('.fab-menu');
    
    fabMain.addEventListener('click', () => {
        fabContainer.classList.toggle('open');
        fabMenu.classList.toggle('hidden');
    });
    
    // Close menu when clicking outside
    document.addEventListener('click', (e) => {
        if (!fabContainer.contains(e.target)) {
            fabContainer.classList.remove('open');
            fabMenu.classList.add('hidden');
        }
    });
    
    // FAB actions
    document.getElementById('fab-generate').addEventListener('click', () => {
        handleGenerate();
        closeFABMenu();
    });
    
    document.getElementById('fab-regenerate').addEventListener('click', () => {
        handleRegenerate();
        closeFABMenu();
    });
    
    document.getElementById('fab-play').addEventListener('click', () => {
        playProgression();
        closeFABMenu();
    });
    
    document.getElementById('fab-export-midi').addEventListener('click', () => {
        exportToMIDI();
        closeFABMenu();
    });
}

function closeFABMenu() {
    document.querySelector('.fab-container').classList.remove('open');
    document.querySelector('.fab-menu').classList.add('hidden');
}

// ===================================
// Onboarding
// ===================================

function initOnboarding() {
    const overlay = document.getElementById('onboarding-overlay');
    const nextBtn = document.getElementById('onboarding-next');
    const skipBtn = document.getElementById('onboarding-skip');
    const dots = document.querySelectorAll('.dot');
    const slides = document.querySelectorAll('.onboarding-slide');
    
    // Check if onboarding was completed
    if (loadFromStorage('onboardingComplete', false)) {
        overlay.classList.add('hidden');
        return;
    }
    
    overlay.classList.remove('hidden');
    let currentSlide = 0;
    
    function showSlide(index) {
        slides.forEach((slide, i) => {
            slide.classList.toggle('active', i === index);
        });
        dots.forEach((dot, i) => {
            dot.classList.toggle('active', i === index);
        });
        
        nextBtn.textContent = index === slides.length - 1 ? 'Get Started' : 'Next';
    }
    
    nextBtn.addEventListener('click', () => {
        if (currentSlide < slides.length - 1) {
            currentSlide++;
            showSlide(currentSlide);
        } else {
            completeOnboarding();
        }
    });
    
    skipBtn.addEventListener('click', completeOnboarding);
    
    dots.forEach((dot, index) => {
        dot.addEventListener('click', () => {
            currentSlide = index;
            showSlide(currentSlide);
        });
    });
    
    function completeOnboarding() {
        overlay.classList.add('hidden');
        saveToStorage('onboardingComplete', true);
    }
    
    // Show onboarding button in settings
    document.getElementById('show-onboarding').addEventListener('click', () => {
        currentSlide = 0;
        showSlide(0);
        overlay.classList.remove('hidden');
    });
}

// ===================================
// Settings
// ===================================

function initSettings() {
    // Load saved settings first before initializing UI
    AppState.masterVolume = loadFromStorage('masterVolume', 0.8);
    AppState.soundType = loadFromStorage('soundType', 'sine');
    AppState.showNumerals = loadFromStorage('showNumerals', true);
    AppState.showTips = loadFromStorage('showTips', true);
    AppState.useVoiceLeading = loadFromStorage('useVoiceLeading', false);
    AppState.useAdvancedTheory = loadFromStorage('useAdvancedTheory', false);
    const savedEnvelope = loadFromStorage('envelope', null);
    if (savedEnvelope) {
        AppState.envelope = savedEnvelope;
    }

    // Volume
    const volumeSlider = document.getElementById('volume-slider');
    volumeSlider.value = AppState.masterVolume * 100;
    volumeSlider.addEventListener('input', (e) => {
        AppState.masterVolume = e.target.value / 100;
        saveToStorage('masterVolume', AppState.masterVolume);
    });
    
    // Sound type
    const soundType = document.getElementById('sound-type');
    soundType.value = AppState.soundType;
    soundType.addEventListener('change', (e) => {
        AppState.soundType = e.target.value;
        saveToStorage('soundType', AppState.soundType);
    });
    
    // Show numerals
    const showNumerals = document.getElementById('show-numerals');
    showNumerals.checked = AppState.showNumerals;
    showNumerals.addEventListener('change', (e) => {
        AppState.showNumerals = e.target.checked;
        saveToStorage('showNumerals', AppState.showNumerals);
        renderChordDisplay();
    });
    
    // Show tips
    const showTips = document.getElementById('show-tips');
    showTips.checked = AppState.showTips;
    showTips.addEventListener('change', (e) => {
        AppState.showTips = e.target.checked;
        saveToStorage('showTips', AppState.showTips);
        document.querySelectorAll('.editor-tip').forEach(tip => {
            tip.style.display = AppState.showTips ? 'flex' : 'none';
        });
    });
    
    // Voice Leading
    const voiceLeading = document.getElementById('voice-leading');
    if (voiceLeading) {
        voiceLeading.checked = AppState.useVoiceLeading;
        voiceLeading.addEventListener('change', (e) => {
            AppState.useVoiceLeading = e.target.checked;
            saveToStorage('useVoiceLeading', AppState.useVoiceLeading);
        });
    }
    
    // Advanced Theory
    const advancedTheory = document.getElementById('advanced-theory');
    if (advancedTheory) {
        advancedTheory.checked = AppState.useAdvancedTheory;
        advancedTheory.addEventListener('change', (e) => {
            AppState.useAdvancedTheory = e.target.checked;
            saveToStorage('useAdvancedTheory', AppState.useAdvancedTheory);
        });
    }

    // Envelope ADSR controls
    const envAttack = document.getElementById('env-attack');
    const envDecay = document.getElementById('env-decay');
    const envSustain = document.getElementById('env-sustain');
    const envRelease = document.getElementById('env-release');
    
    envAttack.value = AppState.envelope.attack;
    envAttack.addEventListener('input', (e) => {
        AppState.envelope.attack = parseFloat(e.target.value);
        saveToStorage('envelope', AppState.envelope);
    });
    
    envDecay.value = AppState.envelope.decay;
    envDecay.addEventListener('input', (e) => {
        AppState.envelope.decay = parseFloat(e.target.value);
        saveToStorage('envelope', AppState.envelope);
    });
    
    envSustain.value = AppState.envelope.sustain;
    envSustain.addEventListener('input', (e) => {
        AppState.envelope.sustain = parseFloat(e.target.value);
        saveToStorage('envelope', AppState.envelope);
    });
    
    envRelease.value = AppState.envelope.release;
    envRelease.addEventListener('input', (e) => {
        AppState.envelope.release = parseFloat(e.target.value);
        saveToStorage('envelope', AppState.envelope);
    });
}

// ===================================
// Piano Roll / Visual Editor
// ===================================

const PianoRoll = {
    canvas: null,
    ctx: null,
    noteHeight: 28,
    beatWidth: 60,
    totalBeats: 16,
    notes: [],
    zoom: 1,
    isDragging: false,
    lastTouchDistance: 0,
    touchStartTime: null,
    touchStartPos: null,
    
    init() {
        this.canvas = document.getElementById('piano-roll-canvas');
        if (!this.canvas) return;
        
        this.ctx = this.canvas.getContext('2d');
        this.setupCanvas();
        this.renderPianoKeys();
        this.draw();
        this.setupEventListeners();
        this.setupZoomControls();
    },
    
    setupCanvas() {
        const container = document.querySelector('.piano-roll');
        if (!container) return;
        
        const effectiveBeatWidth = this.beatWidth * this.zoom;
        this.canvas.width = effectiveBeatWidth * this.totalBeats;
        this.canvas.height = this.noteHeight * 24; // 2 octaves
        this.canvas.style.width = this.canvas.width + 'px';
        this.canvas.style.height = this.canvas.height + 'px';
    },
    
    renderPianoKeys() {
        const container = document.getElementById('piano-keys');
        if (!container) return;
        
        // Notes in descending order for piano roll display (high notes at top)
        const notes = ['C', 'B', 'A#', 'A', 'G#', 'G', 'F#', 'F', 'E', 'D#', 'D', 'C#'];
        let html = '';
        
        for (let octave = 5; octave >= 4; octave--) {
            notes.forEach(note => {
                const isBlack = note.includes('#');
                const keyClass = isBlack ? 'black' : 'white';
                html += `<div class="piano-key ${keyClass}" data-note="${note}${octave}">${note}${octave}</div>`;
            });
        }
        
        container.innerHTML = html;
        
        // Add click handlers for piano keys
        container.querySelectorAll('.piano-key').forEach(key => {
            key.addEventListener('click', () => {
                const noteName = key.dataset.note;
                this.playPreviewNote(noteName);
            });
        });
    },
    
    playPreviewNote(noteName) {
        const note = noteName.slice(0, -1);
        const octave = parseInt(noteName.slice(-1));
        playNote(note, octave, 0.3);
    },
    
    draw() {
        if (!this.ctx) return;
        
        const ctx = this.ctx;
        const { width, height } = this.canvas;
        const effectiveBeatWidth = this.beatWidth * this.zoom;
        
        // Clear canvas
        ctx.fillStyle = '#1a1a2e';
        ctx.fillRect(0, 0, width, height);
        
        // Draw grid
        ctx.strokeStyle = '#3a3a5c';
        ctx.lineWidth = 1;
        
        // Horizontal lines (note rows)
        for (let i = 0; i <= 24; i++) {
            const y = i * this.noteHeight;
            ctx.beginPath();
            ctx.moveTo(0, y);
            ctx.lineTo(width, y);
            ctx.stroke();
            
            // Highlight black keys
            const noteIndex = (23 - i) % 12;
            if ([1, 3, 6, 8, 10].includes(noteIndex)) {
                ctx.fillStyle = 'rgba(0, 0, 0, 0.2)';
                ctx.fillRect(0, y, width, this.noteHeight);
            }
        }
        
        // Vertical lines (beats)
        for (let i = 0; i <= this.totalBeats; i++) {
            const x = i * effectiveBeatWidth;
            ctx.strokeStyle = i % 4 === 0 ? '#5a5a7c' : '#3a3a5c';
            ctx.lineWidth = i % 4 === 0 ? 2 : 1;
            ctx.beginPath();
            ctx.moveTo(x, 0);
            ctx.lineTo(x, height);
            ctx.stroke();
        }
        
        // Draw notes
        this.notes.forEach(note => {
            this.drawNote(note);
        });
    },
    
    drawNote(note) {
        const ctx = this.ctx;
        const effectiveBeatWidth = this.beatWidth * this.zoom;
        const scaledX = (note.x / this.beatWidth) * effectiveBeatWidth;
        const scaledWidth = (note.width / this.beatWidth) * effectiveBeatWidth;
        
        const gradient = ctx.createLinearGradient(scaledX, note.y, scaledX + scaledWidth, note.y);
        gradient.addColorStop(0, '#7c3aed');
        gradient.addColorStop(1, '#ec4899');
        
        ctx.fillStyle = gradient;
        ctx.fillRect(scaledX, note.y, scaledWidth, this.noteHeight - 2);
        
        // Note border
        ctx.strokeStyle = '#a855f7';
        ctx.lineWidth = 1;
        ctx.strokeRect(scaledX, note.y, scaledWidth, this.noteHeight - 2);
    },
    
    setupEventListeners() {
        if (!this.canvas) return;
        
        // Mouse/touch click
        this.canvas.addEventListener('click', (e) => this.handleClick(e));
        
        // Touch events for mobile
        this.canvas.addEventListener('touchstart', (e) => this.handleTouchStart(e), { passive: false });
        this.canvas.addEventListener('touchmove', (e) => this.handleTouchMove(e), { passive: false });
        this.canvas.addEventListener('touchend', (e) => this.handleTouchEnd(e));
    },
    
    setupZoomControls() {
        const zoomIn = document.getElementById('zoom-in-btn');
        const zoomOut = document.getElementById('zoom-out-btn');
        const resetView = document.getElementById('reset-view-btn');
        
        if (zoomIn) {
            zoomIn.addEventListener('click', () => {
                this.zoom = Math.min(this.zoom * 1.25, 3);
                this.setupCanvas();
                this.draw();
            });
        }
        
        if (zoomOut) {
            zoomOut.addEventListener('click', () => {
                this.zoom = Math.max(this.zoom / 1.25, 0.5);
                this.setupCanvas();
                this.draw();
            });
        }
        
        if (resetView) {
            resetView.addEventListener('click', () => {
                this.zoom = 1;
                this.setupCanvas();
                this.draw();
                const wrapper = document.querySelector('.piano-roll-wrapper');
                if (wrapper) wrapper.scrollLeft = 0;
            });
        }
    },
    
    handleClick(e) {
        const rect = this.canvas.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        
        this.toggleNote(x, y);
    },
    
    handleTouchStart(e) {
        if (e.touches.length === 2) {
            // Pinch zoom start
            this.lastTouchDistance = this.getTouchDistance(e.touches);
            e.preventDefault();
        } else if (e.touches.length === 1) {
            // Single touch - wait to see if it's a tap or scroll
            this.touchStartTime = Date.now();
            this.touchStartPos = {
                x: e.touches[0].clientX,
                y: e.touches[0].clientY
            };
        }
    },
    
    handleTouchMove(e) {
        if (e.touches.length === 2) {
            // Pinch zoom
            const newDistance = this.getTouchDistance(e.touches);
            const delta = newDistance / this.lastTouchDistance;
            this.zoom = Math.max(0.5, Math.min(3, this.zoom * delta));
            this.lastTouchDistance = newDistance;
            this.setupCanvas();
            this.draw();
            e.preventDefault();
        }
    },
    
    handleTouchEnd(e) {
        if (e.changedTouches.length === 1 && this.touchStartTime) {
            const touchDuration = Date.now() - this.touchStartTime;
            const touch = e.changedTouches[0];
            const moveDistance = Math.sqrt(
                Math.pow(touch.clientX - this.touchStartPos.x, 2) +
                Math.pow(touch.clientY - this.touchStartPos.y, 2)
            );
            
            // If it was a quick tap with minimal movement, treat as click
            if (touchDuration < 300 && moveDistance < 10) {
                const rect = this.canvas.getBoundingClientRect();
                const x = touch.clientX - rect.left;
                const y = touch.clientY - rect.top;
                this.toggleNote(x, y);
            }
        }
        this.touchStartTime = null;
    },
    
    getTouchDistance(touches) {
        return Math.sqrt(
            Math.pow(touches[0].clientX - touches[1].clientX, 2) +
            Math.pow(touches[0].clientY - touches[1].clientY, 2)
        );
    },
    
    toggleNote(x, y) {
        const effectiveBeatWidth = this.beatWidth * this.zoom;
        
        // Find clicked note or create new one
        const clickedNoteIndex = this.notes.findIndex(note => {
            const scaledX = (note.x / this.beatWidth) * effectiveBeatWidth;
            const scaledWidth = (note.width / this.beatWidth) * effectiveBeatWidth;
            return x >= scaledX && x <= scaledX + scaledWidth &&
                   y >= note.y && y <= note.y + this.noteHeight;
        });
        
        if (clickedNoteIndex !== -1) {
            // Remove note
            this.notes.splice(clickedNoteIndex, 1);
        } else {
            // Add note
            const beatIndex = Math.floor(x / effectiveBeatWidth);
            const noteIndex = Math.floor(y / this.noteHeight);
            
            this.notes.push({
                x: beatIndex * this.beatWidth,
                y: noteIndex * this.noteHeight,
                width: this.beatWidth,
                noteIndex,
                beat: beatIndex
            });
            
            // Play preview
            const noteNames = ['C', 'B', 'A#', 'A', 'G#', 'G', 'F#', 'F', 'E', 'D#', 'D', 'C#'];
            const octave = noteIndex < 12 ? 5 : 4;
            const noteName = noteNames[noteIndex % 12];
            playNote(noteName, octave, 0.2);
        }
        
        this.draw();
    },
    
    loadFromProgression() {
        this.notes = [];
        
        AppState.currentProgression.forEach((chord, chordIndex) => {
            // Use voiced notes if available for more accurate piano roll display
            if (chord.voicedNotes && chord.voicedNotes.length > 0) {
                chord.voicedNotes.forEach((voicedNote) => {
                    // Convert voiced note to piano roll coordinates
                    // Piano roll shows notes from C5 at top (noteIndex 0) to C#4 at bottom (noteIndex 23)
                    const noteIndex = getNoteIndex(voicedNote.note);
                    // Calculate row: octave 5 notes are at rows 0-11, octave 4 notes at rows 12-23
                    const octaveOffset = (5 - voicedNote.octave) * 12;
                    const noteRow = (12 - noteIndex) % 12 + octaveOffset;
                    
                    // Ensure note is within visible range
                    if (noteRow >= 0 && noteRow < 24) {
                        this.notes.push({
                            x: chordIndex * this.beatWidth * 4,
                            y: noteRow * this.noteHeight,
                            width: this.beatWidth * 4,
                            noteIndex: noteRow,
                            beat: chordIndex * 4
                        });
                    }
                });
            } else {
                // Fallback to original behavior
                const chordNotes = CHORD_TYPES[chord.type].intervals;
                const rootIndex = getNoteIndex(chord.root);
                
                chordNotes.forEach((interval) => {
                    const noteIndex = 12 - ((rootIndex + interval) % 12);
                    this.notes.push({
                        x: chordIndex * this.beatWidth * 4,
                        y: noteIndex * this.noteHeight,
                        width: this.beatWidth * 4,
                        noteIndex,
                        beat: chordIndex * 4
                    });
                });
            }
        });
        
        this.draw();
    },
    
    clear() {
        this.notes = [];
        this.draw();
    }
};

// ===================================
// Audio Playback (Web Audio API)
// ===================================

function initAudio() {
    if (!AppState.audioContext) {
        AppState.audioContext = new (window.AudioContext || window.webkitAudioContext)();
    }
    return AppState.audioContext;
}

function noteToFrequency(note, octave = 4) {
    const noteIndex = getNoteIndex(note);
    const a4 = 440;
    const a4Index = 9; // A is at index 9 in our zero-indexed NOTES array
    const halfSteps = noteIndex - a4Index + (octave - 4) * 12;
    return a4 * Math.pow(2, halfSteps / 12);
}

function playNote(note, octave = 4, duration = 0.5, time = 0) {
    const ctx = initAudio();
    const frequency = noteToFrequency(note, octave);
    
    const oscillator = ctx.createOscillator();
    const gainNode = ctx.createGain();
    
    oscillator.type = AppState.soundType;
    oscillator.frequency.setValueAtTime(frequency, ctx.currentTime + time);
    
    const volume = 0.3 * AppState.masterVolume;
    const env = AppState.envelope;
    const startTime = ctx.currentTime + time;
    
    // Minimum gain value for exponential ramps (cannot be 0)
    const MIN_GAIN = 0.0001;
    
    // ADSR Envelope Implementation
    // Attack: Linear ramp from 0 to max volume
    gainNode.gain.setValueAtTime(0, startTime);
    gainNode.gain.linearRampToValueAtTime(volume, startTime + env.attack);
    
    // Decay: Exponential ramp from max volume to sustain level
    const sustainLevel = volume * env.sustain;
    const effectiveSustain = Math.max(sustainLevel, MIN_GAIN);
    gainNode.gain.exponentialRampToValueAtTime(
        effectiveSustain, 
        startTime + env.attack + env.decay
    );
    
    // Sustain: Hold level until the note duration ends
    // (The sustain level is held automatically until the next scheduled change)
    
    // Release: Exponential ramp from sustain level to silence after the duration
    const releaseStartTime = startTime + duration;
    gainNode.gain.setValueAtTime(effectiveSustain, releaseStartTime);
    gainNode.gain.exponentialRampToValueAtTime(MIN_GAIN, releaseStartTime + env.release);
    
    oscillator.connect(gainNode);
    gainNode.connect(ctx.destination);
    
    oscillator.start(startTime);
    // Oscillator stops after the release phase completes
    oscillator.stop(releaseStartTime + env.release);
    
    return oscillator;
}

function playChord(chord, duration = 1) {
    const ctx = initAudio();
    
    // Use voiced notes if available (from voice leading), otherwise use default voicing
    if (chord.voicedNotes && chord.voicedNotes.length > 0) {
        chord.voicedNotes.forEach((voicedNote, i) => {
            playNote(voicedNote.note, voicedNote.octave, duration, i * 0.02);
        });
    } else {
        // Fallback to original behavior
        const intervals = CHORD_TYPES[chord.type]?.intervals || [0, 4, 7];
        intervals.forEach((interval, i) => {
            const note = transposeNote(chord.root, interval);
            playNote(note, 4, duration, i * 0.02);
        });
    }
}

function playProgression() {
    if (AppState.isPlaying) return;
    if (AppState.currentProgression.length === 0) {
        handleGenerate();
    }
    
    AppState.isPlaying = true;
    
    initAudio();
    const tempo = parseInt(document.getElementById('tempo-input').value) || 120;
    const beatDuration = 60 / tempo;
    const chordDuration = beatDuration * 4; // 4 beats per chord
    
    let currentTime = 0;
    
    AppState.currentProgression.forEach((chord, index) => {
        setTimeout(() => {
            if (AppState.isPlaying) {
                playChord(chord, chordDuration * 0.9);
                highlightChord(index);
            }
        }, currentTime * 1000);
        
        currentTime += chordDuration;
    });
    
    // Reset after progression ends
    setTimeout(() => {
        AppState.isPlaying = false;
        clearChordHighlights();
    }, currentTime * 1000);
}

function stopPlayback() {
    AppState.isPlaying = false;
    clearChordHighlights();
}

function highlightChord(index) {
    const cards = document.querySelectorAll('.chord-card');
    cards.forEach((card, i) => {
        card.classList.toggle('active', i === index);
    });
}

function clearChordHighlights() {
    const cards = document.querySelectorAll('.chord-card');
    cards.forEach(card => card.classList.remove('active'));
}

// ===================================
// Generation Animations & Sounds
// ===================================

function showGenerationAnimation() {
    // Create or reuse animation overlay
    let overlay = document.getElementById('generation-animation');
    if (!overlay) {
        overlay = document.createElement('div');
        overlay.id = 'generation-animation';
        overlay.className = 'generation-animation';
        overlay.innerHTML = `
            <div class="light-burst"></div>
            <div class="particles-container">
                ${Array(12).fill('').map((_, i) => `<div class="particle particle-${i + 1}"></div>`).join('')}
            </div>
            <div class="sparkles-container">
                ${Array(8).fill('').map((_, i) => `<div class="sparkle sparkle-${i + 1}">✨</div>`).join('')}
            </div>
            <div class="music-notes">
                <span class="note note-1">🎵</span>
                <span class="note note-2">🎶</span>
                <span class="note note-3">🎵</span>
                <span class="note note-4">🎶</span>
            </div>
        `;
        document.body.appendChild(overlay);
    }
    
    // Trigger animation
    overlay.classList.remove('hidden');
    overlay.classList.add('active');
    
    // Hide after animation completes
    setTimeout(() => {
        overlay.classList.remove('active');
        overlay.classList.add('hidden');
    }, 1200);
}

function playGenerationSounds() {
    const ctx = initAudio();
    
    // Fun "whoosh" sound - quick ascending sweep
    const whooshOsc = ctx.createOscillator();
    const whooshGain = ctx.createGain();
    whooshOsc.type = 'sine';
    whooshOsc.frequency.setValueAtTime(200, ctx.currentTime);
    whooshOsc.frequency.exponentialRampToValueAtTime(800, ctx.currentTime + 0.15);
    whooshGain.gain.setValueAtTime(0.2 * AppState.masterVolume, ctx.currentTime);
    whooshGain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.2);
    whooshOsc.connect(whooshGain);
    whooshGain.connect(ctx.destination);
    whooshOsc.start(ctx.currentTime);
    whooshOsc.stop(ctx.currentTime + 0.2);
    
    // Sparkle/chime sound - high pitched blips
    const chimeDelays = [0.05, 0.12, 0.2, 0.28];
    const chimeFreqs = [1200, 1500, 1800, 2000];
    
    chimeDelays.forEach((delay, i) => {
        const chimeOsc = ctx.createOscillator();
        const chimeGain = ctx.createGain();
        chimeOsc.type = 'sine';
        chimeOsc.frequency.setValueAtTime(chimeFreqs[i], ctx.currentTime + delay);
        chimeGain.gain.setValueAtTime(0.1 * AppState.masterVolume, ctx.currentTime + delay);
        chimeGain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + delay + 0.15);
        chimeOsc.connect(chimeGain);
        chimeGain.connect(ctx.destination);
        chimeOsc.start(ctx.currentTime + delay);
        chimeOsc.stop(ctx.currentTime + delay + 0.15);
    });
    
    // Completion "ding" sound
    setTimeout(() => {
        const dingOsc = ctx.createOscillator();
        const dingGain = ctx.createGain();
        dingOsc.type = 'triangle';
        dingOsc.frequency.setValueAtTime(880, ctx.currentTime);
        dingGain.gain.setValueAtTime(0.15 * AppState.masterVolume, ctx.currentTime);
        dingGain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.4);
        dingOsc.connect(dingGain);
        dingGain.connect(ctx.destination);
        dingOsc.start(ctx.currentTime);
        dingOsc.stop(ctx.currentTime + 0.4);
    }, 350);
}

// ===================================
// MIDI Export Functionality
// ===================================

function exportToMIDI() {
    if (AppState.currentProgression.length === 0) {
        alert('Please generate a chord progression first!');
        return;
    }
    
    // MIDI file constants
    const HEADER_CHUNK = 'MThd';
    const TRACK_CHUNK = 'MTrk';
    const TICKS_PER_BEAT = 480;
    const BEATS_PER_CHORD = 4;
    
    // Get tempo from UI
    const tempo = parseInt(document.getElementById('tempo-input').value) || 120;
    const microsecondsPerBeat = Math.round(60000000 / tempo);
    
    // Helper to convert number to variable-length quantity
    function toVLQ(value) {
        const bytes = [];
        bytes.push(value & 0x7F);
        value >>= 7;
        while (value > 0) {
            bytes.push((value & 0x7F) | 0x80);
            value >>= 7;
        }
        return bytes.reverse();
    }
    
    // Helper to convert string to byte array
    function stringToBytes(str) {
        return Array.from(str).map(c => c.charCodeAt(0));
    }
    
    // Helper to convert number to big-endian bytes
    function toBytes(num, byteCount) {
        const bytes = [];
        for (let i = byteCount - 1; i >= 0; i--) {
            bytes.push((num >> (i * 8)) & 0xFF);
        }
        return bytes;
    }
    
    // Convert note name to MIDI note number
    function noteToMIDI(noteName, octave = 4) {
        const noteMap = {
            'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3,
            'E': 4, 'F': 5, 'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8,
            'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11
        };
        return 12 + (octave * 12) + (noteMap[noteName] || 0);
    }
    
    // Build track data
    const trackData = [];
    
    // Tempo meta event (delta=0, FF 51 03 + 3 bytes tempo)
    trackData.push(...toVLQ(0)); // Delta time
    trackData.push(0xFF, 0x51, 0x03);
    trackData.push(...toBytes(microsecondsPerBeat, 3));
    
    // Time signature meta event (4/4 time)
    trackData.push(...toVLQ(0)); // Delta time
    trackData.push(0xFF, 0x58, 0x04, 0x04, 0x02, 0x18, 0x08);
    
    // Track name meta event
    const trackName = 'Chord Progression';
    trackData.push(...toVLQ(0)); // Delta time
    trackData.push(0xFF, 0x03, trackName.length);
    trackData.push(...stringToBytes(trackName));
    
    // Add chord events
    const ticksPerChord = TICKS_PER_BEAT * BEATS_PER_CHORD;
    const velocity = 80;
    const channel = 0;
    
    AppState.currentProgression.forEach((chord, chordIndex) => {
        let notes;
        
        // Use voiced notes if available for better voice leading in MIDI export
        if (chord.voicedNotes && chord.voicedNotes.length > 0) {
            notes = chord.voicedNotes.map(voicedNote => 
                noteToMIDI(voicedNote.note, voicedNote.octave)
            );
        } else {
            // Fallback to original behavior
            const chordType = CHORD_TYPES[chord.type];
            const intervals = chordType ? chordType.intervals : [0, 4, 7];
            notes = intervals.map(interval => {
                const noteName = transposeNote(chord.root, interval);
                return noteToMIDI(noteName, 4);
            });
        }
        
        // Note On events (delta=0 for simultaneous notes)
        notes.forEach((note, noteIndex) => {
            const delta = noteIndex === 0 ? (chordIndex === 0 ? 0 : ticksPerChord) : 0;
            trackData.push(...toVLQ(delta));
            trackData.push(0x90 | channel, note, velocity);
        });
        
        // Note Off events after chord duration
        notes.forEach((note, noteIndex) => {
            const delta = noteIndex === 0 ? ticksPerChord : 0;
            trackData.push(...toVLQ(delta));
            trackData.push(0x80 | channel, note, 0);
        });
    });
    
    // End of track meta event
    trackData.push(...toVLQ(0)); // Delta time
    trackData.push(0xFF, 0x2F, 0x00);
    
    // Build MIDI file
    const midiData = [];
    
    // Header chunk
    midiData.push(...stringToBytes(HEADER_CHUNK));
    midiData.push(...toBytes(6, 4)); // Header length (always 6)
    midiData.push(...toBytes(0, 2)); // Format type 0 (single track)
    midiData.push(...toBytes(1, 2)); // Number of tracks
    midiData.push(...toBytes(TICKS_PER_BEAT, 2)); // Ticks per beat
    
    // Track chunk
    midiData.push(...stringToBytes(TRACK_CHUNK));
    midiData.push(...toBytes(trackData.length, 4)); // Track length
    midiData.push(...trackData);
    
    // Create and download file
    const blob = new Blob([new Uint8Array(midiData)], { type: 'audio/midi' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    
    // Create filename with key and genre
    const keyName = AppState.currentKey.replace('#', 'sharp').replace('b', 'flat');
    const genreName = AppState.genre.replace('-', '_');
    link.download = `chord_progression_${keyName}_${genreName}.mid`;
    
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
    
    // Play success sound
    playExportSound();
}

function playExportSound() {
    const ctx = initAudio();
    
    // Success sound - two ascending notes
    const notes = [523.25, 659.25]; // C5, E5
    notes.forEach((freq, i) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq, ctx.currentTime + i * 0.1);
        gain.gain.setValueAtTime(0.15 * AppState.masterVolume, ctx.currentTime + i * 0.1);
        gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + i * 0.1 + 0.3);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(ctx.currentTime + i * 0.1);
        osc.stop(ctx.currentTime + i * 0.1 + 0.3);
    });
}

// ===================================
// Event Handlers
// ===================================

function handleGenerate() {
    // Update state from UI
    AppState.genre = document.getElementById('genre-select').value;
    AppState.complexity = document.getElementById('complexity-select').value;
    AppState.rhythm = document.getElementById('rhythm-select').value;
    AppState.currentKey = document.getElementById('key-select').value;
    
    // Update tempo based on genre
    const profile = GENRE_PROFILES[AppState.genre];
    document.getElementById('tempo-input').value = profile.tempo;
    AppState.tempo = profile.tempo;
    
    // Show animation overlay and play fun noises
    showGenerationAnimation();
    playGenerationSounds();
    
    // Generate progression and melody
    generateProgression();
    generateMelody();
    
    // Update UI
    renderChordDisplay();
    renderMelodyDisplay();
    PianoRoll.loadFromProgression();
    
    // Expand chord section if collapsed
    const chordDisplay = document.getElementById('chord-display');
    const chordSection = chordDisplay ? chordDisplay.closest('.collapsible-section') : null;
    if (chordSection && !chordSection.classList.contains('expanded')) {
        chordSection.classList.add('expanded');
    }
    
    // Add animation effect
    if (chordDisplay) {
        chordDisplay.classList.add('pulse');
        setTimeout(() => chordDisplay.classList.remove('pulse'), 500);
    }
}

function handleRegenerate() {
    // Quick regeneration with same settings
    generateProgression();
    generateMelody();
    renderChordDisplay();
    renderMelodyDisplay();
    PianoRoll.loadFromProgression();
    
    // Shake animation
    const chordDisplay = document.getElementById('chord-display');
    if (chordDisplay) {
        chordDisplay.classList.add('shake');
        setTimeout(() => chordDisplay.classList.remove('shake'), 500);
    }
}

// ===================================
// Initialization
// ===================================

document.addEventListener('DOMContentLoaded', () => {
    // Initialize components
    initSettings();
    initCollapsibles();
    initFAB();
    initOnboarding();
    
    // Initialize v2.4 features
    loadHistory();
    renderSmartPresets();
    renderHistoryPanel();
    initSwingControl();
    
    // Initialize piano roll
    PianoRoll.init();
    
    // Set up tab navigation
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', () => {
            switchTab(item.dataset.tab);
        });
    });
    
    // Settings toggle in header
    document.getElementById('settings-toggle').addEventListener('click', () => {
        switchTab('settings');
    });
    
    // Set up event listeners for editor controls
    document.getElementById('play-btn').addEventListener('click', playProgression);
    document.getElementById('stop-btn').addEventListener('click', stopPlayback);
    document.getElementById('clear-btn').addEventListener('click', () => PianoRoll.clear());
    
    // Genre change updates tempo suggestion
    document.getElementById('genre-select').addEventListener('change', (e) => {
        const profile = GENRE_PROFILES[e.target.value];
        document.getElementById('tempo-input').value = profile.tempo;
    });
    
    // Spice It Up button - v2.4
    const spiceBtn = document.getElementById('spice-btn');
    if (spiceBtn) {
        spiceBtn.addEventListener('click', spiceItUp);
    }
    
    // FAB Spice It Up button - v2.4
    const fabSpice = document.getElementById('fab-spice');
    if (fabSpice) {
        fabSpice.addEventListener('click', () => {
            spiceItUp();
            closeFABMenu();
        });
    }
    
    // Initial render
    renderChordDisplay();
    renderMelodyDisplay();
    
    // Handle resize for responsive piano roll
    let resizeTimeout;
    window.addEventListener('resize', () => {
        clearTimeout(resizeTimeout);
        resizeTimeout = setTimeout(() => {
            if (AppState.currentTab === 'editor') {
                PianoRoll.init();
            }
        }, 250);
    });
    
    console.log('🎵 Groovy Chord Generator v2.4 initialized!');
    console.log('Created by Edgar Valle');
});

/**
 * Initialize swing/groove control - v2.4
 */
function initSwingControl() {
    const swingSlider = document.getElementById('swing-slider');
    if (swingSlider) {
        AppState.swing = loadFromStorage('swing', 0);
        swingSlider.value = AppState.swing * 100;
        
        swingSlider.addEventListener('input', (e) => {
            AppState.swing = e.target.value / 100;
            saveToStorage('swing', AppState.swing);
            
            // Update label if exists
            const swingLabel = document.getElementById('swing-value');
            if (swingLabel) {
                swingLabel.textContent = `${Math.round(AppState.swing * 100)}%`;
            }
        });
    }
    
    // Modal interchange toggle
    const modalInterchangeToggle = document.getElementById('modal-interchange');
    if (modalInterchangeToggle) {
        AppState.useModalInterchange = loadFromStorage('useModalInterchange', false);
        modalInterchangeToggle.checked = AppState.useModalInterchange;
        
        modalInterchangeToggle.addEventListener('change', (e) => {
            AppState.useModalInterchange = e.target.checked;
            saveToStorage('useModalInterchange', AppState.useModalInterchange);
        });
    }
}

// Export for potential module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        generateProgression,
        generateMelody,
        exportToMIDI,
        applyVoiceLeading,
        applyAdvancedSubstitutions,
        applyModalInterchange,
        spiceItUp,
        applyPreset,
        GENRE_PROFILES,
        CHORD_TYPES,
        SCALES,
        SMART_PRESETS,
        MODAL_INTERCHANGE
    };
}
