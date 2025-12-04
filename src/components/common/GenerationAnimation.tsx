/**
 * Groovy Chord Generator
 * Generation Animation Component
 * Version 2.5
 */

import { useState, useEffect } from 'react';

export function GenerationAnimation() {
  const [isActive, setIsActive] = useState(false);

  // Listen for custom event to trigger animation
  useEffect(() => {
    const handleTrigger = () => {
      setIsActive(true);
      setTimeout(() => setIsActive(false), 1200);
    };

    window.addEventListener('triggerGenerationAnimation', handleTrigger);
    return () => window.removeEventListener('triggerGenerationAnimation', handleTrigger);
  }, []);

  if (!isActive) {
    return null;
  }

  return (
    <div id="generation-animation" className={`generation-animation ${isActive ? 'active' : 'hidden'}`}>
      <div className="light-burst"></div>
      <div className="particles-container">
        {Array.from({ length: 12 }, (_, i) => (
          <div key={i} className={`particle particle-${i + 1}`}></div>
        ))}
      </div>
      <div className="sparkles-container">
        {Array.from({ length: 8 }, (_, i) => (
          <div key={i} className={`sparkle sparkle-${i + 1}`}>
            ✨
          </div>
        ))}
      </div>
      <div className="music-notes">
        <span className="note note-1">🎵</span>
        <span className="note note-2">🎶</span>
        <span className="note note-3">🎵</span>
        <span className="note note-4">🎶</span>
      </div>
    </div>
  );
}
