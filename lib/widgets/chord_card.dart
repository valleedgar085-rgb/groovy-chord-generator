/// Groovy Chord Generator
/// Chord Card Widget
/// Version 2.5

import 'package:flutter/material.dart';
import '../models/types.dart';
import '../utils/theme.dart';
import '../utils/music_theory.dart';

class ChordCard extends StatelessWidget {
  final Chord chord;
  final int index;
  final bool showNumerals;
  final bool isLocked;
  final VoidCallback? onLockToggle;

  const ChordCard({
    super.key,
    required this.chord,
    required this.index,
    this.showNumerals = true,
    this.isLocked = false,
    this.onLockToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + (index * 50)),
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
        onTap: () {
          // Play chord sound
        },
        child: Container(
          constraints: const BoxConstraints(minWidth: 80),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingMd,
          ),
          decoration: BoxDecoration(
            color: isLocked
                ? AppTheme.success.withValues(alpha: 0.1)
                : AppTheme.bgTertiary,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
            border: Border.all(
              color: isLocked ? AppTheme.success : AppTheme.borderColor,
              width: isLocked ? 2 : 1,
            ),
            boxShadow: isLocked ? AppTheme.shadowGlow : null,
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
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        isLocked ? '🔒' : '🔓',
                        style: TextStyle(
                          fontSize: 12,
                          color: isLocked ? AppTheme.success : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Chord content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chord name
                  Text(
                    getChordSymbol(chord),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  
                  // Chord type
                  Text(
                    getChordTypeName(chord.type),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  
                  // Roman numeral
                  if (showNumerals) ...[
                    const SizedBox(height: 4),
                    Text(
                      chord.numeral,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentSecondary,
                      ),
                    ),
                  ],
                  
                  // Harmony function
                  if (chord.harmonyFunction != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      chord.harmonyFunction!.name,
                      style: const TextStyle(
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textMuted,
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
                          color: AppTheme.accentPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getSpecialIndicator(),
                          style: const TextStyle(
                            fontSize: 8,
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

  String _getSpecialIndicator() {
    if (chord.isSecondaryDominant) return 'V/V';
    if (chord.isTritoneSubstitution) return 'TT';
    if (chord.isBorrowed) return 'Borrowed';
    return '';
  }
}
