/**
 * Groovy Chord Generator
 * Chord Card Component
 * Version 2.4
 */

import { useState } from 'react';
import type { Chord } from '../../types';
import { CHORD_TYPES } from '../../constants';

interface ChordCardProps {
  chord: Chord;
  index: number;
  showNumerals: boolean;
  onPlayChord: (chord: Chord) => void;
}

export function ChordCard({ chord, index, showNumerals, onPlayChord }: ChordCardProps) {
  const [isActive, setIsActive] = useState(false);

  const chordSymbol = CHORD_TYPES[chord.type]?.symbol || '';
  const displayName = chord.root + chordSymbol;
  const chordTypeName = CHORD_TYPES[chord.type]?.name || chord.type;

  const handleClick = () => {
    setIsActive(true);
    onPlayChord(chord);
    setTimeout(() => setIsActive(false), 500);
  };

  return (
    <div
      className={`chord-card ${isActive ? 'active' : ''}`}
      data-index={index}
      onClick={handleClick}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          handleClick();
        }
      }}
      tabIndex={0}
      role="button"
    >
      <div className="chord-name">{displayName}</div>
      <div className="chord-type">{chordTypeName}</div>
      {showNumerals && <div className="chord-numeral">{chord.degree}</div>}
    </div>
  );
}
