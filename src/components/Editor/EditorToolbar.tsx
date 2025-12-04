/**
 * Groovy Chord Generator
 * Editor Toolbar Component
 * Version 2.5
 */

import { useApp } from '../../hooks';

export function EditorToolbar() {
  const { state, actions } = useApp();

  return (
    <div className="editor-toolbar">
      <div className="toolbar-group">
        <button
          id="play-btn"
          className="toolbar-btn"
          aria-label="Play"
          onClick={actions.playProgression}
        >
          <span>▶️</span>
          <span className="btn-label">Play</span>
        </button>
        <button
          id="stop-btn"
          className="toolbar-btn"
          aria-label="Stop"
          onClick={actions.stopPlayback}
        >
          <span>⏹️</span>
          <span className="btn-label">Stop</span>
        </button>
        <button
          id="clear-btn"
          className="toolbar-btn"
          aria-label="Clear"
          onClick={actions.clearPianoRoll}
        >
          <span>🗑️</span>
          <span className="btn-label">Clear</span>
        </button>
      </div>
      <div className="toolbar-group">
        <div className="tempo-control">
          <label htmlFor="tempo-input">BPM</label>
          <input
            type="number"
            id="tempo-input"
            value={state.tempo}
            min={60}
            max={200}
            onChange={(e) => actions.setTempo(Number(e.target.value))}
          />
        </div>
      </div>
    </div>
  );
}
