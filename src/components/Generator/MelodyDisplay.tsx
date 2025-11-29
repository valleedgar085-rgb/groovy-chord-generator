/**
 * Groovy Chord Generator
 * Melody Display Component
 * Version 2.4
 */

import { useApp } from '../../hooks';

export function MelodyDisplay() {
  const { state } = useApp();

  if (state.currentMelody.length === 0) {
    return (
      <div id="melody-display" className="melody-display">
        <div className="melody-placeholder">Melody appears after generation</div>
      </div>
    );
  }

  return (
    <div id="melody-display" className="melody-display">
      {state.currentMelody.map((note, index) => (
        <span
          key={index}
          className="melody-note"
          style={{ animationDelay: `${index * 0.05}s` }}
        >
          {note.note}
          {note.octave}
        </span>
      ))}
    </div>
  );
}
