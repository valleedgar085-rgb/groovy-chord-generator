import 'package:flutter/material.dart';

import '../models/types.dart';
import '../services/audio_playback_service.dart';
import '../utils/theme.dart';

class StudioTransport extends StatefulWidget {
  const StudioTransport({
    super.key,
    required this.progression,
  });

  final List<Chord> progression;

  @override
  State<StudioTransport> createState() => _StudioTransportState();
}

class _StudioTransportState extends State<StudioTransport> {
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
    final canPlay = widget.progression.isNotEmpty;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTheme.accentPrimary.withValues(alpha: 0.09),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        children: [
          _TransportButton(
            icon: _audio.isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
            active: _audio.isPlaying,
            enabled: canPlay,
            prominent: true,
            tooltip: _audio.isPlaying ? 'Stop' : 'Play progression',
            onTap: () {
              if (_audio.isPlaying) {
                _audio.stop();
              } else {
                _audio.playProgression(widget.progression);
              }
            },
          ),
          const SizedBox(width: 8),
          _TransportButton(
            icon: Icons.repeat_rounded,
            active: _audio.looping,
            enabled: true,
            tooltip: 'Loop',
            onTap: () => _audio.setLooping(!_audio.looping),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 32, color: AppTheme.borderColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'TEMPO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_audio.bpm} BPM',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: _audio.bpm.toDouble(),
                    min: 55,
                    max: 180,
                    divisions: 125,
                    onChanged: (value) => _audio.setBpm(value.round()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _LevelMeter(active: _audio.isPlaying),
        ],
      ),
    );
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.icon,
    required this.active,
    required this.enabled,
    required this.tooltip,
    required this.onTap,
    this.prominent = false,
  });

  final IconData icon;
  final bool active;
  final bool enabled;
  final bool prominent;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled
        ? (active || prominent ? Colors.white : AppTheme.textSecondary)
        : AppTheme.textMuted;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: AppTheme.animationFast,
          width: prominent ? 50 : 40,
          height: prominent ? 50 : 40,
          decoration: BoxDecoration(
            gradient: prominent && enabled ? AppTheme.accentGradient : null,
            color: prominent
                ? null
                : (active
                    ? AppTheme.accentPrimary.withValues(alpha: 0.22)
                    : AppTheme.bgTertiary),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: active
                  ? AppTheme.accentSecondary.withValues(alpha: 0.65)
                  : AppTheme.borderColor,
            ),
            boxShadow: prominent && enabled ? AppTheme.shadowGlow : null,
          ),
          child: Icon(icon, color: foreground, size: prominent ? 28 : 21),
        ),
      ),
    );
  }
}

class _LevelMeter extends StatelessWidget {
  const _LevelMeter({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 17,
      height: 42,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: List<Widget>.generate(5, (index) {
          final lit = active && index >= 1;
          return AnimatedContainer(
            duration: Duration(milliseconds: 120 + (index * 35)),
            width: 15,
            height: 5,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: lit
                  ? (index == 4 ? AppTheme.warning : AppTheme.success)
                  : AppTheme.bgElevated,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }).reversed.toList(),
      ),
    );
  }
}
