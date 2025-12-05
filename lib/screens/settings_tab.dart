/// Groovy Chord Generator
/// Settings Tab
/// Version 2.5

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/types.dart';
import '../models/constants.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';
import '../widgets/control_dropdown.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Audio Settings
              _buildSettingsGroup(
                title: 'Audio',
                children: [
                  _buildVolumeSlider(appState),
                  const SizedBox(height: AppTheme.spacingMd),
                  ControlDropdown(
                    label: 'Sound Type',
                    value: appState.soundType,
                    items: soundTypeOptions.map((o) => DropdownMenuItem(
                      value: o['value'] as SoundType,
                      child: Text(o['label'] as String),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) appState.setSoundType(value);
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildTempoSlider(appState),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              
              // Display Settings
              _buildSettingsGroup(
                title: 'Display',
                children: [
                  _buildToggleSetting(
                    'Show Roman Numerals',
                    appState.showNumerals,
                    appState.setShowNumerals,
                  ),
                  _buildToggleSetting(
                    'Show Tips',
                    appState.showTips,
                    appState.setShowTips,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              
              // Envelope Settings
              _buildSettingsGroup(
                title: 'Envelope',
                children: [
                  _buildEnvelopeSlider('Attack', appState.envelope.attack, (v) {
                    appState.setEnvelope(appState.envelope.copyWith(attack: v));
                  }),
                  _buildEnvelopeSlider('Decay', appState.envelope.decay, (v) {
                    appState.setEnvelope(appState.envelope.copyWith(decay: v));
                  }),
                  _buildEnvelopeSlider('Sustain', appState.envelope.sustain, (v) {
                    appState.setEnvelope(appState.envelope.copyWith(sustain: v));
                  }),
                  _buildEnvelopeSlider('Release', appState.envelope.release, (v) {
                    appState.setEnvelope(appState.envelope.copyWith(release: v));
                  }),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              
              // About Section
              _buildSettingsGroup(
                title: 'About',
                children: [
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          '🎵 Groovy Chord Generator',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingSm),
                        Text(
                          'Version $appVersion',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingSm),
                        Text(
                          'Created by Edgar Valle',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingMd),
                        Text(
                          '© 2024 All rights reserved',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const Divider(color: AppTheme.borderColor),
          const SizedBox(height: AppTheme.spacingSm),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleSetting(String label, bool value, void Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeSlider(AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Master Volume',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '${(appState.masterVolume * 100).round()}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentSecondary,
              ),
            ),
          ],
        ),
        Slider(
          value: appState.masterVolume,
          onChanged: appState.setMasterVolume,
          min: 0,
          max: 1,
        ),
      ],
    );
  }

  Widget _buildTempoSlider(AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tempo',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '${appState.tempo} BPM',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentSecondary,
              ),
            ),
          ],
        ),
        Slider(
          value: appState.tempo.toDouble(),
          onChanged: (value) => appState.setTempo(value.round()),
          min: 40,
          max: 200,
        ),
      ],
    );
  }

  Widget _buildEnvelopeSlider(String label, double value, void Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentSecondary,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          min: 0,
          max: 1,
        ),
      ],
    );
  }
}
