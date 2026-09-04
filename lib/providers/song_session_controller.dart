import 'package:flutter/foundation.dart';

import '../engine/producer_song_composer.dart';
import '../engine/song_architecture.dart';
import '../engine/song_draft.dart';
import '../engine/song_request.dart';
import '../models/types.dart';

/// Live full-song state for the application.
///
/// AppState remains the compatibility/settings provider for the existing
/// single-progression UI. Full-song composition gets its own focused state
/// object so Song Memory, section regeneration, timeline editing, and export can
/// grow without turning AppState into another monolith.
class SongSessionController extends ChangeNotifier {
  SongSessionController({ProducerSongComposer? composer})
      : _composer = composer ?? ProducerSongComposer();

  final ProducerSongComposer _composer;

  SongDraft? _currentDraft;
  String? _selectedSectionId;
  SongRequest? _lastRequest;
  SongPlan? _lastPlan;
  BassStyle _lastBassStyle = BassStyle.root;
  int _lastBassVariety = 50;
  GrooveTemplate _lastGrooveTemplate = GrooveTemplate.straight;

  SongDraft? get currentDraft => _currentDraft;
  String? get selectedSectionId => _selectedSectionId;
  SongRequest? get lastRequest => _lastRequest;
  bool get hasSong => _currentDraft != null && _currentDraft!.sections.isNotEmpty;
  bool get isComplete => _currentDraft?.isComplete ?? false;
  double get averageHarmonyScore => _currentDraft?.averageHarmonyScore ?? 0.0;

  GeneratedSongSection? get selectedSection {
    final draft = _currentDraft;
    final id = _selectedSectionId;
    if (draft == null || id == null) return null;
    return draft.sectionById(id);
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
    final draft = _composer.compose(
      request: request,
      plan: effectivePlan,
      bassStyle: bassStyle,
      bassVariety: bassVariety,
      grooveTemplate: grooveTemplate,
    );

    _currentDraft = draft;
    _selectedSectionId = draft.sections.isEmpty ? null : draft.sections.first.plan.id;
    _lastRequest = request;
    _lastPlan = effectivePlan;
    _lastBassStyle = bassStyle;
    _lastBassVariety = bassVariety;
    _lastGrooveTemplate = grooveTemplate;
    notifyListeners();
  }

  /// Rebuilds the exact same song from the stored request and plan.
  void replay() {
    final request = _lastRequest;
    final plan = _lastPlan;
    if (request == null || plan == null) return;
    final previouslySelected = _selectedSectionId;
    generate(
      request: request,
      plan: plan,
      bassStyle: _lastBassStyle,
      bassVariety: _lastBassVariety,
      grooveTemplate: _lastGrooveTemplate,
    );
    if (previouslySelected != null) {
      selectSection(previouslySelected);
    }
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
    _selectedSectionId = null;
    _lastRequest = null;
    _lastPlan = null;
    notifyListeners();
  }
}
