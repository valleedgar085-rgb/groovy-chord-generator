// Groovy Chord Generator
// Home screen
// Version 2.7

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/types.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';
import '../widgets/header.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/fab_menu.dart';
import '../widgets/producer_brain_panel.dart';
import '../widgets/studio_transport.dart';
import 'generator_tab.dart';
import 'editor_tab.dart';
import 'bass_tab.dart';
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
              gradient: RadialGradient(
                center: Alignment(-0.7, -1.05),
                radius: 1.25,
                colors: [
                  Color(0xFF22183D),
                  AppTheme.bgPrimary,
                  Color(0xFF070A12),
                ],
                stops: [0, 0.48, 1],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const AppHeader(),
                  if (isGenerator) ...[
                    ProducerBrainPanel(appState: appState),
                    const StudioTransport(),
                  ],
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: KeyedSubtree(
                        key: ValueKey(appState.currentTab),
                        child: _buildCurrentTab(appState.currentTab),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: const FabMenu(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: const AppBottomNavigation(),
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
