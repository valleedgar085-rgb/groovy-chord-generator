/**
 * Groovy Chord Generator
 * Generator Tab Component
 * Version 2.5
 */

import { CollapsibleSection } from '../common';
import { SmartPresets } from './SmartPresets';
import { QuickControls } from './QuickControls';
import { AdvancedSettings } from './AdvancedSettings';
import { GrooveSettings } from './GrooveSettings';
import { ChordDisplay } from './ChordDisplay';
import { ChordKnobs } from './ChordKnobs';
import { SpiceButton } from './SpiceButton';
import { MelodyDisplay } from './MelodyDisplay';
import { HistoryPanel } from './HistoryPanel';

export function GeneratorTab() {
  return (
    <section id="tab-generator" className="tab-content active">
      {/* Smart Presets */}
      <CollapsibleSection title="Smart Presets" icon="✨" defaultExpanded>
        <SmartPresets />
      </CollapsibleSection>

      {/* Quick Controls */}
      <QuickControls />

      {/* Variety Knobs */}
      <CollapsibleSection title="Variety Controls" icon="🎛️" defaultExpanded>
        <ChordKnobs />
      </CollapsibleSection>

      {/* Groove & Mood Settings - NEW Phase 1 & 2 */}
      <CollapsibleSection title="Groove & Mood" icon="🎵" defaultExpanded>
        <GrooveSettings />
      </CollapsibleSection>

      {/* Advanced Controls */}
      <CollapsibleSection title="Advanced Settings" icon="⚙️">
        <AdvancedSettings />
      </CollapsibleSection>

      {/* Chord Display */}
      <CollapsibleSection title="Chord Progression" icon="🎸" defaultExpanded>
        <ChordDisplay />
        <SpiceButton />
      </CollapsibleSection>

      {/* Melody Section */}
      <CollapsibleSection title="Melody Pattern" icon="🎹">
        <MelodyDisplay />
      </CollapsibleSection>

      {/* History */}
      <CollapsibleSection title="Recent Progressions" icon="📜">
        <HistoryPanel />
      </CollapsibleSection>
    </section>
  );
}
