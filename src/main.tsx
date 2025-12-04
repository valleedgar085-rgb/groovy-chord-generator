/**
 * Groovy Chord Generator
 * Main Entry Point
 * Version 2.4
 * Author: Edgar Valle
 */

import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import { AppProvider } from './hooks';

// Mount root safely
const rootElement = document.getElementById('root');

if (!rootElement) {
  // Fail fast in development if #root is missing
  throw new Error('Root element with id "root" not found');
}

const root = createRoot(rootElement);

root.render(
  <StrictMode>
    <AppProvider>
      <App />
    </AppProvider>
  </StrictMode>,
);

console.info('🎵 Groovy Chord Generator v2.4 initialized');
console.info('Created by Edgar Valle');
