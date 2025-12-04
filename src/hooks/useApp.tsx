/**
 * Groovy Chord Generator
 * React Context Hook for App State
 * Version 2.5
 */

import {
  createContext,
  useContext,
  useState,
  useCallback,
  useRef,
  useEffect,
  type ReactNode,
} from 'react';
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
  BassStyle,
  HistoryEntry,
  AppContextType,
  ScaleName,
  MoodType,
  GrooveTemplate,
  SpiceLevel,
  LockedChord,
} from '../types';
import {
  GENRE_PROFILES,
  COMPLEXITY_SETTINGS,
  RHYTHM_PATTERNS,
  SMART_PRESETS,
  DEFAULT_STATE,
  DEFAULT_ENVELOPE,
  MAX_HISTORY_LENGTH,
  CHORD_TYPES,
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
  generateBassLine as generateBassLineUtil,
  generateFunctionalProgression,
  applySpiceToProgression,
} from '../utils/musicTheory';
import { saveToStorage, loadFromStorage } from '../utils/storage';
import {
  playChord as playChordAudio,
  playBassNote as playBassNoteAudio,
  playSpiceSound,
  playGenerationSounds,
  playExportSound,
} from '../utils/audio';
import { exportToMIDI } from '../utils/midiExport';
import { applyGrooveToProgression } from '../utils/GrooveEngine';

// Helpers

function deepCloneProgression(prog: Chord[]): Chord[] {
  if (typeof structuredClone === 'function') {
    return structuredClone(prog) as Chord[];
  }
  return JSON.parse(JSON.stringify(prog)) as Chord[];
}

function loadInitialState(): AppState {
  return {
    currentProgression: [],
    currentMelody: [],
    currentBassLine: [],
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
    useModalInterchange: loadFromStorage(
      'useModalInterchange',
      DEFAULT_STATE.useModalInterchange,
    ),
    includeMelody: loadFromStorage('includeMelody', DEFAULT_STATE.includeMelody),
    includeBass: loadFromStorage('includeBass', DEFAULT_STATE.includeBass),
    bassStyle: loadFromStorage('bassStyle', DEFAULT_STATE.bassStyle),
    bassVariety: loadFromStorage('bassVariety', DEFAULT_STATE.bassVariety),
    chordVariety: loadFromStorage('chordVariety', DEFAULT_STATE.chordVariety),
    rhythmVariety: loadFromStorage('rhythmVariety', DEFAULT_STATE.rhythmVariety),
    currentPreset: null,
    progressionHistory: loadFromStorage('progressionHistory', []),
    // Phase 1: Mood/Mode Selector
    currentMood: loadFromStorage('currentMood', DEFAULT_STATE.currentMood),
    useFunctionalHarmony: loadFromStorage('useFunctionalHarmony', DEFAULT_STATE.useFunctionalHarmony),
    // Phase 2: Groove Engine
    grooveTemplate: loadFromStorage('grooveTemplate', DEFAULT_STATE.grooveTemplate),
    // Phase 3: Spice Control
    spiceLevel: loadFromStorage('spiceLevel', DEFAULT_STATE.spiceLevel),
    lockedChords: [],
  };
}

// Build base degree sequence given complexity
function buildDegreeSequence(
  baseProgression: string[],
  complexityConfig: (typeof COMPLEXITY_SETTINGS)[ComplexityLevel],
): string[] {
  const progression = [...baseProgression];
  const targetLength = randomInt(
    complexityConfig.chordCount[0],
    complexityConfig.chordCount[1],
  );

  while (progression.length < targetLength) {
    const insertIndex = randomInt(0, progression.length);
    const newChord = randomChoice(['ii', 'IV', 'V', 'vi', 'iii']);
    progression.splice(insertIndex, 0, newChord);
  }

  return progression;
}

interface BuildChordArgs {
  degree: string;
  root: string;
  isMinor: boolean;
  scale: ScaleName;
  profile: (typeof GENRE_PROFILES)[GenreKey];
  complexityConfig: (typeof COMPLEXITY_SETTINGS)[ComplexityLevel];
  genre: GenreKey;
}

function buildChordForDegree({
  degree,
  root,
  isMinor,
  scale,
  profile,
  complexityConfig,
  genre,
}: BuildChordArgs): Chord {
  let chord = getChordFromDegree(root, degree, isMinor, scale);

  if (complexityConfig.useExtensions && Math.random() > 0.5) {
    const extensions = profile.chordTypes.filter(
      (t) => t.includes('7') || t.includes('9') || t.includes('sus') || t.includes('add'),
    );

    if (extensions.length > 0 && Math.random() > 0.6) {
      chord.type = randomChoice(extensions);
    }
  }

  chord = applyGenreVoicing(chord, genre);
  return chord;
}

// Context

const AppContext = createContext<AppContextType | null>(null);

export function AppProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AppState>(loadInitialState);
  const stateRef = useRef<AppState>(state);
  const playbackTimeoutRef = useRef<ReturnType<typeof setTimeout>[]>([]);
  const isPlayingRef = useRef(false);

  useEffect(() => {
    stateRef.current = state;
  }, [state]);

  // Generic state updater with optional persistence
  const updateState = useCallback(
    <K extends keyof AppState>(key: K, value: AppState[K], persist = false) => {
      setState((prev) => {
        const next = { ...prev, [key]: value };
        return next;
      });
      if (persist) {
        saveToStorage(key, value);
      }
    },
    [],
  );

  // Actions: preferences / UI

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

  const setKey = useCallback(
    (key: KeyName) => {
      updateState('currentKey', key, true);
    },
    [updateState],
  );

  const setComplexity = useCallback(
    (complexity: ComplexityLevel) => {
      updateState('complexity', complexity, true);
    },
    [updateState],
  );

  const setRhythm = useCallback(
    (rhythm: RhythmLevel) => {
      updateState('rhythm', rhythm, true);
    },
    [updateState],
  );

  const setTempo = useCallback(
    (tempo: number) => {
      updateState('tempo', tempo, true);
    },
    [updateState],
  );

  const setVolume = useCallback(
    (volume: number) => {
      updateState('masterVolume', volume, true);
    },
    [updateState],
  );

  const setSoundType = useCallback(
    (type: SoundType) => {
      updateState('soundType', type, true);
    },
    [updateState],
  );

  const setEnvelope = useCallback(
    (envelope: Envelope) => {
      updateState('envelope', envelope, true);
    },
    [updateState],
  );

  const setShowNumerals = useCallback(
    (show: boolean) => {
      updateState('showNumerals', show, true);
    },
    [updateState],
  );

  const setShowTips = useCallback(
    (show: boolean) => {
      updateState('showTips', show, true);
    },
    [updateState],
  );

  const setSwing = useCallback(
    (swing: number) => {
      updateState('swing', swing, true);
    },
    [updateState],
  );

  const setUseVoiceLeading = useCallback(
    (use: boolean) => {
      updateState('useVoiceLeading', use, true);
    },
    [updateState],
  );

  const setUseAdvancedTheory = useCallback(
    (use: boolean) => {
      updateState('useAdvancedTheory', use, true);
    },
    [updateState],
  );

  const setUseModalInterchange = useCallback(
    (use: boolean) => {
      updateState('useModalInterchange', use, true);
    },
    [updateState],
  );

  const setIncludeMelody = useCallback(
    (include: boolean) => {
      updateState('includeMelody', include, true);
    },
    [updateState],
  );

  const setIncludeBass = useCallback(
    (include: boolean) => {
      updateState('includeBass', include, true);
    },
    [updateState],
  );

  const setBassStyle = useCallback(
    (style: BassStyle) => {
      updateState('bassStyle', style, true);
    },
    [updateState],
  );

  const setBassVariety = useCallback(
    (variety: number) => {
      updateState('bassVariety', variety, true);
    },
    [updateState],
  );

  const setChordVariety = useCallback(
    (variety: number) => {
      updateState('chordVariety', variety, true);
    },
    [updateState],
  );

  const setRhythmVariety = useCallback(
    (variety: number) => {
      updateState('rhythmVariety', variety, true);
    },
    [updateState],
  );

  const setCurrentTab = useCallback(
    (tab: TabName) => {
      updateState('currentTab', tab);
    },
    [updateState],
  );

  const setOnboardingComplete = useCallback(
    (complete: boolean) => {
      updateState('onboardingComplete', complete, true);
    },
    [updateState],
  );

  const clearPianoRoll = useCallback(() => {
    updateState('pianoRollNotes', []);
  }, [updateState]);

  // Phase 1: Mood/Mode Selector Actions
  const setMood = useCallback(
    (mood: MoodType) => {
      updateState('currentMood', mood, true);
    },
    [updateState],
  );

  const setUseFunctionalHarmony = useCallback(
    (use: boolean) => {
      updateState('useFunctionalHarmony', use, true);
    },
    [updateState],
  );

  // Phase 2: Groove Engine Actions
  const setGrooveTemplate = useCallback(
    (template: GrooveTemplate) => {
      updateState('grooveTemplate', template, true);
    },
    [updateState],
  );

  // Phase 3: Spice Control Actions
  const setSpiceLevel = useCallback(
    (level: SpiceLevel) => {
      updateState('spiceLevel', level, true);
    },
    [updateState],
  );

  const toggleChordLock = useCallback((index: number) => {
    setState((prev) => {
      const existingLock = prev.lockedChords.find((lc) => lc.index === index);
      let newLockedChords: LockedChord[];
      
      if (existingLock) {
        // Toggle existing lock
        newLockedChords = prev.lockedChords.map((lc) =>
          lc.index === index ? { ...lc, locked: !lc.locked } : lc
        );
      } else {
        // Add new lock
        newLockedChords = [...prev.lockedChords, { index, locked: true }];
      }
      
      return { ...prev, lockedChords: newLockedChords };
    });
  }, []);

  // Melody generation

  const generateMelodyNotes = useCallback(
    (progression: Chord[], genre: GenreKey, rhythm: RhythmLevel, currentKey: KeyName): MelodyNote[] => {
      const profile = GENRE_PROFILES[genre];
      const rhythmPattern = RHYTHM_PATTERNS[rhythm];
      const { root } = parseKey(currentKey);

      const scaleNotes = getScaleNotes(root, profile.melodyScale);
      const melody: MelodyNote[] = [];

      progression.forEach((chord, chordIndex) => {
        const notesPerChord = Math.ceil(4 * rhythmPattern.melodyDensity) + 1;
        const chordTones = CHORD_TYPES[chord.type].intervals.map((interval) =>
          transposeNote(chord.root, interval),
        );

        for (let i = 0; i < notesPerChord; i++) {
          const useChordTone = Math.random() > 0.3;
          const sourcePool = useChordTone ? chordTones : scaleNotes;

          const note = randomChoice(sourcePool);
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
    },
    [],
  );

  // Progression generation / history

  const generateProgression = useCallback(() => {
    setState((prev) => {
      let next: AppState = prev;

      // Save current progression to history if present
      if (prev.currentProgression.length > 0) {
        const historyCopy = deepCloneProgression(prev.currentProgression);
        const historyEntry: HistoryEntry = {
          progression: historyCopy,
          key: prev.currentKey,
          genre: prev.genre,
          timestamp: Date.now(),
        };

        const newHistory = [historyEntry, ...prev.progressionHistory].slice(
          0,
          MAX_HISTORY_LENGTH,
        );
        saveToStorage('progressionHistory', newHistory);

        next = { ...prev, progressionHistory: newHistory };
      }

      const { root, isMinor } = parseKey(next.currentKey);
      const profile = GENRE_PROFILES[next.genre];
      const complexityConfig = COMPLEXITY_SETTINGS[next.complexity];

      let chords: Chord[];

      // Phase 1: Use functional harmony if enabled
      if (next.useFunctionalHarmony) {
        chords = generateFunctionalProgression(
          root,
          isMinor,
          complexityConfig.chordCount[1],
          next.currentMood
        );
      } else {
        // Original progression generation
        const baseProgression = randomChoice(profile.progressions);
        const degreeSequence = buildDegreeSequence(baseProgression, complexityConfig);

        const scale = isMinor ? 'minor' : profile.scale;

        chords = degreeSequence.map((degree) =>
          buildChordForDegree({
            degree,
            root,
            isMinor,
            scale,
            profile,
            complexityConfig,
            genre: next.genre,
          }),
        );
      }

      // Preserve locked chords
      if (next.lockedChords.length > 0 && prev.currentProgression.length > 0) {
        next.lockedChords.forEach((lc) => {
          if (lc.locked && lc.index < prev.currentProgression.length && lc.index < chords.length) {
            chords[lc.index] = prev.currentProgression[lc.index];
          }
        });
      }

      if (
        next.useModalInterchange &&
        (next.complexity === 'complex' || next.complexity === 'advanced')
      ) {
        chords = applyModalInterchange(chords, root, isMinor);
      }

      if (
        next.useAdvancedTheory &&
        (next.complexity === 'complex' || next.complexity === 'advanced')
      ) {
        chords = applyAdvancedSubstitutions(chords, root, isMinor);
      }

      // Phase 3: Apply spice level to chords
      chords = applySpiceToProgression(chords, next.spiceLevel);

      // Phase 2: Apply groove template
      chords = applyGrooveToProgression(chords, next.grooveTemplate);

      if (next.useVoiceLeading) {
        applyVoiceLeading(chords);
      }

      // Only generate melody if includeMelody is enabled
      const melody = next.includeMelody
        ? generateMelodyNotes(
            chords,
            next.genre,
            next.rhythm,
            next.currentKey,
          )
        : [];

      // Generate bass line if includeBass is enabled
      const bassLine = next.includeBass
        ? generateBassLineUtil(
            chords,
            next.bassStyle,
            next.bassVariety,
            next.rhythm,
          )
        : [];

      playGenerationSounds(next.masterVolume);

      return {
        ...next,
        currentProgression: chords,
        currentMelody: melody,
        currentBassLine: bassLine,
        isMinorKey: isMinor,
      };
    });
  }, [generateMelodyNotes]);

  const generateBassLine = useCallback(() => {
    setState((prev) => {
      if (prev.currentProgression.length === 0) return prev;

      const bassLine = generateBassLineUtil(
        prev.currentProgression,
        prev.bassStyle,
        prev.bassVariety,
        prev.rhythm,
      );

      playGenerationSounds(prev.masterVolume);

      return {
        ...prev,
        currentBassLine: bassLine,
      };
    });
  }, []);

  const regenerateProgression = useCallback(() => {
    generateProgression();
  }, [generateProgression]);

  const spiceItUp = useCallback(() => {
    setState((prev) => {
      if (prev.currentProgression.length === 0) return prev;

      const { root, isMinor } = parseKey(prev.currentKey);
      let newProgression = spiceUpProgression(prev.currentProgression, root, isMinor);

      if (prev.useVoiceLeading) {
        newProgression = applyVoiceLeading(newProgression);
      }

      playSpiceSound(prev.masterVolume);

      return {
        ...prev,
        currentProgression: newProgression,
      };
    });
  }, []);

  const applyPreset = useCallback(
    (presetKey: string) => {
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

      saveToStorage('genre', preset.genre);
      saveToStorage('currentKey', preset.key);
      saveToStorage('complexity', preset.complexity);
      saveToStorage('rhythm', preset.rhythm);
      saveToStorage('swing', preset.swing);
      saveToStorage('useVoiceLeading', preset.useVoiceLeading);
      saveToStorage('useAdvancedTheory', preset.useAdvancedTheory);

      setTimeout(() => generateProgression(), 0);
    },
    [generateProgression],
  );

  const restoreFromHistory = useCallback((index: number) => {
    setState((prev) => {
      if (index < 0 || index >= prev.progressionHistory.length) return prev;

      const entry = prev.progressionHistory[index];
      let restoredProgression = deepCloneProgression(entry.progression);

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

  // Playback

  const playProgression = useCallback(() => {
    setState((prev) => {
      if (prev.isPlaying || prev.currentProgression.length === 0) return prev;

      const beatDuration = 60 / prev.tempo;
      const beatsPerChord = 4;
      const chordDurationSeconds = beatDuration * beatsPerChord;

      playbackTimeoutRef.current.forEach(clearTimeout);
      playbackTimeoutRef.current = [];

      let currentTime = 0;

      prev.currentProgression.forEach((chord) => {
        const timeout = setTimeout(() => {
          const s = stateRef.current;
          playChordAudio(chord, chordDurationSeconds * 0.9, {
            soundType: s.soundType,
            masterVolume: s.masterVolume,
            envelope: s.envelope,
          });
        }, currentTime * 1000);

        playbackTimeoutRef.current.push(timeout);
        currentTime += chordDurationSeconds;
      });

      const endTimeout = setTimeout(() => {
        isPlayingRef.current = false;
        setState((s) => ({ ...s, isPlaying: false }));
      }, currentTime * 1000);

      playbackTimeoutRef.current.push(endTimeout);
      isPlayingRef.current = true;

      return { ...prev, isPlaying: true };
    });
  }, []);

  const stopPlayback = useCallback(() => {
    playbackTimeoutRef.current.forEach(clearTimeout);
    playbackTimeoutRef.current = [];
    isPlayingRef.current = false;
    updateState('isPlaying', false);
  }, [updateState]);

  // Bass line playback
  const playBassLine = useCallback(() => {
    setState((prev) => {
      if (prev.isPlaying || prev.currentBassLine.length === 0) return prev;

      const beatDuration = 60 / prev.tempo;

      playbackTimeoutRef.current.forEach(clearTimeout);
      playbackTimeoutRef.current = [];

      let currentTime = 0;

      prev.currentBassLine.forEach((bassNote) => {
        const noteDurationSeconds = bassNote.duration * beatDuration;
        const timeout = setTimeout(() => {
          const s = stateRef.current;
          playBassNoteAudio(bassNote, noteDurationSeconds * 0.9, {
            soundType: s.soundType,
            masterVolume: s.masterVolume,
            envelope: s.envelope,
          });
        }, currentTime * 1000);

        playbackTimeoutRef.current.push(timeout);
        currentTime += noteDurationSeconds;
      });

      const endTimeout = setTimeout(() => {
        isPlayingRef.current = false;
        setState((s) => ({ ...s, isPlaying: false }));
      }, currentTime * 1000);

      playbackTimeoutRef.current.push(endTimeout);
      isPlayingRef.current = true;

      return { ...prev, isPlaying: true };
    });
  }, []);

  // One-shot chord & export

  const playChord = useCallback((chord: Chord) => {
    const s = stateRef.current;
    playChordAudio(chord, 1, {
      soundType: s.soundType,
      masterVolume: s.masterVolume,
      envelope: s.envelope,
    });
  }, []);

  const handleExportToMIDI = useCallback(() => {
    const s = stateRef.current;
    exportToMIDI(s.currentProgression, s.currentKey, s.genre, s.tempo);
    playExportSound(s.masterVolume);
  }, []);

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
      setIncludeMelody,
      setIncludeBass,
      setBassStyle,
      setBassVariety,
      setChordVariety,
      setRhythmVariety,
      setCurrentTab,
      setOnboardingComplete,
      generateProgression,
      generateBassLine,
      regenerateProgression,
      spiceItUp,
      applyPreset,
      restoreFromHistory,
      playProgression,
      playBassLine,
      stopPlayback,
      playChord,
      exportToMIDI: handleExportToMIDI,
      clearPianoRoll,
      // Phase 1: Mood/Mode Selector
      setMood,
      setUseFunctionalHarmony,
      // Phase 2: Groove Engine
      setGrooveTemplate,
      // Phase 3: Spice Control
      setSpiceLevel,
      toggleChordLock,
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
