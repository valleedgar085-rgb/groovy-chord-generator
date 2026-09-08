import 'package:flutter/material.dart';

import '../engine/god_judge.dart';
import '../models/types.dart';
import '../providers/app_state.dart';
import '../providers/song_session_controller.dart';
import '../utils/theme.dart';

/// Compact primary-workflow bridge for the Phase 5.10 Emotion Director and
/// final God Judge. Mood stays editable without reopening Deep Tools, while the
/// quality gate remains read-only and never exposes rejected Producer variants.
class EmotionQualityStrip extends StatelessWidget {
  const EmotionQualityStrip({
    super.key,
    required this.appState,
    required this.songSession,
  });

  final AppState appState;
  final SongSessionController songSession;

  @override
  Widget build(BuildContext context) {
    final canJudge = songSession.currentDraft != null &&
        songSession.lastRequest != null &&
        songSession.currentTimeline != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 1),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                key: const ValueKey<String>('emotionControl'),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(15),
                ),
                onTap: () => _openMoodPicker(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: AppTheme.accentPink,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EMOTION',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _moodLabel(appState.currentMood),
                              key: const ValueKey<String>('activeMoodLabel'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.expand_more_rounded,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(width: 1, height: 28, color: AppTheme.borderColor),
            Expanded(
              child: InkWell(
                key: const ValueKey<String>('godQualityControl'),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(15),
                ),
                onTap: canJudge
                    ? () => GodQualityConsoleSheet.open(
                          context,
                          songSession: songSession,
                        )
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: canJudge
                            ? AppTheme.producerGold
                            : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FINAL QUALITY',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              canJudge ? 'OPEN GOD JUDGE' : 'AFTER FULL SONG',
                              style: TextStyle(
                                color: canJudge
                                    ? AppTheme.textPrimary
                                    : AppTheme.textMuted,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: canJudge
                            ? AppTheme.textSecondary
                            : AppTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMoodPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<MoodType>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppTheme.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EMOTIONAL DIRECTION',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Emotion Director uses this to shape density, register, dynamics, tension and payoff across the song.',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 9.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: MoodType.values.map((mood) {
                final active = mood == appState.currentMood;
                return ChoiceChip(
                  key: ValueKey<String>('mood-${mood.name}'),
                  selected: active,
                  label: Text(_moodLabel(mood)),
                  onSelected: (_) => Navigator.of(context).pop(mood),
                  selectedColor:
                      AppTheme.accentPink.withValues(alpha: 0.18),
                  backgroundColor: AppTheme.bgTertiary,
                  side: BorderSide(
                    color: active
                        ? AppTheme.accentPink.withValues(alpha: 0.72)
                        : AppTheme.borderColor,
                  ),
                  labelStyle: TextStyle(
                    color: active
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 12),
            Text(
              _moodDescription(appState.currentMood),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 9,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null) appState.setMood(selected);
  }
}

/// Read-only explanation of the current song's final Phase 5.10 gate. The
/// verdict is recomputed from the canonical draft/timeline at open time so the
/// sheet cannot display stale quality information after an edit.
class GodQualityConsoleSheet extends StatelessWidget {
  const GodQualityConsoleSheet({
    super.key,
    required this.verdict,
    required this.mood,
  });

  final GodJudgeVerdict verdict;
  final MoodType mood;

  static Future<void> open(
    BuildContext context, {
    required SongSessionController songSession,
  }) {
    final draft = songSession.currentDraft;
    final request = songSession.lastRequest;
    final timeline = songSession.currentTimeline;
    if (draft == null || request == null || timeline == null) {
      return Future<void>.value();
    }
    final verdict = const GodJudge().evaluate(
      draft: draft,
      request: request,
      timeline: timeline,
    );
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.88,
        child: GodQualityConsoleSheet(
          verdict: verdict,
          mood: request.mood,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weakest = verdict.weakestMetric;
    final emotion = verdict.emotion;
    final weakestEmotion = emotion.weakestMetric;
    final statusColor = verdict.approved ? AppTheme.success : AppTheme.accentPink;

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
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.34),
                      ),
                    ),
                    child: Icon(
                      verdict.approved
                          ? Icons.verified_rounded
                          : Icons.gpp_maybe_rounded,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FINAL QUALITY GATE',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${verdict.grade} • ${_moodLabel(mood)} emotional direction',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    verdict.score.toStringAsFixed(1),
                    key: const ValueKey<String>('godJudgeScore'),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 24),
                children: [
                  _StatusCard(
                    approved: verdict.approved,
                    weakestLabel: weakest.label,
                    weakestScore: weakest.score,
                    blockers: verdict.blockers,
                  ),
                  const SizedBox(height: 10),
                  const _SectionTitle(
                    icon: Icons.fact_check_rounded,
                    title: 'GOD JUDGE DIMENSIONS',
                  ),
                  const SizedBox(height: 7),
                  ...verdict.metrics.map(
                    (metric) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: _MetricRow(
                        label: metric.label,
                        score: metric.score,
                        minimum: metric.minimum,
                        passed: metric.passesFloor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const _SectionTitle(
                    icon: Icons.auto_awesome_rounded,
                    title: 'EMOTION DIRECTOR',
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              emotion.overallScore.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppTheme.accentPink,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Peak ${_sectionLabel(emotion.peakSectionId)} • dynamic range ${(emotion.dynamicRange * 100).round()}%',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (weakestEmotion != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Weakest: ${weakestEmotion.label} ${weakestEmotion.score.round()} • ${weakestEmotion.insight}',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 8.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                        if (emotion.metrics.isNotEmpty) ...[
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: emotion.metrics
                                .map(
                                  (metric) => _MiniScore(
                                    label: metric.label,
                                    score: metric.score,
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: AppTheme.producerGold.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: AppTheme.producerGold.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Text(
                      'The final gate is intentionally conservative. A HELD result is not exposed as a supposedly-good Producer option; use the Director, Transition Lab, Phrase Repair, or a new take to improve the weak link.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 8.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
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
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.approved,
    required this.weakestLabel,
    required this.weakestScore,
    required this.blockers,
  });

  final bool approved;
  final String weakestLabel;
  final double weakestScore;
  final List<String> blockers;

  @override
  Widget build(BuildContext context) {
    final color = approved ? AppTheme.success : AppTheme.accentPink;
    return Container(
      key: const ValueKey<String>('godJudgeStatus'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                approved ? Icons.check_circle_rounded : Icons.lock_rounded,
                size: 17,
                color: color,
              ),
              const SizedBox(width: 7),
              Text(
                approved ? 'APPROVED FOR PRODUCER PREVIEW' : 'QUALITY HOLD',
                style: TextStyle(
                  color: color,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Weakest measurable link: $weakestLabel ${weakestScore.round()}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (blockers.isNotEmpty) ...[
            const SizedBox(height: 7),
            ...blockers.take(4).map(
                  (blocker) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '• $blocker',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 8.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.score,
    required this.minimum,
    required this.passed,
  });

  final String label;
  final double score;
  final double minimum;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    final color = passed ? AppTheme.success : AppTheme.accentPink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${score.round()} / floor ${minimum.round()}',
                style: TextStyle(
                  color: color,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: (score / 100).clamp(0.0, 1.0),
              backgroundColor: AppTheme.bgTertiary,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  const _MiniScore({required this.label, required this.score});

  final String label;
  final double score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.bgTertiary,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$label ${score.round()}',
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.producerGold),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.55,
          ),
        ),
      ],
    );
  }
}

String _moodLabel(MoodType mood) => switch (mood) {
      MoodType.happy => 'Happy',
      MoodType.sad => 'Sad',
      MoodType.energetic => 'Energetic',
      MoodType.relaxed => 'Relaxed',
      MoodType.dark => 'Dark',
      MoodType.dreamy => 'Dreamy',
      MoodType.mysterious => 'Mysterious',
      MoodType.triumphant => 'Triumphant',
    };

String _moodDescription(MoodType mood) => switch (mood) {
      MoodType.happy => 'Brighter register, positive lift and clear payoff.',
      MoodType.sad => 'More intimate motion, restrained energy and softer release.',
      MoodType.energetic => 'Higher activity, velocity and stronger section lift.',
      MoodType.relaxed => 'More space, lower density and gentler tension movement.',
      MoodType.dark => 'Lower brightness, stronger shadow and unresolved tension.',
      MoodType.dreamy => 'Airier spacing, floating register and smoother contour.',
      MoodType.mysterious => 'Controlled ambiguity, tension and delayed resolution.',
      MoodType.triumphant => 'Wide lift, strong climax and decisive emotional payoff.',
    };

String _sectionLabel(String? sectionId) {
  if (sectionId == null || sectionId.isEmpty) return '—';
  return sectionId.replaceAll('-', ' ').toUpperCase();
}
