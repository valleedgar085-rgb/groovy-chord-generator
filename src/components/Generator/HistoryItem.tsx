/**
 * Groovy Chord Generator
 * History Item Component
 * Version 2.4
 */

import type { HistoryEntry } from '../../types';
import { CHORD_TYPES, GENRE_PROFILES } from '../../constants';
import { getTimeAgo } from '../../utils';

interface HistoryItemProps {
  entry: HistoryEntry;
  index: number;
  onRestore: (index: number) => void;
}

export function HistoryItem({ entry, index, onRestore }: HistoryItemProps) {
  const chords = entry.progression
    .map((c) => c.root + (CHORD_TYPES[c.type]?.symbol || ''))
    .join(' - ');
  const timeAgo = getTimeAgo(entry.timestamp);
  const genreProfile = GENRE_PROFILES[entry.genre];

  return (
    <div
      className="history-item"
      onClick={() => onRestore(index)}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          onRestore(index);
        }
      }}
      tabIndex={0}
      role="button"
    >
      <div className="history-item-header">
        <span className="history-key">{entry.key}</span>
        <span className="history-genre">{genreProfile?.name || entry.genre}</span>
      </div>
      <div className="history-chords">{chords}</div>
      <div className="history-time">{timeAgo}</div>
    </div>
  );
}
