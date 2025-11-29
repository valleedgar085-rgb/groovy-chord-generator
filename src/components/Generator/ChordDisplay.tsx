/**
 * Groovy Chord Generator
 * Chord Display Component
 * Version 2.4
 */

import { useApp } from '../../hooks';
import { ChordCard } from './ChordCard';

export function ChordDisplay() {
  const { state, actions } = useApp();

  if (state.currentProgression.length === 0) {
    return (
      <div id="chord-display" className="chord-display">
        <div className="chord-placeholder">Tap "Generate" to create a progression</div>
      </div>
    );
  }

  return (
    <div id="chord-display" className="chord-display">
      {state.currentProgression.map((chord, index) => (
        <ChordCard
          key={`${chord.root}-${chord.type}-${index}`}
          chord={chord}
          index={index}
          showNumerals={state.showNumerals}
          onPlayChord={actions.playChord}
        />
      ))}
    </div>
  );
}
