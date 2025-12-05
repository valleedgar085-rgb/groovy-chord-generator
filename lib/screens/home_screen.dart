/// Groovy Chord Generator
/// Home Screen
/// Version 2.5

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/types.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';
import '../widgets/header.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/fab_menu.dart';
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
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              color: AppTheme.bgPrimary,
              image: DecorationImage(
                image: AssetImage('assets/background.png'),
                fit: BoxFit.cover,
                opacity: 0.1,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const AppHeader(),
                  Expanded(
                    child: _buildCurrentTab(appState.currentTab),
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
