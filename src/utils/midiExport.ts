/**
 * Groovy Chord Generator
 * Utility Functions - MIDI Export
 * Version 2.4
 */

import type { Chord, KeyName, GenreKey } from '../types';
import { CHORD_TYPES } from '../constants';
import { transposeNote } from './musicTheory';

const TICKS_PER_BEAT = 480;
const BEATS_PER_CHORD = 4;

// Helper to convert number to variable-length quantity
function toVLQ(value: number): number[] {
  const bytes: number[] = [];
  bytes.push(value & 0x7f);
  value >>= 7;
  while (value > 0) {
    bytes.push((value & 0x7f) | 0x80);
    value >>= 7;
  }
  return bytes.reverse();
}

// Helper to convert string to byte array
function stringToBytes(str: string): number[] {
  return Array.from(str).map((c) => c.charCodeAt(0));
}

// Helper to convert number to big-endian bytes
function toBytes(num: number, byteCount: number): number[] {
  const bytes: number[] = [];
  for (let i = byteCount - 1; i >= 0; i--) {
    bytes.push((num >> (i * 8)) & 0xff);
  }
  return bytes;
}

// Convert note name to MIDI note number
function noteToMIDI(noteName: string, octave = 4): number {
  const noteMap: Record<string, number> = {
    C: 0, 'C#': 1, Db: 1, D: 2, 'D#': 3, Eb: 3,
    E: 4, F: 5, 'F#': 6, Gb: 6, G: 7, 'G#': 8,
    Ab: 8, A: 9, 'A#': 10, Bb: 10, B: 11,
  };
  return 12 + octave * 12 + (noteMap[noteName] || 0);
}

export function exportToMIDI(
  progression: Chord[],
  currentKey: KeyName,
  genre: GenreKey,
  tempo: number
): void {
  if (progression.length === 0) {
    alert('Please generate a chord progression first!');
    return;
  }

  const HEADER_CHUNK = 'MThd';
  const TRACK_CHUNK = 'MTrk';

  const microsecondsPerBeat = Math.round(60000000 / tempo);

  // Build track data
  const trackData: number[] = [];

  // Tempo meta event
  trackData.push(...toVLQ(0));
  trackData.push(0xff, 0x51, 0x03);
  trackData.push(...toBytes(microsecondsPerBeat, 3));

  // Time signature meta event (4/4 time)
  trackData.push(...toVLQ(0));
  trackData.push(0xff, 0x58, 0x04, 0x04, 0x02, 0x18, 0x08);

  // Track name meta event
  const trackName = 'Chord Progression';
  trackData.push(...toVLQ(0));
  trackData.push(0xff, 0x03, trackName.length);
  trackData.push(...stringToBytes(trackName));

  // Add chord events
  const ticksPerChord = TICKS_PER_BEAT * BEATS_PER_CHORD;
  const velocity = 80;
  const channel = 0;

  progression.forEach((chord, chordIndex) => {
    let notes: number[];

    if (chord.voicedNotes && chord.voicedNotes.length > 0) {
      notes = chord.voicedNotes.map((voicedNote) =>
        noteToMIDI(voicedNote.note, voicedNote.octave)
      );
    } else {
      const chordType = CHORD_TYPES[chord.type];
      const intervals = chordType ? chordType.intervals : [0, 4, 7];
      notes = intervals.map((interval) => {
        const noteName = transposeNote(chord.root, interval);
        return noteToMIDI(noteName, 4);
      });
    }

    // Note On events
    notes.forEach((note, noteIndex) => {
      const delta = noteIndex === 0 ? (chordIndex === 0 ? 0 : ticksPerChord) : 0;
      trackData.push(...toVLQ(delta));
      trackData.push(0x90 | channel, note, velocity);
    });

    // Note Off events
    notes.forEach((note, noteIndex) => {
      const delta = noteIndex === 0 ? ticksPerChord : 0;
      trackData.push(...toVLQ(delta));
      trackData.push(0x80 | channel, note, 0);
    });
  });

  // End of track
  trackData.push(...toVLQ(0));
  trackData.push(0xff, 0x2f, 0x00);

  // Build MIDI file
  const midiData: number[] = [];

  // Header chunk
  midiData.push(...stringToBytes(HEADER_CHUNK));
  midiData.push(...toBytes(6, 4));
  midiData.push(...toBytes(0, 2));
  midiData.push(...toBytes(1, 2));
  midiData.push(...toBytes(TICKS_PER_BEAT, 2));

  // Track chunk
  midiData.push(...stringToBytes(TRACK_CHUNK));
  midiData.push(...toBytes(trackData.length, 4));
  midiData.push(...trackData);

  // Create and download file
  const blob = new Blob([new Uint8Array(midiData)], { type: 'audio/midi' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;

  const keyName = currentKey.replace('#', 'sharp').replace('b', 'flat');
  const genreName = genre.replace('-', '_');
  link.download = `chord_progression_${keyName}_${genreName}.mid`;

  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}
