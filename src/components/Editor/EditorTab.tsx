/**
 * Groovy Chord Generator
 * Editor Tab Component
 * Version 2.5
 */

import { useApp } from '../../hooks';
import { EditorToolbar } from './EditorToolbar';
import { PianoRoll } from './PianoRoll';

export function EditorTab() {
  const { state } = useApp();

  return (
    <section id="tab-editor" className="tab-content">
      <div className="editor-section">
        <EditorToolbar />
        <PianoRoll />
        {state.showTips && (
          <div className="editor-tip">
            <span>💡</span>
            <p>Tap to add notes, tap again to remove. Pinch to zoom.</p>
          </div>
        )}
      </div>
    </section>
  );
}
