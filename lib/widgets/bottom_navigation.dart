// Groovy Chord Generator
// Bottom navigation widget
// Version 2.7

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/types.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xEE11111F),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildNavItem(
                icon: Icons.auto_awesome_rounded,
                label: 'Create',
                tab: TabName.generator,
                currentTab: appState.currentTab,
                onTap: () => appState.setCurrentTab(TabName.generator),
              ),
              _buildNavItem(
                icon: Icons.piano_rounded,
                label: 'Chords',
                tab: TabName.editor,
                currentTab: appState.currentTab,
                onTap: () => appState.setCurrentTab(TabName.editor),
              ),
              _buildNavItem(
                icon: Icons.multiline_chart_rounded,
                label: 'Bass',
                tab: TabName.bass,
                currentTab: appState.currentTab,
                onTap: () => appState.setCurrentTab(TabName.bass),
              ),
              _buildNavItem(
                icon: Icons.tune_rounded,
                label: 'Setup',
                tab: TabName.settings,
                currentTab: appState.currentTab,
                onTap: () => appState.setCurrentTab(TabName.settings),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required TabName tab,
    required TabName currentTab,
    required VoidCallback onTap,
  }) {
    final active = tab == currentTab;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 54,
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      colors: [
                        AppTheme.accentPrimary.withValues(alpha: 0.24),
                        AppTheme.accentPink.withValues(alpha: 0.11),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(18),
              border: active
                  ? Border.all(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.28),
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: active ? 1.08 : 1,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    icon,
                    size: 23,
                    color: active
                        ? AppTheme.textPrimary
                        : AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: 0.3,
                    color: active
                        ? AppTheme.accentSecondary
                        : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
