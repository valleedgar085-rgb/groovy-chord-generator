// Groovy Chord Generator
// Bass tab
// Version 2.5

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/types.dart';
import '../models/constants.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';
import '../widgets/control_dropdown.dart';

class BassTab extends StatelessWidget {
  const BassTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bass Controls
              _buildBassControls(context, appState),
              const SizedBox(height: AppTheme.spacingMd),

              // Bass Display
              _buildBassDisplay(context, appState),
              const SizedBox(height: AppTheme.spacingMd),

              // Bass Actions
              _buildBassActions(context, appState),

              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        );
      },
    );
  }

  Widget _buildBassControls(BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎸 Bass Controls',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: ControlDropdown(
                  label: 'Bass Style',
                  value: appState.bassStyle,
                  items: bassStyleOptions
                      .map((o) => DropdownMenuItem(
                            value: o['value'] as BassStyle,
                            child: Text(o['label'] as String),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) appState.setBassStyle(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Bass Variety slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Variety',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '${appState.bassVariety}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentSecondary,
                    ),
                  ),
                ],
              ),
              Slider(
                value: appState.bassVariety.toDouble(),
                onChanged: (value) => appState.setBassVariety(value.round()),
                min: 0,
                max: 100,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBassDisplay(BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎵 Bass Line',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          if (appState.currentBassLine.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: const Center(
                child: Text(
                  'Generate a progression first, then create a bass line',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              alignment: WrapAlignment.center,
              children: appState.currentBassLine.asMap().entries.map((entry) {
                final index = entry.key;
                final bassNote = entry.value;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 200 + (index * 50)),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusSm),
                      boxShadow: AppTheme.shadowGlow,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          bassNote.note,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'O${bassNote.octave}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBassActions(BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: appState.currentProgression.isNotEmpty
                  ? appState.generateBassLineOnly
                  : null,
              icon: const Icon(Icons.refresh),
              label: const Text('Generate Bass Line'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.bgTertiary,
                disabledForegroundColor: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: appState.currentBassLine.isNotEmpty
                  ? () {
                      if (appState.isPlaying) {
                        appState.stopPlayback();
                      } else {
                        appState.playProgression();
                      }
                    }
                  : null,
              icon: Icon(appState.isPlaying ? Icons.stop : Icons.play_arrow),
              label: Text(appState.isPlaying ? 'Stop' : 'Play Bass'),
            ),
          ),
        ],
      ),
    );
  }
}
