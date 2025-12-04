/**
 * Groovy Chord Generator
 * Piano Roll Component
 * Version 2.5
 */

import React, { useEffect, useRef, useCallback, useState } from 'react';
import { useApp } from '../../hooks';
import { CHORD_TYPES } from '../../constants';
import { getNoteIndex } from '../../utils';
import { playNote } from '../../utils/audio';
import type { PianoRollNote } from '../../types';

interface PianoRollState {
  notes: PianoRollNote[];
  zoom: number;
}

export function PianoRoll() {
  const { state } = useApp();
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const [pianoState, setPianoState] = useState<PianoRollState>({
    notes: [],
    zoom: 1,
  });
  const [lastTouchDistance, setLastTouchDistance] = useState(0);
  const touchStartRef = useRef<{ time: number; x: number; y: number } | null>(null);

  const noteHeight = 28;
  const beatWidth = 60;
  const totalBeats = 16;

  // Draw the piano roll
  const draw = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const effectiveBeatWidth = beatWidth * pianoState.zoom;
    const width = effectiveBeatWidth * totalBeats;
    const height = noteHeight * 24;

    // Set canvas size
    canvas.width = width;
    canvas.height = height;
    canvas.style.width = `${width}px`;
    canvas.style.height = `${height}px`;

    // Clear canvas
    ctx.fillStyle = '#1a1a2e';
    ctx.fillRect(0, 0, width, height);

    // Draw grid
    ctx.strokeStyle = '#3a3a5c';
    ctx.lineWidth = 1;

    // Horizontal lines (note rows)
    for (let i = 0; i <= 24; i++) {
      const y = i * noteHeight;
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
      ctx.stroke();

      // Highlight black keys
      const noteIndex = (23 - i) % 12;
      if ([1, 3, 6, 8, 10].includes(noteIndex)) {
        ctx.fillStyle = 'rgba(0, 0, 0, 0.2)';
        ctx.fillRect(0, y, width, noteHeight);
      }
    }

    // Vertical lines (beats)
    for (let i = 0; i <= totalBeats; i++) {
      const x = i * effectiveBeatWidth;
      ctx.strokeStyle = i % 4 === 0 ? '#5a5a7c' : '#3a3a5c';
      ctx.lineWidth = i % 4 === 0 ? 2 : 1;
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, height);
      ctx.stroke();
    }

    // Draw notes
    pianoState.notes.forEach((note) => {
      const scaledX = (note.x / beatWidth) * effectiveBeatWidth;
      const scaledWidth = (note.width / beatWidth) * effectiveBeatWidth;

      const gradient = ctx.createLinearGradient(scaledX, note.y, scaledX + scaledWidth, note.y);
      gradient.addColorStop(0, '#7c3aed');
      gradient.addColorStop(1, '#ec4899');

      ctx.fillStyle = gradient;
      ctx.fillRect(scaledX, note.y, scaledWidth, noteHeight - 2);

      ctx.strokeStyle = '#a855f7';
      ctx.lineWidth = 1;
      ctx.strokeRect(scaledX, note.y, scaledWidth, noteHeight - 2);
    });
  }, [pianoState]);

  // Load notes from progression
  useEffect(() => {
    const notes: PianoRollNote[] = [];

    state.currentProgression.forEach((chord, chordIndex) => {
      if (chord.voicedNotes && chord.voicedNotes.length > 0) {
        chord.voicedNotes.forEach((voicedNote) => {
          const noteIndex = getNoteIndex(voicedNote.note);
          const octaveOffset = (5 - voicedNote.octave) * 12;
          const noteRow = (12 - noteIndex) % 12 + octaveOffset;

          if (noteRow >= 0 && noteRow < 24) {
            notes.push({
              x: chordIndex * beatWidth * 4,
              y: noteRow * noteHeight,
              width: beatWidth * 4,
              noteIndex: noteRow,
              beat: chordIndex * 4,
            });
          }
        });
      } else {
        const chordNotes = CHORD_TYPES[chord.type].intervals;
        const rootIndex = getNoteIndex(chord.root);

        chordNotes.forEach((interval) => {
          const noteIdx = 12 - ((rootIndex + interval) % 12);
          notes.push({
            x: chordIndex * beatWidth * 4,
            y: noteIdx * noteHeight,
            width: beatWidth * 4,
            noteIndex: noteIdx,
            beat: chordIndex * 4,
          });
        });
      }
    });

    setPianoState((prev) => ({ ...prev, notes }));
  }, [state.currentProgression]);

  // Redraw when state changes
  useEffect(() => {
    draw();
  }, [draw]);

  // Handle click/tap to toggle notes
  const toggleNote = useCallback(
    (x: number, y: number) => {
      const effectiveBeatWidth = beatWidth * pianoState.zoom;

      const clickedNoteIndex = pianoState.notes.findIndex((note) => {
        const scaledX = (note.x / beatWidth) * effectiveBeatWidth;
        const scaledWidth = (note.width / beatWidth) * effectiveBeatWidth;
        return (
          x >= scaledX &&
          x <= scaledX + scaledWidth &&
          y >= note.y &&
          y <= note.y + noteHeight
        );
      });

      if (clickedNoteIndex !== -1) {
        setPianoState((prev) => ({
          ...prev,
          notes: prev.notes.filter((_, i) => i !== clickedNoteIndex),
        }));
      } else {
        const beatIndex = Math.floor(x / effectiveBeatWidth);
        const noteIndex = Math.floor(y / noteHeight);

        setPianoState((prev) => ({
          ...prev,
          notes: [
            ...prev.notes,
            {
              x: beatIndex * beatWidth,
              y: noteIndex * noteHeight,
              width: beatWidth,
              noteIndex,
              beat: beatIndex,
            },
          ],
        }));

        // Play preview
        const noteNames = ['C', 'B', 'A#', 'A', 'G#', 'G', 'F#', 'F', 'E', 'D#', 'D', 'C#'];
        const octave = noteIndex < 12 ? 5 : 4;
        const noteName = noteNames[noteIndex % 12];
        playNote(noteName, octave, 0.2, 0, {
          soundType: state.soundType,
          masterVolume: state.masterVolume,
          envelope: state.envelope,
        });
      }
    },
    [pianoState, state.soundType, state.masterVolume, state.envelope]
  );

  const handleClick = useCallback(
    (e: React.MouseEvent<HTMLCanvasElement>) => {
      const canvas = canvasRef.current;
      if (!canvas) return;

      const rect = canvas.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      toggleNote(x, y);
    },
    [toggleNote]
  );

  const getTouchDistance = (touches: React.TouchList) => {
    return Math.sqrt(
      Math.pow(touches[0].clientX - touches[1].clientX, 2) +
        Math.pow(touches[0].clientY - touches[1].clientY, 2)
    );
  };

  const handleTouchStart = useCallback((e: React.TouchEvent<HTMLCanvasElement>) => {
    if (e.touches.length === 2) {
      setLastTouchDistance(getTouchDistance(e.touches));
      e.preventDefault();
    } else if (e.touches.length === 1) {
      touchStartRef.current = {
        time: Date.now(),
        x: e.touches[0].clientX,
        y: e.touches[0].clientY,
      };
    }
  }, []);

  const handleTouchMove = useCallback(
    (e: React.TouchEvent<HTMLCanvasElement>) => {
      if (e.touches.length === 2) {
        const newDistance = getTouchDistance(e.touches);
        const delta = newDistance / lastTouchDistance;
        setPianoState((prev) => ({
          ...prev,
          zoom: Math.max(0.5, Math.min(3, prev.zoom * delta)),
        }));
        setLastTouchDistance(newDistance);
        e.preventDefault();
      }
    },
    [lastTouchDistance]
  );

  const handleTouchEnd = useCallback(
    (e: React.TouchEvent<HTMLCanvasElement>) => {
      if (e.changedTouches.length === 1 && touchStartRef.current) {
        const touchDuration = Date.now() - touchStartRef.current.time;
        const touch = e.changedTouches[0];
        const moveDistance = Math.sqrt(
          Math.pow(touch.clientX - touchStartRef.current.x, 2) +
            Math.pow(touch.clientY - touchStartRef.current.y, 2)
        );

        if (touchDuration < 300 && moveDistance < 10) {
          const canvas = canvasRef.current;
          if (canvas) {
            const rect = canvas.getBoundingClientRect();
            const x = touch.clientX - rect.left;
            const y = touch.clientY - rect.top;
            toggleNote(x, y);
          }
        }
      }
      touchStartRef.current = null;
    },
    [toggleNote]
  );

  const handleZoomIn = () => {
    setPianoState((prev) => ({
      ...prev,
      zoom: Math.min(prev.zoom * 1.25, 3),
    }));
  };

  const handleZoomOut = () => {
    setPianoState((prev) => ({
      ...prev,
      zoom: Math.max(prev.zoom / 1.25, 0.5),
    }));
  };

  const handleResetView = () => {
    setPianoState((prev) => ({ ...prev, zoom: 1 }));
    if (containerRef.current) {
      const wrapper = containerRef.current.closest('.piano-roll-wrapper');
      if (wrapper) {
        wrapper.scrollLeft = 0;
      }
    }
  };

  // Render piano keys
  const renderPianoKeys = () => {
    const noteLabels = ['C', 'B', 'A#', 'A', 'G#', 'G', 'F#', 'F', 'E', 'D#', 'D', 'C#'];
    const keys: React.ReactElement[] = [];

    for (let octave = 5; octave >= 4; octave--) {
      noteLabels.forEach((note) => {
        const isBlack = note.includes('#');
        const keyClass = isBlack ? 'black' : 'white';
        keys.push(
          <div
            key={`${note}${octave}`}
            className={`piano-key ${keyClass}`}
            data-note={`${note}${octave}`}
            onClick={() => {
              playNote(note, octave, 0.3, 0, {
                soundType: state.soundType,
                masterVolume: state.masterVolume,
                envelope: state.envelope,
              });
            }}
          >
            {note}
            {octave}
          </div>
        );
      });
    }

    return keys;
  };

  return (
    <>
      <div className="piano-roll-controls">
        <button
          id="zoom-in-btn"
          className="control-btn"
          aria-label="Zoom in"
          onClick={handleZoomIn}
        >
          ➕
        </button>
        <button
          id="zoom-out-btn"
          className="control-btn"
          aria-label="Zoom out"
          onClick={handleZoomOut}
        >
          ➖
        </button>
        <button
          id="reset-view-btn"
          className="control-btn"
          aria-label="Reset view"
          onClick={handleResetView}
        >
          🔄
        </button>
      </div>

      <div className="piano-roll-wrapper">
        <div className="piano-roll-container" id="piano-roll-container" ref={containerRef}>
          <div className="piano-keys" id="piano-keys">
            {renderPianoKeys()}
          </div>
          <div className="piano-roll" id="piano-roll">
            <canvas
              ref={canvasRef}
              id="piano-roll-canvas"
              onClick={handleClick}
              onTouchStart={handleTouchStart}
              onTouchMove={handleTouchMove}
              onTouchEnd={handleTouchEnd}
            />
          </div>
        </div>
      </div>
    </>
  );
}
