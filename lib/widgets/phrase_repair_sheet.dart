import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/phrase_producer_brain.dart';
import '../engine/phrase_repair_engine.dart';
import '../engine/song_timeline_builder.dart';
import '../providers/app_state.dart';
import '../providers/song_session_controller.dart';
import '../services/audio_playback_service.dart';
import '../utils/theme.dart';

class PhraseRepairSheet extends StatefulWidget {
  const PhraseRepairSheet({
    super.key,
    required this.appState,
    required this.songSession,
    required this.phraseId,
  });

  final AppState appState;
  final SongSessionController songSession;
  final String phraseId;

  static Future<void> open(
    BuildContext context, {
    required AppState appState,
    required SongSessionController songSession,
    required String phraseId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.88,
        child: PhraseRepairSheet(
          appState: appState,
          songSession: songSession,
          phraseId: phraseId,
        ),
      ),
    );
  }

  @override
  State<PhraseRepairSheet> createState() => _PhraseRepairSheetState();
}

class _PhraseRepairSheetState extends State<PhraseRepairSheet> {
  late final List<PhraseRepairVariant> _variants;
  AudioPlaybackService? _audio;
  PhraseRepairStyle? _previewStyle;

  @override
  void initState() {
    super.initState();
    _variants = widget.songSession.buildPhraseRepairVariants(widget.phraseId);
  }

  @override
  Widget build(BuildContext context) {
    final audio = _audio;
    if (audio == null) return _buildSheet(isPlaying: false);
    return AnimatedBuilder(
      animation: audio,
      builder: (_, __) => _buildSheet(
        isPlaying: audio.isTimelinePlayback && audio.isPlaying,
      ),
    );
  }

  Widget _buildSheet({required bool isPlaying}) {
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
                          AppTheme.accentCyan.withValues(alpha: 0.88),
                          AppTheme.accentPrimary.withValues(alpha: 0.82),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.auto_fix_high_rounded,
                      color: AppTheme.bgPrimary,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PHRASE REPAIR LAB',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.phraseId.toUpperCase(),
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
                      key: const ValueKey('stopPhrasePreview'),
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
                child: _BaselineCard(assessment: baseline),
              ),
            Expanded(
              child: _variants.isEmpty
                  ? const _NoSafeRepairs()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 24),
                      itemCount: _variants.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final variant = _variants[index];
                        return _VariantCard(
                          variant: variant,
                          previewing:
                              isPlaying && _previewStyle == variant.style,
                          active: widget.songSession.phraseRepairFor(
                                widget.phraseId,
                              ) ==
                              variant.style,
                          onPreview: () => _preview(variant),
                          onUse: () => _use(variant),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _preview(PhraseRepairVariant variant) async {
    final audio = _audio ??= AudioPlaybackService.instance;
    final timeline = const SongTimelineBuilder().build(
      variant.draft,
      performanceProfile: widget.songSession.performanceProfile,
    );
    final section = timeline.sectionById(variant.sectionId);
    final phraseStart = (section?.startBeat ?? 0.0) +
        variant.before.phraseIndex * timeline.beatsPerBar * 4.0;
    final startBeat = max(
      section?.startBeat ?? 0.0,
      phraseStart - timeline.beatsPerBar,
    );
    audio.setBpm(widget.appState.tempo);
    await audio.playFullSong(timeline, startBeat: startBeat);
    if (!mounted) return;
    setState(() => _previewStyle = variant.style);
  }

  void _use(PhraseRepairVariant variant) {
    final messenger = ScaffoldMessenger.of(context);
    final applied = widget.songSession.applyPhraseRepairVariant(variant);
    if (!applied) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Song changed after preview. Reopen Phrase Repair Lab.'),
        ),
      );
      return;
    }
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${variant.style.label} applied to ${variant.phraseId.toUpperCase()} (+${variant.scoreDelta.toStringAsFixed(1)}).',
        ),
      ),
    );
  }
}

class _BaselineCard extends StatelessWidget {
  const _BaselineCard({required this.assessment});

  final PhraseProducerAssessment assessment;

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
            width: 52,
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
                  assessment.score.round().toString(),
                  style: TextStyle(
                    color: _scoreColor(assessment.score),
                    fontSize: 20,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assessment.issue,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  assessment.action,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 7.5,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
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

  final PhraseRepairVariant variant;
  final bool previewing;
  final bool active;
  final VoidCallback onPreview;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final delta = variant.scoreDelta;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? AppTheme.success.withValues(alpha: 0.55)
              : AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  variant.style.label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Text(
                '${variant.before.score.round()} → ${variant.after.score.round()}  +${delta.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: AppTheme.success,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            variant.style.description,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 8,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              _chip('${variant.changedNoteCount} NOTES'),
              _chip(
                'SONG ${variant.beforeSongScore.toStringAsFixed(1)} → ${variant.afterSongScore.toStringAsFixed(1)}',
              ),
              if (variant.after.lineageInsideGuardrail) _chip('DNA SAFE'),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPreview,
                  icon: Icon(
                    previewing
                        ? Icons.graphic_eq_rounded
                        : Icons.play_arrow_rounded,
                    size: 14,
                  ),
                  label: Text(previewing ? 'PLAYING' : 'PREVIEW'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  key: ValueKey('usePhraseRepair-${variant.style.name}'),
                  onPressed: onUse,
                  icon: const Icon(Icons.check_rounded, size: 14),
                  label: Text(active ? 'ACTIVE' : 'USE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.bgTertiary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 6.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class _NoSafeRepairs extends StatelessWidget {
  const _NoSafeRepairs();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No repair beat the current phrase without regressing song identity. The original phrase stays untouched.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            height: 1.45,
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
