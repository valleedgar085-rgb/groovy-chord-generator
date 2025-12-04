/**
 * Groovy Chord Generator
 * Main App Component
 * Version 2.5
 */

import { memo } from 'react';
import { useApp } from './hooks';
import {
  Header,
  Navigation,
  GeneratorTab,
  EditorTab,
  SettingsTab,
  Onboarding,
  FAB,
  GenerationAnimation,
} from './components';
import { BassTab } from './components/Bass';
import './App.css';

import type { TabName } from './types';

function AppContentBase() {
  const { state } = useApp();
  const currentTab: TabName = state.currentTab;

  return (
    <>
      <Onboarding />
      <GenerationAnimation />

      <div className="app-container">
        <Header />

        <main className="main-content" aria-live="polite">
          {currentTab === 'generator' && <GeneratorTab />}
          {currentTab === 'editor' && <EditorTab />}
          {currentTab === 'bass' && <BassTab />}
          {currentTab === 'settings' && <SettingsTab />}
        </main>

        <FAB />
        <Navigation />
      </div>
    </>
  );
}

const AppContent = memo(AppContentBase);

function App() {
  return <AppContent />;
}

export default App;
