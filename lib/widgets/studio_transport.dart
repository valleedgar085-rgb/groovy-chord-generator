import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/types.dart';
import '../services/audio_playback_service.dart';
import '../utils/music_theory.dart';
import '../utils/theme.dart';
import 'studio_sound_sheet.dart';

class StudioTransport extends StatefulWidget {
  const StudioTransport({super.key, required this.progression});
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
    final hasActiveChord = _audio.activeChordIndex >= 0 &&
        _audio.activeChordIndex < widget.progression.length;
    final activeChord = hasActiveChord
        ? getChordSymbol(widget.progression[_audio.activeChordIndex])
        : null;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_audio.isPlaying) ...[
            Row(
              children: [
                const SizedBox(width: 4),
                _PulseVisualizer(
                  active: _audio.isPlaying,
                  phaseSeed: _audio.activeChordIndex,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppTheme.animationFast,
                    child: Text(
                      activeChord == null
                          ? 'PLAYING'
                          : 'NOW  $activeChord  •  ${_audio.activeChordIndex + 1}/${widget.progression.length}',
                      key: ValueKey('${_audio.activeChordIndex}:$activeChord'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppTheme.accentSecondary,
                      ),
                    ),
                  ),
                ),
                Text(
                  _audio.synthCharacter.label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
          ],
          Row(
            children: [
              _TransportButton(
                icon: _audio.isPlaying
                    ? Icons.stop_rounded
                    : Icons.play_arrow_rounded,
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
              const SizedBox(width: 8),
              _TransportButton(
                icon: Icons.tune_rounded,
                active: false,
                enabled: true,
                tooltip: 'Studio Sound',
                onTap: () => _openSoundSheet(context),
              ),
              const SizedBox(width: 10),
              Container(width: 1, height: 32, color: AppTheme.borderColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
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
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 14),
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
              const SizedBox(width: 8),
              _LevelMeter(active: _audio.isPlaying),
            ],
          ),
        ],
      ),
    );
  }

  void _openSoundSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => const StudioSoundSheet(),
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

class _PulseVisualizer extends StatefulWidget {
  const _PulseVisualizer({required this.active, required this.phaseSeed});
  final bool active;
  final int phaseSeed;

  @override
  State<_PulseVisualizer> createState() => _PulseVisualizerState();
}

class _PulseVisualizerState extends State<_PulseVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _PulseVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: 54,
          height: 18,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(9, (index) {
              final phase = (_controller.value * math.pi * 2) +
                  (index * 0.78) +
                  (widget.phaseSeed * 0.43);
              final strength = widget.active
                  ? (0.35 + (math.sin(phase).abs() * 0.65))
                  : 0.18;
              return Container(
                width: 3,
                height: 4 + (14 * strength),
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppTheme.accentPrimary, AppTheme.accentCyan],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        );
      },
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
