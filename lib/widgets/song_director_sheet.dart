import 'package:flutter/material.dart';

import '../engine/song_director.dart';
import '../providers/song_session_controller.dart';
import '../utils/theme.dart';

class SongDirectorSheet extends StatelessWidget {
  const SongDirectorSheet({
    super.key,
    required this.songSession,
  });

  final SongSessionController songSession;

  static Future<void> open(
    BuildContext context, {
    required SongSessionController songSession,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.90,
        child: SongDirectorSheet(songSession: songSession),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: songSession,
      builder: (context, _) {
        final draft = songSession.currentDraft;
        final analysis = draft == null
            ? SongDirectorAnalysis.empty()
            : const SongDirectorAnalyzer().analyze(
                draft: draft,
                memory: songSession.currentMemory,
              );
        final score = analysis.overallScore;
        final sortedTransitions = List<SongTransitionAssessment>.from(
          analysis.transitions,
        )..sort((a, b) => a.score.compareTo(b.score));

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
                _Header(
                  score: score,
                  hasSong: draft != null,
                  onClose: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: draft == null
                      ? const _EmptyState()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
                          children: [
                            _WeakestLinkCard(analysis: analysis),
                            const SizedBox(height: 14),
                            const _SectionLabel('SONG MAP'),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 82,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: analysis.sections.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 7),
                                itemBuilder: (context, index) {
                                  final section = analysis.sections[index];
                                  return _SectionScoreCard(
                                    section: section,
                                    selected: songSession.selectedSectionId ==
                                        section.sectionId,
                                    onTap: () => songSession
                                        .selectSection(section.sectionId),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            const _SectionLabel('DIRECTOR SCORECARD'),
                            const SizedBox(height: 8),
                            ...analysis.metrics.map(
                              (metric) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _MetricCard(metric: metric),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Expanded(
                                  child: _SectionLabel('TRANSITION MAP'),
                                ),
                                Text(
                                  '${analysis.transitions.length} handoffs',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...sortedTransitions.map(
                              (transition) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _TransitionCard(
                                  transition: transition,
                                  onTap: () => songSession
                                      .selectSection(transition.toSectionId),
                                ),
                              ),
                            ),
                          ],
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

class _Header extends StatelessWidget {
  const _Header({
    required this.score,
    required this.hasSong,
    required this.onClose,
  });

  final double score;
  final bool hasSong;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 8, 12),
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
              Icons.account_tree_rounded,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SONG DIRECTOR',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Structure • transitions • payoff • identity • energy',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (hasSong) ...[
            Text(
              score.round().toString(),
              style: TextStyle(
                color: color,
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 2),
            const Text(
              '/100',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 7,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _WeakestLinkCard extends StatelessWidget {
  const _WeakestLinkCard({required this.analysis});

  final SongDirectorAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final score = analysis.weakestLinkScore;
    return Container(
      key: const ValueKey('songDirectorWeakestLink'),
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.error.withValues(alpha: 0.10),
            AppTheme.bgSecondary,
            AppTheme.accentPrimary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _scoreColor(score).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _scoreColor(score).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.build_circle_outlined,
              size: 18,
              color: _scoreColor(score),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WEAKEST LINK',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  analysis.weakestLinkLabel,
                  key: const ValueKey('songDirectorWeakestLabel'),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  analysis.weakestLinkAction,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            score.round().toString(),
            style: TextStyle(
              color: _scoreColor(score),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final SongDirectorMetric metric;

  @override
  Widget build(BuildContext context) {
    final color = metric.active ? _scoreColor(metric.score) : AppTheme.textMuted;
    return Container(
      key: ValueKey('songDirectorMetric-${metric.dimension.name}'),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Text(
              metric.active ? metric.score.round().toString() : 'N/A',
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.insight,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 8,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Icon(
            metric.isStrength
                ? Icons.check_circle_rounded
                : metric.needsAttention
                    ? Icons.priority_high_rounded
                    : Icons.remove_circle_outline_rounded,
            color: color,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _SectionScoreCard extends StatelessWidget {
  const _SectionScoreCard({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final SongSectionAssessment section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(section.score);
    return InkWell(
      key: ValueKey('songDirectorSection-${section.sectionId}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 91,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentPrimary.withValues(alpha: 0.18)
              : AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? AppTheme.accentCyan.withValues(alpha: 0.45)
                : AppTheme.borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _displaySection(section.sectionId),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  section.score.round().toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransitionCard extends StatelessWidget {
  const _TransitionCard({
    required this.transition,
    required this.onTap,
  });

  final SongTransitionAssessment transition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(transition.score);
    return InkWell(
      key: ValueKey(
        'songDirectorTransition-${transition.fromSectionId}-${transition.toSectionId}',
      ),
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.72)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_displaySection(transition.fromSectionId)}  →  ${_displaySection(transition.toSectionId)}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  transition.score.round().toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                _MiniScore('HARM', transition.harmonyContinuity),
                const SizedBox(width: 5),
                _MiniScore('BASS', transition.bassContinuity),
                const SizedBox(width: 5),
                _MiniScore('MELODY', transition.melodyHandoff),
                const SizedBox(width: 5),
                _MiniScore('ENERGY', transition.energyHandoff),
              ],
            ),
            if (transition.score < 72) ...[
              const SizedBox(height: 7),
              Text(
                transition.action,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 7.5,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  const _MiniScore(this.label, this.score);

  final String label;
  final double score;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          color: _scoreColor(score).withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              score.round().toString(),
              style: TextStyle(
                color: _scoreColor(score),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 5.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textMuted,
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Create a full song first. Song Director will then analyze the structure, every transition, chorus payoff, motif recall, energy curve, section contrast and ending.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

String _displaySection(String id) => id
    .replaceAll('-', ' ')
    .split(' ')
    .map((part) => part.isEmpty
        ? part
        : '${part.substring(0, 1).toUpperCase()}${part.substring(1)}')
    .join(' ');

Color _scoreColor(double score) {
  if (score >= 85) return AppTheme.success;
  if (score >= 72) return AppTheme.accentCyan;
  if (score >= 58) return AppTheme.warning;
  return AppTheme.error;
}
