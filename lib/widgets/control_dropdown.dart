// Chord Flow
// Crash-safe control dropdown

import 'package:flutter/material.dart';
import '../utils/theme.dart';

class ControlDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const ControlDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final matches = items.where((item) => item.value == value).length;
    final safeValue = matches == 1 ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
            letterSpacing: 0.65,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.bgTertiary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: safeValue == null
                  ? AppTheme.warning.withValues(alpha: 0.65)
                  : AppTheme.borderColor,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: safeValue,
              hint: Text(
                'Select $label',
                style: const TextStyle(color: AppTheme.textMuted),
              ),
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              borderRadius: BorderRadius.circular(14),
              dropdownColor: AppTheme.bgElevated,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTheme.accentCyan,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
