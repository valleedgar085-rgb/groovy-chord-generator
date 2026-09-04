import 'package:flutter/foundation.dart';

import '../engine/producer_song_composer.dart';
import '../engine/song_architecture.dart';
import '../engine/song_development_engine.dart';
import '../engine/song_draft.dart';
import '../engine/song_memory.dart';
import '../engine/song_memory_extractor.dart';
import '../engine/song_request.dart';
import '../engine/song_timeline.dart';
import '../engine/song_timeline_builder.dart';
import '../models/types.dart';

/// Live full-song state for the application.
///
/// AppState remains the compatibility/settings provider for the existing
/// single-progression UI. Full-song composition gets its own focused state
/// object so Song Memory, timeline editing, playback, and export can grow
/// without turning AppState into another monolith.
class SongSessionController extends ChangeNotifier {
  SongSessionController({
    ProducerSongComposer? composer,
    SongDevelopmentEngine? developmentEngine,
    SongMemoryExtractor? memoryExtractor,
    SongTimelineBuilder? timelineBuilder,
  })  : _composer = composer ?? ProducerSongComposer(),
        _developmentEngine = developmentEngine ?? SongDevelopmentEngine(),
        _memoryExtractor = memoryExtractor ?? const SongMemoryExtractor(),
        _timelineBuilder = timelineBuilder ?? const SongTimelineBuilder();

  final ProducerSongComposer _composer;
  final SongDevelopmentEngine _developmentEngine;
  final SongMemoryExtractor _memoryExtractor;
  final SongTimelineBuilder _timelineBuilder;

  SongDraft? _currentDraft;
  SongMemory? _currentMemory;
  SongTimeline? _currentTimeline;
  String? _selectedSectionId;
  SongRequest? _lastRequest;
  SongPlan? _lastPlan;
  BassStyle _lastBassStyle = BassStyle.root;
  int _lastBassVariety = 50;
  GrooveTemplate _lastGrooveTemplate = GrooveTemplate.straight;
  final Map<String, int> _sectionRevisions = <String, int>{};
  final List<_SectionRegenerationOp> _regenerationOps =
      <_SectionRegenerationOp>[];

  SongDraft? get currentDraft => _currentDraft;
  SongMemory? get currentMemory => _currentMemory;
  SongTimeline? get currentTimeline => _currentTimeline;
  String? get selectedSectionId => _selectedSectionId;
  SongRequest? get lastRequest => _lastRequest;
  bool get hasSong => _currentDraft != null && _currentDraft!.sections.isNotEmpty;
  bool get hasMemory => _currentMemory != null && _currentMemory!.sections.isNotEmpty;
  bool get hasTimeline =>
      _currentTimeline != null && _currentTimeline!.sections.isNotEmpty;
  bool get isComplete => _currentDraft?.isComplete ?? false;
  double get averageHarmonyScore => _currentDraft?.averageHarmonyScore ?? 0.0;
  bool get canRegenerateSelected => hasSong && selectedSection != null;

  Map<String, int> get sectionRevisions =>
      Map<String, int>.unmodifiable(_sectionRevisions);

  int revisionFor(String sectionId) => _sectionRevisions[sectionId] ?? 0;

  GeneratedSongSection? get selectedSection {
    final draft = _currentDraft;
    final id = _selectedSectionId;
    if (draft == null || id == null) return null;
    return draft.sectionById(id);
  }

  SectionMemory? get selectedSectionMemory {
    final memory = _currentMemory;
    final id = _selectedSectionId;
    if (memory == null || id == null) return null;
    return memory.section(id);
  }

  SectionMemory? get selectedSourceMemory {
    final memory = _currentMemory;
    final id = _selectedSectionId;
    if (memory == null || id == null) return null;
    return memory.sourceFor(id);
  }

  TimelineSection? get selectedTimelineSection {
    final timeline = _currentTimeline;
    final id = _selectedSectionId;
    if (timeline == null || id == null) return null;
    return timeline.sectionById(id);
  }

  List<SongTimelineEvent> get selectedTimelineEvents {
    final timeline = _currentTimeline;
    final id = _selectedSectionId;
    if (timeline == null || id == null) return const <SongTimelineEvent>[];
    return timeline.eventsInSection(id);
  }

  /// Similarity between the selected section and its canonical repetition
  /// source. Source sections naturally score 1.0 against themselves.
  double get selectedIdentitySimilarity {
    final selected = selectedSectionMemory;
    final source = selectedSourceMemory;
    if (selected == null || source == null) return 0.0;
    return selected.identitySimilarityTo(source);
  }

  List<Chord> get selectedProgression =>
      selectedSection?.progression ?? const <Chord>[];
  List<MelodyNote> get selectedMelody =>
      selectedSection?.melody ?? const <MelodyNote>[];
  List<BassNote> get selectedBass => selectedSection?.bass ?? const <BassNote>[];

  /// Generates an entire deterministic song and selects its first section.
  void generate({
    required SongRequest request,
    SongPlan? plan,
    BassStyle bassStyle = BassStyle.root,
    int bassVariety = 50,
    GrooveTemplate grooveTemplate = GrooveTemplate.straight,
  }) {
    final effectivePlan = plan ?? SongPlan.standard(seed: request.seed);
    final rawDraft = _composer.compose(
      request: request,
      plan: effectivePlan,
      bassStyle: bassStyle,
      bassVariety: bassVariety,
      grooveTemplate: grooveTemplate,
    );
    final draft = _developmentEngine.develop(rawDraft);

    _setDraft(draft);
    _selectedSectionId = draft.sections.isEmpty ? null : draft.sections.first.plan.id;
    _lastRequest = request;
    _lastPlan = effectivePlan;
    _lastBassStyle = bassStyle;
    _lastBassVariety = bassVariety;
    _lastGrooveTemplate = grooveTemplate;
    _sectionRevisions.clear();
    _regenerationOps.clear();
    notifyListeners();
  }

  /// Generates a deterministic new revision of one section while preserving
  /// every unrelated section in the current draft.
  ///
  /// If the regenerated section is a canonical repetition source (Verse 1,
  /// Chorus 1, etc.), later A′ / A″ dependents are re-derived automatically.
  /// Revisions are recorded as operations so [replay] reconstructs the exact
  /// sequence of local edits.
  bool regenerateSection([String? sectionId]) {
    final request = _lastRequest;
    final draft = _currentDraft;
    final targetId = sectionId ?? _selectedSectionId;
    if (request == null || draft == null || targetId == null) return false;
    final existing = draft.sectionById(targetId);
    if (existing == null) return false;

    final revision = (_sectionRevisions[targetId] ?? 0) + 1;
    final rawReplacement = _composer.regenerateSection(
      request: request,
      draft: draft,
      sectionId: targetId,
      revision: revision,
      bassStyle: _lastBassStyle,
      bassVariety: _lastBassVariety,
      grooveTemplate: _lastGrooveTemplate,
    );

    final rawUpdatedDraft = draft.withSection(rawReplacement);
    final SongDraft updatedDraft;
    if (existing.plan.variation > 0) {
      final replacement = _developmentEngine.developSection(
        rawUpdatedDraft,
        targetId,
      );
      updatedDraft = draft.withSection(replacement);
    } else {
      updatedDraft = _developmentEngine.redevelopDependents(
        rawUpdatedDraft,
        targetId,
      );
    }

    _setDraft(updatedDraft);
    _selectedSectionId = targetId;
    _sectionRevisions[targetId] = revision;
    _regenerationOps.add(_SectionRegenerationOp(targetId, revision));
    notifyListeners();
    return true;
  }

  /// Rebuilds the exact same song, including every section-regeneration edit,
  /// from the stored request, plan and deterministic operation log.
  void replay() {
    final request = _lastRequest;
    final plan = _lastPlan;
    if (request == null || plan == null) return;

    final previouslySelected = _selectedSectionId;
    final operations = List<_SectionRegenerationOp>.from(_regenerationOps);

    final rawBase = _composer.compose(
      request: request,
      plan: plan,
      bassStyle: _lastBassStyle,
      bassVariety: _lastBassVariety,
      grooveTemplate: _lastGrooveTemplate,
    );
    var draft = _developmentEngine.develop(rawBase);
    final rebuiltRevisions = <String, int>{};

    for (final operation in operations) {
      final existing = draft.sectionById(operation.sectionId);
      if (existing == null) continue;
      final rawReplacement = _composer.regenerateSection(
        request: request,
        draft: draft,
        sectionId: operation.sectionId,
        revision: operation.revision,
        bassStyle: _lastBassStyle,
        bassVariety: _lastBassVariety,
        grooveTemplate: _lastGrooveTemplate,
      );
      final rawUpdatedDraft = draft.withSection(rawReplacement);
      if (existing.plan.variation > 0) {
        final replacement = _developmentEngine.developSection(
          rawUpdatedDraft,
          operation.sectionId,
        );
        draft = draft.withSection(replacement);
      } else {
        draft = _developmentEngine.redevelopDependents(
          rawUpdatedDraft,
          operation.sectionId,
        );
      }
      rebuiltRevisions[operation.sectionId] = operation.revision;
    }

    _setDraft(draft);
    _sectionRevisions
      ..clear()
      ..addAll(rebuiltRevisions);
    // Keep the original operation order; it is part of the replay contract.
    _regenerationOps
      ..clear()
      ..addAll(operations);

    if (previouslySelected != null &&
        draft.sectionById(previouslySelected) != null) {
      _selectedSectionId = previouslySelected;
    } else {
      _selectedSectionId = draft.sections.isEmpty ? null : draft.sections.first.plan.id;
    }
    notifyListeners();
  }

  bool selectSection(String sectionId) {
    final draft = _currentDraft;
    if (draft == null || draft.sectionById(sectionId) == null) return false;
    if (_selectedSectionId == sectionId) return true;
    _selectedSectionId = sectionId;
    notifyListeners();
    return true;
  }

  void clear() {
    if (_currentDraft == null && _selectedSectionId == null) return;
    _currentDraft = null;
    _currentMemory = null;
    _currentTimeline = null;
    _selectedSectionId = null;
    _lastRequest = null;
    _lastPlan = null;
    _sectionRevisions.clear();
    _regenerationOps.clear();
    notifyListeners();
  }

  /// Draft, memory, and timeline are one derived state transaction. Keeping the
  /// three representations synchronized here prevents playback/export from
  /// reading a stale timeline after regeneration or replay.
  void _setDraft(SongDraft draft) {
    _currentDraft = draft;
    _currentMemory = _memoryExtractor.capture(draft);
    _currentTimeline = _timelineBuilder.build(draft);
  }
}

class _SectionRegenerationOp {
  const _SectionRegenerationOp(this.sectionId, this.revision);

  final String sectionId;
  final int revision;
}
