/**
 * Groovy Chord Generator
 * Smart Presets Grid Component
 * Version 2.4
 */

import { useApp } from '../../hooks';
import { SMART_PRESETS } from '../../constants';
import { PresetCard } from './PresetCard';

export function SmartPresets() {
  const { state, actions } = useApp();

  return (
    <div id="presets-grid" className="presets-grid">
      {Object.entries(SMART_PRESETS).map(([key, preset]) => (
        <PresetCard
          key={key}
          presetKey={key}
          preset={preset}
          isSelected={state.currentPreset === key}
          onSelect={actions.applyPreset}
        />
      ))}
    </div>
  );
}
