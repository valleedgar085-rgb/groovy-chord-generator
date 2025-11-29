/**
 * Groovy Chord Generator
 * React Context Hook for App State
 * Version 2.4
 */

import { createContext, useContext, useState, useCallback, useRef, type ReactNode } from 'react';
import type {
  AppState,
  GenreKey,
  KeyName,
  ComplexityLevel,
  RhythmLevel,
  SoundType,
  Envelope,
  TabName,
  Chord,
  MelodyNote,
  HistoryEntry,
  AppContextType,
} from '../types';
import {
  GENRE_PROFILES,
  COMPLEXITY_SETTINGS,
  RHYTHM_PATTERNS,
  SMART_PRESETS,
  DEFAULT_STATE,
  DEFAULT_ENVELOPE,
  MAX_HISTORY_LENGTH,
} from '../constants';
import {
  parseKey,
  getChordFromDegree,
  applyVoiceLeading,
  applyAdvancedSubstitutions,
  applyModalInterchange,
  applyGenreVoicing,
  spiceUpProgression,
  randomChoice,
  randomInt,
  getScaleNotes,
  transposeNote,
} from '../utils/musicTheory';
import { saveToStorage, loadFromStorage } from '../utils/storage';
import {
  playChord as playChordAudio,
  playSpiceSound,
  playGenerationSounds,
  playExportSound,
} from '../utils/audio';
import { exportToMIDI } from '../utils/midiExport';
import { CHORD_TYPES } from '../constants';

// Create context
const AppContext = createContext<AppContextType | null>(null);

// Load initial state from localStorage
function loadInitialState(): AppState {
  return {
    currentProgression: [],
    currentMelody: [],
    currentKey: loadFromStorage('currentKey', DEFAULT_STATE.currentKey),
    isMinorKey: false,
    genre: loadFromStorage('genre', DEFAULT_STATE.genre),
    complexity: loadFromStorage('complexity', DEFAULT_STATE.complexity),
    rhythm: loadFromStorage('rhythm', DEFAULT_STATE.rhythm),
    tempo: loadFromStorage('tempo', DEFAULT_STATE.tempo),
    isPlaying: false,
    pianoRollNotes: [],
    audioContext: null,
    masterVolume: loadFromStorage('masterVolume', DEFAULT_STATE.masterVolume),
    soundType: loadFromStorage('soundType', DEFAULT_STATE.soundType),
    showNumerals: loadFromStorage('showNumerals', DEFAULT_STATE.showNumerals),
    showTips: loadFromStorage('showTips', DEFAULT_STATE.showTips),
    currentTab: 'generator',
    onboardingComplete: loadFromStorage('onboardingComplete', false),
    pianoRollZoom: 1,
    useVoiceLeading: loadFromStorage('useVoiceLeading', DEFAULT_STATE.useVoiceLeading),
    useAdvancedTheory: loadFromStorage('useAdvancedTheory', DEFAULT_STATE.useAdvancedTheory),
    envelope: loadFromStorage('envelope', DEFAULT_ENVELOPE),
    swing: loadFromStorage('swing', DEFAULT_STATE.swing),
    useModalInterchange: loadFromStorage('useModalInterchange', DEFAULT_STATE.useModalInterchange),
    currentPreset: null,
    progressionHistory: loadFromStorage('progressionHistory', []),
  };
}

// Provider component
export function AppProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AppState>(loadInitialState);
  const playbackTimeoutRef = useRef<ReturnType<typeof setTimeout>[]>([]);

  // Helper to update state and optionally save to storage
  const updateState = useCallback(<K extends keyof AppState>(
    key: K,
    value: AppState[K],
    persist = false
  ) => {
    setState((prev) => ({ ...prev, [key]: value }));
    if (persist) {
      saveToStorage(key, value);
    }
  }, []);

  // Actions
  const setGenre = useCallback((genre: GenreKey) => {
    const profile = GENRE_PROFILES[genre];
    setState((prev) => ({
      ...prev,
      genre,
      tempo: profile.tempo,
    }));
    saveToStorage('genre', genre);
    saveToStorage('tempo', profile.tempo);
  }, []);

  const setKey = useCallback((key: KeyName) => {
    updateState('currentKey', key, true);
  }, [updateState]);

  const setComplexity = useCallback((complexity: ComplexityLevel) => {
    updateState('complexity', complexity, true);
  }, [updateState]);

  const setRhythm = useCallback((rhythm: RhythmLevel) => {
    updateState('rhythm', rhythm, true);
  }, [updateState]);

  const setTempo = useCallback((tempo: number) => {
    updateState('tempo', tempo, true);
  }, [updateState]);

  const setVolume = useCallback((volume: number) => {
    updateState('masterVolume', volume, true);
  }, [updateState]);

  const setSoundType = useCallback((type: SoundType) => {
    updateState('soundType', type, true);
  }, [updateState]);

  const setEnvelope = useCallback((envelope: Envelope) => {
    updateState('envelope', envelope, true);
  }, [updateState]);

  const setShowNumerals = useCallback((show: boolean) => {
    updateState('showNumerals', show, true);
  }, [updateState]);

  const setShowTips = useCallback((show: boolean) => {
    updateState('showTips', show, true);
  }, [updateState]);

  const setSwing = useCallback((swing: number) => {
    updateState('swing', swing, true);
  }, [updateState]);

  const setUseVoiceLeading = useCallback((use: boolean) => {
    updateState('useVoiceLeading', use, true);
  }, [updateState]);

  const setUseAdvancedTheory = useCallback((use: boolean) => {
    updateState('useAdvancedTheory', use, true);
  }, [updateState]);

  const setUseModalInterchange = useCallback((use: boolean) => {
    updateState('useModalInterchange', use, true);
  }, [updateState]);

  const setCurrentTab = useCallback((tab: TabName) => {
    updateState('currentTab', tab);
  }, [updateState]);

  const setOnboardingComplete = useCallback((complete: boolean) => {
    updateState('onboardingComplete', complete, true);
  }, [updateState]);

  // Generate melody
  const generateMelodyNotes = useCallback((progression: Chord[], genre: GenreKey, rhythm: RhythmLevel, currentKey: KeyName): MelodyNote[] => {
    const profile = GENRE_PROFILES[genre];
    const rhythmPattern = RHYTHM_PATTERNS[rhythm];
    const { root } = parseKey(currentKey);

    const scaleNotes = getScaleNotes(root, profile.melodyScale);
    const melody: MelodyNote[] = [];

    progression.forEach((chord, chordIndex) => {
      const notesPerChord = Math.ceil(4 * rhythmPattern.melodyDensity) + 1;
      const chordTones = CHORD_TYPES[chord.type].intervals.map((i) =>
        transposeNote(chord.root, i)
      );

      for (let i = 0; i < notesPerChord; i++) {
        const useChordTone = Math.random() > 0.3;
        const note = useChordTone
          ? randomChoice(chordTones)
          : randomChoice(scaleNotes);

        const duration = randomChoice(rhythmPattern.durations);
        const velocity = rhythmPattern.dynamics[i % rhythmPattern.dynamics.length];

        melody.push({
          note,
          duration,
          velocity,
          chordIndex,
          octave: randomInt(4, 5),
        });
      }
    });

    return melody;
  }, []);

  // Generate progression
  const generateProgression = useCallback(() => {
    setState((prev) => {
      // Save current progression to history before generating new one
      if (prev.currentProgression.length > 0) {
        const historyCopy = JSON.parse(JSON.stringify(prev.currentProgression)) as Chord[];
        const historyEntry: HistoryEntry = {
          progression: historyCopy,
          key: prev.currentKey,
          genre: prev.genre,
          timestamp: Date.now(),
        };
        const newHistory = [historyEntry, ...prev.progressionHistory].slice(0, MAX_HISTORY_LENGTH);
        saveToStorage('progressionHistory', newHistory);
        prev = { ...prev, progressionHistory: newHistory };
      }

      const { root, isMinor } = parseKey(prev.currentKey);
      const profile = GENRE_PROFILES[prev.genre];
      const complexity = COMPLEXITY_SETTINGS[prev.complexity];

      // Select a base progression
      const baseProgression = randomChoice(profile.progressions);
      const progression = [...baseProgression];

      // Extend based on complexity
      const targetLength = randomInt(complexity.chordCount[0], complexity.chordCount[1]);
      while (progression.length < targetLength) {
        const insertIndex = randomInt(0, progression.length);
        const newChord = randomChoice(['ii', 'IV', 'V', 'vi', 'iii']);
        progression.splice(insertIndex, 0, newChord);
      }

      // Convert degrees to actual chords
      const scale = isMinor ? 'minor' : profile.scale;
      let chords = progression.map((degree) => {
        let chord = getChordFromDegree(root, degree, isMinor, scale);

        // Apply chord extensions
        if (complexity.useExtensions && Math.random() > 0.5) {
          const extensions = profile.chordTypes.filter(
            (t) => t.includes('7') || t.includes('9') || t.includes('sus') || t.includes('add')
          );
          if (extensions.length > 0 && Math.random() > 0.6) {
            chord.type = randomChoice(extensions);
          }
        }

        // Apply genre-specific voicing
        chord = applyGenreVoicing(chord, prev.genre);

        return chord;
      });

      // Apply modal interchange if enabled
      if (prev.useModalInterchange && (prev.complexity === 'complex' || prev.complexity === 'advanced')) {
        chords = applyModalInterchange(chords, root, isMinor);
      }

      // Apply advanced substitutions if enabled
      if (prev.useAdvancedTheory && (prev.complexity === 'complex' || prev.complexity === 'advanced')) {
        chords = applyAdvancedSubstitutions(chords, root, isMinor);
      }

      // Apply voice leading if enabled
      if (prev.useVoiceLeading) {
        applyVoiceLeading(chords);
      }

      // Generate melody
      const melody = generateMelodyNotes(chords, prev.genre, prev.rhythm, prev.currentKey);

      // Play generation sounds
      playGenerationSounds(prev.masterVolume);

      return {
        ...prev,
        currentProgression: chords,
        currentMelody: melody,
        isMinorKey: isMinor,
      };
    });
  }, [generateMelodyNotes]);

  const regenerateProgression = useCallback(() => {
    generateProgression();
  }, [generateProgression]);

  const spiceItUp = useCallback(() => {
    setState((prev) => {
      if (prev.currentProgression.length === 0) return prev;

      const { root, isMinor } = parseKey(prev.currentKey);
      let newProgression = spiceUpProgression(prev.currentProgression, root, isMinor);

      // Re-apply voice leading if enabled
      if (prev.useVoiceLeading) {
        newProgression = applyVoiceLeading(newProgression);
      }

      // Play spice sound
      playSpiceSound(prev.masterVolume);

      return {
        ...prev,
        currentProgression: newProgression,
      };
    });
  }, []);

  const applyPreset = useCallback((presetKey: string) => {
    const preset = SMART_PRESETS[presetKey];
    if (!preset) return;

    setState((prev) => {
      const profile = GENRE_PROFILES[preset.genre];

      return {
        ...prev,
        genre: preset.genre,
        currentKey: preset.key,
        complexity: preset.complexity,
        rhythm: preset.rhythm,
        swing: preset.swing,
        useVoiceLeading: preset.useVoiceLeading,
        useAdvancedTheory: preset.useAdvancedTheory,
        currentPreset: presetKey,
        tempo: profile.tempo,
      };
    });

    // Save preferences
    saveToStorage('genre', preset.genre);
    saveToStorage('currentKey', preset.key);
    saveToStorage('complexity', preset.complexity);
    saveToStorage('rhythm', preset.rhythm);
    saveToStorage('swing', preset.swing);
    saveToStorage('useVoiceLeading', preset.useVoiceLeading);
    saveToStorage('useAdvancedTheory', preset.useAdvancedTheory);

    // Generate new progression with preset settings
    setTimeout(() => generateProgression(), 0);
  }, [generateProgression]);

  const restoreFromHistory = useCallback((index: number) => {
    setState((prev) => {
      if (index < 0 || index >= prev.progressionHistory.length) return prev;

      const entry = prev.progressionHistory[index];
      let restoredProgression = JSON.parse(JSON.stringify(entry.progression)) as Chord[];

      // Re-apply voice leading if enabled
      if (prev.useVoiceLeading) {
        restoredProgression = applyVoiceLeading(restoredProgression);
      }

      return {
        ...prev,
        currentProgression: restoredProgression,
        currentKey: entry.key,
        genre: entry.genre,
      };
    });
  }, []);

  const playProgression = useCallback(() => {
    setState((prev) => {
      if (prev.isPlaying || prev.currentProgression.length === 0) return prev;

      const beatDuration = 60 / prev.tempo;
      const chordDuration = beatDuration * 4;

      // Clear any existing timeouts
      playbackTimeoutRef.current.forEach(clearTimeout);
      playbackTimeoutRef.current = [];

      let currentTime = 0;

      prev.currentProgression.forEach((chord) => {
        const timeout = setTimeout(() => {
          playChordAudio(chord, chordDuration * 0.9, {
            soundType: prev.soundType,
            masterVolume: prev.masterVolume,
            envelope: prev.envelope,
          });
        }, currentTime * 1000);
        playbackTimeoutRef.current.push(timeout);
        currentTime += chordDuration;
      });

      // Reset after progression ends
      const endTimeout = setTimeout(() => {
        setState((s) => ({ ...s, isPlaying: false }));
      }, currentTime * 1000);
      playbackTimeoutRef.current.push(endTimeout);

      return { ...prev, isPlaying: true };
    });
  }, []);

  const stopPlayback = useCallback(() => {
    playbackTimeoutRef.current.forEach(clearTimeout);
    playbackTimeoutRef.current = [];
    updateState('isPlaying', false);
  }, [updateState]);

  const playChord = useCallback((chord: Chord) => {
    setState((prev) => {
      playChordAudio(chord, 1, {
        soundType: prev.soundType,
        masterVolume: prev.masterVolume,
        envelope: prev.envelope,
      });
      return prev;
    });
  }, []);

  const handleExportToMIDI = useCallback(() => {
    setState((prev) => {
      exportToMIDI(prev.currentProgression, prev.currentKey, prev.genre, prev.tempo);
      playExportSound(prev.masterVolume);
      return prev;
    });
  }, []);

  const clearPianoRoll = useCallback(() => {
    updateState('pianoRollNotes', []);
  }, [updateState]);

  const contextValue: AppContextType = {
    state,
    actions: {
      setGenre,
      setKey,
      setComplexity,
      setRhythm,
      setTempo,
      setVolume,
      setSoundType,
      setEnvelope,
      setShowNumerals,
      setShowTips,
      setSwing,
      setUseVoiceLeading,
      setUseAdvancedTheory,
      setUseModalInterchange,
      setCurrentTab,
      setOnboardingComplete,
      generateProgression,
      regenerateProgression,
      spiceItUp,
      applyPreset,
      restoreFromHistory,
      playProgression,
      stopPlayback,
      playChord,
      exportToMIDI: handleExportToMIDI,
      clearPianoRoll,
    },
  };

  return <AppContext.Provider value={contextValue}>{children}</AppContext.Provider>;
}

// Custom hook to use the context
export function useApp(): AppContextType {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
}
