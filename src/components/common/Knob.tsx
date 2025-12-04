/**
 * Groovy Chord Generator
 * Knob Component - Rotary Control
 * Version 2.5
 */

import { useState, useRef, useCallback, useEffect } from 'react';

export interface KnobProps {
  id: string;
  label: string;
  value: number;
  min: number;
  max: number;
  step?: number;
  size?: 'small' | 'medium' | 'large';
  color?: string;
  onChange: (value: number) => void;
  displayValue?: string;
}

export function Knob({
  id,
  label,
  value,
  min,
  max,
  step = 1,
  size = 'medium',
  color = 'var(--accent-primary)',
  onChange,
  displayValue,
}: KnobProps) {
  const knobRef = useRef<HTMLDivElement>(null);
  const [isDragging, setIsDragging] = useState(false);
  const dragStartRef = useRef<{ y: number; value: number } | null>(null);

  const sizeClasses = {
    small: 'knob-small',
    medium: 'knob-medium',
    large: 'knob-large',
  };

  // Avoid division by zero when min equals max
  const range = max - min;
  const normalizedValue = range > 0 ? (value - min) / range : 0;
  const rotation = normalizedValue * 270 - 135; // -135 to 135 degrees

  const handleMouseDown = useCallback(
    (e: React.MouseEvent) => {
      e.preventDefault();
      setIsDragging(true);
      dragStartRef.current = { y: e.clientY, value };
    },
    [value]
  );

  const handleTouchStart = useCallback(
    (e: React.TouchEvent) => {
      e.preventDefault();
      if (e.touches.length === 0) return;
      setIsDragging(true);
      dragStartRef.current = { y: e.touches[0].clientY, value };
    },
    [value]
  );

  useEffect(() => {
    if (!isDragging) return;

    const handleMove = (clientY: number) => {
      if (!dragStartRef.current) return;

      const deltaY = dragStartRef.current.y - clientY;
      const sensitivity = range > 0 ? range / 100 : 1;
      const newValue = Math.round(
        Math.min(max, Math.max(min, dragStartRef.current.value + deltaY * sensitivity)) / step
      ) * step;

      if (newValue !== value) {
        onChange(newValue);
      }
    };

    const handleMouseMove = (e: MouseEvent) => {
      handleMove(e.clientY);
    };

    const handleTouchMove = (e: TouchEvent) => {
      if (e.touches.length === 0) return;
      handleMove(e.touches[0].clientY);
    };

    const handleEnd = () => {
      setIsDragging(false);
      dragStartRef.current = null;
    };

    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleEnd);
    document.addEventListener('touchmove', handleTouchMove);
    document.addEventListener('touchend', handleEnd);

    return () => {
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleEnd);
      document.removeEventListener('touchmove', handleTouchMove);
      document.removeEventListener('touchend', handleEnd);
    };
  }, [isDragging, max, min, onChange, range, step, value]);

  return (
    <div className={`knob-container ${sizeClasses[size]}`}>
      <label htmlFor={id} className="knob-label">
        {label}
      </label>
      <div
        id={id}
        ref={knobRef}
        className={`knob ${isDragging ? 'knob-active' : ''}`}
        style={{ '--knob-color': color } as React.CSSProperties}
        role="slider"
        aria-valuenow={value}
        aria-valuemin={min}
        aria-valuemax={max}
        aria-label={label}
        tabIndex={0}
        onMouseDown={handleMouseDown}
        onTouchStart={handleTouchStart}
        onKeyDown={(e) => {
          if (e.key === 'ArrowUp' || e.key === 'ArrowRight') {
            e.preventDefault();
            onChange(Math.min(max, value + step));
          } else if (e.key === 'ArrowDown' || e.key === 'ArrowLeft') {
            e.preventDefault();
            onChange(Math.max(min, value - step));
          }
        }}
      >
        <div className="knob-track">
          <svg viewBox="0 0 100 100" className="knob-arc">
            <circle
              cx="50"
              cy="50"
              r="40"
              fill="none"
              stroke="var(--bg-tertiary)"
              strokeWidth="8"
              strokeLinecap="round"
              strokeDasharray="220"
              strokeDashoffset="63"
              transform="rotate(135 50 50)"
            />
            <circle
              cx="50"
              cy="50"
              r="40"
              fill="none"
              stroke={color}
              strokeWidth="8"
              strokeLinecap="round"
              strokeDasharray={`${normalizedValue * 220} 220`}
              strokeDashoffset="0"
              transform="rotate(135 50 50)"
              className="knob-progress"
            />
          </svg>
        </div>
        <div
          className="knob-inner"
          style={{ transform: `rotate(${rotation}deg)` }}
        >
          <div className="knob-indicator" />
        </div>
      </div>
      <div className="knob-value">
        {displayValue ?? value}
      </div>
    </div>
  );
}
