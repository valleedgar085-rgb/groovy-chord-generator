import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/song_timeline_builder.dart';
import '../engine/transition_repair_engine.dart';
import '../providers/app_state.dart';
import '../providers/song_session_controller.dart';
import '../services/audio_playback_service.dart';
import '../utils/theme.dart';

class TransitionRepairSheet extends StatefulWidget {
  const TransitionRepairSheet({
    super.key,
    required this.appState,
    required this.songSession,
    required this.fromSectionId,
    required this.toSectionId,
  });

  final AppState appState;
  final SongSessionController songSession;
  final String fromSectionId;
  final String toSectionId;

  static Future<void> open(
    BuildContext context, {
    required AppState appState,
    required SongSessionController songSession,
    required String fromSectionId,
    required String toSectionId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.88,
        child: TransitionRepairSheet(
          appState: appState,
          songSession: songSession,
          fromSectionId: fromSectionId,
          toSectionId: toSectionId,
        ),
      ),
    );
  }

  @override
  State<TransitionRepairSheet> createState() => _TransitionRepairSheetState();
}

class _TransitionRepairSheetState extends State<TransitionRepairSheet> {
  late final List<TransitionRepairVariant> _variants;
  AudioPlaybackService? _audio;
  TransitionRepairStyle? _previewStyle;

  @override
  void initState() {
    super.initState();
    _variants = widget.songSession.buildTransitionRepairVariants(
      widget.fromSectionId,
      widget.toSectionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = _audio;
    if (audio == null) {
      return _buildSheet(context, isPlaying: false, songBeat: 0.0);
    }
    return AnimatedBuilder(
      animation: audio,
      builder: (context, _) => _buildSheet(
        context,
        isPlaying: audio.isTimelinePlayback && audio.isPlaying,
        songBeat: audio.songBeat,
      ),
    );
  }

  Widget _buildSheet(
    BuildContext context, {
    required bool isPlaying,
    required double songBeat,
  }) {
    final baseline = _variants.isEmpty ? null : _variants.first.before;
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
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.producerGold.withValues(alpha: 0.85),
                          AppTheme.accentPink.withValues(alpha: 0.70),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.swap_calls_rounded,
                      color: AppTheme.bgPrimary,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TRANSITION LAB',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_displaySection(widget.fromSectionId)}  →  ${_displaySection(widget.toSectionId)}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPlaying)
                    IconButton(
                      key: const ValueKey('stopTransitionPreview'),
                      tooltip: 'Stop preview',
                      onPressed: _audio?.stop,
                      icon: const Icon(
                        Icons.stop_circle_rounded,
                        color: AppTheme.accentPink,
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
            if (baseline != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: _BaselineCard(
                  beforeScore: baseline.score,
                  harmony: baseline.harmonyContinuity,
                  bass: baseline.bassContinuity,
                  melody: baseline.melodyHandoff,
                  energy: baseline.energyHandoff,
                ),
              ),
            Expanded(
              child: _variants.isEmpty
                  ? const _NoSafeRepairs()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 24),
                      itemCount: _variants.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final variant = _variants[index];
                        final previewing = isPlaying &&
                            _previewStyle == variant.style;
                        final activeStyle = widget.songSession.transitionRepairFor(
                          widget.fromSectionId,
                          widget.toSectionId,
                        );
                        return _VariantCard(
                          variant: variant,
                          previewing: previewing,
                          active: activeStyle == variant.style,
                          onPreview: () => _preview(variant),
                          onUse: variant.improved ? () => _use(variant) : null,
                        );
                      },
                    ),
            ),
            if (isPlaying)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Preview playhead: beat ${songBeat.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _preview(TransitionRepairVariant variant) async {
    final audio = _audio ??= AudioPlaybackService.instance;
    final timeline = const SongTimelineBuilder().build(
      variant.draft,
      performanceProfile: widget.songSession.performanceProfile,
    );
    final toSection = timeline.sectionById(widget.toSectionId);
    final switching = audio.isTimelinePlayback && audio.isPlaying;
    final startBeat = switching
        ? audio.songBeat.clamp(0.0, timeline.totalBeats).toDouble()
        : max(
            0.0,
            (toSection?.startBeat ?? 0.0) - timeline.beatsPerBar * 2.0,
          );

    audio.setBpm(widget.appState.tempo);
    await audio.playFullSong(timeline, startBeat: startBeat);
    if (!mounted) return;
    setState(() => _previewStyle = variant.style);
  }

  void _use(TransitionRepairVariant variant) {
    final messenger = ScaffoldMessenger.of(context);
    final applied = widget.songSession.applyTransitionRepairVariant(variant);
    if (!applied) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${variant.style.label} applied to ${_displaySection(variant.fromSectionId)} → ${_displaySection(variant.toSectionId)}.',
        ),
      ),
    );
  }
}

class _BaselineCard extends StatelessWidget {
  const _BaselineCard({
    required this.beforeScore,
    required this.harmony,
    required this.bass,
    required this.melody,
    required this.energy,
  });

  final double beforeScore;
  final double harmony;
  final double bass;
  final double melody;
  final double energy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NOW',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 6.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  beforeScore.round().toString(),
                  style: TextStyle(
                    color: _scoreColor(beforeScore),
                    fontSize: 20,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _MiniScore('HARM', harmony)),
          const SizedBox(width: 5),
          Expanded(child: _MiniScore('BASS', bass)),
          const SizedBox(width: 5),
          Expanded(child: _MiniScore('MELODY', melody)),
          const SizedBox(width: 5),
          Expanded(child: _MiniScore('ENERGY', energy)),
        ],
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  const _VariantCard({
    required this.variant,
    required this.previewing,
    required this.active,
    required this.onPreview,
    required this.onUse,
  });

  final TransitionRepairVariant variant;
  final bool previewing;
  final bool active;
  final VoidCallback onPreview;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    final color = _styleColor(variant.style);
    final delta = variant.scoreDelta;
    return Container(
      key: ValueKey('transitionVariant-${variant.style.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.10),
            AppTheme.bgSecondary,
            AppTheme.bgSecondary,
          ],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: active
              ? AppTheme.accentCyan.withValues(alpha: 0.55)
              : previewing
                  ? AppTheme.accentPink.withValues(alpha: 0.52)
                  : AppTheme.borderColor,
          width: active || previewing ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  variant.style.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.45,
                  ),
                ),
              ),
              if (active) ...[
                const SizedBox(width: 6),
                const _Badge('ACTIVE', AppTheme.accentCyan),
              ],
              if (previewing) ...[
                const SizedBox(width: 6),
                const _Badge('PLAYING', AppTheme.accentPink),
              ],
              const Spacer(),
              Text(
                variant.after.score.round().toString(),
                style: TextStyle(
                  color: _scoreColor(variant.after.score),
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
                style: TextStyle(
                  color: variant.improved ? AppTheme.success : AppTheme.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            variant.summary,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 8.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Changes: ${variant.changedParts.join(' • ')}',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(child: _MiniScore('HARM', variant.after.harmonyContinuity)),
              const SizedBox(width: 5),
              Expanded(child: _MiniScore('BASS', variant.after.bassContinuity)),
              const SizedBox(width: 5),
              Expanded(child: _MiniScore('MELODY', variant.after.melodyHandoff)),
              const SizedBox(width: 5),
              Expanded(child: _MiniScore('ENERGY', variant.after.energyHandoff)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: ValueKey('previewTransition-${variant.style.id}'),
                  onPressed: onPreview,
                  icon: Icon(
                    previewing ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
                    size: 16,
                  ),
                  label: Text(previewing ? 'Playing' : 'Preview'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  key: ValueKey('useTransition-${variant.style.id}'),
                  onPressed: active ? null : onUse,
                  icon: Icon(
                    active ? Icons.check_circle_rounded : Icons.auto_fix_high_rounded,
                    size: 16,
                  ),
                  label: Text(active ? 'Active' : 'Use'),
                ),
              ),
            ],
          ),
        ],
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
    return Container(
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
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);

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
          fontSize: 6.3,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _NoSafeRepairs extends StatelessWidget {
  const _NoSafeRepairs();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Song Director could not find a safe boundary-only improvement. This handoff may already be strong, or it may need a deeper section rewrite instead of a transition patch.',
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

Color _styleColor(TransitionRepairStyle style) => switch (style) {
      TransitionRepairStyle.dominantLift => AppTheme.producerGold,
      TransitionRepairStyle.smoothHandoff => AppTheme.accentCyan,
      TransitionRepairStyle.bassApproach => AppTheme.accentSecondary,
      TransitionRepairStyle.melodicPickup => AppTheme.accentPink,
      TransitionRepairStyle.energyShape => AppTheme.success,
    };

Color _scoreColor(double score) {
  if (score >= 85) return AppTheme.success;
  if (score >= 72) return AppTheme.accentCyan;
  if (score >= 58) return AppTheme.warning;
  return AppTheme.error;
}