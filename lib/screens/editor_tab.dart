/// Groovy Chord Generator
/// Editor Tab
/// Version 2.5

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';

class EditorTab extends StatelessWidget {
  const EditorTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toolbar
              _buildToolbar(context, appState),
              const SizedBox(height: AppTheme.spacingMd),
              
              // Piano Roll placeholder
              _buildPianoRoll(context, appState),
              const SizedBox(height: AppTheme.spacingMd),
              
              // Editor tip
              _buildEditorTip(),
              
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolbarButton(
            icon: appState.isPlaying ? Icons.stop : Icons.play_arrow,
            label: appState.isPlaying ? 'Stop' : 'Play',
            onTap: () {
              if (appState.isPlaying) {
                appState.stopPlayback();
              } else {
                appState.playProgression();
              }
            },
          ),
          _buildToolbarButton(
            icon: Icons.loop,
            label: 'Loop',
            onTap: () {
              // Loop functionality
            },
          ),
          _buildToolbarButton(
            icon: Icons.clear,
            label: 'Clear',
            onTap: appState.clearProgression,
          ),
          // Tempo control
          Column(
            children: [
              const Text(
                'BPM',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                width: 70,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.bgTertiary,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Center(
                  child: Text(
                    '${appState.tempo}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: AppTheme.bgTertiary,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: AppTheme.textPrimary),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPianoRoll(BuildContext context, AppState appState) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          // Piano keys
          Container(
            width: 50,
            decoration: const BoxDecoration(
              color: AppTheme.bgTertiary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadius),
                bottomLeft: Radius.circular(AppTheme.borderRadius),
              ),
            ),
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              // Add cache extent for better performance on lower-end devices
              cacheExtent: 50,
              itemCount: 12,
              itemBuilder: (context, index) {
                final isBlackKey = [1, 3, 6, 8, 10].contains(index);
                // Wrap each item in RepaintBoundary for isolated repaints
                return RepaintBoundary(
                  child: Container(
                  height: 25,
                  decoration: BoxDecoration(
                    gradient: isBlackKey
                        ? const LinearGradient(
                            colors: [Color(0xFF1A1A1A), Color(0xFF333333)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFE8E8E8), Color(0xFFFFFFFF)],
                          ),
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.borderColor.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    _getNoteNameForIndex(index),
                    style: TextStyle(
                      fontSize: 10,
                      color: isBlackKey ? const Color(0xFFAAAAAA) : const Color(0xFF333333),
                    ),
                  ),
                  ),
                );
              },
            ),
          ),
          // Grid area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.bgTertiary.withValues(alpha: 0.5),
              ),
              child: appState.currentProgression.isEmpty
                  ? const Center(
                      child: Text(
                        'Generate a progression to see it here',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : CustomPaint(
                      painter: PianoRollPainter(
                        progression: appState.currentProgression,
                      ),
                      size: const Size(double.infinity, 300),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getNoteNameForIndex(int index) {
    const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return noteNames[11 - index];
  }

  Widget _buildEditorTip() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
      ),
      child: const Row(
        children: [
          Text('💡', style: TextStyle(fontSize: 18)),
          SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              'Tap and drag on the piano roll to add or edit notes',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PianoRollPainter extends CustomPainter {
  final List<dynamic> progression;

  PianoRollPainter({required this.progression});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // Draw grid lines
    const rowCount = 12;
    final rowHeight = size.height / rowCount;
    
    for (var i = 0; i <= rowCount; i++) {
      final y = i * rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw column lines for each chord
    if (progression.isNotEmpty) {
      final colWidth = size.width / progression.length;
      for (var i = 0; i <= progression.length; i++) {
        final x = i * colWidth;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }

      // Draw chord indicators
      final chordPaint = Paint()
        ..color = AppTheme.accentPrimary.withValues(alpha: 0.3);

      for (var i = 0; i < progression.length; i++) {
        final x = i * colWidth;
        canvas.drawRect(
          Rect.fromLTWH(x + 2, size.height / 3, colWidth - 4, size.height / 3),
          chordPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
