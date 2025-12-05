/// Groovy Chord Generator
/// Generator Tab
/// Version 2.5

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/types.dart';
import '../models/constants.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';
import '../utils/music_theory.dart';
import '../widgets/chord_card.dart';
import '../widgets/preset_card.dart';
import '../widgets/control_dropdown.dart';
import '../widgets/collapsible_section.dart';

class GeneratorTab extends StatelessWidget {
  const GeneratorTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Quick Controls
              _buildQuickControls(context, appState),
              const SizedBox(height: AppTheme.spacingMd),
              
              // Chord Display
              _buildChordDisplay(context, appState),
              const SizedBox(height: AppTheme.spacingMd),
              
              // Smart Presets
              CollapsibleSection(
                title: '✨ Smart Presets',
                initiallyExpanded: false,
                child: _buildSmartPresets(context, appState),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              
              // Advanced Settings
              CollapsibleSection(
                title: '⚙️ Advanced Settings',
                initiallyExpanded: false,
                child: _buildAdvancedSettings(context, appState),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              
              // Groove Settings
              CollapsibleSection(
                title: '🎵 Groove Settings',
                initiallyExpanded: false,
                child: _buildGrooveSettings(context, appState),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              
              // History
              if (appState.progressionHistory.isNotEmpty)
                CollapsibleSection(
                  title: '📜 History',
                  initiallyExpanded: false,
                  child: _buildHistory(context, appState),
                ),
              
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickControls(BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ControlDropdown(
                  label: 'Genre',
                  value: appState.genre,
                  items: genreOptions.map((o) => DropdownMenuItem(
                    value: o['value'] as GenreKey,
                    child: Text(o['label'] as String),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) appState.setGenre(value);
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: ControlDropdown(
                  label: 'Key',
                  value: appState.currentKey,
                  items: keyOptions.map((o) => DropdownMenuItem(
                    value: o['value'] as KeyName,
                    child: Text(o['label'] as String),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) appState.setCurrentKey(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: ControlDropdown(
                  label: 'Complexity',
                  value: appState.complexity,
                  items: complexityOptions.map((o) => DropdownMenuItem(
                    value: o['value'] as ComplexityLevel,
                    child: Text(o['label'] as String),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) appState.setComplexity(value);
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: ControlDropdown(
                  label: 'Rhythm',
                  value: appState.rhythm,
                  items: rhythmOptions.map((o) => DropdownMenuItem(
                    value: o['value'] as RhythmLevel,
                    child: Text(o['label'] as String),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) appState.setRhythm(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChordDisplay(BuildContext context, AppState appState) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🎹 Chord Progression',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (appState.currentProgression.isNotEmpty)
                _buildSpiceButton(context, appState),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          if (appState.currentProgression.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: const Center(
                child: Text(
                  'Tap the + button to generate chords',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              alignment: WrapAlignment.center,
              children: appState.currentProgression.asMap().entries.map((entry) {
                final index = entry.key;
                final chord = entry.value;
                return ChordCard(
                  chord: chord,
                  index: index,
                  showNumerals: appState.showNumerals,
                  isLocked: appState.isChordLocked(index),
                  onLockToggle: () => appState.toggleChordLock(index),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSpiceButton(BuildContext context, AppState appState) {
    return GestureDetector(
      onTap: appState.spiceItUp,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          gradient: AppTheme.spiceGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF97316).withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌶️', style: TextStyle(fontSize: 16)),
            SizedBox(width: 4),
            Text(
              'Spice It Up!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartPresets(BuildContext context, AppState appState) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppTheme.spacingSm,
        mainAxisSpacing: AppTheme.spacingSm,
        childAspectRatio: 1.2,
      ),
      itemCount: smartPresets.length,
      itemBuilder: (context, index) {
        final presetKey = smartPresets.keys.elementAt(index);
        final preset = smartPresets[presetKey]!;
        return PresetCard(
          presetKey: presetKey,
          preset: preset,
          isSelected: appState.currentPreset == presetKey,
          onSelect: (key) => appState.applyPreset(key),
        );
      },
    );
  }

  Widget _buildAdvancedSettings(BuildContext context, AppState appState) {
    return Column(
      children: [
        // Spice Level
        ControlDropdown(
          label: 'Spice Level',
          value: appState.spiceLevel,
          items: spiceLevelOptions.map((o) => DropdownMenuItem(
            value: o['value'] as SpiceLevel,
            child: Text(o['label'] as String),
          )).toList(),
          onChanged: (value) {
            if (value != null) appState.setSpiceLevel(value);
          },
        ),
        const SizedBox(height: AppTheme.spacingMd),
        
        // Mood
        ControlDropdown(
          label: 'Mood',
          value: appState.currentMood,
          items: moodOptions.map((o) => DropdownMenuItem(
            value: o['value'] as MoodType,
            child: Text(o['label'] as String),
          )).toList(),
          onChanged: (value) {
            if (value != null) appState.setMood(value);
          },
        ),
        const SizedBox(height: AppTheme.spacingMd),
        
        // Toggle options
        _buildToggleOption(
          'Voice Leading',
          appState.useVoiceLeading,
          appState.setUseVoiceLeading,
        ),
        _buildToggleOption(
          'Advanced Theory',
          appState.useAdvancedTheory,
          appState.setUseAdvancedTheory,
        ),
        _buildToggleOption(
          'Modal Interchange',
          appState.useModalInterchange,
          appState.setUseModalInterchange,
        ),
        _buildToggleOption(
          'Functional Harmony',
          appState.useFunctionalHarmony,
          appState.setUseFunctionalHarmony,
        ),
        _buildToggleOption(
          'Include Melody',
          appState.includeMelody,
          appState.setIncludeMelody,
        ),
        _buildToggleOption(
          'Include Bass',
          appState.includeBass,
          appState.setIncludeBass,
        ),
      ],
    );
  }

  Widget _buildGrooveSettings(BuildContext context, AppState appState) {
    return Column(
      children: [
        ControlDropdown(
          label: 'Groove Template',
          value: appState.grooveTemplate,
          items: grooveTemplateOptions.map((o) => DropdownMenuItem(
            value: o['value'] as GrooveTemplate,
            child: Text(o['label'] as String),
          )).toList(),
          onChanged: (value) {
            if (value != null) appState.setGrooveTemplate(value);
          },
        ),
        const SizedBox(height: AppTheme.spacingMd),
        
        // Swing slider
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Swing',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '${(appState.swing * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentSecondary,
                  ),
                ),
              ],
            ),
            Slider(
              value: appState.swing,
              onChanged: appState.setSwing,
              min: 0,
              max: 1,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleOption(String label, bool value, void Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.spacingSm,
        horizontal: AppTheme.spacingMd,
      ),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: AppTheme.bgTertiary,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
      ),
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

  Widget _buildHistory(BuildContext context, AppState appState) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appState.progressionHistory.length,
      itemBuilder: (context, index) {
        final entry = appState.progressionHistory[index];
        return GestureDetector(
          onTap: () => appState.restoreFromHistory(index),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.bgTertiary,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      keyNameToString(entry.key),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        genreProfiles[entry.genre]?.name ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.progression.map((c) => getChordSymbol(c)).join(' - '),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  getTimeAgo(entry.timestamp),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
