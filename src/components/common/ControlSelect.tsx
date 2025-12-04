/**
 * Groovy Chord Generator
 * Control Select Component
 * Version 2.5
 */

import type { ControlSelectProps } from '../../types';

export function ControlSelect({
  id,
  label,
  value,
  options,
  onChange,
}: ControlSelectProps) {
  return (
    <div className="control-group compact">
      <label htmlFor={id}>{label}</label>
      <select
        id={id}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      >
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
    </div>
  );
}
