/**
 * Groovy Chord Generator
 * History Panel Component
 * Version 2.4
 */

import { useApp } from '../../hooks';
import { HistoryItem } from './HistoryItem';

export function HistoryPanel() {
  const { state, actions } = useApp();

  if (state.progressionHistory.length === 0) {
    return (
      <div id="history-list" className="history-list">
        <div className="history-empty">No saved progressions yet</div>
      </div>
    );
  }

  return (
    <div id="history-list" className="history-list">
      {state.progressionHistory.map((entry, index) => (
        <HistoryItem
          key={entry.timestamp}
          entry={entry}
          index={index}
          onRestore={actions.restoreFromHistory}
        />
      ))}
    </div>
  );
}
