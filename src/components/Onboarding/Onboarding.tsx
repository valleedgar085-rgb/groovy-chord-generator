/**
 * Groovy Chord Generator
 * Onboarding Overlay Component
 * Version 2.5
 */

import { useState, useCallback, type KeyboardEvent } from 'react';
import { useApp } from '../../hooks';

const slides = [
  {
    icon: '🎵',
    title: 'Welcome to Groovy Chord Generator!',
    description: 'Create amazing chord progressions for any genre in seconds.',
  },
  {
    icon: '🎛️',
    title: 'Choose Your Style',
    description: 'Select a genre, complexity, and key to customize your progression.',
  },
  {
    icon: '🎹',
    title: 'Edit & Play',
    description: 'Use the visual editor to fine-tune your music and hear it come to life!',
  },
];

export function Onboarding() {
  const { state, actions } = useApp();
  const [currentSlide, setCurrentSlide] = useState(0);

  const handleNext = useCallback(() => {
    if (currentSlide < slides.length - 1) {
      setCurrentSlide(currentSlide + 1);
    } else {
      actions.setOnboardingComplete(true);
    }
  }, [currentSlide, actions]);

  const handleSkip = useCallback(() => {
    actions.setOnboardingComplete(true);
  }, [actions]);

  const handleDotClick = useCallback((index: number) => {
    setCurrentSlide(index);
  }, []);

  const handleDotKeyDown = useCallback((e: KeyboardEvent, index: number) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      setCurrentSlide(index);
    }
  }, []);

  if (state.onboardingComplete) {
    return null;
  }

  return (
    <div id="onboarding-overlay" className="onboarding-overlay">
      <div className="onboarding-content">
        {slides.map((slide, index) => (
          <div
            key={index}
            className={`onboarding-slide ${index === currentSlide ? 'active' : ''}`}
            data-slide={index}
          >
            <div className="onboarding-icon">{slide.icon}</div>
            <h2>{slide.title}</h2>
            <p>{slide.description}</p>
          </div>
        ))}
        <div className="onboarding-nav">
          <div className="onboarding-dots" role="tablist" aria-label="Onboarding slides">
            {slides.map((_, index) => (
              <span
                key={index}
                className={`dot ${index === currentSlide ? 'active' : ''}`}
                data-dot={index}
                onClick={() => handleDotClick(index)}
                onKeyDown={(e) => handleDotKeyDown(e, index)}
                role="tab"
                aria-selected={index === currentSlide}
                aria-label={`Slide ${index + 1}`}
                tabIndex={0}
              />
            ))}
          </div>
          <button id="onboarding-next" className="btn-primary" onClick={handleNext}>
            {currentSlide === slides.length - 1 ? 'Get Started' : 'Next'}
          </button>
          <button id="onboarding-skip" className="btn-secondary" onClick={handleSkip}>
            Skip
          </button>
        </div>
      </div>
    </div>
  );
}
