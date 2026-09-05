import 'package:flutter/material.dart';

import '../models/types.dart';
import '../services/audio_playback_service.dart';
import '../utilities/helpers.dart';
import '../utils/music_theory.dart';
import '../utils/theme.dart';

class ChordCard extends StatefulWidget {
  const ChordCard({
    super.key,
    required this.chord,
    required this.index,
    this.showNumerals = true,
    this.isLocked = false,
    this.onLockToggle,
    this.onTap,
  });

  final Chord chord;
  final int index;
  final bool showNumerals;
  final bool isLocked;
  final VoidCallback? onLockToggle;
  final VoidCallback? onTap;

  @override
  State<ChordCard> createState() => _ChordCardState();
}

class _ChordCardState extends State<ChordCard> {
  AudioPlaybackService? _audio;
  bool _pressed = false;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    // Custom tap handlers (including widget tests and parent-controlled
    // audition flows) do not need to load the native audio engine merely to
    // render a chord card. Normal production cards still attach immediately.
    if (widget.onTap == null) {
      _attachAudio();
    }
  }

  void _attachAudio() {
    if (_audio != null) return;
    final audio = AudioPlaybackService.instance;
    _audio = audio;
    _isActive = audio.isPlaying && audio.activeChordIndex == widget.index;
    audio.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant ChordCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_audio == null && widget.onTap == null) {
      _attachAudio();
    }
    final audio = _audio;
    if (audio != null) {
      _isActive = audio.isPlaying && audio.activeChordIndex == widget.index;
    }
  }

  @override
  void dispose() {
    _audio?.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    final audio = _audio;
    if (audio == null) return;
    final nextIsActive = audio.isPlaying && audio.activeChordIndex == widget.index;
    if (!mounted || nextIsActive == _isActive) return;
    setState(() => _isActive = nextIsActive);
  }

  @override
  Widget build(BuildContext context) {
    final chordColor = ColorHelper.getChordTypeColor(widget.chord.type);
    final symbol = getChordSymbol(widget.chord);
    final illuminated = _pressed || _isActive;

    return Semantics(
      button: true,
      label: 'Chord ${widget.index + 1}: $symbol',
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 140 + (widget.index * 28)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - value)),
              child: child,
            ),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) {
              setState(() => _pressed = false);
              if (widget.onTap != null) {
                widget.onTap!();
              } else {
                _audio?.auditionChord(widget.chord);
              }
            },
            child: AnimatedScale(
              scale: _pressed ? 0.968 : (_isActive ? 1.018 : 1),
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                key: ValueKey('chordCard-${widget.index}'),
                duration: AppTheme.animationFast,
                curve: Curves.easeOutCubic,
                width: 124,
                height: 154,
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isLocked
                        ? [
                            AppTheme.success.withValues(alpha: 0.18),
                            AppTheme.bgSecondary,
                          ]
                        : [
                            chordColor.withValues(alpha: illuminated ? 0.22 : 0.10),
                            AppTheme.bgTertiary,
                            AppTheme.bgSecondary,
                          ],
                    stops: const [0.0, 0.50, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: widget.isLocked
                        ? AppTheme.success.withValues(alpha: 0.78)
                        : chordColor.withValues(alpha: illuminated ? 0.90 : 0.38),
                    width: widget.isLocked || illuminated ? 1.7 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                    if (illuminated)
                      BoxShadow(
                        color: chordColor.withValues(alpha: _isActive ? 0.32 : 0.22),
                        blurRadius: _isActive ? 26 : 20,
                        spreadRadius: _isActive ? 1.5 : 0.5,
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: AppTheme.animationFast,
                          width: _isActive ? 10 : 8,
                          height: _isActive ? 10 : 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: chordColor,
                            boxShadow: [
                              BoxShadow(
                                color: chordColor.withValues(
                                  alpha: _isActive ? 0.88 : 0.55,
                                ),
                                blurRadius: _isActive ? 13 : 7,
                              ),
                            ],
                          ),
                        ),
                        if (_isActive) ...[
                          const SizedBox(width: 6),
                          const Text(
                            'PLAYING',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: AppTheme.accentCyan,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (widget.onLockToggle != null)
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: widget.onLockToggle,
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Icon(
                                widget.isLocked
                                    ? Icons.lock_rounded
                                    : Icons.lock_open_rounded,
                                size: 15,
                                color: widget.isLocked
                                    ? AppTheme.success
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        symbol,
                        style: const TextStyle(
                          fontSize: 27,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.9,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      getChordTypeName(widget.chord.type).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: chordColor.withValues(alpha: 0.96),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (widget.showNumerals)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.bgPrimary.withValues(alpha: 0.42),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              widget.chord.numeral,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.accentSecondary,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Icon(
                          Icons.graphic_eq_rounded,
                          size: 15,
                          color: illuminated ? chordColor : AppTheme.textMuted,
                        ),
                      ],
                    ),
                    if (widget.chord.isBorrowed ||
                        widget.chord.isSecondaryDominant ||
                        widget.chord.isTritoneSubstitution) ...[
                      const SizedBox(height: 6),
                      Text(
                        _specialIndicator(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.45,
                          color: AppTheme.accentPink,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _specialIndicator() {
    if (widget.chord.isSecondaryDominant) return 'SECONDARY DOM';
    if (widget.chord.isTritoneSubstitution) return 'TRITONE SUB';
    if (widget.chord.isBorrowed) return 'BORROWED';
    return '';
  }
}
