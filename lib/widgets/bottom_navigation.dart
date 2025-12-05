/// Groovy Chord Generator
/// Bottom Navigation Widget
/// Version 2.5

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
          height: AppTheme.navHeight,
          decoration: const BoxDecoration(
            color: AppTheme.bgSecondary,
            border: Border(
              top: BorderSide(color: AppTheme.borderColor),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.auto_awesome,
                label: 'Generate',
                tab: TabName.generator,
                currentTab: appState.currentTab,
                onTap: () => appState.setCurrentTab(TabName.generator),
              ),
              _buildNavItem(
                context,
                icon: Icons.piano,
                label: 'Editor',
                tab: TabName.editor,
                currentTab: appState.currentTab,
                onTap: () => appState.setCurrentTab(TabName.editor),
              ),
              _buildNavItem(
                context,
                icon: Icons.music_note,
                label: 'Bass',
                tab: TabName.bass,
                currentTab: appState.currentTab,
                onTap: () => appState.setCurrentTab(TabName.bass),
              ),
              _buildNavItem(
                context,
                icon: Icons.settings,
                label: 'Settings',
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

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required TabName tab,
    required TabName currentTab,
    required VoidCallback onTap,
  }) {
    final isActive = tab == currentTab;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.bgTertiary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 24,
                color: isActive ? AppTheme.accentSecondary : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
                color: isActive ? AppTheme.accentSecondary : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
