import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/harmony_engine.dart';
import '../engine/phrase_producer_brain.dart';
import '../engine/producer_analysis.dart';
import '../engine/producer_brain_telemetry.dart';
import '../engine/song_director.dart';
import '../providers/app_state.dart';
import '../providers/song_session_controller.dart';
import '../utils/theme.dart';
import 'phrase_repair_sheet.dart';
import 'producer_analysis_sheet.dart';
import 'producer_song_variation_sheet.dart';
import 'producer_variation_sheet.dart';
import 'song_composer_sheet.dart';
import 'song_director_sheet.dart';
import 'transition_repair_sheet.dart';

class ProducerBrainPanel extends StatelessWidget {
  const ProducerBrainPanel({
    super.key,
    required this.appState,
  });

  final AppState appState;

  static final ProducerAnalyzer _producerAnalyzer = ProducerAnalyzer();
  static const SongDirectorAnalyzer _songDirectorAnalyzer = SongDirectorAnalyzer();
  static const PhraseProducerAnalyzer _phraseProducerAnalyzer =
      PhraseProducerAnalyzer();

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
    final decision = hasProgression ? ProducerBrainTelemetry.instance.latest : null;
    final activeCandidate = decision?.activeCandidate;
    final score = analysis.overallScore.clamp(0.0, 100.0).toDouble();
    final songSession = context.watch<SongSessionController>();
    final selectedSongSection = songSession.selectedSectionId;
    final selectedRevision = selectedSongSection == null
        ? 0
        : songSession.revisionFor(selectedSongSection);
    final canOpenVariants = songSession.hasSong ||
        (decision != null && decision.variations.isNotEmpty);

    final directorAnalysis = songSession.hasSong
        ? _songDirectorAnalyzer.analyze(
            draft: songSession.currentDraft!,
            memory: songSession.currentMemory,
          )
        : null;
    final weakestTransition = directorAnalysis?.weakestTransition;
    final phraseAnalysis = songSession.hasSong
        ? _phraseProducerAnalyzer.analyze(
            draft: songSession.currentDraft!,
            memory: songSession.currentMemory,
          )
        : null;
    final weakestPhrase = phraseAnalysis?.weakestPhrase;

    return Container(
      height: 60,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.bgSecondary,
            AppTheme.accentPrimary.withValues(alpha: 0.055),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.borderColor.withValues(alpha: 0.86),
        ),
        boxShadow: AppTheme.shadowSm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 430;
          return Row(
            children: [
              Container(
                width: narrow ? 36 : 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.producerGradient,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: AppTheme.shadowColorGlow(AppTheme.accentPrimary),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 19,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: _sectionRail()),
              if (weakestPhrase != null) ...[
                const SizedBox(width: 4),
                _phraseRepairButton(
                  context,
                  songSession: songSession,
                  weakestPhrase: weakestPhrase,
                ),
              ],
              if (songSession.hasSong) ...[
                const SizedBox(width: 4),
                _songButton(context),
              ],
              if (songSession.canRegenerateSelected) ...[
                const SizedBox(width: 4),
                _regenerateButton(
                  songSession,
                  selectedSongSection: selectedSongSection,
                  selectedRevision: selectedRevision,
                ),
              ],
              const SizedBox(width: 4),
              SizedBox(
                width: narrow ? 76 : 184,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (songSession.hasSong)
                        _directorButton(context, songSession),
                      if (weakestTransition != null) ...[
                        const SizedBox(width: 4),
                        _transitionButton(
                          context,
                          songSession: songSession,
                          transition: weakestTransition,
                        ),
                      ],
                      if (canOpenVariants) ...[
                        const SizedBox(width: 4),
                        _variantsButton(
                          context,
                          songSession: songSession,
                          decision: decision,
                        ),
                      ],
                      const SizedBox(width: 4),
                      _analysisButton(
                        context,
                        hasProgression: hasProgression,
                        score: score,
                        analysis: analysis,
                        decision: decision,
                        activeCandidate: activeCandidate,
                        activeSongStyle: songSession.activeProducerSongStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionRail() => ListView.separated(
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
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.accentPrimary.withValues(alpha: 0.20)
                    : AppTheme.bgTertiary.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: selected
                      ? AppTheme.accentCyan.withValues(alpha: 0.34)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                _sectionLabels[section]!,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.65,
                  color: selected ? AppTheme.textPrimary : AppTheme.textMuted,
                ),
              ),
            ),
          );
        },
      );

  Widget _phraseRepairButton(
    BuildContext context, {
    required SongSessionController songSession,
    required PhraseProducerAssessment weakestPhrase,
  }) =>
      Tooltip(
        message:
            'Repair weakest phrase: ${weakestPhrase.phraseId} (${weakestPhrase.score.round()})',
        child: InkWell(
          key: const ValueKey('phraseRepairButton'),
          onTap: () => PhraseRepairSheet.open(
            context,
            appState: appState,
            songSession: songSession,
            phraseId: weakestPhrase.phraseId,
          ),
          borderRadius: BorderRadius.circular(11),
          child: _buttonShell(
            width: 38,
            tint: AppTheme.accentCyan,
            icon: Icons.auto_fix_high_rounded,
            label: 'PHR',
          ),
        ),
      );

  Widget _songButton(BuildContext context) => Tooltip(
        message: 'Open Song Composer',
        child: InkWell(
          onTap: () => SongComposerSheet.open(context),
          borderRadius: BorderRadius.circular(11),
          child: _buttonShell(
            width: 40,
            tint: AppTheme.accentCyan,
            icon: Icons.view_timeline_rounded,
            label: 'SONG',
          ),
        ),
      );

  Widget _regenerateButton(
    SongSessionController songSession, {
    required String? selectedSongSection,
    required int selectedRevision,
  }) =>
      Tooltip(
        message: selectedSongSection == null
            ? 'Regenerate selected song section'
            : 'Regenerate $selectedSongSection',
        child: InkWell(
          onTap: () => songSession.regenerateSection(),
          borderRadius: BorderRadius.circular(11),
          child: _buttonShell(
            width: 34,
            tint: AppTheme.accentPrimary,
            icon: Icons.autorenew_rounded,
            label: selectedRevision == 0 ? 'RE' : 'R$selectedRevision',
          ),
        ),
      );

  Widget _directorButton(
    BuildContext context,
    SongSessionController songSession,
  ) =>
      Tooltip(
        message: 'Open Song Director',
        child: InkWell(
          key: const ValueKey('songDirectorButton'),
          onTap: () => SongDirectorSheet.open(
            context,
            songSession: songSession,
          ),
          borderRadius: BorderRadius.circular(11),
          child: _buttonShell(
            width: 38,
            tint: AppTheme.producerGold,
            icon: Icons.account_tree_rounded,
            label: 'DIR',
          ),
        ),
      );

  Widget _transitionButton(
    BuildContext context, {
    required SongSessionController songSession,
    required SongTransitionAssessment transition,
  }) =>
      Tooltip(
        message:
            'Repair weakest transition: ${transition.label} (${transition.score.round()})',
        child: InkWell(
          key: const ValueKey('transitionRepairButton'),
          onTap: () => TransitionRepairSheet.open(
            context,
            appState: appState,
            songSession: songSession,
            fromSectionId: transition.fromSectionId,
            toSectionId: transition.toSectionId,
          ),
          borderRadius: BorderRadius.circular(11),
          child: _buttonShell(
            width: 38,
            tint: AppTheme.warning,
            icon: Icons.swap_calls_rounded,
            label: 'FIX',
          ),
        ),
      );

  Widget _variantsButton(
    BuildContext context, {
    required SongSessionController songSession,
    required ProducerDecisionSnapshot? decision,
  }) =>
      Tooltip(
        message: songSession.hasSong
            ? 'Preview and choose full-song Producer A/B/C'
            : 'Preview and choose progression Producer A/B/C',
        child: InkWell(
          key: const ValueKey('producerVariantsButton'),
          onTap: () {
            if (songSession.hasSong) {
              ProducerSongVariationSheet.open(
                context,
                appState: appState,
                songSession: songSession,
              );
              return;
            }
            if (decision != null) {
              ProducerVariationSheet.open(
                context,
                appState: appState,
                decision: decision,
              );
            }
          },
          borderRadius: BorderRadius.circular(11),
          child: _buttonShell(
            width: 40,
            tint: AppTheme.accentPink,
            icon: songSession.hasSong
                ? Icons.library_music_rounded
                : Icons.compare_arrows_rounded,
            label: songSession.hasSong ? 'SONG A/B/C' : 'A/B/C',
            fontSize: 5.1,
          ),
        ),
      );

  Widget _analysisButton(
    BuildContext context, {
    required bool hasProgression,
    required double score,
    required ProducerAnalysis analysis,
    required ProducerDecisionSnapshot? decision,
    required dynamic activeCandidate,
    required dynamic activeSongStyle,
  }) {
    final scoreColor = hasProgression ? _scoreColor(score) : AppTheme.textMuted;
    return Tooltip(
      message: hasProgression
          ? 'Open Producer Analysis'
          : 'Generate music to unlock Producer Analysis',
      child: InkWell(
        key: const ValueKey('producerAnalysisButton'),
        onTap: hasProgression
            ? () => ProducerAnalysisSheet.open(
                  context,
                  analysis,
                  decision: decision,
                )
            : null,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: decision == null ? 52 : 70,
          height: 38,
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
                      fontWeight: FontWeight.w900,
                      color: scoreColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.insights_rounded, size: 10, color: scoreColor),
                ],
              ),
              const SizedBox(height: 3),
              if (activeSongStyle != null)
                Text(
                  '${activeSongStyle.label} SONG',
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: const TextStyle(
                    color: AppTheme.accentPink,
                    fontSize: 6.5,
                    fontWeight: FontWeight.w900,
                  ),
                )
              else if (activeCandidate != null)
                const Text(
                  'BRAIN PICK',
                  style: TextStyle(
                    color: AppTheme.accentCyan,
                    fontSize: 6.5,
                    fontWeight: FontWeight.w900,
                  ),
                )
              else
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
    );
  }

  Widget _buttonShell({
    required double width,
    required Color tint,
    required IconData icon,
    required String label,
    double fontSize = 5.8,
  }) =>
      Container(
        width: width,
        height: 38,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: tint.withValues(alpha: 0.24)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: tint),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                fontSize: fontSize,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.35,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );

  Color _scoreColor(double score) {
    if (score >= 85) return AppTheme.success;
    if (score >= 72) return AppTheme.accentCyan;
    if (score >= 58) return AppTheme.warning;
    return AppTheme.error;
  }
}
