/**
 * Groovy Chord Generator
 * Keyboard Click Handler Hook
 * Version 2.5
 */

import { useCallback, type KeyboardEvent } from 'react';

/**
 * Creates a keyboard event handler that triggers onClick for Enter or Space keys.
 * Use this for elements with role="button" to ensure accessibility.
 */
export function useKeyboardClick<T>(onClick: (arg: T) => void, arg: T) {
  return useCallback(
    (e: KeyboardEvent) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        onClick(arg);
      }
    },
    [onClick, arg]
  );
}

/**
 * Creates a keyboard event handler for simpler cases (no argument needed).
 */
export function useKeyboardClickSimple(onClick: () => void) {
  return useCallback(
    (e: KeyboardEvent) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        onClick();
      }
    },
    [onClick]
  );
}
