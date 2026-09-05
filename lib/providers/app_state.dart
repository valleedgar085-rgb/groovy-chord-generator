// Groovy Chord Generator
// App state provider
// Version 2.8

import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/types.dart';
import '../models/constants.dart';
import '../utils/music_theory.dart';
import '../engine/harmony_engine.dart';
import '../engine/harmony_candidate_pool.dart';
import '../engine/seeded_harmony_builder.dart';
import '../engine/song_candidate.dart';
import '../engine/song_request.dart';
import '../engine/seeded_music_generation.dart';
import '../services/firebase_favorites_service.dart';
import '../services/share_service.dart';

class AppState extends ChangeNotifier {
  static const int _producerCandidateCount = 8;

  // Current state
  List<Chord> _currentProgression = [];
  List<MelodyNote> _currentMelody = [];
  List<BassNote> _currentBassLine = [];
  KeyName _currentKey = KeyName.C;
  bool _isMinorKey = false;
  GenreKey _genre = defaultGenre;
  ComplexityLevel _complexity = defaultComplexity;
  RhythmLevel _rhythm = defaultRhythm;
  int _tempo = defaultTempo;
  bool _isPlaying = false;
  double _masterVolume = defaultMasterVolume;
  SoundType _soundType = defaultSoundType;
  bool _showNumerals = defaultShowNumerals;
  bool _showTips = defaultShowTips;
  TabName _currentTab = TabName.generator;
  bool _onboardingComplete = false;
  bool _useVoiceLeading = defaultUseVoiceLeading;
  bool _useAdvancedTheory = defaultUseAdvancedTheory;
  Envelope _envelope = defaultEnvelope;
  double _swing = defaultSwing;
  bool _useModalInterchange = defaultUseModalInterchange;
  bool _includeMelody = defaultIncludeMelody;
  bool _includeBass = defaultIncludeBass;
  BassStyle _bassStyle = defaultBassStyle;
  int _bassVariety = defaultBassVariety;
  int _chordVariety = defaultChordVariety;
  int _rhythmVariety = defaultRhythmVariety;
  String? _currentPreset;
  List<HistoryEntry> _progressionHistory = [];
  MoodType _currentMood = defaultMood;
  bool _useFunctionalHarmony = defaultUseFunctionalHarmony;
  GrooveTemplate _grooveTemplate = defaultGrooveTemplate;
  SpiceLevel _spiceLevel = defaultSpiceLevel;
  List<LockedChord> _lockedChords = [];
  HarmonySection _harmonySection = HarmonySection.neutral;
  double _lastHarmonyScore = 0.0;
  int? _lastGenerationSeed;

  // Favorites state
  List<FavoriteProgression> _favorites = [];
  bool _favoritesLoading = false;
  final Random _melodyRandom = Random();
  final HarmonyEngine _harmonyEngine = HarmonyEngine();
  final SeededMusicGeneration _seededGeneration = const SeededMusicGeneration();
  final SeededHarmonyBuilder _harmonyBuilder = const SeededHarmonyBuilder();
  HarmonyCandidatePool? _harmonyCandidatePool;

  HarmonyCandidatePool get _producerPool =>
      _harmonyCandidatePool ??= HarmonyCandidatePool(engine: _harmonyEngine);

  // Getters
  List<Chord> get currentProgression => _currentProgression;
  List<MelodyNote> get currentMelody => _currentMelody;
  List<BassNote> get currentBassLine => _currentBassLine;
  KeyName get currentKey => _currentKey;
  bool get isMinorKey => _isMinorKey;
  GenreKey get genre => _genre;
  ComplexityLevel get complexity => _complexity;
  RhythmLevel get rhythm => _rhythm;
  int get tempo => _tempo;
  bool get isPlaying => _isPlaying;
  double get masterVolume => _masterVolume;
  SoundType get soundType => _soundType;
  bool get showNumerals => _showNumerals;
  bool get showTips => _showTips;
  TabName get currentTab => _currentTab;
  bool get onboardingComplete => _onboardingComplete;
  bool get useVoiceLeading => _useVoiceLeading;
  bool get useAdvancedTheory => _useAdvancedTheory;
  Envelope get envelope => _envelope;
  double get swing => _swing;
  bool get useModalInterchange => _useModalInterchange;
  bool get includeMelody => _includeMelody;
  bool get includeBass => _includeBass;
  BassStyle get bassStyle => _bassStyle;
  int get bassVariety => _bassVariety;
  int get chordVariety => _chordVariety;
  int get rhythmVariety => _rhythmVariety;
  String? get currentPreset => _currentPreset;
  List<HistoryEntry> get progressionHistory => _progressionHistory;
  MoodType get currentMood => _currentMood;
  bool get useFunctionalHarmony => _useFunctionalHarmony;
  GrooveTemplate get grooveTemplate => _grooveTemplate;
  SpiceLevel get spiceLevel => _spiceLevel;
  List<LockedChord> get lockedChords => _lockedChords;
  List<FavoriteProgression> get favorites => _favorites;
  bool get favoritesLoading => _favoritesLoading;
  HarmonySection get harmonySection => _harmonySection;
  double get lastHarmonyScore => _lastHarmonyScore;
  int get producerCandidateCount => _producerCandidateCount;
  int? get lastGenerationSeed => _lastGenerationSeed;

  // Initialize favorites on app start
  Future<void> loadFavorites() async {
    _favoritesLoading = true;
    notifyListeners();

    _favorites = await FavoritesService.getFavorites();

    _favoritesLoading = false;
    notifyListeners();
  }

  // Setters with notification
  void setGenre(GenreKey value) {
    _genre = value;
    final profile = genreProfiles[value];
    if (profile != null) {
      _tempo = profile.tempo;
    }
    notifyListeners();
  }

  void setCurrentKey(KeyName value) {
    _currentKey = value;
    _isMinorKey = value.name.contains('m') && value.name.length > 1;
    notifyListeners();
  }

  void setComplexity(ComplexityLevel value) {
    _complexity = value;
    notifyListeners();
  }

  void setRhythm(RhythmLevel value) {
    _rhythm = value;
    notifyListeners();
  }

  void setTempo(int value) {
    _tempo = value;
    notifyListeners();
  }

  void setMasterVolume(double value) {
    _masterVolume = value;
    notifyListeners();
  }

  void setSoundType(SoundType value) {
    _soundType = value;
    notifyListeners();
  }

  void setShowNumerals(bool value) {
    _showNumerals = value;
    notifyListeners();
  }

  void setShowTips(bool value) {
    _showTips = value;
    notifyListeners();
  }

  void setCurrentTab(TabName value) {
    _currentTab = value;
    notifyListeners();
  }

  void setOnboardingComplete(bool value) {
    _onboardingComplete = value;
    notifyListeners();
  }

  void setUseVoiceLeading(bool value) {
    _useVoiceLeading = value;
    notifyListeners();
  }

  void setUseAdvancedTheory(bool value) {
    _useAdvancedTheory = value;
    notifyListeners();
  }

  void setEnvelope(Envelope value) {
    _envelope = value;
    notifyListeners();
  }

  void setSwing(double value) {
    _swing = value;
    notifyListeners();
  }

  void setUseModalInterchange(bool value) {
    _useModalInterchange = value;
    notifyListeners();
  }

  void setIncludeMelody(bool value) {
    _includeMelody = value;
    notifyListeners();
  }

  void setIncludeBass(bool value) {
    _includeBass = value;
    notifyListeners();
  }

  void setBassStyle(BassStyle value) {
    _bassStyle = value;
    notifyListeners();
  }

  void setBassVariety(int value) {
    _bassVariety = value;
    notifyListeners();
  }

  void setChordVariety(int value) {
    _chordVariety = value;
    notifyListeners();
  }

  void setRhythmVariety(int value) {
    _rhythmVariety = value;
    notifyListeners();
  }

  void setMood(MoodType value) {
    _currentMood = value;
    notifyListeners();
  }

  void setUseFunctionalHarmony(bool value) {
    _useFunctionalHarmony = value;
    notifyListeners();
  }

  void setGrooveTemplate(GrooveTemplate value) {
    _grooveTemplate = value;
    notifyListeners();
  }

  void setSpiceLevel(SpiceLevel value) {
    _spiceLevel = value;
    notifyListeners();
  }

  void setHarmonySection(HarmonySection value) {
    _harmonySection = value;
    notifyListeners();
  }

  void setIsPlaying(bool value) {
    _isPlaying = value;
    notifyListeners();
  }

  // Toggle chord lock
  void toggleChordLock(int index) {
    final existingIndex = _lockedChords.indexWhere((lc) => lc.index == index);
    if (existingIndex != -1) {
      final existing = _lockedChords[existingIndex];
      _lockedChords[existingIndex] =
          existing.copyWith(locked: !existing.locked);
    } else {
      _lockedChords.add(LockedChord(index: index, locked: true));
    }
    notifyListeners();
  }

  bool isChordLocked(int index) {
    final lock = _lockedChords.firstWhere(
      (lc) => lc.index == index,
      orElse: () => const LockedChord(index: -1, locked: false),
    );
    return lock.locked;
  }

  /// Generate a progression through the same UI-independent harmony builder
  /// used by Song Architect. This is the Phase 3.75 compatibility seam: the
  /// single-loop workflow and full-song workflow now share one construction
  /// path before Producer Brain ranking and canonical theory repair.
  void generateProgression({int? seed}) {
    if (_currentProgression.isNotEmpty) {
      final historyEntry = HistoryEntry(
        progression: List.from(_currentProgression),
        key: _currentKey,
        genre: _genre,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      _progressionHistory.insert(0, historyEntry);
      if (_progressionHistory.length > maxHistoryLength) {
        _progressionHistory = _progressionHistory.sublist(0, maxHistoryLength);
      }
    }

    final generationSeed =
        seed ?? (DateTime.now().microsecondsSinceEpoch & 0x7fffffff);
    final request = SongRequest(
      seed: generationSeed,
      key: _currentKey,
      genre: _genre,
      mood: _currentMood,
      complexity: _complexity,
      spice: _spiceLevel,
      rhythm: _rhythm,
      section: _harmonySection,
      candidateCount: _producerCandidateCount,
      chordVariety: _chordVariety,
      useVoiceLeading: _useVoiceLeading,
      useAdvancedTheory: _useAdvancedTheory,
      useModalInterchange: _useModalInterchange,
      useFunctionalHarmony: _useFunctionalHarmony,
      includeMelody: _includeMelody,
      includeBass: _includeBass,
    );

    final keyInfo = parseKey(keyNameToString(request.key));
    final isMinor = keyInfo['isMinor'] as bool;
    final lockedProgression = List<Chord>.from(_currentProgression);

    List<Chord> buildCandidate(int candidateSeed) => _harmonyBuilder.build(
          request: request,
          random: Random(candidateSeed),
          lockedChords: _lockedChords,
          lockedProgression: lockedProgression,
        );

    final winner = _producerPool.generateBestForRequest(
      request: request,
      buildCandidate: (candidateSeed, candidateIndex) =>
          buildCandidate(candidateSeed),
    );

    var chords = winner.progression.isNotEmpty
        ? List<Chord>.from(winner.progression)
        : List<Chord>.from(buildCandidate(request.candidateSeed(0)));

    if (request.useVoiceLeading) {
      chords = applyVoiceLeading(chords);
    }

    // Groove is performance metadata, not harmonic candidate quality.
    chords = applyGrooveToProgression(chords, _grooveTemplate);

    _lastHarmonyScore = winner.progression.isNotEmpty
        ? winner.score
        : _harmonyEngine.score(chords, section: request.section);
    _lastGenerationSeed = generationSeed;
    _currentProgression = chords;
    _isMinorKey = isMinor;

    if (request.includeMelody) {
      _currentMelody = _seededGeneration.generateMelody(
        random: Random(request.melodySeed),
        progression: chords,
        genre: request.genre,
        rhythm: request.rhythm,
        key: request.key,
      );
    } else {
      _currentMelody = [];
    }

    if (request.includeBass) {
      _currentBassLine = _seededGeneration.generateBass(
        random: Random(request.bassSeed),
        progression: chords,
        style: _bassStyle,
        variety: _bassVariety,
        rhythm: request.rhythm,
      );
    } else {
      _currentBassLine = [];
    }

    notifyListeners();
  }

  /// Replay the last generated musical result against the current settings.
  void replayLastGeneration() {
    final seed = _lastGenerationSeed;
    if (seed != null) generateProgression(seed: seed);
  }

  /// Phase 5.3: commit a Producer Brain A/B/C alternative without rebuilding
  /// the harmony pool. Melody and bass are regenerated from the original song
  /// request seed, so choosing the same variation is exactly replayable.
  bool applyProducerCandidate(SongCandidate candidate) {
    if (candidate.progression.isEmpty) return false;

    if (_currentProgression.isNotEmpty) {
      final historyEntry = HistoryEntry(
        progression: List.from(_currentProgression),
        key: _currentKey,
        genre: _genre,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      _progressionHistory.insert(0, historyEntry);
      if (_progressionHistory.length > maxHistoryLength) {
        _progressionHistory = _progressionHistory.sublist(0, maxHistoryLength);
      }
    }

    final generationSeed = _lastGenerationSeed ?? candidate.seed;
    final request = SongRequest(
      seed: generationSeed,
      key: _currentKey,
      genre: _genre,
      mood: _currentMood,
      complexity: _complexity,
      spice: _spiceLevel,
      rhythm: _rhythm,
      section: _harmonySection,
      candidateCount: _producerCandidateCount,
      chordVariety: _chordVariety,
      useVoiceLeading: _useVoiceLeading,
      useAdvancedTheory: _useAdvancedTheory,
      useModalInterchange: _useModalInterchange,
      useFunctionalHarmony: _useFunctionalHarmony,
      includeMelody: _includeMelody,
      includeBass: _includeBass,
    );

    var chords = List<Chord>.from(candidate.progression);
    if (request.useVoiceLeading) {
      chords = applyVoiceLeading(chords);
    }
    chords = applyGrooveToProgression(chords, _grooveTemplate);

    _currentProgression = chords;
    _lastHarmonyScore = candidate.score;
    _lastGenerationSeed = generationSeed;
    final keyInfo = parseKey(keyNameToString(request.key));
    _isMinorKey = keyInfo['isMinor'] as bool;

    if (request.includeMelody) {
      _currentMelody = _seededGeneration.generateMelody(
        random: Random(request.melodySeed),
        progression: chords,
        genre: request.genre,
        rhythm: request.rhythm,
        key: request.key,
      );
    } else {
      _currentMelody = [];
    }

    if (request.includeBass) {
      _currentBassLine = _seededGeneration.generateBass(
        random: Random(request.bassSeed),
        progression: chords,
        style: _bassStyle,
        variety: _bassVariety,
        rhythm: request.rhythm,
      );
    } else {
      _currentBassLine = [];
    }

    notifyListeners();
    return true;
  }

  List<MelodyNote> _generateMelodyNotes(
    List<Chord> progression,
    GenreKey genre,
    RhythmLevel rhythm,
    KeyName currentKey,
  ) {
    final profile = genreProfiles[genre]!;
    final rhythmPattern = rhythmPatterns[rhythm]!;
    final keyString = keyNameToString(currentKey);
    final keyInfo = parseKey(keyString);
    final root = keyInfo['root'] as String;

    final scaleNotes = getScaleNotes(root, profile.melodyScale);
    final melody = <MelodyNote>[];

    for (var chordIndex = 0; chordIndex < progression.length; chordIndex++) {
      final chord = progression[chordIndex];
      final notesPerChord = (4 * rhythmPattern.melodyDensity).ceil() + 1;
      final chordTones = chordTypes[chord.type]!
          .intervals
          .map((interval) => transposeNote(chord.root, interval))
          .toList();

      for (var i = 0; i < notesPerChord; i++) {
        final shouldUseChordTone = _melodyRandom.nextDouble() > 0.3;
        final sourcePool = shouldUseChordTone ? chordTones : scaleNotes;

        final note = randomChoice(sourcePool);
        final duration = randomChoice(rhythmPattern.durations);
        final velocity =
            rhythmPattern.dynamics[i % rhythmPattern.dynamics.length];

        melody.add(MelodyNote(
          note: note,
          duration: duration,
          velocity: velocity,
          chordIndex: chordIndex,
          octave: randomInt(4, 5),
        ));
      }
    }

    return melody;
  }

  // Generate bass line only
  void generateBassLineOnly() {
    if (_currentProgression.isEmpty) return;

    _currentBassLine = generateBassLine(
      _currentProgression,
      _bassStyle,
      _bassVariety,
      _rhythm,
    );

    notifyListeners();
  }

  // Spice it up
  void spiceItUp() {
    if (_currentProgression.isEmpty) return;

    final keyString = keyNameToString(_currentKey);
    final keyInfo = parseKey(keyString);
    final root = keyInfo['root'] as String;
    final isMinor = keyInfo['isMinor'] as bool;

    var newProgression = spiceUpProgression(_currentProgression, root, isMinor);

    if (_useVoiceLeading) {
      newProgression = applyVoiceLeading(newProgression);
    }

    _currentProgression = newProgression;
    _lastHarmonyScore =
        _harmonyEngine.score(newProgression, section: _harmonySection);
    notifyListeners();
  }

  // Apply preset
  void applyPreset(String presetKey) {
    final preset = smartPresets[presetKey];
    if (preset == null) return;

    final profile = genreProfiles[preset.genre];

    _genre = preset.genre;
    _currentKey = preset.key;
    _complexity = preset.complexity;
    _rhythm = preset.rhythm;
    _swing = preset.swing;
    _useVoiceLeading = preset.useVoiceLeading;
    _useAdvancedTheory = preset.useAdvancedTheory;
    _currentPreset = presetKey;
    if (profile != null) {
      _tempo = profile.tempo;
    }

    notifyListeners();
    generateProgression();
  }

  // Restore from history
  void restoreFromHistory(int index) {
    if (index < 0 || index >= _progressionHistory.length) return;

    final entry = _progressionHistory[index];
    var restoredProgression = List<Chord>.from(entry.progression);

    if (_useVoiceLeading) {
      restoredProgression = applyVoiceLeading(restoredProgression);
    }

    _currentProgression = restoredProgression;
    _currentKey = entry.key;
    _genre = entry.genre;
    _lastHarmonyScore =
        _harmonyEngine.score(restoredProgression, section: _harmonySection);

    notifyListeners();
  }

  // Play/Stop progression
  void playProgression() {
    if (_isPlaying || _currentProgression.isEmpty) return;
    _isPlaying = true;
    notifyListeners();
  }

  void stopPlayback() {
    _isPlaying = false;
    notifyListeners();
  }

  // Clear progression
  void clearProgression() {
    _currentProgression = [];
    _currentMelody = [];
    _currentBassLine = [];
    _lockedChords = [];
    _lastHarmonyScore = 0.0;
    notifyListeners();
  }

  // ===================================
  // Favorites Methods
  // ===================================

  /// Add current progression to favorites
  Future<bool> addToFavorites(String name) async {
    if (_currentProgression.isEmpty) return false;

    final favorite = await FavoritesService.addFavorite(
      name: name,
      progression: _currentProgression,
      key: _currentKey,
      genre: _genre,
    );

    if (favorite != null) {
      _favorites.insert(0, favorite);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Remove a favorite by ID
  Future<bool> removeFavorite(String id) async {
    final result = await FavoritesService.removeFavorite(id);
    if (result) {
      _favorites.removeWhere((f) => f.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Load a favorite progression
  void loadFavorite(FavoriteProgression favorite) {
    if (_currentProgression.isNotEmpty) {
      final historyEntry = HistoryEntry(
        progression: List.from(_currentProgression),
        key: _currentKey,
        genre: _genre,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      _progressionHistory.insert(0, historyEntry);
      if (_progressionHistory.length > maxHistoryLength) {
        _progressionHistory = _progressionHistory.sublist(0, maxHistoryLength);
      }
    }

    var restoredProgression = List<Chord>.from(favorite.progression);

    if (_useVoiceLeading) {
      restoredProgression = applyVoiceLeading(restoredProgression);
    }

    _currentProgression = restoredProgression;
    _currentKey = favorite.key;
    _genre = favorite.genre;
    _isMinorKey =
        favorite.key.name.contains('m') && favorite.key.name.length > 1;
    _lastHarmonyScore =
        _harmonyEngine.score(restoredProgression, section: _harmonySection);

    final profile = genreProfiles[favorite.genre];
    if (profile != null) {
      _tempo = profile.tempo;
    }

    if (_includeMelody) {
      _currentMelody = _generateMelodyNotes(
          _currentProgression, _genre, _rhythm, _currentKey);
    }
    if (_includeBass) {
      _currentBassLine = generateBassLine(
          _currentProgression, _bassStyle, _bassVariety, _rhythm);
    }

    notifyListeners();
  }

  /// Check if current progression is a favorite
  Future<bool> isCurrentFavorite() async {
    return FavoritesService.isFavorite(_currentProgression);
  }

  // ===================================
  // Share Methods
  // ===================================

  /// Generate a shareable URL for current progression
  String generateShareUrl() {
    return ShareService.generateShareUrl(
      progression: _currentProgression,
      key: _currentKey,
      genre: _genre,
      tempo: _tempo,
    );
  }

  /// Generate a compact share code
  String generateShareCode() {
    return ShareService.generateShareCode(
      progression: _currentProgression,
      key: _currentKey,
      genre: _genre,
    );
  }

  /// Get shareable text with progression details
  String getShareableText() {
    return ShareService.getShareableText(
      progression: _currentProgression,
      key: _currentKey,
      genre: _genre,
      tempo: _tempo,
    );
  }

  /// Load progression from share URL
  bool loadFromShareUrl(String url) {
    final sharedSet = ShareService.parseShareUrl(url);
    if (sharedSet == null) return false;

    _loadSharedChordSet(sharedSet);
    return true;
  }

  /// Load progression from share code
  bool loadFromShareCode(String code) {
    final sharedSet = ShareService.parseShareCode(code);
    if (sharedSet == null) return false;

    _loadSharedChordSet(sharedSet);
    return true;
  }

  /// Private helper to load a shared chord set
  void _loadSharedChordSet(SharedChordSet sharedSet) {
    if (_currentProgression.isNotEmpty) {
      final historyEntry = HistoryEntry(
        progression: List.from(_currentProgression),
        key: _currentKey,
        genre: _genre,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      _progressionHistory.insert(0, historyEntry);
      if (_progressionHistory.length > maxHistoryLength) {
        _progressionHistory = _progressionHistory.sublist(0, maxHistoryLength);
      }
    }

    var loadedProgression = List<Chord>.from(sharedSet.progression);

    if (_useVoiceLeading) {
      loadedProgression = applyVoiceLeading(loadedProgression);
    }

    _currentProgression = loadedProgression;
    _currentKey = sharedSet.key;
    _genre = sharedSet.genre;
    _tempo = sharedSet.tempo;
    _isMinorKey =
        sharedSet.key.name.contains('m') && sharedSet.key.name.length > 1;
    _lastHarmonyScore =
        _harmonyEngine.score(loadedProgression, section: _harmonySection);

    if (_includeMelody) {
      _currentMelody = _generateMelodyNotes(
          _currentProgression, _genre, _rhythm, _currentKey);
    }
    if (_includeBass) {
      _currentBassLine = generateBassLine(
          _currentProgression, _bassStyle, _bassVariety, _rhythm);
    }

    notifyListeners();
  }
}
