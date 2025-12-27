/// Groovy Chord Generator
/// Generator Tab
/// Version 2.5
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/types.dart';
import '../models/constants.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';
import '../utils/music_theory.dart';
import '../utils/performance_config.dart';
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

              // Favorites
              if (appState.favorites.isNotEmpty)
                CollapsibleSection(
                  title: '❤️ Favorites',
                  initiallyExpanded: false,
                  child: _buildFavorites(context, appState),
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

  Widget _buildFavorites(BuildContext context, AppState appState) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Add cache extent for better scrolling performance on lower-end devices
      cacheExtent: PerformanceConfig.getCacheExtent(),
      itemCount: appState.favorites.length,
      itemBuilder: (context, index) {
        final favorite = appState.favorites[index];
        // Wrap each item in RepaintBoundary for isolated repaints
        return RepaintBoundary(
          child: Dismissible(
            key: Key(favorite.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
              ),
              child: const Icon(Icons.delete, color: AppTheme.error),
            ),
            onDismissed: (_) => appState.removeFavorite(favorite.id),
            child: GestureDetector(
              onTap: () => appState.loadFavorite(favorite),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.bgTertiary,
                      AppTheme.bgTertiary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                  border: Border.all(
                      color: AppTheme.accentPink.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.accentPink, AppTheme.accentPrimary],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.favorite,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            favorite.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            favorite.progression
                                .map((c) => getChordSymbol(c))
                                .join(' - '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        keyNameToString(favorite.key),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.accentSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                  items: genreOptions
                      .map((o) => DropdownMenuItem(
                            value: o['value'] as GenreKey,
                            child: Text(o['label'] as String),
                          ))
                      .toList(),
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
                  items: keyOptions
                      .map((o) => DropdownMenuItem(
                            value: o['value'] as KeyName,
                            child: Text(o['label'] as String),
                          ))
                      .toList(),
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
                  items: complexityOptions
                      .map((o) => DropdownMenuItem(
                            value: o['value'] as ComplexityLevel,
                            child: Text(o['label'] as String),
                          ))
                      .toList(),
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
                  items: rhythmOptions
                      .map((o) => DropdownMenuItem(
                            value: o['value'] as RhythmLevel,
                            child: Text(o['label'] as String),
                          ))
                      .toList(),
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.favorite_border,
                      tooltip: 'Save to Favorites',
                      onTap: () => _showSaveFavoriteDialog(context, appState),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      icon: Icons.share,
                      tooltip: 'Share',
                      onTap: () => _showShareDialog(context, appState),
                    ),
                    const SizedBox(width: 8),
                    _buildSpiceButton(context, appState),
                  ],
                ),
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
              children:
                  appState.currentProgression.asMap().entries.map((entry) {
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

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.bgTertiary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Icon(icon, size: 18, color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  void _showSaveFavoriteDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save to Favorites'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter a name for this progression',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final success =
                    await appState.addToFavorites(controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Saved to favorites!'
                          : 'Could not save to favorites'),
                      backgroundColor:
                          success ? AppTheme.success : AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context, AppState appState) {
    final shareText = appState.getShareableText();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Progression'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.bgTertiary,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
              ),
              child: Text(
                shareText,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            const Text(
              'Copy the text above to share your progression!',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // In a full implementation, this would copy to clipboard
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard!'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
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
      // Add cache extent for better scrolling performance on lower-end devices
      cacheExtent: PerformanceConfig.getCacheExtent(),
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
          items: spiceLevelOptions
              .map((o) => DropdownMenuItem(
                    value: o['value'] as SpiceLevel,
                    child: Text(o['label'] as String),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) appState.setSpiceLevel(value);
          },
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Mood
        ControlDropdown(
          label: 'Mood',
          value: appState.currentMood,
          items: moodOptions
              .map((o) => DropdownMenuItem(
                    value: o['value'] as MoodType,
                    child: Text(o['label'] as String),
                  ))
              .toList(),
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
          items: grooveTemplateOptions
              .map((o) => DropdownMenuItem(
                    value: o['value'] as GrooveTemplate,
                    child: Text(o['label'] as String),
                  ))
              .toList(),
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

  Widget _buildToggleOption(
      String label, bool value, void Function(bool) onChanged) {
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
      // Add cache extent for better scrolling performance on lower-end devices
      cacheExtent: PerformanceConfig.getCacheExtent(),
      itemCount: appState.progressionHistory.length,
      itemBuilder: (context, index) {
        final entry = appState.progressionHistory[index];
        // Wrap each item in RepaintBoundary for isolated repaints
        return RepaintBoundary(
          child: GestureDetector(
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
          ),
        );
      },
    );
  }
}
