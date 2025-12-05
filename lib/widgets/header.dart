/// Groovy Chord Generator
/// App Header Widget
/// Version 2.5

import 'package:flutter/material.dart';
import '../utils/theme.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      decoration: const BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.accentGradient.createShader(bounds),
            child: const Text(
              'Groovy Chords',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          // Menu button
          GestureDetector(
            onTap: () {
              // Show menu
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.bgTertiary,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Icon(
                Icons.more_vert,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
