/**
 * Groovy Chord Generator
 * Bass Tab Component
 * Version 2.5
 */

import { useApp } from '../../hooks';
import { CollapsibleSection, ControlSelect, Knob } from '../common';
import { BASS_STYLE_OPTIONS, KEY_OPTIONS, GENRE_OPTIONS } from '../../constants';
import type { BassStyle, GenreKey, KeyName } from '../../types';

function BassControls() {
  const { state, actions } = useApp();

  return (
    <div className="bass-controls">
      <div className="control-row">
        <ControlSelect
          id="bass-genre-select"
          label="Genre"
          value={state.genre}
          options={GENRE_OPTIONS}
          onChange={(value) => actions.setGenre(value as GenreKey)}
        />
        <ControlSelect
          id="bass-key-select"
          label="Key"
          value={state.currentKey}
          options={KEY_OPTIONS}
          onChange={(value) => actions.setKey(value as KeyName)}
        />
      </div>
      <div className="control-row">
        <ControlSelect
          id="bass-style-select"
          label="Bass Style"
          value={state.bassStyle}
          options={BASS_STYLE_OPTIONS}
          onChange={(value) => actions.setBassStyle(value as BassStyle)}
        />
      </div>
    </div>
  );
}

function BassKnobs() {
  const { state, actions } = useApp();

  return (
    <div className="knobs-container">
      <Knob
        id="bass-variety-knob"
        label="Bass Variety"
        value={state.bassVariety}
        min={0}
        max={100}
        step={5}
        size="large"
        color="var(--accent-primary)"
        onChange={actions.setBassVariety}
        displayValue={`${state.bassVariety}%`}
      />
      <Knob
        id="rhythm-variety-knob"
        label="Rhythm Variety"
        value={state.rhythmVariety}
        min={0}
        max={100}
        step={5}
        size="large"
        color="var(--accent-pink)"
        onChange={actions.setRhythmVariety}
        displayValue={`${state.rhythmVariety}%`}
      />
    </div>
  );
}

function BassDisplay() {
  const { state } = useApp();

  if (state.currentBassLine.length === 0) {
    return (
      <div className="bass-display">
        <div className="bass-placeholder">
          Generate a chord progression first, then your bass line will appear here
        </div>
      </div>
    );
  }

  return (
    <div className="bass-display">
      <div className="bass-notes-container">
        {state.currentBassLine.map((bassNote, index) => (
          <div
            key={`bass-${index}`}
            className="bass-note-card"
            style={{
              animationDelay: `${index * 0.05}s`,
            }}
          >
            <span className="bass-note-name">{bassNote.note}</span>
            <span className="bass-note-octave">{bassNote.octave}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function BassActions() {
  const { state, actions } = useApp();

  return (
    <div className="bass-actions">
      <button
        className="btn-primary full-width"
        onClick={actions.generateBassLine}
        disabled={state.currentProgression.length === 0}
      >
        <span>🎸</span>
        <span>Generate Bass Line</span>
      </button>
      <button
        className="btn-secondary full-width"
        onClick={actions.playBassLine}
        disabled={state.currentBassLine.length === 0 || state.isPlaying}
      >
        <span>▶️</span>
        <span>Play Bass Line</span>
      </button>
    </div>
  );
}

export function BassTab() {
  return (
    <section id="tab-bass" className="tab-content active">
      {/* Bass Controls */}
      <CollapsibleSection title="Bass Settings" icon="🎸" defaultExpanded>
        <BassControls />
      </CollapsibleSection>

      {/* Bass Knobs */}
      <CollapsibleSection title="Variety Controls" icon="🎛️" defaultExpanded>
        <BassKnobs />
      </CollapsibleSection>

      {/* Bass Display */}
      <CollapsibleSection title="Bass Line" icon="🎵" defaultExpanded>
        <BassDisplay />
      </CollapsibleSection>

      {/* Bass Actions */}
      <div className="bass-actions-section">
        <BassActions />
      </div>
    </section>
  );
}
