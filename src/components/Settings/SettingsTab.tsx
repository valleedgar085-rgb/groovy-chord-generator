/**
 * Groovy Chord Generator
 * Settings Tab Component
 * Version 2.4
 */

import { useApp } from '../../hooks';
import { Slider, Toggle, ControlSelect } from '../common';
import { SOUND_TYPE_OPTIONS } from '../../constants';
import type { SoundType } from '../../types';

export function SettingsTab() {
  const { state, actions } = useApp();

  return (
    <section id="tab-settings" className="tab-content">
      <div className="settings-section">
        <h2>Settings</h2>

        {/* Audio Settings */}
        <div className="settings-group">
          <h3>Audio</h3>
          <Slider
            id="volume-slider"
            label="Master Volume"
            value={state.masterVolume * 100}
            min={0}
            max={100}
            onChange={(value) => actions.setVolume(value / 100)}
          />
          <ControlSelect
            id="sound-type"
            label="Sound Type"
            value={state.soundType}
            options={SOUND_TYPE_OPTIONS}
            onChange={(value) => actions.setSoundType(value as SoundType)}
          />
        </div>

        {/* Envelope ADSR Settings */}
        <div className="settings-group">
          <h3>Envelope (ADSR)</h3>
          <Slider
            id="env-attack"
            label="Attack (0 - 2s)"
            value={state.envelope.attack}
            min={0}
            max={2}
            step={0.01}
            onChange={(attack) =>
              actions.setEnvelope({ ...state.envelope, attack })
            }
          />
          <Slider
            id="env-decay"
            label="Decay (0 - 2s)"
            value={state.envelope.decay}
            min={0}
            max={2}
            step={0.01}
            onChange={(decay) =>
              actions.setEnvelope({ ...state.envelope, decay })
            }
          />
          <Slider
            id="env-sustain"
            label="Sustain (0 - 1)"
            value={state.envelope.sustain}
            min={0}
            max={1}
            step={0.01}
            onChange={(sustain) =>
              actions.setEnvelope({ ...state.envelope, sustain })
            }
          />
          <Slider
            id="env-release"
            label="Release (0 - 3s)"
            value={state.envelope.release}
            min={0}
            max={3}
            step={0.01}
            onChange={(release) =>
              actions.setEnvelope({ ...state.envelope, release })
            }
          />
        </div>

        {/* Display Settings */}
        <div className="settings-group">
          <h3>Display</h3>
          <Toggle
            id="show-numerals"
            label="Show Roman Numerals"
            checked={state.showNumerals}
            onChange={actions.setShowNumerals}
          />
          <Toggle
            id="show-tips"
            label="Show Tips"
            checked={state.showTips}
            onChange={actions.setShowTips}
          />
        </div>

        {/* About Section */}
        <div className="settings-group">
          <h3>About</h3>
          <div className="about-info">
            <p>
              <strong>Groovy Chord Generator</strong>
            </p>
            <p>Version 2.4</p>
            <p>
              Created by <span className="accent">Edgar Valle</span>
            </p>
            <p className="copyright">© 2025</p>
          </div>
          <button
            id="show-onboarding"
            className="btn-secondary full-width"
            onClick={() => actions.setOnboardingComplete(false)}
          >
            Show Tutorial
          </button>
        </div>
      </div>
    </section>
  );
}
