import 'package:flutter/material.dart';

import '../services/audio_playback_service.dart';
import '../utils/theme.dart';

class AppHeader extends StatefulWidget {
  const AppHeader({super.key});

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  final AudioPlaybackService _audio = AudioPlaybackService.instance;

  @override
  void initState() {
    super.initState();
    _audio.addListener(_refresh);
  }

  @override
  void dispose() {
    _audio.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xB80A0A15),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor.withValues(alpha: 0.55),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.shadowGlow,
            ),
            child: const Icon(
              Icons.multitrack_audio_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHORD FLOW',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'PRODUCER STUDIO',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.bgTertiary.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: AppTheme.animationFast,
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _audio.isPlaying
                        ? AppTheme.success
                        : (_audio.isReady
                            ? AppTheme.accentCyan
                            : AppTheme.textMuted),
                    boxShadow: _audio.isPlaying
                        ? AppTheme.shadowColorGlow(AppTheme.success)
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _audio.isPlaying
                      ? 'PLAYING'
                      : (_audio.isReady ? 'AUDIO READY' : 'STUDIO'),
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.textSecondary,
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
