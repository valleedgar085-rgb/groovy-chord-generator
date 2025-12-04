/**
 * Groovy Chord Generator
 * Slider Component
 * Version 2.5
 */

import type { SliderProps } from '../../types';

export function Slider({
  id,
  label,
  value,
  min,
  max,
  step = 1,
  displayValue,
  onChange,
}: SliderProps) {
  return (
    <div className="setting-item">
      <label htmlFor={id}>
        {label}
        {displayValue && <span id={`${id}-value`}> {displayValue}</span>}
      </label>
      <input
        type="range"
        id={id}
        min={min}
        max={max}
        step={step}
        value={value}
        onChange={(e) => onChange(Number(e.target.value))}
      />
    </div>
  );
}
