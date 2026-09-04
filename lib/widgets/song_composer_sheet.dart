import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/song_architecture.dart';
import '../engine/song_draft.dart';
import '../engine/song_memory.dart';
import '../providers/app_state.dart';
import '../providers/song_request_adapter.dart';
import '../providers/song_session_controller.dart';
import '../utils/music_theory.dart';
import '../utils/theme.dart';

/// Full-song arrangement surface for Producer Brain + Song Memory.
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
      heightFactor: 0.90,
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
                _buildHeader(context, session),
                Expanded(
                  child: session.hasSong
                      ? _buildSong(session)
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

  Widget _buildHeader(BuildContext context, SongSessionController session) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
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
                      ? 'Song Memory active • seed ${session.lastRequest?.seed ?? '--'}'
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
            icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
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
                'Chord Flow builds a complete arrangement, remembers each section identity, and develops repeated sections as A → A′ → A″ instead of rolling unrelated ideas.',
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

  Widget _buildSong(SongSessionController session) {
    final draft = session.currentDraft!;
    final selected = session.selectedSection ?? draft.sections.first;
    final selectedMemory = session.currentMemory?.section(selected.plan.id);
    final sourceMemory = selectedMemory == null
        ? null
        : session.currentMemory?.section(selectedMemory.sourceSectionId);
    final identity = selectedMemory == null || sourceMemory == null
        ? 0.0
        : selectedMemory.identitySimilarityTo(sourceMemory);

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
                label: 'IDENTITY',
                value: selectedMemory == null ? '--' : '${(identity * 100).round()}',
                suffix: selectedMemory == null ? '' : '% match',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'ARRANGEMENT • SONG MEMORY',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: draft.sections.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final section = draft.sections[index];
              final isSelected = session.selectedSectionId == section.plan.id;
              final memory = session.currentMemory?.section(section.plan.id);
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => session.selectSection(section.plan.id),
                child: AnimatedContainer(
                  duration: AppTheme.animationFast,
                  width: 84,
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentPrimary.withValues(alpha: 0.20)
                        : AppTheme.bgTertiary.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
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
                                color: isSelected
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.45,
                              ),
                            ),
                          ),
                          if (memory != null && section.plan.repetitionGroup != null)
                            _variationPill(section.plan),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${section.candidate.score.round()} • ${section.plan.bars} bars',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 8,
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
        _selectedSectionCard(session, selected),
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
    SongSessionController session,
    GeneratedSongSection section,
  ) {
    final plan = section.plan;
    final memory = session.currentMemory?.section(plan.id);
    final source = memory == null
        ? null
        : session.currentMemory?.section(memory.sourceSectionId);
    final similarity = memory == null || source == null
        ? 0.0
        : memory.identitySimilarityTo(source);
    final revision = session.revisionFor(plan.id);

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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _sectionLabel(plan.type),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                        if (plan.repetitionGroup != null) ...[
                          const SizedBox(width: 8),
                          _variationPill(plan),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${plan.bars} bars • harmony ${section.candidate.score.round()}/100${revision > 0 ? ' • revision $revision' : ''}',
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
          if (memory != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.bgElevated.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.accentCyan.withValues(alpha: 0.16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _memoryCell(
                      'SOURCE',
                      _shortSectionLabel(memory.sourceSectionId),
                    ),
                  ),
                  _memoryDivider(),
                  Expanded(
                    child: _memoryCell(
                      'IDENTITY',
                      '${(similarity * 100).round()}%',
                    ),
                  ),
                  _memoryDivider(),
                  Expanded(
                    child: _memoryCell(
                      'CADENCE',
                      _cadenceLabel(memory.harmony.cadence),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: section.progression
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
          const SizedBox(height: 13),
          Row(
            children: [
              _trackBadge(
                Icons.music_note_rounded,
                '${section.melody.length} melody notes',
              ),
              const SizedBox(width: 8),
              _trackBadge(
                Icons.graphic_eq_rounded,
                '${section.bass.length} bass notes',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => session.regenerateSection(plan.id),
              icon: const Icon(Icons.autorenew_rounded, size: 17),
              label: Text(revision == 0
                  ? 'REGENERATE SECTION'
                  : 'GENERATE REVISION ${revision + 1}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentSecondary,
                side: BorderSide(
                  color: AppTheme.accentPrimary.withValues(alpha: 0.30),
                ),
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                textStyle: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _variationPill(SongSectionPlan plan) {
    final label = _variationLabel(plan);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: plan.variation >= 2
            ? AppTheme.accentCyan.withValues(alpha: 0.18)
            : AppTheme.accentPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: plan.variation >= 2
              ? AppTheme.accentCyan
              : AppTheme.accentSecondary,
          fontSize: 7,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _variationLabel(SongSectionPlan plan) {
    if (plan.variation >= 2) return 'A″';
    if (plan.variation == 1) return 'A′';
    return 'A';
  }

  Widget _memoryCell(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 7,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _memoryDivider() {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppTheme.borderColor.withValues(alpha: 0.55),
    );
  }

  String _cadenceLabel(CadenceIdentity cadence) {
    switch (cadence) {
      case CadenceIdentity.authentic:
        return 'AUTHENTIC';
      case CadenceIdentity.plagal:
        return 'PLAGAL';
      case CadenceIdentity.deceptive:
        return 'DECEPTIVE';
      case CadenceIdentity.half:
        return 'HALF';
      case CadenceIdentity.unresolved:
        return 'OPEN';
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
