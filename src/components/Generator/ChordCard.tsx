/**
 * Groovy Chord Generator
 * Chord Card Component
 * Version 2.5
 */

import { useState, useCallback } from 'react';
import { useKeyboardClickSimple } from '../../hooks';
import type { Chord } from '../../types';
import { CHORD_TYPES } from '../../constants';

interface ChordCardProps {
  chord: Chord;
  index: number;
  showNumerals: boolean;
  isLocked?: boolean;
  onPlayChord: (chord: Chord) => void;
  onToggleLock?: (index: number) => void;
}

export function ChordCard({ 
  chord, 
  index, 
  showNumerals, 
  isLocked = false,
  onPlayChord, 
  onToggleLock 
}: ChordCardProps) {
  const [isActive, setIsActive] = useState(false);

  const chordSymbol = CHORD_TYPES[chord.type]?.symbol || '';
  const displayName = chord.root + chordSymbol;
  const chordTypeName = CHORD_TYPES[chord.type]?.name || chord.type;

  const handleClick = useCallback(() => {
    setIsActive(true);
    onPlayChord(chord);
    setTimeout(() => setIsActive(false), 500);
  }, [chord, onPlayChord]);

  const handleLockClick = useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
    onToggleLock?.(index);
  }, [index, onToggleLock]);

  const handleKeyDown = useKeyboardClickSimple(handleClick);

  return (
    <div
      className={`chord-card ${isActive ? 'active' : ''} ${isLocked ? 'locked' : ''}`}
      data-index={index}
      onClick={handleClick}
      onKeyDown={handleKeyDown}
      tabIndex={0}
      role="button"
    >
      {onToggleLock && (
        <button 
          className="chord-lock-btn" 
          onClick={handleLockClick}
          title={isLocked ? 'Unlock chord' : 'Lock chord (preserve on regenerate)'}
        >
          {isLocked ? '🔒' : '🔓'}
        </button>
      )}
      <div className="chord-name">{displayName}</div>
      <div className="chord-type">{chordTypeName}</div>
      {showNumerals && <div className="chord-numeral">{chord.degree}</div>}
      {chord.harmonyFunction && (
        <div className="chord-function">{chord.harmonyFunction}</div>
      )}
    </div>
  );
}
