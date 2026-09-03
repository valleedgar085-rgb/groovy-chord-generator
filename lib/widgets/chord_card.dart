// Groovy Chord Generator
// Chord Card Widget
// Version 2.7

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/types.dart';
import '../providers/playback_controller.dart';
import '../utils/theme.dart';
import '../utils/music_theory.dart';
import '../utilities/helpers.dart';

class ChordCard extends StatelessWidget {
  final Chord chord;
  final int index;
  final bool showNumerals;
  final bool isLocked;
  final VoidCallback? onLockToggle;
  final VoidCallback? onTap;

  const ChordCard({
    super.key,
    required this.chord,
    required this.index,
    this.showNumerals = true,
    this.isLocked = false,
    this.onLockToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chordColor = ColorHelper.getChordTypeColor(chord.type);
    return Consumer<PlaybackController>(
      builder: (context, playback, _) {
        final isActive = playback.currentChordIndex == index;
        return RepaintBoundary(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 140 + (index * 35)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 7 * (1 - value)),
                child: Transform.scale(
                  scale: 0.94 + (0.06 * value),
                  child: child,
                ),
              ),
            ),
            child: Semantics(
              button: true,
              label: 'Play ${getChordSymbol(chord)} chord',
              child: AnimatedScale(
                scale: isActive ? 1.055 : 1,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutBack,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onTap ?? () => playback.previewChord(chord, index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      constraints: const BoxConstraints(minWidth: 92, minHeight: 126),
                      padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isActive
                              ? [
                                  chordColor.withValues(alpha: 0.38),
                                  AppTheme.accentPrimary.withValues(alpha: 0.17),
                                  AppTheme.bgTertiary,
                                ]
                              : isLocked
                                  ? [
                                      AppTheme.success.withValues(alpha: 0.16),
                                      AppTheme.bgTertiary,
                                    ]
                                  : [
                                      const Color(0xFF24233D),
                                      const Color(0xFF171827),
                                    ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? chordColor
                              : isLocked
                                  ? AppTheme.success.withValues(alpha: 0.72)
                                  : chordColor.withValues(alpha: 0.32),
                          width: isActive ? 1.8 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: chordColor.withValues(alpha: isActive ? 0.42 : 0.12),
                            blurRadius: isActive ? 25 : 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Row(
                              children: [
                                if (isActive)
                                  Container(
                                    width: 7,
                                    height: 7,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: chordColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: chordColor,
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                if (onLockToggle != null)
                                  InkResponse(
                                    radius: 18,
                                    onTap: onLockToggle,
                                    child: Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: Icon(
                                        isLocked
                                            ? Icons.lock_rounded
                                            : Icons.lock_open_rounded,
                                        size: 14,
                                        color: isLocked
                                            ? AppTheme.success
                                            : AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      chordColor,
                                      ColorHelper.darken(chordColor, 0.24),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Center(
                                  child: Text(
                                    chord.root.isEmpty ? '?' : chord.root.substring(0, 1),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                getChordSymbol(chord),
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                  color: AppTheme.textPrimary,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                getChordTypeName(chord.type).toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.7,
                                  color: chordColor.withValues(alpha: 0.92),
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  if (showNumerals)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.bgPrimary.withValues(alpha: 0.58),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: Text(
                                        chord.numeral,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.accentSecondary,
                                        ),
                                      ),
                                    ),
                                  const Spacer(),
                                  Icon(
                                    isActive
                                        ? Icons.graphic_eq_rounded
                                        : Icons.touch_app_rounded,
                                    size: 14,
                                    color: isActive ? chordColor : AppTheme.textMuted,
                                  ),
                                ],
                              ),
                              if (chord.isBorrowed ||
                                  chord.isSecondaryDominant ||
                                  chord.isTritoneSubstitution) ...[
                                const SizedBox(height: 5),
                                Text(
                                  _specialIndicator(),
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.accentPink,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _specialIndicator() {
    if (chord.isSecondaryDominant) return 'SECONDARY DOMINANT';
    if (chord.isTritoneSubstitution) return 'TRITONE SUB';
    if (chord.isBorrowed) return 'BORROWED COLOR';
    return '';
  }
}
