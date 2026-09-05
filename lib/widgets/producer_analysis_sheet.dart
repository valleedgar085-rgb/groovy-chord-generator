import 'package:flutter/material.dart';

import '../engine/producer_analysis.dart';
import '../engine/producer_brain_telemetry.dart';
import '../engine/song_candidate.dart';
import '../utils/theme.dart';

class ProducerAnalysisSheet extends StatelessWidget {
  const ProducerAnalysisSheet({
    super.key,
    required this.analysis,
    this.decision,
  });

  final ProducerAnalysis analysis;
  final ProducerDecisionSnapshot? decision;

  static Future<void> open(
    BuildContext context,
    ProducerAnalysis analysis, {
    ProducerDecisionSnapshot? decision,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.90,
        child: ProducerAnalysisSheet(
          analysis: analysis,
          decision: decision,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priorities = analysis.priorities;
    final strengths = analysis.strengths;
    final score = analysis.overallScore.clamp(0.0, 100.0).toDouble();

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
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: AppTheme.producerGradient,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.psychology_alt_rounded,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Producer Analysis',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Phase 5.2 · score → diagnose → evolve → rescore',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _OverallBadge(score: score),
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
              child: analysis.metrics.isEmpty
                  ? const _EmptyAnalysis()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 24),
                      children: [
                        if (decision != null) ...[
                          _ProducerDecisionCard(decision: decision!),
                          const SizedBox(height: 10),
                        ],
                        if (priorities.isNotEmpty)
                          _SummaryCard(
                            title: 'Next moves',
                            icon: Icons.tune_rounded,
                            metrics: priorities,
                            useAction: true,
                          ),
                        if (strengths.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _SummaryCard(
                            title: 'Keep these',
                            icon: Icons.workspace_premium_rounded,
                            metrics: strengths,
                            useAction: false,
                          ),
                        ],
                        const SizedBox(height: 14),
                        const Text(
                          'SCORECARD',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...analysis.metrics.map(
                          (metric) => Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: _MetricCard(metric: metric),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProducerDecisionCard extends StatelessWidget {
  const _ProducerDecisionCard({required this.decision});

  final ProducerDecisionSnapshot decision;

  @override
  Widget build(BuildContext context) {
    final winner = decision.winner;
    return Container(
      key: const ValueKey('producerDecisionCard'),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentPrimary.withValues(alpha: 0.18),
            AppTheme.bgSecondary,
            AppTheme.accentCyan.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.accentPrimary.withValues(alpha: 0.38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_fix_high_rounded,
                size: 17,
                color: AppTheme.producerGold,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'PRODUCER EVOLUTION',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.producerGold.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  winner.variationStyle.label,
                  style: const TextStyle(
                    color: AppTheme.producerGold,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ScoreDelta(
                before: winner.beforeRefineScore ?? winner.score,
                after: winner.score,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  winner.wasRefined
                      ? 'Producer Brain accepted this revision only after it beat the original candidate on the full scorecard.'
                      : 'The raw candidate remained stronger than its attempted revisions, so Producer Brain kept it unchanged.',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (winner.repairs.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...winner.repairs.map(
              (repair) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 11,
                        color: AppTheme.accentCyan,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        repair,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 9,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (decision.variations.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'A / B / C PRODUCER OPTIONS',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: decision.variations.map((candidate) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: candidate == decision.variations.last ? 0 : 6,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.bgTertiary.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        children: [
                          Text(
                            candidate.variationStyle.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            candidate.score.round().toString(),
                            style: TextStyle(
                              color: _scoreColor(candidate.score),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            candidate.scoreDelta >= 0
                                ? '+${candidate.scoreDelta.toStringAsFixed(1)}'
                                : candidate.scoreDelta.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreDelta extends StatelessWidget {
  const _ScoreDelta({required this.before, required this.after});

  final double before;
  final double after;

  @override
  Widget build(BuildContext context) {
    final delta = after - before;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgTertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            before.round().toString(),
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 12,
              color: AppTheme.accentCyan,
            ),
          ),
          Text(
            after.round().toString(),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (delta > 0.05) ...[
            const SizedBox(width: 5),
            Text(
              '+${delta.toStringAsFixed(1)}',
              style: const TextStyle(
                color: AppTheme.success,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverallBadge extends StatelessWidget {
  const _OverallBadge({required this.score});
  final double score;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Column(
        children: [
          Text(
            score.round().toString(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'OVERALL',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 6,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.metrics,
    required this.useAction,
  });

  final String title;
  final IconData icon;
  final List<ProducerMetric> metrics;
  final bool useAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppTheme.accentCyan),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ...metrics.map(
            (metric) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _scoreColor(metric.score),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${metric.label}: ',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: useAction ? metric.action : metric.insight,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      style: const TextStyle(fontSize: 10, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});
  final ProducerMetric metric;

  @override
  Widget build(BuildContext context) {
    final score = metric.score.clamp(0.0, 100.0).toDouble();
    final color = metric.active ? _scoreColor(score) : AppTheme.textMuted;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: metric.needsAttention
              ? color.withValues(alpha: 0.34)
              : AppTheme.borderColor.withValues(alpha: 0.72),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_metricIcon(metric.dimension), size: 16, color: color),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  metric.label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                metric.active ? score.round().toString() : 'N/A',
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: metric.active ? score / 100 : 0,
              minHeight: 4,
              backgroundColor: AppTheme.bgElevated,
              color: color,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            metric.insight,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.bgTertiary.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'ACTION  ',
                    style: TextStyle(
                      color: AppTheme.accentCyan,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.55,
                    ),
                  ),
                  TextSpan(
                    text: metric.action,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 9, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAnalysis extends StatelessWidget {
  const _EmptyAnalysis();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Generate a progression to unlock Producer Analysis.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

Color _scoreColor(double score) {
  if (score >= 85) return AppTheme.success;
  if (score >= 72) return AppTheme.accentCyan;
  if (score >= 58) return AppTheme.warning;
  return AppTheme.error;
}

IconData _metricIcon(ProducerDimension dimension) => switch (dimension) {
      ProducerDimension.harmony => Icons.piano_rounded,
      ProducerDimension.melody => Icons.graphic_eq_rounded,
      ProducerDimension.bass => Icons.surround_sound_rounded,
      ProducerDimension.motifCoherence => Icons.repeat_rounded,
      ProducerDimension.rhythm => Icons.av_timer_rounded,
      ProducerDimension.genreAuthenticity => Icons.library_music_rounded,
      ProducerDimension.tension => Icons.show_chart_rounded,
      ProducerDimension.repetition => Icons.loop_rounded,
      ProducerDimension.playability => Icons.back_hand_rounded,
      ProducerDimension.surprise => Icons.auto_awesome_rounded,
    };
