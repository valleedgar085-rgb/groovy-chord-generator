/**
 * Groovy Chord Generator
 * Main App Component
 * Version 2.4
 */

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
import './App.css';

function AppContent() {
  const { state } = useApp();

  return (
    <>
      <Onboarding />
      <GenerationAnimation />

      <div className="app-container">
        <Header />

        <main className="main-content">
          {state.currentTab === 'generator' && <GeneratorTab />}
          {state.currentTab === 'editor' && <EditorTab />}
          {state.currentTab === 'settings' && <SettingsTab />}
        </main>

        <FAB />
        <Navigation />
      </div>
    </>
  );
}

function App() {
  return <AppContent />;
}

export default App;
