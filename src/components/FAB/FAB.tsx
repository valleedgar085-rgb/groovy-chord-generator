/**
 * Groovy Chord Generator
 * Floating Action Button Component
 * Version 2.5
 */

import { useState, useRef, useEffect } from 'react';
import { useApp } from '../../hooks';

const fabActions = [
  { id: 'fab-generate', icon: '🎲', label: 'Generate', action: 'generate' },
  { id: 'fab-regenerate', icon: '🔄', label: 'Regenerate', action: 'regenerate' },
  { id: 'fab-spice', icon: '🌶️', label: 'Spice It Up', action: 'spice' },
  { id: 'fab-play', icon: '▶️', label: 'Play', action: 'play' },
  { id: 'fab-export-midi', icon: '💾', label: 'Export MIDI', action: 'export' },
] as const;

type ActionType = (typeof fabActions)[number]['action'];

export function FAB() {
  const { actions } = useApp();
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  // Close menu when clicking outside
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('click', handleClickOutside);
    return () => document.removeEventListener('click', handleClickOutside);
  }, []);

  const handleMainClick = () => {
    setIsOpen(!isOpen);
  };

  const handleAction = (action: ActionType) => {
    switch (action) {
      case 'generate':
        actions.generateProgression();
        break;
      case 'regenerate':
        actions.regenerateProgression();
        break;
      case 'spice':
        actions.spiceItUp();
        break;
      case 'play':
        actions.playProgression();
        break;
      case 'export':
        actions.exportToMIDI();
        break;
    }
    setIsOpen(false);
  };

  return (
    <div className={`fab-container ${isOpen ? 'open' : ''}`} ref={containerRef}>
      <button id="fab-main" className="fab" aria-label="Quick actions" onClick={handleMainClick}>
        <span className="fab-icon">🎲</span>
      </button>
      <div className={`fab-menu ${isOpen ? '' : 'hidden'}`}>
        {fabActions.map(({ id, icon, label, action }) => (
          <button
            key={id}
            id={id}
            className="fab-action"
            aria-label={label}
            onClick={() => handleAction(action)}
          >
            <span>{icon}</span>
            <span className="fab-label">{label}</span>
          </button>
        ))}
      </div>
    </div>
  );
}
