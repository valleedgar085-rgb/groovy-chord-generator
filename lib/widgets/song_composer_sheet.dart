import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/motif_transformation_engine.dart';
import '../engine/section_development_metadata.dart';
import '../engine/song_architecture.dart';
import '../engine/song_draft.dart';
import '../providers/app_state.dart';
import '../providers/song_request_adapter.dart';
import '../providers/song_session_controller.dart';
import '../utils/music_theory.dart';
import '../utils/theme.dart';

/// Arrangement surface for the multi-section Producer Brain.
///
/// In addition to generation and replay, the Composer now exposes the real
/// Song Memory lineage retained by each generated section: A / A′ / A″,
/// canonical source identity, similarity, and actual motif operations.
class SongComposerSheet extends StatelessWidget {
  const SongComposerSheet({super.key});

  static Future<void> open(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SongComposerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: AppTheme.borderColor.withValues(alpha: 0.85),
          ),
        ),
        child: Consumer2<AppState, SongSessionController>(
          builder: (context, appState, session, _) {
            return Column(
              children: [
                _buildHandle(),
                _buildHeader(context, appState, session),
                Expanded(
                  child: session.hasSong
                      ? _buildSong(context, session)
                      : _buildEmptyState(appState, session),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.textMuted.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppState appState,
    SongSessionController session,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentPrimary.withValues(alpha: 0.55),
                  AppTheme.accentCyan.withValues(alpha: 0.28),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.view_timeline_rounded,
              color: AppTheme.textPrimary,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SONG COMPOSER',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  session.hasSong
                      ? '10-section arrangement • seed ${session.lastRequest?.seed ?? '--'}'
                      : 'Build a complete arrangement from the current setup',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    AppState appState,
    SongSessionController session,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.bgTertiary.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.borderColor.withValues(alpha: 0.72),
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FROM LOOP TO SONG',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                ),
              ),
              SizedBox(height: 9),
              Text(
                'Chord Flow will build Intro, Verse, Pre-Chorus, Chorus, Verse 2, Pre 2, Chorus 2, Bridge, Final Chorus and Outro from one deterministic producer seed.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _setupSummary(appState),
        const SizedBox(height: 18),
        _generateButton(appState, session, label: 'CREATE FULL SONG'),
      ],
    );
  }

  Widget _buildSong(BuildContext context, SongSessionController session) {
    final draft = session.currentDraft!;
    final selected = session.selectedSection ?? draft.sections.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 26),
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                label: 'SONG SCORE',
                value: session.averageHarmonyScore.round().toString(),
                suffix: '/100',
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _metricCard(
                label: 'SECTIONS',
                value: '${draft.sections.length}',
                suffix: draft.isComplete ? ' complete' : ' building',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'ARRANGEMENT',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: draft.sections.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final section = draft.sections[index];
              final selectedSection = session.selectedSectionId == section.plan.id;
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => session.selectSection(section.plan.id),
                child: AnimatedContainer(
                  duration: AppTheme.animationFast,
                  width: 88,
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                  decoration: BoxDecoration(
                    color: selectedSection
                        ? AppTheme.accentPrimary.withValues(alpha: 0.20)
                        : AppTheme.bgTertiary.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selectedSection
                          ? AppTheme.accentSecondary.withValues(alpha: 0.55)
                          : AppTheme.borderColor.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _shortSectionLabel(section.plan.id),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selectedSection
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.35,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _identityBadge(section.development.identity, compact: true),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${section.candidate.score.round()} • ${section.plan.bars} bars',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _selectedSectionCard(selected, session),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: session.replay,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('REPLAY SEED'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: BorderSide(
                    color: AppTheme.borderColor.withValues(alpha: 0.85),
                  ),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Consumer<AppState>(
                builder: (context, appState, _) =>
                    _generateButton(appState, session, label: 'NEW TAKE'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _selectedSectionCard(
    GeneratedSongSection section,
    SongSessionController session,
  ) {
    final plan = section.plan;
    final chords = section.progression;
    final development = section.development;
    final rawSimilarity = development.isDeveloped
        ? (session.currentMemory?.similarity(
              development.sourceSectionId,
              plan.id,
            ) ??
            session.selectedIdentitySimilarity)
        : 1.0;
    final identitySimilarity = rawSimilarity.clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgTertiary.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderColor.withValues(alpha: 0.72),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _sectionLabel(plan.type),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${plan.bars} bars • harmony ${section.candidate.score.round()}/100',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _miniMeter('ENERGY', plan.targetEnergy),
              const SizedBox(width: 10),
              _miniMeter('TENSION', plan.targetTension),
            ],
          ),
          const SizedBox(height: 14),
          _developmentSummary(development, identitySimilarity),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: chords
                .map<Widget>(
                  (chord) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.bgElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      getChordSymbol(chord),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          if (development.operations.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'DEVELOPMENT MOVES',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: development.operations
                  .map((operation) => _operationBadge(_operationLabel(operation)))
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 13),
          Row(
            children: [
              _trackBadge(Icons.music_note_rounded, '${section.melody.length} melody notes'),
              const SizedBox(width: 8),
              _trackBadge(Icons.graphic_eq_rounded, '${section.bass.length} bass notes'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _developmentSummary(
    SectionDevelopmentMetadata development,
    double identitySimilarity,
  ) {
    final developed = development.isDeveloped;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: _identityColor(development.identity).withValues(alpha: 0.26),
        ),
      ),
      child: Row(
        children: [
          _identityBadge(development.identity),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  developed
                      ? 'FROM ${_shortSectionLabel(development.sourceSectionId)}'
                      : 'ORIGINAL MOTIF',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  developed
                      ? 'IDENTITY ${(identitySimilarity * 100).round()}%'
                      : 'CANONICAL SOURCE',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.35,
                  ),
                ),
              ],
            ),
          ),
          if (developed)
            Icon(
              Icons.account_tree_rounded,
              size: 16,
              color: _identityColor(development.identity),
            ),
        ],
      ),
    );
  }

  Widget _identityBadge(
    SectionDevelopmentIdentity identity, {
    bool compact = false,
  }) {
    final color = _identityColor(identity);
    return Container(
      constraints: BoxConstraints(minWidth: compact ? 21 : 32),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 8,
        vertical: compact ? 2 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(compact ? 7 : 9),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Text(
        identity.label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: compact ? 7 : 11,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Color _identityColor(SectionDevelopmentIdentity identity) {
    switch (identity) {
      case SectionDevelopmentIdentity.original:
        return AppTheme.textSecondary;
      case SectionDevelopmentIdentity.aPrime:
        return AppTheme.accentCyan;
      case SectionDevelopmentIdentity.aDoublePrime:
        return AppTheme.accentSecondary;
    }
  }

  Widget _operationBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.accentPrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: AppTheme.accentPrimary.withValues(alpha: 0.20),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 7,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  String _operationLabel(MotifOperation operation) {
    switch (operation) {
      case MotifOperation.rhythmicDisplacement:
        return 'RHYTHM SHIFT';
      case MotifOperation.embellishment:
        return 'EMBELLISH';
      case MotifOperation.simplification:
        return 'SIMPLIFY';
      case MotifOperation.contourInversion:
        return 'INVERT';
      case MotifOperation.sequence:
        return 'SEQUENCE';
      case MotifOperation.cadenceIntensification:
        return 'CADENCE+';
    }
  }

  Widget _generateButton(
    AppState appState,
    SongSessionController session, {
    required String label,
  }) {
    return FilledButton.icon(
      onPressed: () {
        final request = SongRequestAdapter.fromAppState(appState);
        session.generate(
          request: request,
          bassStyle: appState.bassStyle,
          bassVariety: appState.bassVariety,
          grooveTemplate: appState.grooveTemplate,
        );
      },
      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.accentPrimary,
        foregroundColor: AppTheme.textPrimary,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        textStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _setupSummary(AppState state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgTertiary.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _setupItem('KEY', state.currentKey.name)),
          Expanded(child: _setupItem('GENRE', state.genre.name)),
          Expanded(child: _setupItem('LEVEL', state.complexity.name)),
        ],
      ),
    );
  }

  Widget _setupItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required String suffix,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgTertiary.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 5),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: suffix,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniMeter(String label, double value) {
    return SizedBox(
      width: 44,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 6,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${(value * 100).round()}%',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trackBadge(IconData icon, String text) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.bgElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppTheme.textMuted),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortSectionLabel(String id) {
    switch (id) {
      case 'verse-1':
        return 'VERSE 1';
      case 'pre-1':
        return 'PRE 1';
      case 'chorus-1':
        return 'CHORUS 1';
      case 'verse-2':
        return 'VERSE 2';
      case 'pre-2':
        return 'PRE 2';
      case 'chorus-2':
        return 'CHORUS 2';
      case 'final-chorus':
        return 'FINAL';
      default:
        return id.replaceAll('-', ' ').toUpperCase();
    }
  }

  String _sectionLabel(SongSectionType type) {
    switch (type) {
      case SongSectionType.intro:
        return 'INTRO';
      case SongSectionType.verse:
        return 'VERSE';
      case SongSectionType.preChorus:
        return 'PRE-CHORUS';
      case SongSectionType.chorus:
        return 'CHORUS';
      case SongSectionType.bridge:
        return 'BRIDGE';
      case SongSectionType.outro:
        return 'OUTRO';
    }
  }
}
