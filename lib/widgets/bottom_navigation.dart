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
          height: 68,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xEE121222),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.borderLight.withValues(alpha: 0.65),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.42),
                blurRadius: 24,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.auto_awesome_rounded,
                label: 'Create',
                active: appState.currentTab == TabName.generator,
                onTap: () => appState.setCurrentTab(TabName.generator),
              ),
              _NavItem(
                icon: Icons.dashboard_customize_rounded,
                label: 'Edit',
                active: appState.currentTab == TabName.editor,
                onTap: () => appState.setCurrentTab(TabName.editor),
              ),
              _NavItem(
                icon: Icons.graphic_eq_rounded,
                label: 'Bass',
                active: appState.currentTab == TabName.bass,
                onTap: () => appState.setCurrentTab(TabName.bass),
              ),
              _NavItem(
                icon: Icons.tune_rounded,
                label: 'Setup',
                active: appState.currentTab == TabName.settings,
                onTap: () => appState.setCurrentTab(TabName.settings),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: AppTheme.animationFast,
          curve: Curves.easeOutCubic,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accentPrimary.withValues(alpha: 0.30),
                      AppTheme.accentPink.withValues(alpha: 0.12),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? AppTheme.accentSecondary.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: active ? 1.08 : 1,
                duration: AppTheme.animationFast,
                child: Icon(
                  icon,
                  size: 22,
                  color: active
                      ? AppTheme.textPrimary
                      : AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: active
                      ? AppTheme.accentSecondary
                      : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
