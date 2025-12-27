// Groovy Chord Generator
// FAB Menu Widget
// Version 2.5

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';

class FabMenu extends StatefulWidget {
  const FabMenu({super.key});

  @override
  State<FabMenu> createState() => _FabMenuState();
}

class _FabMenuState extends State<FabMenu> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Menu items
            if (_isOpen) ...[
              _buildFabAction(
                icon: Icons.play_arrow,
                label: 'Play',
                onTap: () {
                  _toggleMenu();
                  if (appState.isPlaying) {
                    appState.stopPlayback();
                  } else {
                    appState.playProgression();
                  }
                },
              ),
              const SizedBox(height: AppTheme.spacingSm),
              _buildFabAction(
                icon: Icons.shuffle,
                label: 'Regenerate',
                onTap: () {
                  _toggleMenu();
                  appState.generateProgression();
                },
              ),
              const SizedBox(height: AppTheme.spacingSm),
              _buildFabAction(
                icon: Icons.download,
                label: 'Export MIDI',
                onTap: () {
                  _toggleMenu();
                  // Export functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('MIDI export coming soon!'),
                      backgroundColor: AppTheme.accentPrimary,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacingSm),
            ],

            // Main FAB
            GestureDetector(
              onTap: () {
                if (_isOpen) {
                  _toggleMenu();
                } else if (appState.currentProgression.isEmpty) {
                  appState.generateProgression();
                } else {
                  _toggleMenu();
                }
              },
              child: AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Container(
                    width: AppTheme.fabSize,
                    height: AppTheme.fabSize,
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        ...AppTheme.shadowLg,
                        ...AppTheme.shadowGlow,
                      ],
                    ),
                    child: Transform.rotate(
                      angle: _rotationAnimation.value * 2 * 3.14159,
                      child: Icon(
                        _isOpen ? Icons.close : Icons.add,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFabAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        // Combine scale and translate into a single transform for better performance
        final scale = 0.8 + (0.2 * value);
        final translateY = 10 * (1 - value);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0.0, translateY),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: AppTheme.shadowMd,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: AppTheme.textPrimary),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
