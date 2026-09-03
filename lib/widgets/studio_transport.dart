import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../providers/playback_controller.dart';
import '../utils/theme.dart';

class StudioTransport extends StatelessWidget {
  const StudioTransport({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppState, PlaybackController>(
      builder: (context, appState, playback, _) {
        final hasChords = appState.currentProgression.isNotEmpty;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1C1932),
                AppTheme.bgSecondary,
                const Color(0xFF101524),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: playback.isPlaying
                  ? AppTheme.accentCyan.withValues(alpha: 0.6)
                  : AppTheme.borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: (playback.isPlaying
                        ? AppTheme.accentCyan
                        : AppTheme.accentPrimary)
                    .withValues(alpha: playback.isPlaying ? 0.18 : 0.09),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _PlayButton(
                    enabled: hasChords,
                    playing: playback.isPlaying,
                    loading: playback.isInitializing,
                    onPressed: () => playback.playProgression(
                      appState.currentProgression,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              playback.isPlaying ? 'NOW PLAYING' : 'STUDIO TRANSPORT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.25,
                                color: playback.isPlaying
                                    ? AppTheme.accentCyan
                                    : AppTheme.textMuted,
                              ),
                            ),
                            if (playback.audioUnavailable) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.volume_off_outlined,
                                size: 14,
                                color: AppTheme.warning,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hasChords
                              ? '${appState.currentProgression.length} chords • tap any chord to audition'
                              : 'Generate a progression to start playing',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.bgPrimary.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          playback.tempo.round().toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            height: 1,
                          ),
                        ),
                        const Text(
                          'BPM',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.speed, size: 15, color: AppTheme.textMuted),
                  Expanded(
                    child: Slider(
                      value: playback.tempo,
                      min: 60,
                      max: 160,
                      divisions: 20,
                      onChanged: playback.setTempo,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Stop playback',
                    onPressed: playback.isPlaying ? playback.stop : null,
                    icon: Icon(
                      Icons.stop_rounded,
                      color: playback.isPlaying
                          ? AppTheme.textPrimary
                          : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.enabled,
    required this.playing,
    required this.loading,
    required this.onPressed,
  });

  final bool enabled;
  final bool playing;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: enabled ? AppTheme.accentGradient : null,
        color: enabled ? null : AppTheme.bgTertiary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppTheme.accentPrimary.withValues(alpha: 0.34),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? onPressed : null,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 34,
                    color: enabled ? Colors.white : AppTheme.textMuted,
                  ),
          ),
        ),
      ),
    );
  }
}
