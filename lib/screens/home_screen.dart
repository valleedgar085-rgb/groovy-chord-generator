// Chord Flow
// Studio shell

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/types.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/create_mode_panel.dart';
import '../widgets/fab_menu.dart';
import '../widgets/header.dart';
import '../widgets/producer_brain_panel.dart';
import '../widgets/studio_transport.dart';
import 'bass_tab.dart';
import 'editor_tab.dart';
import 'generator_tab.dart';
import 'settings_tab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final isGenerator = appState.currentTab == TabName.generator;

        return Scaffold(
          extendBody: true,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF080914),
                  AppTheme.bgPrimary,
                  Color(0xFF07070E),
                ],
                stops: [0.0, 0.46, 1.0],
              ),
            ),
            child: Stack(
              children: [
                const Positioned(
                  top: -110,
                  right: -90,
                  child: _AmbientGlow(
                    size: 270,
                    color: AppTheme.accentPrimary,
                  ),
                ),
                const Positioned(
                  top: 240,
                  left: -120,
                  child: _AmbientGlow(
                    size: 240,
                    color: AppTheme.accentCyan,
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      const AppHeader(),
                      if (isGenerator) ...[
                        const CreateModePanel(),
                        ProducerBrainPanel(appState: appState),
                      ],
                      Expanded(child: _buildCurrentTab(appState.currentTab)),
                      const SizedBox(height: 150),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: const FabMenu(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isGenerator)
                  StudioTransport(progression: appState.currentProgression),
                const AppBottomNavigation(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentTab(TabName tab) {
    switch (tab) {
      case TabName.generator:
        return const GeneratorTab();
      case TabName.editor:
        return const EditorTab();
      case TabName.bass:
        return const BassTab();
      case TabName.settings:
        return const SettingsTab();
    }
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.11),
              blurRadius: 105,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}
