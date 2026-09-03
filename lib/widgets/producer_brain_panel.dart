import 'package:flutter/material.dart';

import '../engine/harmony_engine.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';

class ProducerBrainPanel extends StatelessWidget {
  const ProducerBrainPanel({
    super.key,
    required this.appState,
  });

  final AppState appState;

  static const _sectionLabels = <HarmonySection, String>{
    HarmonySection.neutral: 'Auto',
    HarmonySection.verse: 'Verse',
    HarmonySection.preChorus: 'Pre',
    HarmonySection.chorus: 'Chorus',
    HarmonySection.bridge: 'Bridge',
  };

  @override
  Widget build(BuildContext context) {
    final score = appState.lastHarmonyScore.clamp(0.0, 100.0);
    final hasProgression = appState.currentProgression.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
        0,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: AppTheme.accentPrimary.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 18,
                color: AppTheme.accentSecondary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Producer Brain',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.bgTertiary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${appState.producerCandidateCount} candidates',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          const Text(
            'Song section',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: HarmonySection.values.map((section) {
              final selected = appState.harmonySection == section;
              return ChoiceChip(
                label: Text(_sectionLabels[section]!),
                selected: selected,
                onSelected: (_) => appState.setHarmonySection(section),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: Text(
                  hasProgression ? _scoreLabel(score) : 'Generate to analyze',
                  style: TextStyle(
                    color: hasProgression
                        ? _scoreColor(score)
                        : AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                hasProgression ? '${score.round()} / 100' : '-- / 100',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: hasProgression ? score / 100.0 : 0.0,
              backgroundColor: AppTheme.bgTertiary,
              color: hasProgression ? _scoreColor(score) : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _scoreLabel(double score) {
    if (score >= 90) return 'Excellent harmonic fit';
    if (score >= 80) return 'Strong harmonic fit';
    if (score >= 70) return 'Good harmonic fit';
    if (score >= 60) return 'Usable — room to improve';
    return 'Experimental result';
  }

  Color _scoreColor(double score) {
    if (score >= 85) return AppTheme.success;
    if (score >= 70) return AppTheme.accentSecondary;
    if (score >= 55) return const Color(0xFFF59E0B);
    return AppTheme.error;
  }
}
