/**
 * Groovy Chord Generator
 * Onboarding Overlay Component
 * Version 2.4
 */

import { useState } from 'react';
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

  if (state.onboardingComplete) {
    return null;
  }

  const handleNext = () => {
    if (currentSlide < slides.length - 1) {
      setCurrentSlide(currentSlide + 1);
    } else {
      actions.setOnboardingComplete(true);
    }
  };

  const handleSkip = () => {
    actions.setOnboardingComplete(true);
  };

  const handleDotClick = (index: number) => {
    setCurrentSlide(index);
  };

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
          <div className="onboarding-dots">
            {slides.map((_, index) => (
              <span
                key={index}
                className={`dot ${index === currentSlide ? 'active' : ''}`}
                data-dot={index}
                onClick={() => handleDotClick(index)}
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
