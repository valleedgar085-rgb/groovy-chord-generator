import 'package:flutter/material.dart';

import '../providers/song_session_controller.dart';
import '../services/audio_playback_service.dart';
import '../utils/theme.dart';

/// Compact entry point for the performance-intent layer.
class PerformanceControls extends StatelessWidget {
  const PerformanceControls({
    super.key,
    required this.session,
  });

  final SongSessionController session;

  @override
  Widget build(BuildContext context) {
    final profile = session.performanceProfile;
    return InkWell(
      key: const ValueKey<String>('performance-toggle'),
      onTap: () => _openPerformanceSheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppTheme.bgTertiary.withValues(alpha: 0.46),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.borderColor.withValues(alpha: 0.58),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.spatial_audio_off_rounded,
              size: 15,
              color: AppTheme.accentSecondary,
            ),
            const SizedBox(width: 7),
            const Text(
              'PERFORMANCE',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.95,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'T${((1 - profile.looseness) * 100).round()} • P${(profile.punch * 100).round()} • S${(profile.swing * 100).round()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.tune_rounded,
              size: 16,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPerformanceSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PerformanceSheet(session: session),
    );
  }
}

class _PerformanceSheet extends StatelessWidget {
  const _PerformanceSheet({required this.session});

  final SongSessionController session;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: AppTheme.borderColor.withValues(alpha: 0.75),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        child: AnimatedBuilder(
          animation: session,
          builder: (context, _) {
            final profile = session.performanceProfile;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.spatial_audio_off_rounded,
                      color: AppTheme.accentSecondary,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PERFORMANCE FEEL',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.9,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Humanize timing, dynamics and articulation without changing song structure.',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 8.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _PerformanceSlider(
                  key: const ValueKey<String>('performance-looseness'),
                  leftLabel: 'TIGHT',
                  rightLabel: 'LOOSE',
                  value: profile.looseness,
                  onChanged: (value) {
                    session.setPerformanceLooseness(value);
                    AudioPlaybackService.instance
                        .setStrumMs((6 + value * 34).round());
                  },
                ),
                _PerformanceSlider(
                  key: const ValueKey<String>('performance-punch'),
                  leftLabel: 'SOFT',
                  rightLabel: 'PUNCHY',
                  value: profile.punch,
                  onChanged: (value) {
                    session.setPerformancePunch(value);
                    AudioPlaybackService.instance.setChordVolume(
                      (0.58 + value * 0.28).clamp(0.0, 1.0).toDouble(),
                    );
                  },
                ),
                _PerformanceSlider(
                  key: const ValueKey<String>('performance-swing'),
                  leftLabel: 'STRAIGHT',
                  rightLabel: 'SWING',
                  value: profile.swing,
                  onChanged: session.setPerformanceSwing,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Timeline intent: timing ${_percent(profile.looseness)} • punch ${_percent(profile.punch)} • swing ${_percent(profile.swing)}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        session.resetPerformance();
                        AudioPlaybackService.instance.setStrumMs(18);
                        AudioPlaybackService.instance.setChordVolume(0.72);
                      },
                      child: const Text(
                        'RESET FEEL',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _percent(double value) => '${(value * 100).round()}%';
}

class _PerformanceSlider extends StatelessWidget {
  const _PerformanceSlider({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.value,
    required this.onChanged,
  });

  final String leftLabel;
  final String rightLabel;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              leftLabel,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 13),
              ),
              child: Slider(
                value: value,
                onChanged: onChanged,
                min: 0,
                max: 1,
              ),
            ),
          ),
          SizedBox(
            width: 58,
            child: Text(
              rightLabel,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '${(value * 100).round()}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
