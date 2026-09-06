import 'package:flutter/foundation.dart';

import '../engine/performance_profile.dart';
import '../engine/phrase_repair_engine.dart';
import '../engine/producer_song_composer.dart';
import '../engine/producer_song_variation_engine.dart';
import '../engine/song_architecture.dart';
import '../engine/song_candidate.dart';
import '../engine/song_development_engine.dart';
import '../engine/song_draft.dart';
import '../engine/song_memory.dart';
import '../engine/song_memory_extractor.dart';
import '../engine/song_request.dart';
import '../engine/song_timeline.dart';
import '../engine/song_timeline_builder.dart';
import '../engine/transition_repair_engine.dart';
import '../models/types.dart';

/// Live full-song state for the application.
class SongSessionController extends ChangeNotifier {
  SongSessionController({
    ProducerSongComposer? composer,
    SongDevelopmentEngine? developmentEngine,
    SongMemoryExtractor? memoryExtractor,
    SongTimelineBuilder? timelineBuilder,
    ProducerSongVariationEngine? producerVariationEngine,
    TransitionRepairEngine? transitionRepairEngine,
    PhraseRepairEngine? phraseRepairEngine,
  })  : _composer = composer ?? ProducerSongComposer(),
        _developmentEngine = developmentEngine ?? SongDevelopmentEngine(),
        _memoryExtractor = memoryExtractor ?? const SongMemoryExtractor(),
        _timelineBuilder = timelineBuilder ?? const SongTimelineBuilder(),
        _producerVariationEngine =
            producerVariationEngine ?? ProducerSongVariationEngine(),
        _transitionRepairEngine =
            transitionRepairEngine ?? const TransitionRepairEngine(),
        _phraseRepairEngine = phraseRepairEngine ?? const PhraseRepairEngine();

  final ProducerSongComposer _composer;
  final SongDevelopmentEngine _developmentEngine;
  final SongMemoryExtractor _memoryExtractor;
  final SongTimelineBuilder _timelineBuilder;
  final ProducerSongVariationEngine _producerVariationEngine;
  final TransitionRepairEngine _transitionRepairEngine;
  final PhraseRepairEngine _phraseRepairEngine;

  SongDraft? _currentDraft;
  SongMemory? _currentMemory;
  SongTimeline? _currentTimeline;
  PerformanceProfile _performanceProfile = const PerformanceProfile();
  String? _selectedSectionId;
  SongRequest? _lastRequest;
  SongPlan? _lastPlan;
  BassStyle _lastBassStyle = BassStyle.root;
  int _lastBassVariety = 50;
  GrooveTemplate _lastGrooveTemplate = GrooveTemplate.straight;
  SongDraft? _producerVariationOriginDraft;
  SongDraft? _producerReplayBaseDraft;
  ProducerVariationStyle? _activeProducerSongStyle;
  final Map<String, int> _sectionRevisions = <String, int>{};
  final List<_SectionRegenerationOp> _regenerationOps =
      <_SectionRegenerationOp>[];
  final Map<String, TransitionRepairStyle> _activeTransitionRepairs =
      <String, TransitionRepairStyle>{};
  final Map<String, PhraseRepairStyle> _activePhraseRepairs =
      <String, PhraseRepairStyle>{};

  SongDraft? get currentDraft => _currentDraft;
  SongMemory? get currentMemory => _currentMemory;
  SongTimeline? get currentTimeline => _currentTimeline;
  PerformanceProfile get performanceProfile => _performanceProfile;
  String? get selectedSectionId => _selectedSectionId;
  SongRequest? get lastRequest => _lastRequest;
  ProducerVariationStyle? get activeProducerSongStyle => _activeProducerSongStyle;
  bool get hasSong => _currentDraft != null && _currentDraft!.sections.isNotEmpty;
  bool get hasMemory => _currentMemory != null && _currentMemory!.sections.isNotEmpty;
  bool get hasTimeline => _currentTimeline != null && _currentTimeline!.sections.isNotEmpty;
  bool get isComplete => _currentDraft?.isComplete ?? false;
  double get averageHarmonyScore => _currentDraft?.averageHarmonyScore ?? 0.0;
  bool get canRegenerateSelected => hasSong && selectedSection != null;

  Map<String, int> get sectionRevisions =>
      Map<String, int>.unmodifiable(_sectionRevisions);
  Map<String, TransitionRepairStyle> get activeTransitionRepairs =>
      Map<String, TransitionRepairStyle>.unmodifiable(_activeTransitionRepairs);
  Map<String, PhraseRepairStyle> get activePhraseRepairs =>
      Map<String, PhraseRepairStyle>.unmodifiable(_activePhraseRepairs);

  int revisionFor(String sectionId) => _sectionRevisions[sectionId] ?? 0;

  TransitionRepairStyle? transitionRepairFor(
    String fromSectionId,
    String toSectionId,
  ) =>
      _activeTransitionRepairs[_transitionKey(fromSectionId, toSectionId)];

  PhraseRepairStyle? phraseRepairFor(String phraseId) =>
      _activePhraseRepairs[phraseId];

  GeneratedSongSection? get selectedSection {
    final draft = _currentDraft;
    final id = _selectedSectionId;
    if (draft == null || id == null) return null;
    return draft.sectionById(id);
  }

  TimelineSection? get selectedTimelineSection {
    final timeline = _currentTimeline;
    final id = _selectedSectionId;
    if (timeline == null || id == null) return null;
    return timeline.sectionById(id);
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

    _currentDraft = draft;
    _refreshDerivedSongState(draft);
    _selectedSectionId = draft.sections.isEmpty ? null : draft.sections.first.plan.id;
    _lastRequest = request;
    _lastPlan = effectivePlan;
    _lastBassStyle = bassStyle;
    _lastBassVariety = bassVariety;
    _lastGrooveTemplate = grooveTemplate;
    _producerVariationOriginDraft = draft;
    _producerReplayBaseDraft = null;
    _activeProducerSongStyle = null;
    _sectionRevisions.clear();
    _regenerationOps.clear();
    _activeTransitionRepairs.clear();
    _activePhraseRepairs.clear();
    notifyListeners();
  }

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
      final replacement = _developmentEngine.developSection(rawUpdatedDraft, targetId);
      updatedDraft = draft.withSection(replacement);
    } else {
      updatedDraft = _developmentEngine.redevelopDependents(rawUpdatedDraft, targetId);
    }

    _currentDraft = updatedDraft;
    _refreshDerivedSongState(updatedDraft);
    _selectedSectionId = targetId;
    _producerVariationOriginDraft = updatedDraft;
    _sectionRevisions[targetId] = revision;
    _regenerationOps.add(_SectionRegenerationOp(targetId, revision));
    _activeTransitionRepairs.clear();
    _activePhraseRepairs.clear();
    notifyListeners();
    return true;
  }

  void replay() {
    final request = _lastRequest;
    final plan = _lastPlan;
    if (request == null || plan == null) return;

    final previouslySelected = _selectedSectionId;
    final operations = List<_SectionRegenerationOp>.from(_regenerationOps);

    SongDraft draft;
    final producerBase = _producerReplayBaseDraft;
    if (producerBase != null) {
      draft = producerBase;
    } else {
      final rawBase = _composer.compose(
        request: request,
        plan: plan,
        bassStyle: _lastBassStyle,
        bassVariety: _lastBassVariety,
        grooveTemplate: _lastGrooveTemplate,
      );
      draft = _developmentEngine.develop(rawBase);
    }
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
        final replacement =
            _developmentEngine.developSection(rawUpdatedDraft, operation.sectionId);
        draft = draft.withSection(replacement);
      } else {
        draft = _developmentEngine.redevelopDependents(
          rawUpdatedDraft,
          operation.sectionId,
        );
      }
      rebuiltRevisions[operation.sectionId] = operation.revision;
    }

    _currentDraft = draft;
    _refreshDerivedSongState(draft);
    _sectionRevisions
      ..clear()
      ..addAll(rebuiltRevisions);
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

  /// Lazily builds complete Polished / Creative / Hook interpretations of the
  /// current song. No live state is changed until [applyProducerSongVariation]
  /// is called, so opening the chooser is safe for A/B comparison.
  List<ProducerSongVariation> buildProducerSongVariations({
    required int tempo,
    required double swing,
  }) {
    final draft = _producerVariationOriginDraft ?? _currentDraft;
    final request = _lastRequest;
    if (draft == null || request == null || draft.sections.isEmpty) {
      return const <ProducerSongVariation>[];
    }
    return _producerVariationEngine.build(
      baseDraft: draft,
      request: request,
      performanceProfile: _performanceProfile,
      bassStyle: _lastBassStyle,
      bassVariety: _lastBassVariety,
      grooveTemplate: _lastGrooveTemplate,
      tempo: tempo,
      swing: swing,
    );
  }

  /// Commits one full-song Producer interpretation as a new deterministic base.
  /// Later section regeneration is replayed on top of this chosen base.
  bool applyProducerSongVariation(ProducerSongVariation variation) {
    final plan = _lastPlan;
    if (plan == null ||
        variation.draft.plan.seed != plan.seed ||
        variation.draft.sections.length != plan.sections.length) {
      return false;
    }

    final previouslySelected = _selectedSectionId;
    _currentDraft = variation.draft;
    _refreshDerivedSongState(variation.draft);
    _producerReplayBaseDraft = variation.draft;
    _activeProducerSongStyle = variation.style;
    _sectionRevisions.clear();
    _regenerationOps.clear();
    _activeTransitionRepairs.clear();
    _activePhraseRepairs.clear();

    if (previouslySelected != null &&
        variation.draft.sectionById(previouslySelected) != null) {
      _selectedSectionId = previouslySelected;
    } else {
      _selectedSectionId = variation.draft.sections.isEmpty
          ? null
          : variation.draft.sections.first.plan.id;
    }
    notifyListeners();
    return true;
  }

  /// Generates safe, non-regressing alternatives for one adjacent song handoff.
  /// This is pure audition state; the live song is untouched until apply.
  List<TransitionRepairVariant> buildTransitionRepairVariants(
    String fromSectionId,
    String toSectionId,
  ) {
    final draft = _currentDraft;
    if (draft == null) return const <TransitionRepairVariant>[];
    return _transitionRepairEngine.build(
      draft: draft,
      fromSectionId: fromSectionId,
      toSectionId: toSectionId,
    );
  }

  /// Commits exactly the already-scored transition repair shown in the UI.
  /// The repaired draft becomes the deterministic replay/edit baseline so later
  /// playback or additional repairs do not silently regenerate the boundary.
  bool applyTransitionRepairVariant(TransitionRepairVariant variant) {
    final current = _currentDraft;
    final plan = _lastPlan;
    if (current == null ||
        plan == null ||
        variant.draft.plan.seed != plan.seed ||
        variant.draft.sections.length != current.sections.length ||
        variant.after.score + 0.01 < variant.before.score) {
      return false;
    }
    if (current.sectionById(variant.fromSectionId) == null ||
        current.sectionById(variant.toSectionId) == null ||
        current.plan.nextOf(variant.fromSectionId)?.id != variant.toSectionId) {
      return false;
    }

    _currentDraft = variant.draft;
    _refreshDerivedSongState(variant.draft);
    _selectedSectionId = variant.toSectionId;

    // An explicit transition edit establishes a new custom song baseline.
    // Preserve exact replay while avoiding a misleading pure A/B/C style badge.
    _producerReplayBaseDraft = variant.draft;
    _producerVariationOriginDraft = variant.draft;
    _activeProducerSongStyle = null;
    _sectionRevisions.clear();
    _regenerationOps.clear();
    _activePhraseRepairs.clear();
    _activeTransitionRepairs[
      _transitionKey(variant.fromSectionId, variant.toSectionId)
    ] = variant.style;
    notifyListeners();
    return true;
  }

  /// Builds safe alternatives for one phrase. If [phraseId] is omitted the
  /// Phrase Producer Brain's weakest current phrase is targeted automatically.
  List<PhraseRepairVariant> buildPhraseRepairVariants([String? phraseId]) {
    final draft = _currentDraft;
    if (draft == null) return const <PhraseRepairVariant>[];
    return _phraseRepairEngine.build(
      draft: draft,
      phraseId: phraseId,
    );
  }

  /// Commits the exact phrase repair that was scored against the current song.
  /// The repair is recomputed first so stale UI variants cannot overwrite a song
  /// that changed after preview. The resulting custom draft becomes the exact
  /// deterministic replay baseline.
  bool applyPhraseRepairVariant(PhraseRepairVariant variant) {
    final current = _currentDraft;
    final plan = _lastPlan;
    if (current == null ||
        plan == null ||
        !variant.improved ||
        variant.draft.plan.seed != plan.seed ||
        variant.draft.sections.length != current.sections.length ||
        current.sectionById(variant.sectionId) == null ||
        _currentMemory?.phrase(variant.phraseId) == null) {
      return false;
    }

    PhraseRepairVariant? fresh;
    for (final candidate in _phraseRepairEngine.build(
      draft: current,
      phraseId: variant.phraseId,
    )) {
      if (candidate.style == variant.style) {
        fresh = candidate;
        break;
      }
    }
    if (fresh == null ||
        (fresh.before.score - variant.before.score).abs() > 0.001 ||
        (fresh.after.score - variant.after.score).abs() > 0.001 ||
        fresh.changedNoteCount != variant.changedNoteCount) {
      return false;
    }

    _currentDraft = fresh.draft;
    _refreshDerivedSongState(fresh.draft);
    _selectedSectionId = fresh.sectionId;
    _producerReplayBaseDraft = fresh.draft;
    _producerVariationOriginDraft = fresh.draft;
    _activeProducerSongStyle = null;
    _sectionRevisions.clear();
    _regenerationOps.clear();
    _activeTransitionRepairs.clear();
    _activePhraseRepairs[fresh.phraseId] = fresh.style;
    notifyListeners();
    return true;
  }

  bool selectSection(String sectionId) {
    final draft = _currentDraft;
    if (draft == null || draft.sectionById(sectionId) == null) return false;
    if (_selectedSectionId == sectionId) return true;
    _selectedSectionId = sectionId;
    notifyListeners();
    return true;
  }

  void setPerformanceLooseness(double value) => _setPerformance(
        _performanceProfile.copyWith(looseness: value.clamp(0.0, 1.0).toDouble()),
      );

  void setPerformancePunch(double value) => _setPerformance(
        _performanceProfile.copyWith(punch: value.clamp(0.0, 1.0).toDouble()),
      );

  void setPerformanceSwing(double value) => _setPerformance(
        _performanceProfile.copyWith(swing: value.clamp(0.0, 1.0).toDouble()),
      );

  void resetPerformance() => _setPerformance(const PerformanceProfile());

  void clear() {
    if (_currentDraft == null && _selectedSectionId == null) return;
    _currentDraft = null;
    _currentMemory = null;
    _currentTimeline = null;
    _performanceProfile = const PerformanceProfile();
    _selectedSectionId = null;
    _lastRequest = null;
    _lastPlan = null;
    _producerVariationOriginDraft = null;
    _producerReplayBaseDraft = null;
    _activeProducerSongStyle = null;
    _sectionRevisions.clear();
    _regenerationOps.clear();
    _activeTransitionRepairs.clear();
    _activePhraseRepairs.clear();
    notifyListeners();
  }

  void _setPerformance(PerformanceProfile profile) {
    _performanceProfile = profile;
    final draft = _currentDraft;
    if (draft != null) {
      _currentTimeline = _timelineBuilder.build(
        draft,
        performanceProfile: _performanceProfile,
      );
    }
    notifyListeners();
  }

  void _refreshDerivedSongState(SongDraft draft) {
    _currentMemory = _memoryExtractor.capture(draft);
    _currentTimeline = _timelineBuilder.build(
      draft,
      performanceProfile: _performanceProfile,
    );
  }

  String _transitionKey(String fromSectionId, String toSectionId) =>
      '$fromSectionId->$toSectionId';
}

class _SectionRegenerationOp {
  const _SectionRegenerationOp(this.sectionId, this.revision);

  final String sectionId;
  final int revision;
}
