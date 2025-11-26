// Groovy Chord Progression Generator
// Created by Edgar Valle

// Music Theory Data
const NOTES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

// Scale patterns (intervals from root)
const SCALES = {
    major: [0, 2, 4, 5, 7, 9, 11],
    minor: [0, 2, 3, 5, 7, 8, 10]
};

// Chord quality patterns
const CHORD_QUALITIES = {
    major: { symbol: '', intervals: [0, 4, 7] },
    minor: { symbol: 'm', intervals: [0, 3, 7] },
    diminished: { symbol: '°', intervals: [0, 3, 6] },
    augmented: { symbol: '+', intervals: [0, 4, 8] },
    major7: { symbol: 'maj7', intervals: [0, 4, 7, 11] },
    minor7: { symbol: 'm7', intervals: [0, 3, 7, 10] },
    dominant7: { symbol: '7', intervals: [0, 4, 7, 10] },
    diminished7: { symbol: '°7', intervals: [0, 3, 6, 9] },
    halfDiminished7: { symbol: 'ø7', intervals: [0, 3, 6, 10] },
    major9: { symbol: 'maj9', intervals: [0, 4, 7, 11, 14] },
    minor9: { symbol: 'm9', intervals: [0, 3, 7, 10, 14] },
    add9: { symbol: 'add9', intervals: [0, 4, 7, 14] }
};

// Diatonic chord numerals and qualities for each scale degree
const DIATONIC_CHORDS = {
    major: {
        simple: [
            { numeral: 'I', degree: 0, quality: 'major' },
            { numeral: 'ii', degree: 1, quality: 'minor' },
            { numeral: 'iii', degree: 2, quality: 'minor' },
            { numeral: 'IV', degree: 3, quality: 'major' },
            { numeral: 'V', degree: 4, quality: 'major' },
            { numeral: 'vi', degree: 5, quality: 'minor' },
            { numeral: 'vii°', degree: 6, quality: 'diminished' }
        ],
        advanced: [
            { numeral: 'I', degree: 0, quality: 'major7' },
            { numeral: 'ii', degree: 1, quality: 'minor7' },
            { numeral: 'iii', degree: 2, quality: 'minor7' },
            { numeral: 'IV', degree: 3, quality: 'major7' },
            { numeral: 'V', degree: 4, quality: 'dominant7' },
            { numeral: 'vi', degree: 5, quality: 'minor7' },
            { numeral: 'vii°', degree: 6, quality: 'halfDiminished7' }
        ],
        jazzy: [
            { numeral: 'Imaj9', degree: 0, quality: 'major9' },
            { numeral: 'ii9', degree: 1, quality: 'minor9' },
            { numeral: 'iii7', degree: 2, quality: 'minor7' },
            { numeral: 'IVmaj7', degree: 3, quality: 'major7' },
            { numeral: 'V9', degree: 4, quality: 'dominant7' },
            { numeral: 'vi9', degree: 5, quality: 'minor9' },
            { numeral: 'viiø7', degree: 6, quality: 'halfDiminished7' }
        ]
    },
    minor: {
        simple: [
            { numeral: 'i', degree: 0, quality: 'minor' },
            { numeral: 'ii°', degree: 1, quality: 'diminished' },
            { numeral: 'III', degree: 2, quality: 'major' },
            { numeral: 'iv', degree: 3, quality: 'minor' },
            { numeral: 'v', degree: 4, quality: 'minor' },
            { numeral: 'VI', degree: 5, quality: 'major' },
            { numeral: 'VII', degree: 6, quality: 'major' }
        ],
        advanced: [
            { numeral: 'i7', degree: 0, quality: 'minor7' },
            { numeral: 'iiø7', degree: 1, quality: 'halfDiminished7' },
            { numeral: 'III7', degree: 2, quality: 'major7' },
            { numeral: 'iv7', degree: 3, quality: 'minor7' },
            { numeral: 'v7', degree: 4, quality: 'minor7' },
            { numeral: 'VI7', degree: 5, quality: 'major7' },
            { numeral: 'VII7', degree: 6, quality: 'dominant7' }
        ],
        jazzy: [
            { numeral: 'i9', degree: 0, quality: 'minor9' },
            { numeral: 'iiø7', degree: 1, quality: 'halfDiminished7' },
            { numeral: 'IIImaj7', degree: 2, quality: 'major7' },
            { numeral: 'iv9', degree: 3, quality: 'minor9' },
            { numeral: 'V7', degree: 4, quality: 'dominant7' },
            { numeral: 'VImaj7', degree: 5, quality: 'major7' },
            { numeral: 'VII7', degree: 6, quality: 'dominant7' }
        ]
    }
};

// Genre-specific progression patterns (using scale degrees 0-6)
const GENRE_PROGRESSIONS = {
    'happy-pop': {
        preferredMode: 'major',
        patterns: [
            [0, 4, 5, 3],    // I-V-vi-IV (most popular pop progression)
            [0, 3, 4, 4],    // I-IV-V-V
            [0, 5, 3, 4],    // I-vi-IV-V
            [0, 3, 0, 4],    // I-IV-I-V
            [0, 3, 5, 4]     // I-IV-vi-V
        ]
    },
    'dark-trap': {
        preferredMode: 'minor',
        patterns: [
            [0, 5, 3, 6],    // i-VI-iv-VII
            [0, 6, 5, 3],    // i-VII-VI-iv
            [0, 3, 5, 1],    // i-iv-VI-ii° (with diminished)
            [0, 1, 5, 3],    // i-ii°-VI-iv
            [0, 5, 6, 3]     // i-VI-VII-iv
        ]
    },
    'lofi': {
        preferredMode: 'major',
        patterns: [
            [1, 4, 0, 5],    // ii-V-I-vi
            [0, 5, 1, 4],    // I-vi-ii-V
            [3, 4, 2, 5],    // IV-V-iii-vi
            [0, 2, 5, 3],    // I-iii-vi-IV
            [5, 3, 0, 4]     // vi-IV-I-V
        ]
    },
    'neo-soul': {
        preferredMode: 'major',
        patterns: [
            [1, 4, 2, 5],    // ii-V-iii-vi
            [3, 2, 1, 0],    // IV-iii-ii-I
            [0, 6, 2, 5],    // I-vii°-iii-vi
            [5, 1, 4, 0],    // vi-ii-V-I
            [3, 0, 5, 1]     // IV-I-vi-ii
        ]
    }
};

// State
let currentProgression = [];
let currentKey = { root: 'C', mode: 'major' };
let currentGenre = 'happy-pop';
let currentComplexity = 'simple';
let currentRhythm = 'straight';
let selectedSlot = null;

// DOM Elements
const genreSelect = document.getElementById('genre');
const keySelect = document.getElementById('key');
const complexitySelect = document.getElementById('complexity');
const rhythmSelect = document.getElementById('rhythm');
const generateBtn = document.getElementById('generate-btn');
const regenerateBtn = document.getElementById('regenerate-btn');
const melodyBtn = document.getElementById('melody-btn');
const chordGrid = document.getElementById('chord-grid');
const melodyDisplay = document.getElementById('melody-display');
const rhythmIndicator = document.getElementById('rhythm-indicator');
const modal = document.getElementById('chord-modal');
const chordOptions = document.getElementById('chord-options');
const modalClose = document.getElementById('modal-close');

// Helper Functions
function parseKey(keyValue) {
    const parts = keyValue.split('-');
    return {
        root: parts[0],
        mode: parts[1]
    };
}

function getNoteIndex(note) {
    return NOTES.indexOf(note);
}

function getNote(index) {
    return NOTES[((index % 12) + 12) % 12];
}

function getScaleNotes(root, mode) {
    const rootIndex = getNoteIndex(root);
    const pattern = SCALES[mode];
    return pattern.map(interval => getNote(rootIndex + interval));
}

function getChordName(root, quality) {
    const qualitySymbol = CHORD_QUALITIES[quality].symbol;
    return root + qualitySymbol;
}

function getAvailableChords(key, complexity) {
    const scaleNotes = getScaleNotes(key.root, key.mode);
    const chordSet = DIATONIC_CHORDS[key.mode][complexity];
    
    return chordSet.map(chord => ({
        name: getChordName(scaleNotes[chord.degree], chord.quality),
        numeral: chord.numeral,
        degree: chord.degree,
        quality: chord.quality,
        root: scaleNotes[chord.degree]
    }));
}

function generateProgression() {
    const key = parseKey(keySelect.value);
    currentKey = key;
    currentGenre = genreSelect.value;
    currentComplexity = complexitySelect.value;
    currentRhythm = rhythmSelect.value;
    
    const genreData = GENRE_PROGRESSIONS[currentGenre];
    const availableChords = getAvailableChords(key, currentComplexity);
    
    // Randomly select a pattern from the genre
    const patterns = genreData.patterns;
    const selectedPattern = patterns[Math.floor(Math.random() * patterns.length)];
    
    // Build the progression
    currentProgression = selectedPattern.map(degree => {
        const chord = availableChords.find(c => c.degree === degree);
        return chord ? { ...chord } : availableChords[0];
    });
    
    updateChordDisplay();
    updateRhythmIndicator();
    clearMelody();
}

function updateChordDisplay() {
    const slots = chordGrid.querySelectorAll('.chord-slot');
    
    slots.forEach((slot, index) => {
        if (currentProgression[index]) {
            const chord = currentProgression[index];
            slot.classList.remove('empty');
            slot.querySelector('.chord-name').textContent = chord.name;
            slot.querySelector('.chord-numeral').textContent = chord.numeral;
        } else {
            slot.classList.add('empty');
            slot.querySelector('.chord-name').textContent = '-';
            slot.querySelector('.chord-numeral').textContent = '-';
        }
    });
}

function updateRhythmIndicator() {
    const rhythmNames = {
        'straight': 'Straight 4/4',
        'triplet': 'Triplet/Trap',
        'swing': 'Swing'
    };
    rhythmIndicator.querySelector('span').textContent = `Rhythm: ${rhythmNames[currentRhythm]}`;
}

function openChordEditor(slotIndex) {
    if (currentProgression.length === 0) {
        alert('Please generate a progression first!');
        return;
    }
    
    selectedSlot = slotIndex;
    const availableChords = getAvailableChords(currentKey, currentComplexity);
    
    // Populate chord options
    chordOptions.innerHTML = '';
    availableChords.forEach(chord => {
        const option = document.createElement('div');
        option.className = 'chord-option';
        option.textContent = chord.name;
        option.dataset.degree = chord.degree;
        option.addEventListener('click', () => selectChord(chord));
        chordOptions.appendChild(option);
    });
    
    modal.classList.add('active');
}

function selectChord(chord) {
    if (selectedSlot !== null && currentProgression[selectedSlot]) {
        currentProgression[selectedSlot] = { ...chord };
        updateChordDisplay();
        closeModal();
    }
}

function closeModal() {
    modal.classList.remove('active');
    selectedSlot = null;
}

function generateMelody() {
    if (currentProgression.length === 0) {
        alert('Please generate a chord progression first!');
        return;
    }
    
    const scaleNotes = getScaleNotes(currentKey.root, currentKey.mode);
    let melody = [];
    
    // Generate 2 notes per chord (8 total)
    currentProgression.forEach(chord => {
        // Get chord tones
        const chordRootIndex = NOTES.indexOf(chord.root);
        const chordTones = CHORD_QUALITIES[chord.quality].intervals.map(
            interval => getNote(chordRootIndex + interval)
        );
        
        // Pick notes that are either chord tones or scale notes
        const notePool = [...new Set([...chordTones, ...scaleNotes])];
        
        // Generate 2 notes for this chord
        for (let i = 0; i < 2; i++) {
            // Favor chord tones (70% chance) over scale notes
            if (Math.random() < 0.7 && chordTones.length > 0) {
                melody.push(chordTones[Math.floor(Math.random() * chordTones.length)]);
            } else {
                melody.push(scaleNotes[Math.floor(Math.random() * scaleNotes.length)]);
            }
        }
    });
    
    displayMelody(melody);
}

function displayMelody(melody) {
    melodyDisplay.innerHTML = '';
    const container = document.createElement('div');
    container.className = 'melody-notes';
    
    melody.forEach(note => {
        const noteElement = document.createElement('span');
        noteElement.className = 'melody-note';
        noteElement.textContent = note;
        container.appendChild(noteElement);
    });
    
    melodyDisplay.appendChild(container);
}

function clearMelody() {
    melodyDisplay.innerHTML = '<p class="melody-placeholder">Generate a chord progression first, then add a melody!</p>';
}

// Event Listeners
generateBtn.addEventListener('click', generateProgression);
regenerateBtn.addEventListener('click', generateProgression);
melodyBtn.addEventListener('click', generateMelody);
modalClose.addEventListener('click', closeModal);

// Close modal when clicking outside
modal.addEventListener('click', (e) => {
    if (e.target === modal) {
        closeModal();
    }
});

// Chord slot click handlers
chordGrid.querySelectorAll('.chord-slot').forEach((slot, index) => {
    slot.addEventListener('click', () => openChordEditor(index));
});

// Update rhythm indicator when rhythm changes
rhythmSelect.addEventListener('change', () => {
    currentRhythm = rhythmSelect.value;
    updateRhythmIndicator();
});

// Initialize
updateRhythmIndicator();
