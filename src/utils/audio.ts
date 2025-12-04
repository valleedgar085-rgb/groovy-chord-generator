/**
 * Groovy Chord Generator
 * Utility Functions - Audio (Web Audio API)
 * Version 2.4
 */

import type { Chord, Envelope, SoundType, NoteName } from '../types';
import { CHORD_TYPES } from '../constants';
import { getNoteIndex, transposeNote } from './musicTheory';

let audioContext: AudioContext | null = null;

export function initAudio(): AudioContext {
  if (!audioContext) {
    audioContext = new (window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext)();
  }
  return audioContext;
}

export function getAudioContext(): AudioContext | null {
  return audioContext;
}

export function noteToFrequency(note: NoteName | string, octave = 4): number {
  const noteIndex = getNoteIndex(note);
  const a4 = 440;
  const a4Index = 9; // A is at index 9
  const halfSteps = noteIndex - a4Index + (octave - 4) * 12;
  return a4 * Math.pow(2, halfSteps / 12);
}

export function playNote(
  note: NoteName | string,
  octave = 4,
  duration = 0.5,
  time = 0,
  options: {
    soundType: SoundType;
    masterVolume: number;
    envelope: Envelope;
    useFilter?: boolean;
  }
): OscillatorNode {
  const ctx = initAudio();
  const frequency = noteToFrequency(note, octave);

  const oscillator = ctx.createOscillator();
  const gainNode = ctx.createGain();

  oscillator.type = options.soundType;
  oscillator.frequency.setValueAtTime(frequency, ctx.currentTime + time);

  // Add a subtle detuning for a richer sound
  const detuneAmount = (Math.random() - 0.5) * 4; // +/- 2 cents for warmth
  oscillator.detune.setValueAtTime(detuneAmount, ctx.currentTime + time);

  const volume = 0.25 * options.masterVolume;
  const env = options.envelope;
  const startTime = ctx.currentTime + time;

  // Minimum gain value for exponential ramps (cannot be 0)
  const MIN_GAIN = 0.0001;

  // ADSR Envelope Implementation
  gainNode.gain.setValueAtTime(0, startTime);
  gainNode.gain.linearRampToValueAtTime(volume, startTime + env.attack);

  const sustainLevel = volume * env.sustain;
  const effectiveSustain = Math.max(sustainLevel, MIN_GAIN);
  gainNode.gain.exponentialRampToValueAtTime(
    effectiveSustain,
    startTime + env.attack + env.decay
  );

  const releaseStartTime = startTime + duration;
  gainNode.gain.setValueAtTime(effectiveSustain, releaseStartTime);
  gainNode.gain.exponentialRampToValueAtTime(MIN_GAIN, releaseStartTime + env.release);

  // Add low-pass filter for warmer sound
  if (options.useFilter !== false) {
    const filter = ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(2000 + frequency * 2, startTime);
    filter.Q.setValueAtTime(0.5, startTime);
    
    oscillator.connect(filter);
    filter.connect(gainNode);
  } else {
    oscillator.connect(gainNode);
  }
  
  gainNode.connect(ctx.destination);

  oscillator.start(startTime);
  oscillator.stop(releaseStartTime + env.release);

  return oscillator;
}

export function playChord(
  chord: Chord,
  duration = 1,
  options: {
    soundType: SoundType;
    masterVolume: number;
    envelope: Envelope;
  }
): void {
  initAudio();

  // Add bass note an octave below root for fuller sound
  const addBass = Math.random() > 0.5;
  
  if (chord.voicedNotes && chord.voicedNotes.length > 0) {
    // Play bass note
    if (addBass && chord.voicedNotes.length > 0) {
      const bassNote = chord.voicedNotes[0];
      playNote(bassNote.note, Math.max(2, bassNote.octave - 1), duration, 0, {
        ...options,
        masterVolume: options.masterVolume * 0.6,
      });
    }
    
    chord.voicedNotes.forEach((voicedNote, i) => {
      // Slight delay between notes for arpeggio-like effect
      const delay = i * 0.015;
      playNote(voicedNote.note, voicedNote.octave, duration, delay, options);
    });
  } else {
    const intervals = CHORD_TYPES[chord.type]?.intervals || [0, 4, 7];
    
    // Play bass note
    if (addBass) {
      playNote(chord.root, 3, duration, 0, {
        ...options,
        masterVolume: options.masterVolume * 0.6,
      });
    }
    
    intervals.forEach((interval, i) => {
      const note = transposeNote(chord.root, interval);
      // Slight delay between notes for arpeggio-like effect
      const delay = i * 0.015;
      playNote(note, 4, duration, delay, options);
    });
  }
}

export function playSpiceSound(masterVolume: number): void {
  const ctx = initAudio();
  const notes = [261.63, 329.63, 392.0, 523.25, 659.25]; // C4, E4, G4, C5, E5

  notes.forEach((freq, i) => {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(freq * (1 + Math.random() * 0.02), ctx.currentTime + i * 0.08);
    gain.gain.setValueAtTime(0.12 * masterVolume, ctx.currentTime + i * 0.08);
    gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + i * 0.08 + 0.25);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(ctx.currentTime + i * 0.08);
    osc.stop(ctx.currentTime + i * 0.08 + 0.25);
  });
}

export function playGenerationSounds(masterVolume: number): void {
  const ctx = initAudio();

  // Whoosh sound
  const whooshOsc = ctx.createOscillator();
  const whooshGain = ctx.createGain();
  whooshOsc.type = 'sine';
  whooshOsc.frequency.setValueAtTime(200, ctx.currentTime);
  whooshOsc.frequency.exponentialRampToValueAtTime(800, ctx.currentTime + 0.15);
  whooshGain.gain.setValueAtTime(0.2 * masterVolume, ctx.currentTime);
  whooshGain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.2);
  whooshOsc.connect(whooshGain);
  whooshGain.connect(ctx.destination);
  whooshOsc.start(ctx.currentTime);
  whooshOsc.stop(ctx.currentTime + 0.2);

  // Chime sounds
  const chimeDelays = [0.05, 0.12, 0.2, 0.28];
  const chimeFreqs = [1200, 1500, 1800, 2000];

  chimeDelays.forEach((delay, i) => {
    const chimeOsc = ctx.createOscillator();
    const chimeGain = ctx.createGain();
    chimeOsc.type = 'sine';
    chimeOsc.frequency.setValueAtTime(chimeFreqs[i], ctx.currentTime + delay);
    chimeGain.gain.setValueAtTime(0.1 * masterVolume, ctx.currentTime + delay);
    chimeGain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + delay + 0.15);
    chimeOsc.connect(chimeGain);
    chimeGain.connect(ctx.destination);
    chimeOsc.start(ctx.currentTime + delay);
    chimeOsc.stop(ctx.currentTime + delay + 0.15);
  });

  // Ding sound
  setTimeout(() => {
    const dingOsc = ctx.createOscillator();
    const dingGain = ctx.createGain();
    dingOsc.type = 'triangle';
    dingOsc.frequency.setValueAtTime(880, ctx.currentTime);
    dingGain.gain.setValueAtTime(0.15 * masterVolume, ctx.currentTime);
    dingGain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.4);
    dingOsc.connect(dingGain);
    dingGain.connect(ctx.destination);
    dingOsc.start(ctx.currentTime);
    dingOsc.stop(ctx.currentTime + 0.4);
  }, 350);
}

export function playExportSound(masterVolume: number): void {
  const ctx = initAudio();
  const notes = [523.25, 659.25]; // C5, E5

  notes.forEach((freq, i) => {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(freq, ctx.currentTime + i * 0.1);
    gain.gain.setValueAtTime(0.15 * masterVolume, ctx.currentTime + i * 0.1);
    gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + i * 0.1 + 0.3);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(ctx.currentTime + i * 0.1);
    osc.stop(ctx.currentTime + i * 0.1 + 0.3);
  });
}
