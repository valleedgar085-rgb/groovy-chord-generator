/**
 * Groovy Chord Generator
 * Advanced Settings Component
 * Version 2.5
 */

import { useApp } from '../../hooks';
import { ControlSelect, Slider, Toggle } from '../common';
import { COMPLEXITY_OPTIONS, RHYTHM_OPTIONS } from '../../constants';
import type { ComplexityLevel, RhythmLevel } from '../../types';

export function AdvancedSettings() {
  const { state, actions } = useApp();

  return (
    <>
      <div className="control-row">
        <ControlSelect
          id="complexity-select"
          label="Complexity"
          value={state.complexity}
          options={COMPLEXITY_OPTIONS}
          onChange={(value) => actions.setComplexity(value as ComplexityLevel)}
        />
        <ControlSelect
          id="rhythm-select"
          label="Rhythm"
          value={state.rhythm}
          options={RHYTHM_OPTIONS}
          onChange={(value) => actions.setRhythm(value as RhythmLevel)}
        />
      </div>

      <div className="control-row swing-control">
        <Slider
          id="swing-slider"
          label="Groove/Swing"
          value={state.swing * 100}
          min={0}
          max={100}
          displayValue={`${Math.round(state.swing * 100)}%`}
          onChange={(value) => actions.setSwing(value / 100)}
        />
      </div>

      <div className="control-row music-theory-options">
        <Toggle
          id="include-melody"
          label="Include Melody"
          checked={state.includeMelody}
          onChange={actions.setIncludeMelody}
        />
        <Toggle
          id="voice-leading"
          label="Smooth Voice Leading"
          checked={state.useVoiceLeading}
          onChange={actions.setUseVoiceLeading}
        />
        <Toggle
          id="advanced-theory"
          label="Advanced Theory (Spicy)"
          checked={state.useAdvancedTheory}
          onChange={actions.setUseAdvancedTheory}
        />
        <Toggle
          id="modal-interchange"
          label="Modal Interchange"
          checked={state.useModalInterchange}
          onChange={actions.setUseModalInterchange}
        />
      </div>
    </>
  );
}
