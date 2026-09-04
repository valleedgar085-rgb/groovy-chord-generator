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
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final chordColor = ColorHelper.getChordTypeColor(widget.chord.type);
    final symbol = getChordSymbol(widget.chord);

    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: 160 + (widget.index * 35)),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
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
              AudioPlaybackService.instance.auditionChord(widget.chord);
            }
          },
          child: AnimatedScale(
            scale: _pressed ? 0.965 : 1,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: AppTheme.animationFast,
              curve: Curves.easeOutCubic,
              width: 118,
              constraints: const BoxConstraints(minHeight: 142),
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isLocked
                      ? [
                          AppTheme.success.withValues(alpha: 0.19),
                          AppTheme.bgSecondary,
                        ]
                      : [
                          chordColor.withValues(alpha: _pressed ? 0.18 : 0.11),
                          AppTheme.bgTertiary,
                          const Color(0xFF111121),
                        ],
                  stops: const [0.0, 0.48, 1.0],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: widget.isLocked
                      ? AppTheme.success.withValues(alpha: 0.8)
                      : chordColor.withValues(alpha: _pressed ? 0.85 : 0.42),
                  width: widget.isLocked || _pressed ? 1.6 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                  if (_pressed)
                    BoxShadow(
                      color: chordColor.withValues(alpha: 0.26),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: chordColor,
                          boxShadow: [
                            BoxShadow(
                              color: chordColor.withValues(alpha: 0.65),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
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
                  const SizedBox(height: 15),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      symbol,
                      style: const TextStyle(
                        fontSize: 26,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
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
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: chordColor.withValues(alpha: 0.95),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      if (widget.showNumerals)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.23),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            widget.chord.numeral,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accentSecondary,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Icon(
                        Icons.graphic_eq_rounded,
                        size: 15,
                        color: _pressed ? chordColor : AppTheme.textMuted,
                      ),
                    ],
                  ),
                  if (widget.chord.isBorrowed ||
                      widget.chord.isSecondaryDominant ||
                      widget.chord.isTritoneSubstitution) ...[
                    const SizedBox(height: 7),
                    Text(
                      _specialIndicator(),
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.55,
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
    );
  }

  String _specialIndicator() {
    if (widget.chord.isSecondaryDominant) return 'SECONDARY DOM';
    if (widget.chord.isTritoneSubstitution) return 'TRITONE SUB';
    if (widget.chord.isBorrowed) return 'BORROWED';
    return '';
  }
}
