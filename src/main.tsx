/**
 * Groovy Chord Generator
 * Main Entry Point
 * Version 2.4
 */

import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { AppProvider } from './hooks'
import App from './App.tsx'

// Register service worker
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js')
      .then((registration) => {
        console.log('SW registered:', registration.scope);
      })
      .catch((error) => {
        console.log('SW registration failed:', error);
      });
  });
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AppProvider>
      <App />
    </AppProvider>
  </StrictMode>,
)

console.log('🎵 Groovy Chord Generator v2.4 initialized!');
console.log('Created by Edgar Valle');
