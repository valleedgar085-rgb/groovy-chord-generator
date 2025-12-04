/**
 * Groovy Chord Generator
 * Header Component
 * Version 2.5
 */

import { useApp } from '../../hooks';

export function Header() {
  const { actions } = useApp();

  return (
    <header className="header">
      <div className="header-content">
        <h1 className="logo">🎵 ChordGen</h1>
        <button
          id="settings-toggle"
          className="header-btn"
          aria-label="Settings"
          onClick={() => actions.setCurrentTab('settings')}
        >
          <span>⚙️</span>
        </button>
      </div>
    </header>
  );
}
