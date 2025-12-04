/**
 * Groovy Chord Generator
 * Animation Utilities
 * Version 2.5
 */

// Helper function to trigger the generation animation
export function triggerGenerationAnimation(): void {
  window.dispatchEvent(new CustomEvent('triggerGenerationAnimation'));
}
