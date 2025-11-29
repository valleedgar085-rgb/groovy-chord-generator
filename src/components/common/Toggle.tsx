/**
 * Groovy Chord Generator
 * Toggle Component
 * Version 2.4
 */

import type { ToggleProps } from '../../types';

export function Toggle({ id, label, checked, onChange }: ToggleProps) {
  return (
    <div className="setting-item toggle-item">
      <label htmlFor={id}>{label}</label>
      <input
        type="checkbox"
        id={id}
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
      />
    </div>
  );
}
