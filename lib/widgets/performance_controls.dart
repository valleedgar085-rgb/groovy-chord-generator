import 'package:flutter/material.dart';

import '../providers/song_session_controller.dart';
import '../services/audio_playback_service.dart';
import '../utils/theme.dart';

/// Musical macro controls for the performance-intent layer.
class PerformanceControls extends StatelessWidget {
  const PerformanceControls({
    super.key,
    required this.session,
  });

  final SongSessionController session;

  @override
  Widget build(BuildContext context) {
    final profile = session.performanceProfile;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: AppTheme.bgTertiary.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor.withValues(alpha: 0.58),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Spacer(),
              TextButton(
                onPressed: () {
                  session.resetPerformance();
                  AudioPlaybackService.instance.setStrumMs(18);
                  AudioPlaybackService.instance.setChordVolume(0.72);
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: const Text(
                  'RESET',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          _PerformanceSlider(
            key: const ValueKey<String>('performance-looseness'),
            leftLabel: 'TIGHT',
            rightLabel: 'LOOSE',
            value: profile.looseness,
            onChanged: (value) {
              session.setPerformanceLooseness(value);
              // Existing chord preview gets an immediate tactile approximation
              // until Phase 4.5 schedules the full timeline directly.
              AudioPlaybackService.instance.setStrumMs((6 + value * 34).round());
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
        ],
      ),
    );
  }
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
      height: 34,
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              leftLabel,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 7,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
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
            width: 50,
            child: Text(
              rightLabel,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 7,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 28,
            child: Text(
              '${(value * 100).round()}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
