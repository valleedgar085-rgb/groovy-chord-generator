/**
 * Groovy Chord Generator
 * Chord Knobs Component
 * Version 2.5
 */

import { useApp } from '../../hooks';
import { Knob } from '../common';

export function ChordKnobs() {
  const { state, actions } = useApp();

  return (
    <div className="knobs-container">
      <Knob
        id="chord-variety-knob"
        label="Chord Variety"
        value={state.chordVariety}
        min={0}
        max={100}
        step={5}
        size="large"
        color="var(--accent-primary)"
        onChange={actions.setChordVariety}
        displayValue={`${state.chordVariety}%`}
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
      <Knob
        id="swing-knob"
        label="Swing"
        value={state.swing * 100}
        min={0}
        max={100}
        step={5}
        size="large"
        color="var(--success)"
        onChange={(v) => actions.setSwing(v / 100)}
        displayValue={`${Math.round(state.swing * 100)}%`}
      />
    </div>
  );
}
