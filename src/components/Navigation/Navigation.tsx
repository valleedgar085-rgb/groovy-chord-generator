/**
 * Groovy Chord Generator
 * Bottom Navigation Component
 * Version 2.4
 */

import { useApp } from '../../hooks';
import type { TabName } from '../../types';

const navItems: { tab: TabName; icon: string; label: string }[] = [
  { tab: 'generator', icon: '🎵', label: 'Generator' },
  { tab: 'editor', icon: '🎼', label: 'Editor' },
  { tab: 'settings', icon: '⚙️', label: 'Settings' },
];

export function Navigation() {
  const { state, actions } = useApp();

  return (
    <nav className="bottom-nav">
      {navItems.map(({ tab, icon, label }) => (
        <button
          key={tab}
          className={`nav-item ${state.currentTab === tab ? 'active' : ''}`}
          data-tab={tab}
          aria-label={label}
          onClick={() => actions.setCurrentTab(tab)}
        >
          <span className="nav-icon">{icon}</span>
          <span className="nav-label">{label}</span>
        </button>
      ))}
    </nav>
  );
}
