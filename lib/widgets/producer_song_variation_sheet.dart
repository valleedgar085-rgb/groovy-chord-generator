import 'dart:async';

import 'package:flutter/material.dart';

import '../engine/producer_song_variation_engine.dart';
import '../engine/song_candidate.dart';
import '../providers/app_state.dart';
import '../providers/song_session_controller.dart';
import '../services/audio_playback_service.dart';
import '../services/producer_preference_store.dart';
import '../utils/theme.dart';

class ProducerSongVariationSheet extends StatefulWidget {
  const ProducerSongVariationSheet({
    super.key,
    required this.appState,
    required this.songSession,
  });

  final AppState appState;
  final SongSessionController songSession;

  static Future<void> open(
    BuildContext context, {
    required AppState appState,
    required SongSessionController songSession,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.88,
        child: ProducerSongVariationSheet(
          appState: appState,
          songSession: songSession,
        ),
      ),
    );
  }

  @override
  State<ProducerSongVariationSheet> createState() =>
      _ProducerSongVariationSheetState();
}

class _ProducerSongVariationSheetState
    extends State<ProducerSongVariationSheet> {
  final AudioPlaybackService _audio = AudioPlaybackService.instance;
  final ProducerPreferenceStore _preferences = ProducerPreferenceStore.instance;

  late final List<ProducerSongVariation> _variations;
  ProducerPreferenceSnapshot _preferenceSnapshot =
      const ProducerPreferenceSnapshot(<ProducerVariationStyle, int>{});
  ProducerVariationStyle? _previewStyle;

  @override
  void initState() {
    super.initState();
    _variations = widget.songSession.buildProducerSongVariations(
      tempo: widget.appState.tempo,
      swing: widget.appState.swing,
    );
    unawaited(_loadPreferences());
  }

  Future<void> _loadPreferences() async {
    final snapshot = await _preferences.load();
    if (!mounted) return;
    setState(() => _preferenceSnapshot = snapshot);
  }

  @override
  Widget build(BuildContext context) {
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
                      gradient: AppTheme.producerGradient,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.library_music_rounded,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Full Song Producer A / B / C',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _variations.isEmpty
                              ? 'Generate a full song to unlock complete Producer directions.'
                              : 'Switch at the same playhead beat and choose by ear.',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _audio,
                    builder: (context, _) {
                      if (!_audio.isTimelinePlayback || !_audio.isPlaying) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        key: const ValueKey('stopProducerSongPreview'),
                        tooltip: 'Stop preview',
                        onPressed: _audio.stop,
                        icon: const Icon(
                          Icons.stop_circle_rounded,
                          color: AppTheme.accentPink,
                        ),
                      );
                    },
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
            if (_preferenceSnapshot.totalChoices > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: _TasteBanner(snapshot: _preferenceSnapshot),
              ),
            Expanded(
              child: _variations.isEmpty
                  ? const Center(
                      child: Text(
                        'No full-song variants are available yet.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 24),
                      itemCount: _variations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final variation = _variations[index];
                        return _SongVariationCard(
                          variation: variation,
                          selected: widget.songSession.activeProducerSongStyle ==
                              variation.style,
                          previewing: _previewStyle == variation.style &&
                              _audio.isTimelinePlayback &&
                              _audio.isPlaying,
                          tasteCount:
                              _preferenceSnapshot.countFor(variation.style),
                          tasteLeader:
                              _preferenceSnapshot.preferredStyle == variation.style,
                          onPreview: () => _preview(variation),
                          onUse: () => _use(variation),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _preview(ProducerSongVariation variation) async {
    final switching = _audio.isTimelinePlayback && _audio.isPlaying;
    final currentBeat = switching ? _audio.songBeat : 0.0;
    final startBeat = currentBeat
        .clamp(0.0, variation.timeline.totalBeats)
        .toDouble();
    _audio.setBpm(widget.appState.tempo);
    await _audio.playFullSong(
      variation.timeline,
      startBeat: startBeat,
    );
    if (!mounted) return;
    setState(() => _previewStyle = variation.style);
  }

  Future<void> _use(ProducerSongVariation variation) async {
    final messenger = ScaffoldMessenger.of(context);
    final applied = widget.songSession.applyProducerSongVariation(variation);
    if (!applied) return;
    final snapshot = await _preferences.record(variation.style);
    if (!mounted) return;
    setState(() => _preferenceSnapshot = snapshot);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${variation.style.label} full-song Producer direction is now active.',
        ),
      ),
    );
  }
}

class _SongVariationCard extends StatelessWidget {
  const _SongVariationCard({
    required this.variation,
    required this.selected,
    required this.previewing,
    required this.tasteCount,
    required this.tasteLeader,
    required this.onPreview,
    required this.onUse,
  });

  final ProducerSongVariation variation;
  final bool selected;
  final bool previewing;
  final int tasteCount;
  final bool tasteLeader;
  final VoidCallback onPreview;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(variation.score);
    final delta = variation.scoreDelta;
    final totalBars = variation.timeline.beatsPerBar == 0
        ? 0
        : (variation.timeline.totalBeats / variation.timeline.beatsPerBar).round();

    return Container(
      key: ValueKey('producerSongVariation-${variation.style.name}'),
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
            _styleColor(variation.style).withValues(alpha: selected ? 0.08 : 0.025),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? AppTheme.accentCyan.withValues(alpha: 0.58)
              : previewing
                  ? AppTheme.accentPink.withValues(alpha: 0.52)
                  : AppTheme.borderColor,
          width: selected || previewing ? 1.5 : 1,
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
                  color: _styleColor(variation.style).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  variation.style.label,
                  style: TextStyle(
                    color: _styleColor(variation.style),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.55,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                const _Badge(text: 'ACTIVE', color: AppTheme.accentCyan),
              ],
              if (previewing) ...[
                const SizedBox(width: 6),
                const _Badge(text: 'PLAYING', color: AppTheme.accentPink),
              ],
              if (tasteLeader && tasteCount > 0) ...[
                const SizedBox(width: 6),
                const _Badge(text: 'YOUR TASTE', color: AppTheme.producerGold),
              ],
              const Spacer(),
              Text(
                variation.score.round().toString(),
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
          Row(
            children: [
              _StatChip(
                icon: Icons.view_timeline_rounded,
                text: '$totalBars bars',
              ),
              const SizedBox(width: 6),
              _StatChip(
                icon: Icons.auto_fix_high_rounded,
                text: '${variation.changedSectionCount} sections changed',
              ),
              if (tasteCount > 0) ...[
                const SizedBox(width: 6),
                _StatChip(
                  icon: Icons.favorite_rounded,
                  text: '$tasteCount picks',
                ),
              ],
            ],
          ),
          if (variation.repairs.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: AppTheme.bgTertiary.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                variation.repairs.take(3).join('  ·  '),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 8.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: ValueKey('previewSong-${variation.style.name}'),
                  onPressed: onPreview,
                  icon: Icon(
                    previewing ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
                    size: 17,
                  ),
                  label: Text(previewing ? 'Playing' : 'Preview'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  key: ValueKey('useSong-${variation.style.name}'),
                  onPressed: selected ? null : onUse,
                  icon: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.library_add_check_rounded,
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
}

class _TasteBanner extends StatelessWidget {
  const _TasteBanner({required this.snapshot});

  final ProducerPreferenceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final preferred = snapshot.preferredStyle;
    if (preferred == null) return const SizedBox.shrink();
    final affinity = (snapshot.affinityFor(preferred) * 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.producerGold.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.producerGold.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.psychology_alt_rounded,
            size: 14,
            color: AppTheme.producerGold,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Producer Brain taste memory: ${preferred.label} leads $affinity% of ${snapshot.totalChoices} choices.',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.bgTertiary.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
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
