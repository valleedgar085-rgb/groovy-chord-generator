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
    final score = appState.lastHarmonyScore.clamp(0.0, 100.0).toDouble();
    final hasProgression = appState.currentProgression.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF25203F), Color(0xFF151728)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.accentPrimary.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentPrimary.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  size: 21,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRODUCER BRAIN',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.9,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '8 ideas compete • strongest survives',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _QualityBadge(score: score, active: hasProgression),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: AppTheme.accentPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: appState.generateProgression,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text(
                    'CREATE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: HarmonySection.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final section = HarmonySection.values[index];
                final selected = appState.harmonySection == section;
                return ChoiceChip(
                  label: Text(_sectionLabels[section]!),
                  selected: selected,
                  onSelected: (_) => appState.setHarmonySection(section),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  labelStyle: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                  selectedColor: AppTheme.accentPrimary.withValues(alpha: 0.28),
                  backgroundColor: AppTheme.bgPrimary.withValues(alpha: 0.46),
                  side: BorderSide(
                    color: selected
                        ? AppTheme.accentPrimary.withValues(alpha: 0.62)
                        : AppTheme.borderColor,
                  ),
                );
              },
            ),
          ),
          if (hasProgression) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      value: score / 100,
                      backgroundColor: AppTheme.bgPrimary,
                      color: _scoreColor(score),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _scoreLabel(score),
                  style: TextStyle(
                    color: _scoreColor(score),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _scoreLabel(double score) {
    if (score >= 90) return 'EXCELLENT FIT';
    if (score >= 80) return 'STRONG FIT';
    if (score >= 70) return 'GOOD FIT';
    if (score >= 60) return 'WORKABLE';
    return 'EXPERIMENTAL';
  }

  Color _scoreColor(double score) {
    if (score >= 85) return AppTheme.success;
    if (score >= 70) return AppTheme.accentCyan;
    if (score >= 55) return AppTheme.warning;
    return AppTheme.error;
  }
}

class _QualityBadge extends StatelessWidget {
  const _QualityBadge({required this.score, required this.active});

  final double score;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.bgPrimary.withValues(alpha: 0.66),
        shape: BoxShape.circle,
        border: Border.all(
          color: active
              ? AppTheme.accentCyan.withValues(alpha: 0.42)
              : AppTheme.borderColor,
        ),
      ),
      child: Center(
        child: Text(
          active ? score.round().toString() : '--',
          style: TextStyle(
            color: active ? AppTheme.textPrimary : AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
