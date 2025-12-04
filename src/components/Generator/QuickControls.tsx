/**
 * Groovy Chord Generator
 * Quick Controls Component
 * Version 2.5
 */

import { useApp } from '../../hooks';
import { ControlSelect } from '../common';
import { GENRE_OPTIONS, KEY_OPTIONS } from '../../constants';
import type { GenreKey, KeyName } from '../../types';

export function QuickControls() {
  const { state, actions } = useApp();

  return (
    <div className="quick-controls">
      <div className="control-row">
        <ControlSelect
          id="genre-select"
          label="Genre"
          value={state.genre}
          options={GENRE_OPTIONS}
          onChange={(value) => actions.setGenre(value as GenreKey)}
        />
        <ControlSelect
          id="key-select"
          label="Key"
          value={state.currentKey}
          options={KEY_OPTIONS}
          onChange={(value) => actions.setKey(value as KeyName)}
        />
      </div>
    </div>
  );
}
