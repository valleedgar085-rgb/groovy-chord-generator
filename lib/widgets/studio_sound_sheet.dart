import 'package:flutter/material.dart';

import '../services/audio_playback_service.dart';
import '../utils/theme.dart';

class StudioSoundSheet extends StatefulWidget {
  const StudioSoundSheet({super.key});

  @override
  State<StudioSoundSheet> createState() => _StudioSoundSheetState();
}

class _StudioSoundSheetState extends State<StudioSoundSheet> {
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
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
        decoration: const BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.tune_rounded, color: AppTheme.accentSecondary),
                SizedBox(width: 10),
                Text(
                  'Studio Sound',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Shape playback without changing your progression.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),
            const _SectionLabel('TONE'),
            const SizedBox(height: 8),
            Row(
              children: SynthCharacter.values.map((character) {
                final selected = _audio.synthCharacter == character;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: character == SynthCharacter.analog ? 0 : 8,
                    ),
                    child: InkWell(
                      onTap: () => _audio.setSynthCharacter(character),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: AppTheme.animationFast,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: selected ? AppTheme.accentGradient : null,
                          color: selected ? null : AppTheme.bgTertiary,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? AppTheme.accentSecondary
                                : AppTheme.borderColor,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            character.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('MIX'),
            const SizedBox(height: 6),
            _MixSlider(
              icon: Icons.volume_up_rounded,
              label: 'Master',
              value: _audio.masterVolume,
              onChanged: _audio.setMasterVolume,
            ),
            _MixSlider(
              icon: Icons.piano_rounded,
              label: 'Chords',
              value: _audio.chordVolume,
              onChanged: _audio.setChordVolume,
            ),
            _MixSlider(
              icon: Icons.graphic_eq_rounded,
              label: 'Bass',
              value: _audio.bassVolume,
              enabled: _audio.bassEnabled,
              onChanged: _audio.setBassVolume,
              trailing: Switch.adaptive(
                value: _audio.bassEnabled,
                onChanged: _audio.setBassEnabled,
              ),
            ),
            const SizedBox(height: 14),
            const _SectionLabel('FEEL'),
            const SizedBox(height: 6),
            _ValueSlider(
              label: 'Strum',
              value: _audio.strumMs.toDouble(),
              min: 0,
              max: 80,
              suffix: '${_audio.strumMs} ms',
              onChanged: (value) => _audio.setStrumMs(value.round()),
            ),
            _ValueSlider(
              label: 'Stereo width',
              value: _audio.stereoWidth,
              min: 0,
              max: 1,
              suffix: '${(_audio.stereoWidth * 100).round()}%',
              onChanged: _audio.setStereoWidth,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: AppTheme.textMuted,
      ),
    );
  }
}

class _MixSlider extends StatelessWidget {
  const _MixSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  )),
            ],
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 4),
          SizedBox(width: 42, child: FittedBox(child: trailing!)),
        ],
      ],
    );
  }
}

class _ValueSlider extends StatelessWidget {
  const _ValueSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              )),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 58,
          child: Text(
            suffix,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
