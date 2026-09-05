import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/harmony_engine.dart';
import '../engine/producer_analysis.dart';
import '../providers/app_state.dart';
import '../providers/song_session_controller.dart';
import '../utils/theme.dart';
import 'producer_analysis_sheet.dart';
import 'song_composer_sheet.dart';

class ProducerBrainPanel extends StatelessWidget {
  const ProducerBrainPanel({
    super.key,
    required this.appState,
  });

  final AppState appState;

  static final ProducerAnalyzer _producerAnalyzer = ProducerAnalyzer();

  static const _sectionLabels = <HarmonySection, String>{
    HarmonySection.neutral: 'AUTO',
    HarmonySection.verse: 'VERSE',
    HarmonySection.preChorus: 'PRE',
    HarmonySection.chorus: 'CHORUS',
    HarmonySection.bridge: 'BRIDGE',
  };

  @override
  Widget build(BuildContext context) {
    final hasProgression = appState.currentProgression.isNotEmpty;
    final analysis = hasProgression
        ? _producerAnalyzer.analyze(
            progression: appState.currentProgression,
            melody: appState.currentMelody,
            bass: appState.currentBassLine,
            genre: appState.genre,
            rhythm: appState.rhythm,
            section: appState.harmonySection,
            spice: appState.spiceLevel,
            tempo: appState.tempo,
            swing: appState.swing,
            grooveTemplate: appState.grooveTemplate,
          )
        : ProducerAnalysis.empty();
    final score = analysis.overallScore.clamp(0.0, 100.0).toDouble();
    final scoreColor = hasProgression ? _scoreColor(score) : AppTheme.textMuted;
    final songSession = context.watch<SongSessionController>();
    final selectedSongSection = songSession.selectedSectionId;
    final selectedRevision = selectedSongSection == null
        ? 0
        : songSession.revisionFor(selectedSongSection);

    return Container(
      height: 58,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.borderColor.withValues(alpha: 0.78),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentPrimary.withValues(alpha: 0.42),
                  AppTheme.accentCyan.withValues(alpha: 0.22),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 19,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: HarmonySection.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 5),
              itemBuilder: (context, index) {
                final section = HarmonySection.values[index];
                final selected = appState.harmonySection == section;
                return InkWell(
                  onTap: () => appState.setHarmonySection(section),
                  borderRadius: BorderRadius.circular(11),
                  child: AnimatedContainer(
                    duration: AppTheme.animationFast,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.accentPrimary.withValues(alpha: 0.22)
                          : AppTheme.bgTertiary.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: selected
                            ? AppTheme.accentSecondary.withValues(alpha: 0.42)
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      _sectionLabels[section]!,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.65,
                        color: selected
                            ? AppTheme.textPrimary
                            : AppTheme.textMuted,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: hasProgression
                ? 'Open Producer Analysis'
                : 'Generate music to unlock Producer Analysis',
            child: Semantics(
              button: hasProgression,
              label: hasProgression
                  ? 'Producer Analysis score ${score.round()}'
                  : 'Producer Analysis unavailable',
              child: InkWell(
                key: const ValueKey('producerAnalysisButton'),
                onTap: hasProgression
                    ? () => ProducerAnalysisSheet.open(context, analysis)
                    : null,
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 50,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            hasProgression ? '${score.round()}' : '--',
                            style: TextStyle(
                              fontSize: 17,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              color: scoreColor,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.insights_rounded,
                            size: 10,
                            color: scoreColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: hasProgression ? score / 100 : 0,
                          minHeight: 3,
                          backgroundColor: AppTheme.bgElevated,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Tooltip(
            message: 'Open Song Composer',
            child: InkWell(
              onTap: () => SongComposerSheet.open(context),
              borderRadius: BorderRadius.circular(11),
              child: Container(
                width: 42,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: AppTheme.accentCyan.withValues(alpha: 0.25),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.view_timeline_rounded,
                      size: 15,
                      color: AppTheme.accentCyan,
                    ),
                    SizedBox(height: 1),
                    Text(
                      'SONG',
                      style: TextStyle(
                        fontSize: 6,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (songSession.canRegenerateSelected) ...[
            const SizedBox(width: 5),
            Tooltip(
              message: selectedSongSection == null
                  ? 'Regenerate selected song section'
                  : 'Regenerate $selectedSongSection',
              child: InkWell(
                onTap: () => songSession.regenerateSection(),
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  width: 36,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.autorenew_rounded,
                        size: 15,
                        color: AppTheme.accentSecondary,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        selectedRevision == 0 ? 'RE' : 'R$selectedRevision',
                        style: const TextStyle(
                          fontSize: 6,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.35,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 85) return AppTheme.success;
    if (score >= 72) return AppTheme.accentSecondary;
    if (score >= 58) return AppTheme.warning;
    return AppTheme.error;
  }
}
