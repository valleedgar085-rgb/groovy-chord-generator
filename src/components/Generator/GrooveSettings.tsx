/**
 * Groovy Chord Generator
 * Groove Settings Component - Phase 1 & 2 Controls
 * Version 2.5
 */

import { useApp } from '../../hooks';
import { ControlSelect, Toggle } from '../common';
import { 
  MOOD_OPTIONS, 
  GROOVE_TEMPLATE_OPTIONS, 
  SPICE_LEVEL_OPTIONS 
} from '../../constants';
import type { MoodType, GrooveTemplate, SpiceLevel } from '../../types';

export function GrooveSettings() {
  const { state, actions } = useApp();

  return (
    <>
      {/* Phase 1: Mood/Mode Selector */}
      <div className="control-row">
        <ControlSelect
          id="mood-select"
          label="Mood"
          value={state.currentMood}
          options={MOOD_OPTIONS}
          onChange={(value) => actions.setMood(value as MoodType)}
        />
        <ControlSelect
          id="spice-level-select"
          label="Spice Level"
          value={state.spiceLevel}
          options={SPICE_LEVEL_OPTIONS}
          onChange={(value) => actions.setSpiceLevel(value as SpiceLevel)}
        />
      </div>

      {/* Phase 2: Groove Engine */}
      <div className="control-row">
        <ControlSelect
          id="groove-template-select"
          label="Groove Template"
          value={state.grooveTemplate}
          options={GROOVE_TEMPLATE_OPTIONS}
          onChange={(value) => actions.setGrooveTemplate(value as GrooveTemplate)}
        />
      </div>

      {/* Functional Harmony Toggle */}
      <div className="control-row groove-options">
        <Toggle
          id="functional-harmony"
          label="Use Functional Harmony"
          checked={state.useFunctionalHarmony}
          onChange={actions.setUseFunctionalHarmony}
        />
      </div>

      {state.useFunctionalHarmony && (
        <div className="info-text">
          <span className="info-icon">💡</span>
          <span>Functional harmony ensures chords follow natural harmonic movement (Tonic → Subdominant → Dominant)</span>
        </div>
      )}
    </>
  );
}
