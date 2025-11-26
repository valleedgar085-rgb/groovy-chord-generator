/**
 * Groovy Chord Progression Generator
 * app.js - Main Application Logic
 * Created by Edgar Valle
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
    oscillators: []
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

function generateProgression() {
    const { root, isMinor } = parseKey(AppState.currentKey);
    AppState.isMinorKey = isMinor;
    
    const profile = GENRE_PROFILES[AppState.genre];
    const complexity = COMPLEXITY_SETTINGS[AppState.complexity];
    
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
    const chords = progression.map(degree => {
        const chord = getChordFromDegree(root, degree, isMinor, scale);
        
        // Apply chord extensions for complex settings
        if (complexity.useExtensions && Math.random() > 0.5) {
            const extensions = profile.chordTypes.filter(t => 
                t.includes('7') || t.includes('9') || t.includes('sus') || t.includes('add')
            );
            if (extensions.length > 0 && Math.random() > 0.6) {
                chord.type = randomChoice(extensions);
            }
        }
        
        return chord;
    });
    
    AppState.currentProgression = chords;
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
        container.innerHTML = '<div class="chord-placeholder">Click "Generate Progression" to start</div>';
        return;
    }
    
    container.innerHTML = AppState.currentProgression.map((chord, index) => {
        const chordSymbol = CHORD_TYPES[chord.type]?.symbol || '';
        const displayName = chord.root + chordSymbol;
        
        return `
            <div class="chord-card" data-index="${index}" onclick="toggleChordActive(${index})">
                <div class="chord-name">${displayName}</div>
                <div class="chord-type">${CHORD_TYPES[chord.type]?.name || chord.type}</div>
                <div class="chord-numeral">${chord.degree}</div>
            </div>
        `;
    }).join('');
}

function renderMelodyDisplay() {
    const container = document.getElementById('melody-display');
    
    if (AppState.currentMelody.length === 0) {
        container.innerHTML = '<div class="melody-placeholder">Melody will appear after generation</div>';
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
// Piano Roll / Visual Editor
// ===================================

const PianoRoll = {
    canvas: null,
    ctx: null,
    noteHeight: 20,
    beatWidth: 60,
    totalBeats: 16,
    notes: [],
    
    init() {
        this.canvas = document.getElementById('piano-roll-canvas');
        this.ctx = this.canvas.getContext('2d');
        this.setupCanvas();
        this.renderPianoKeys();
        this.draw();
        this.setupEventListeners();
    },
    
    setupCanvas() {
        const container = document.querySelector('.piano-roll');
        this.canvas.width = this.beatWidth * this.totalBeats;
        this.canvas.height = this.noteHeight * 24; // 2 octaves
        this.canvas.style.width = this.canvas.width + 'px';
        this.canvas.style.height = this.canvas.height + 'px';
    },
    
    renderPianoKeys() {
        const container = document.getElementById('piano-keys');
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
    },
    
    draw() {
        const ctx = this.ctx;
        const { width, height } = this.canvas;
        
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
            const x = i * this.beatWidth;
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
        const gradient = ctx.createLinearGradient(note.x, note.y, note.x + note.width, note.y);
        gradient.addColorStop(0, '#7c3aed');
        gradient.addColorStop(1, '#ec4899');
        
        ctx.fillStyle = gradient;
        ctx.fillRect(note.x, note.y, note.width, this.noteHeight - 2);
        
        // Note border
        ctx.strokeStyle = '#a855f7';
        ctx.lineWidth = 1;
        ctx.strokeRect(note.x, note.y, note.width, this.noteHeight - 2);
    },
    
    setupEventListeners() {
        this.canvas.addEventListener('click', (e) => this.handleClick(e));
    },
    
    handleClick(e) {
        const rect = this.canvas.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        
        // Find clicked note or create new one
        const clickedNoteIndex = this.notes.findIndex(note => 
            x >= note.x && x <= note.x + note.width &&
            y >= note.y && y <= note.y + this.noteHeight
        );
        
        if (clickedNoteIndex !== -1) {
            // Remove note
            this.notes.splice(clickedNoteIndex, 1);
        } else {
            // Add note
            const beatIndex = Math.floor(x / this.beatWidth);
            const noteIndex = Math.floor(y / this.noteHeight);
            
            this.notes.push({
                x: beatIndex * this.beatWidth,
                y: noteIndex * this.noteHeight,
                width: this.beatWidth,
                noteIndex,
                beat: beatIndex
            });
        }
        
        this.draw();
    },
    
    loadFromProgression() {
        this.notes = [];
        
        AppState.currentProgression.forEach((chord, chordIndex) => {
            const chordNotes = CHORD_TYPES[chord.type].intervals;
            const rootIndex = getNoteIndex(chord.root);
            
            chordNotes.forEach((interval, noteNum) => {
                const noteIndex = 12 - ((rootIndex + interval) % 12);
                this.notes.push({
                    x: chordIndex * this.beatWidth * 4,
                    y: noteIndex * this.noteHeight,
                    width: this.beatWidth * 4,
                    noteIndex,
                    beat: chordIndex * 4
                });
            });
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
    
    oscillator.type = 'sine';
    oscillator.frequency.setValueAtTime(frequency, ctx.currentTime + time);
    
    gainNode.gain.setValueAtTime(0.3, ctx.currentTime + time);
    gainNode.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + time + duration);
    
    oscillator.connect(gainNode);
    gainNode.connect(ctx.destination);
    
    oscillator.start(ctx.currentTime + time);
    oscillator.stop(ctx.currentTime + time + duration);
    
    return oscillator;
}

function playChord(chord, duration = 1) {
    const ctx = initAudio();
    const intervals = CHORD_TYPES[chord.type]?.intervals || [0, 4, 7];
    
    intervals.forEach((interval, i) => {
        const note = transposeNote(chord.root, interval);
        playNote(note, 4, duration, i * 0.02); // Slight arpeggio effect
    });
}

function playProgression() {
    if (AppState.isPlaying) return;
    AppState.isPlaying = true;
    
    const ctx = initAudio();
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
    
    // Generate progression and melody
    generateProgression();
    generateMelody();
    
    // Update UI
    renderChordDisplay();
    renderMelodyDisplay();
    PianoRoll.loadFromProgression();
    
    // Add animation effect
    document.querySelector('.chord-display-section').classList.add('pulse');
    setTimeout(() => {
        document.querySelector('.chord-display-section').classList.remove('pulse');
    }, 500);
}

function handleRegenerate() {
    // Quick regeneration with same settings
    generateProgression();
    generateMelody();
    renderChordDisplay();
    renderMelodyDisplay();
    PianoRoll.loadFromProgression();
    
    // Shake animation
    document.querySelector('.chord-display').classList.add('shake');
    setTimeout(() => {
        document.querySelector('.chord-display').classList.remove('shake');
    }, 500);
}

// ===================================
// Initialization
// ===================================

document.addEventListener('DOMContentLoaded', () => {
    // Initialize piano roll
    PianoRoll.init();
    
    // Set up event listeners
    document.getElementById('generate-btn').addEventListener('click', handleGenerate);
    document.getElementById('regenerate-btn').addEventListener('click', handleRegenerate);
    document.getElementById('play-btn').addEventListener('click', playProgression);
    document.getElementById('stop-btn').addEventListener('click', stopPlayback);
    document.getElementById('clear-btn').addEventListener('click', () => PianoRoll.clear());
    
    // Genre change updates tempo suggestion
    document.getElementById('genre-select').addEventListener('change', (e) => {
        const profile = GENRE_PROFILES[e.target.value];
        document.getElementById('tempo-input').value = profile.tempo;
    });
    
    // Initial render
    renderChordDisplay();
    renderMelodyDisplay();
    
    console.log('🎵 Groovy Chord Generator initialized!');
    console.log('Created by Edgar Valle');
});

// Export for potential module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        generateProgression,
        generateMelody,
        GENRE_PROFILES,
        CHORD_TYPES,
        SCALES
    };
}
