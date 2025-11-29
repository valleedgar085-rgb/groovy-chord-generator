/**
 * Groovy Chord Generator
 * Spice Button Component
 * Version 2.4
 */

import { useApp } from '../../hooks';

export function SpiceButton() {
  const { actions } = useApp();

  return (
    <div className="spice-button-container">
      <button id="spice-btn" className="btn-spice" onClick={actions.spiceItUp}>
        <span>🌶️</span> Spice It Up
      </button>
    </div>
  );
}
