/// Groovy Chord Generator
/// Chord Card Widget
/// Version 2.5

import 'package:flutter/material.dart';
import '../models/types.dart';
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
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap ?? () {
          // Play chord sound
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minWidth: 85),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingMd,
          ),
          decoration: BoxDecoration(
            gradient: isLocked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.success.withValues(alpha: 0.15),
                      AppTheme.success.withValues(alpha: 0.08),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.bgTertiary,
                      AppTheme.bgTertiary.withValues(alpha: 0.8),
                    ],
                  ),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
            border: Border.all(
              color: isLocked ? AppTheme.success : chordColor.withValues(alpha: 0.5),
              width: isLocked ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isLocked ? AppTheme.success : chordColor).withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Lock button
              if (onLockToggle != null)
                Positioned(
                  top: -8,
                  right: -8,
                  child: GestureDetector(
                    onTap: onLockToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isLocked 
                            ? AppTheme.success.withValues(alpha: 0.2)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLocked ? Icons.lock : Icons.lock_open_outlined,
                        size: 14,
                        color: isLocked ? AppTheme.success : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              
              // Chord content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chord icon/avatar
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          chordColor,
                          ColorHelper.darken(chordColor, 0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: chordColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getChordIcon(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Chord name
                  Text(
                    getChordSymbol(chord),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      shadows: [
                        Shadow(
                          color: chordColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  
                  // Chord type
                  Text(
                    getChordTypeName(chord.type),
                    style: TextStyle(
                      fontSize: 10,
                      color: chordColor.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  // Roman numeral
                  if (showNumerals) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        chord.numeral,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentSecondary,
                        ),
                      ),
                    ),
                  ],
                  
                  // Harmony function
                  if (chord.harmonyFunction != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      chord.harmonyFunction!.name,
                      style: TextStyle(
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                        color: ColorHelper.getHarmonyFunctionColor(chord.harmonyFunction!),
                      ),
                    ),
                  ],
                  
                  // Special indicators
                  if (chord.isBorrowed || chord.isSecondaryDominant || chord.isTritoneSubstitution)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accentPrimary.withValues(alpha: 0.3),
                              AppTheme.accentPink.withValues(alpha: 0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getSpecialIndicator(),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.accentSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getChordIcon() {
    // Return first letter of root note with safety check
    if (chord.root.isEmpty) return '?';
    return chord.root.substring(0, 1);
  }

  String _getSpecialIndicator() {
    if (chord.isSecondaryDominant) return 'V/V';
    if (chord.isTritoneSubstitution) return 'TT';
    if (chord.isBorrowed) return 'Borrowed';
    return '';
  }
}
