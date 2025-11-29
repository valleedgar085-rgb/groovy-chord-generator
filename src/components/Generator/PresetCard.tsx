/**
 * Groovy Chord Generator
 * Preset Card Component
 * Version 2.4
 */

import type { SmartPreset } from '../../types';

interface PresetCardProps {
  presetKey: string;
  preset: SmartPreset;
  isSelected: boolean;
  onSelect: (key: string) => void;
}

export function PresetCard({ presetKey, preset, isSelected, onSelect }: PresetCardProps) {
  return (
    <div
      className={`preset-card ${isSelected ? 'selected' : ''}`}
      data-preset={presetKey}
      onClick={() => onSelect(presetKey)}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          onSelect(presetKey);
        }
      }}
      tabIndex={0}
      role="button"
    >
      <div className="preset-emoji">{preset.emoji}</div>
      <div className="preset-name">{preset.name}</div>
      <div className="preset-description">{preset.description}</div>
    </div>
  );
}
