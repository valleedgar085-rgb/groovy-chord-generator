import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/constants.dart';
import '../models/types.dart';
import '../providers/app_state.dart';
import '../utils/music_theory.dart';
import '../utils/theme.dart';
import '../widgets/chord_card.dart';
import 'generator_tab.dart';

/// Phase 3.75 primary progression workspace.
///
/// Keeps the everyday create flow compact while preserving the legacy deep
/// controls behind an explicit tools surface during the compatibility cleanup.
class GeneratorWorkspace extends StatelessWidget {
  const GeneratorWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 170),
          children: [
            _SessionSetupCard(appState: appState),
            const SizedBox(height: 12),
            _ProgressionStage(appState: appState),
          ],
        );
      },
    );
  }
}

class _SessionSetupCard extends StatelessWidget {
  const _SessionSetupCard({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 17, color: AppTheme.accentCyan),
              SizedBox(width: 7),
              Text(
                'SESSION SETUP',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PickerChip<GenreKey>(
                  label: 'GENRE',
                  valueLabel: _optionLabel(genreOptions, appState.genre),
                  items: genreOptions,
                  current: appState.genre,
                  onChanged: appState.setGenre,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PickerChip<KeyName>(
                  label: 'KEY',
                  valueLabel: _optionLabel(keyOptions, appState.currentKey),
                  items: keyOptions,
                  current: appState.currentKey,
                  onChanged: appState.setCurrentKey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'COMPLEXITY',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          _SegmentedChoice<ComplexityLevel>(
            current: appState.complexity,
            options: complexityOptions,
            onChanged: appState.setComplexity,
          ),
          const SizedBox(height: 11),
          const Text(
            'GROOVE',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          _SegmentedChoice<RhythmLevel>(
            current: appState.rhythm,
            options: rhythmOptions,
            onChanged: appState.setRhythm,
          ),
        ],
      ),
    );
  }

  static String _optionLabel(List<Map<String, dynamic>> options, Object value) {
    for (final option in options) {
      if (option['value'] == value) return option['label'] as String;
    }
    return value.toString();
  }
}

class _PickerChip<T> extends StatelessWidget {
  const _PickerChip({
    required this.label,
    required this.valueLabel,
    required this.items,
    required this.current,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final List<Map<String, dynamic>> items;
  final T current;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () => _showPicker(context),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.bgTertiary,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    valueLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<T>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final item = items[index];
              final value = item['value'] as T;
              final selected = value == current;
              return ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: selected
                    ? AppTheme.accentPrimary.withValues(alpha: 0.14)
                    : AppTheme.bgTertiary,
                title: Text(
                  item['label'] as String,
                  style: TextStyle(
                    color: selected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check_rounded,
                        color: AppTheme.accentCyan, size: 19)
                    : null,
                onTap: () => Navigator.pop(context, value),
              );
            },
          ),
        );
      },
    );
    if (selected != null) onChanged(selected);
  }
}

class _SegmentedChoice<T> extends StatelessWidget {
  const _SegmentedChoice({
    required this.current,
    required this.options,
    required this.onChanged,
  });

  final T current;
  final List<Map<String, dynamic>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: options.asMap().entries.map((entry) {
            final option = entry.value;
            final value = option['value'] as T;
            final selected = value == current;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: entry.key == 0 ? 0 : 5),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onChanged(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.accentPrimary.withValues(alpha: 0.18)
                          : AppTheme.bgTertiary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppTheme.accentPrimary.withValues(alpha: 0.72)
                            : AppTheme.borderColor,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _shortLabel(option['label'] as String),
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        color: selected
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                        fontSize: constraints.maxWidth < 330 ? 9 : 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }

  String _shortLabel(String value) {
    final upper = value.toUpperCase();
    if (upper == 'MODERATE') return 'MED';
    if (upper == 'ADVANCED') return 'ADV';
    return upper;
  }
}

class _ProgressionStage extends StatelessWidget {
  const _ProgressionStage({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final progression = appState.currentProgression;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROGRESSION STAGE',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tap pads to audition • lock what you want to keep',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (progression.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${appState.lastHarmonyScore.round()} SCORE',
                    style: const TextStyle(
                      color: AppTheme.accentCyan,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (progression.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
              decoration: BoxDecoration(
                color: AppTheme.bgTertiary.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Column(
                children: [
                  Icon(Icons.music_note_rounded,
                      color: AppTheme.textMuted, size: 28),
                  SizedBox(height: 8),
                  Text(
                    'Create a progression above to start playing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: progression.asMap().entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: entry.key == progression.length - 1 ? 0 : 8,
                    ),
                    child: ChordCard(
                      chord: entry.value,
                      index: entry.key,
                      showNumerals: appState.showNumerals,
                      isLocked: appState.isChordLocked(entry.key),
                      onLockToggle: () => appState.toggleChordLock(entry.key),
                    ),
                  );
                }).toList(growable: false),
              ),
            ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (progression.isNotEmpty)
                _StageAction(
                  icon: Icons.replay_rounded,
                  label: 'REPLAY SEED',
                  onTap: appState.replayLastGeneration,
                ),
              if (progression.isNotEmpty)
                _StageAction(
                  icon: Icons.local_fire_department_rounded,
                  label: 'SPICE',
                  onTap: appState.spiceItUp,
                ),
              if (progression.isNotEmpty)
                _StageAction(
                  icon: Icons.delete_outline_rounded,
                  label: 'CLEAR',
                  onTap: appState.clearProgression,
                ),
              _StageAction(
                icon: Icons.tune_rounded,
                label: 'MORE TOOLS',
                onTap: () => _openLegacyTools(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openLegacyTools(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgPrimary,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'DEEP TOOLS',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
              const Expanded(child: GeneratorTab()),
            ],
          ),
        );
      },
    );
  }
}

class _StageAction extends StatelessWidget {
  const _StageAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textSecondary,
        side: const BorderSide(color: AppTheme.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
