import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/constants.dart';
import '../models/types.dart';
import '../providers/app_state.dart';
import '../providers/song_request_adapter.dart';
import '../providers/song_session_controller.dart';
import '../utils/music_theory.dart';
import '../utils/theme.dart';
import 'song_composer_sheet.dart';

enum CreateMode { progression, fullSong }

/// Primary creation surface for Phase 3.75.
///
/// The existing Generator remains available underneath while this becomes the
/// canonical entry point for both quick loops and complete Song Architect runs.
class CreateModePanel extends StatefulWidget {
  const CreateModePanel({super.key});

  @override
  State<CreateModePanel> createState() => _CreateModePanelState();
}

class _CreateModePanelState extends State<CreateModePanel> {
  CreateMode _mode = CreateMode.progression;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final songSession = context.watch<SongSessionController>();
    final isSong = _mode == CreateMode.fullSong;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.borderColor.withValues(alpha: 0.82),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _modeButton(
                  key: const Key('create-mode-progression'),
                  label: 'PROGRESSION',
                  icon: Icons.grid_view_rounded,
                  selected: !isSong,
                  onTap: () => setState(() => _mode = CreateMode.progression),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _modeButton(
                  key: const Key('create-mode-song'),
                  label: 'FULL SONG',
                  icon: Icons.view_timeline_rounded,
                  selected: isSong,
                  onTap: () => setState(() => _mode = CreateMode.fullSong),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    _summaryChip(keyNameToString(appState.currentKey)),
                    _summaryChip(_genreLabel(appState.genre)),
                    _summaryChip(_enumLabel(appState.complexity.name)),
                    _summaryChip('${appState.tempo} BPM'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isSong && appState.currentProgression.isNotEmpty)
                _statusPill(
                  '${appState.lastHarmonyScore.round()}',
                  'SCORE',
                  AppTheme.accentSecondary,
                ),
              if (isSong && songSession.hasSong)
                _statusPill(
                  '${songSession.averageHarmonyScore.round()}',
                  'SONG',
                  AppTheme.accentCyan,
                ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: Key(isSong
                      ? 'create-full-song-primary'
                      : 'create-progression-primary'),
                  onPressed: () => _runPrimaryAction(
                    context,
                    appState,
                    songSession,
                  ),
                  icon: Icon(
                    isSong
                        ? (songSession.hasSong
                            ? Icons.open_in_full_rounded
                            : Icons.auto_awesome_rounded)
                        : Icons.bolt_rounded,
                    size: 18,
                  ),
                  label: Text(
                    isSong
                        ? (songSession.hasSong
                            ? 'OPEN COMPOSER'
                            : 'CREATE FULL SONG')
                        : (appState.currentProgression.isEmpty
                            ? 'CREATE PROGRESSION'
                            : 'NEW PROGRESSION'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isSong ? AppTheme.accentCyan : AppTheme.accentPrimary,
                    foregroundColor: AppTheme.textPrimary,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.65,
                    ),
                  ),
                ),
              ),
              if (isSong && songSession.hasSong) ...[
                const SizedBox(width: 7),
                Tooltip(
                  message: 'Create a completely new song take',
                  child: IconButton.filledTonal(
                    key: const Key('create-new-song-take'),
                    onPressed: () {
                      _generateSong(appState, songSession);
                      SongComposerSheet.open(context);
                    },
                    icon: const Icon(Icons.casino_rounded, size: 19),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      backgroundColor:
                          AppTheme.bgTertiary.withValues(alpha: 0.95),
                      foregroundColor: AppTheme.accentSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _runPrimaryAction(
    BuildContext context,
    AppState appState,
    SongSessionController songSession,
  ) {
    if (_mode == CreateMode.progression) {
      appState.generateProgression();
      return;
    }

    if (!songSession.hasSong) {
      _generateSong(appState, songSession);
    }
    SongComposerSheet.open(context);
  }

  void _generateSong(
    AppState appState,
    SongSessionController songSession,
  ) {
    final request = SongRequestAdapter.fromAppState(appState);
    songSession.generate(
      request: request,
      bassStyle: appState.bassStyle,
      bassVariety: appState.bassVariety,
      grooveTemplate: appState.grooveTemplate,
    );
  }

  Widget _modeButton({
    required Key key,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: AppTheme.animationFast,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.accentPrimary.withValues(alpha: 0.18)
                : AppTheme.bgTertiary.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppTheme.accentSecondary.withValues(alpha: 0.42)
                  : AppTheme.borderColor.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.75,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 7,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _statusPill(String value, String label, Color accent) {
    return Container(
      constraints: const BoxConstraints(minWidth: 50),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 13,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 6,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _genreLabel(GenreKey genre) {
    for (final option in genreOptions) {
      if (option['value'] == genre) return option['label'] as String;
    }
    return _enumLabel(genre.name);
  }

  String _enumLabel(String value) {
    return value
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ');
  }
}
