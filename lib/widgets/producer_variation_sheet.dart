import 'package:flutter/material.dart';

import '../engine/producer_brain_telemetry.dart';
import '../engine/song_candidate.dart';
import '../providers/app_state.dart';
import '../services/audio_playback_service.dart';
import '../utils/music_theory.dart';
import '../utils/theme.dart';

class ProducerVariationSheet extends StatelessWidget {
  const ProducerVariationSheet({
    super.key,
    required this.appState,
    required this.decision,
  });

  final AppState appState;
  final ProducerDecisionSnapshot decision;

  static Future<void> open(
    BuildContext context, {
    required AppState appState,
    required ProducerDecisionSnapshot decision,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.82,
        child: ProducerVariationSheet(
          appState: appState,
          decision: decision,
        ),
      ),
    );
  }

  List<SongCandidate> get _options {
    final options = <SongCandidate>[decision.winner];
    for (final candidate in decision.variations) {
      final exists = options.any((item) =>
          item.variationStyle == candidate.variationStyle &&
          item.candidateIndex == candidate.candidateIndex);
      if (!exists) options.add(candidate);
    }
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.bgPrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 8, 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppTheme.producerGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.compare_arrows_rounded,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Producer A / B / C',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Audition the Producer Brain directions, then choose by ear.',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 3, 14, 24),
                itemCount: options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final candidate = options[index];
                  return _VariationCard(
                    appState: appState,
                    decision: decision,
                    candidate: candidate,
                    recommended: _sameCandidate(candidate, decision.winner),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _sameCandidate(SongCandidate a, SongCandidate b) =>
      a.variationStyle == b.variationStyle &&
      a.candidateIndex == b.candidateIndex;
}

class _VariationCard extends StatelessWidget {
  const _VariationCard({
    required this.appState,
    required this.decision,
    required this.candidate,
    required this.recommended,
  });

  final AppState appState;
  final ProducerDecisionSnapshot decision;
  final SongCandidate candidate;
  final bool recommended;

  bool get selected => decision.isSelected(candidate);

  @override
  Widget build(BuildContext context) {
    final score = candidate.score.clamp(0.0, 100.0).toDouble();
    final delta = candidate.scoreDelta;
    final scoreColor = _scoreColor(score);
    final symbols = candidate.progression
        .take(8)
        .map(getChordSymbol)
        .join('  ·  ');

    return Container(
      key: ValueKey('producerVariation-${candidate.variationStyle.name}'),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            selected
                ? AppTheme.accentPrimary.withValues(alpha: 0.17)
                : AppTheme.bgSecondary,
            AppTheme.bgSecondary,
            AppTheme.accentCyan.withValues(alpha: selected ? 0.07 : 0.025),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? AppTheme.accentCyan.withValues(alpha: 0.56)
              : recommended
                  ? AppTheme.producerGold.withValues(alpha: 0.38)
                  : AppTheme.borderColor,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _styleColor(candidate.variationStyle)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  candidate.variationStyle.label,
                  style: TextStyle(
                    color: _styleColor(candidate.variationStyle),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.55,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              if (recommended)
                const _Badge(
                  text: 'BRAIN PICK',
                  color: AppTheme.producerGold,
                ),
              if (selected) ...[
                const SizedBox(width: 6),
                const _Badge(
                  text: 'ACTIVE',
                  color: AppTheme.accentCyan,
                ),
              ],
              const Spacer(),
              Text(
                score.round().toString(),
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                delta >= 0
                    ? '+${delta.toStringAsFixed(1)}'
                    : delta.toStringAsFixed(1),
                style: TextStyle(
                  color: delta > 0.05 ? AppTheme.success : AppTheme.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.bgTertiary.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              symbols,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.15,
              ),
            ),
          ),
          if (candidate.repairs.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              candidate.repairs.take(2).join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 9,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: ValueKey('preview-${candidate.variationStyle.name}'),
                  onPressed: () {
                    var preview = candidate.progression.toList(growable: false);
                    if (appState.useVoiceLeading) {
                      preview = applyVoiceLeading(preview);
                    }
                    preview = applyGrooveToProgression(
                      preview,
                      appState.grooveTemplate,
                    );
                    AudioPlaybackService.instance.playProgression(preview);
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 17),
                  label: const Text('Preview'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  key: ValueKey('use-${candidate.variationStyle.name}'),
                  onPressed: selected
                      ? null
                      : () => _useCandidate(context),
                  icon: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.auto_fix_high_rounded,
                    size: 16,
                  ),
                  label: Text(selected ? 'Active' : 'Use'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _useCandidate(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final applied = appState.applyProducerCandidate(candidate);
    if (!applied) return;
    ProducerBrainTelemetry.instance.select(candidate);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${candidate.variationStyle.label} Producer variation applied.',
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 6.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.45,
        ),
      ),
    );
  }
}

Color _styleColor(ProducerVariationStyle style) => switch (style) {
      ProducerVariationStyle.raw => AppTheme.textSecondary,
      ProducerVariationStyle.polished => AppTheme.accentCyan,
      ProducerVariationStyle.creative => AppTheme.accentSecondary,
      ProducerVariationStyle.hook => AppTheme.accentPink,
    };

Color _scoreColor(double score) {
  if (score >= 85) return AppTheme.success;
  if (score >= 72) return AppTheme.accentSecondary;
  if (score >= 58) return AppTheme.warning;
  return AppTheme.error;
}
