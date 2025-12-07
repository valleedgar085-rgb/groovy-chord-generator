/// Groovy Chord Generator
/// Preset Card Widget
/// Version 2.5

import 'package:flutter/material.dart';
import '../models/types.dart';
import '../utils/theme.dart';

class PresetCard extends StatelessWidget {
  final String presetKey;
  final SmartPreset preset;
  final bool isSelected;
  final void Function(String) onSelect;

  const PresetCard({
    super.key,
    required this.presetKey,
    required this.preset,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelect(presetKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentPrimary.withValues(alpha: 0.2)
              : AppTheme.bgTertiary,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(
            color: isSelected ? AppTheme.accentSecondary : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppTheme.shadowGlow : null,
        ),
        child: AnimatedScale(
          scale: isSelected ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                preset.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                preset.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                preset.description,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
