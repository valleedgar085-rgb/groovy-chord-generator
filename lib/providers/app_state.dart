/// Groovy Chord Generator
/// App State Provider
/// Version 2.5

import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/types.dart';
import '../models/constants.dart';
import '../utils/music_theory.dart';
import '../services/firebase_favorites_service.dart';
import '../services/share_service.dart';

class AppState extends ChangeNotifier {
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
  
  // Favorites state
  List<FavoriteProgression> _favorites = [];
  bool _favoritesLoading = false;
  final Random _melodyRandom = Random();

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

  void setIsPlaying(bool value) {
    _isPlaying = value;
    notifyListeners();
  }

  // Toggle chord lock
  void toggleChordLock(int index) {
    final existingIndex = _lockedChords.indexWhere((lc) => lc.index == index);
    if (existingIndex != -1) {
      final existing = _lockedChords[existingIndex];
      _lockedChords[existingIndex] = existing.copyWith(locked: !existing.locked);
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

  // Generate progression
  void generateProgression() {
    // Save current progression to history
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

    final keyString = keyNameToString(_currentKey);
    final keyInfo = parseKey(keyString);
    final root = keyInfo['root'] as String;
    final isMinor = keyInfo['isMinor'] as bool;
    final profile = genreProfiles[_genre]!;
    final complexityConfig = complexitySettings[_complexity]!;

    List<Chord> chords;

    if (_useFunctionalHarmony) {
      chords = generateFunctionalProgression(
        root,
        isMinor,
        complexityConfig.chordCount[1],
        _currentMood,
      );
    } else {
      // Original progression generation
      final baseProgression = randomChoice(profile.progressions);
      final degreeSequence = _buildDegreeSequence(baseProgression, complexityConfig);
      final scale = isMinor ? ScaleName.minor : profile.scale;

      chords = degreeSequence.asMap().entries.map((entry) {
        final index = entry.key;
        final degree = entry.value;
        var chord = getChordFromDegree(root, degree, isMinor, scale);
        
        // Smart chord type selection based on variety and complexity
        if (complexityConfig.useExtensions) {
          final varietyFactor = _chordVariety / 100.0;
          final extensionChance = 0.3 + (varietyFactor * 0.4); // 30-70% chance
          
          if (Random().nextDouble() < extensionChance) {
            final extensions = profile.chordTypes.where((t) =>
              t.name.contains('7') || t.name.contains('9') ||
              t.name.contains('sus') || t.name.contains('add')
            ).toList();
            
            if (extensions.isNotEmpty) {
              // Weight selection towards 7th chords for smoother sound
              final weights = <ChordTypeName, double>{};
              for (final ext in extensions) {
                if (ext.name.contains('7') && !ext.name.contains('9')) {
                  weights[ext] = 0.5; // Higher weight for 7th chords
                } else if (ext.name.contains('9')) {
                  weights[ext] = 0.25; // Medium weight for 9th chords
                } else {
                  weights[ext] = 0.25; // Lower weight for sus/add
                }
              }
              
              // Weighted random selection
              final totalWeight = weights.values.fold(0.0, (sum, w) => sum + w);
              var randomValue = Random().nextDouble() * totalWeight;
              
              for (final weightEntry in weights.entries) {
                randomValue -= weightEntry.value;
                if (randomValue <= 0) {
                  chord = chord.copyWith(type: weightEntry.key);
                  break;
                }
              }
            }
          }
        }
        
        // Apply strategic extensions based on position
        chord = addStrategicExtensions(chord, index, degreeSequence.length, _chordVariety);
        
        return applyGenreVoicing(chord, _genre);
      }).toList();
    }

    // Preserve locked chords
    for (final lc in _lockedChords) {
      if (lc.locked && lc.index < _currentProgression.length && lc.index < chords.length) {
        chords[lc.index] = _currentProgression[lc.index];
      }
    }

    if (_useModalInterchange && (_complexity == ComplexityLevel.complex || _complexity == ComplexityLevel.advanced)) {
      chords = applyModalInterchange(chords, root, isMinor);
    }

    if (_useAdvancedTheory && (_complexity == ComplexityLevel.complex || _complexity == ComplexityLevel.advanced)) {
      chords = applyAdvancedSubstitutions(chords, root, isMinor);
    }

    // Apply spice level
    chords = applySpiceToProgression(chords, _spiceLevel);

    // Apply groove template
    chords = applyGrooveToProgression(chords, _grooveTemplate);

    if (_useVoiceLeading) {
      chords = applyVoiceLeading(chords);
    }

    _currentProgression = chords;
    _isMinorKey = isMinor;

    // Generate melody if enabled
    if (_includeMelody) {
      _currentMelody = _generateMelodyNotes(chords, _genre, _rhythm, _currentKey);
    } else {
      _currentMelody = [];
    }

    // Generate bass line if enabled
    if (_includeBass) {
      _currentBassLine = generateBassLine(chords, _bassStyle, _bassVariety, _rhythm);
    } else {
      _currentBassLine = [];
    }

    notifyListeners();
  }

  List<String> _buildDegreeSequence(List<String> baseProgression, ComplexitySetting config) {
    final progression = List<String>.from(baseProgression);
    final targetLength = randomInt(config.chordCount[0], config.chordCount[1]);

    // Use intelligent variation based on chord variety setting
    if (_chordVariety > 0) {
      // Apply smart passing chords
      var enhanced = addPassingChords(progression, _chordVariety);
      
      // Apply approach chords for higher variety
      enhanced = addApproachChords(enhanced, _chordVariety);
      
      // Apply intelligent substitutions
      enhanced = applyIntelligentSubstitutions(enhanced, _chordVariety, _isMinorKey);
      
      // Optimize tension/resolution flow
      enhanced = optimizeTensionFlow(enhanced, _isMinorKey);
      
      // Trim to target length if needed
      while (enhanced.length > targetLength && enhanced.length > 3) {
        // Only remove from middle if we have enough chords
        final removeIndex = enhanced.length > 3 
            ? randomInt(1, enhanced.length - 2) 
            : enhanced.length - 1;
        enhanced.removeAt(removeIndex);
      }
      
      return enhanced;
    }

    // Fallback to simple extension if needed
    while (progression.length < targetLength) {
      final insertIndex = randomInt(0, progression.length);
      final newChord = randomChoice(_isMinorKey 
        ? ['ii', 'iv', 'V', 'VI', 'III', 'VII']
        : ['ii', 'IV', 'V', 'vi', 'iii']);
      progression.insert(insertIndex, newChord);
    }

    return progression;
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
      final chordTones = chordTypes[chord.type]!.intervals.map((interval) =>
        transposeNote(chord.root, interval)
      ).toList();

      for (var i = 0; i < notesPerChord; i++) {
        final shouldUseChordTone = _melodyRandom.nextDouble() > 0.3;
        final sourcePool = shouldUseChordTone ? chordTones : scaleNotes;

        final note = randomChoice(sourcePool);
        final duration = randomChoice(rhythmPattern.durations);
        final velocity = rhythmPattern.dynamics[i % rhythmPattern.dynamics.length];

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

    // Generate new progression with preset settings
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
    }
    return result;
  }

  /// Load a favorite progression
  void loadFavorite(FavoriteProgression favorite) {
    // Save current to history first
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
    _isMinorKey = favorite.key.name.contains('m') && favorite.key.name.length > 1;

    final profile = genreProfiles[favorite.genre];
    if (profile != null) {
      _tempo = profile.tempo;
    }

    // Regenerate melody and bass if enabled
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
    // Save current to history first
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
    _isMinorKey = sharedSet.key.name.contains('m') && sharedSet.key.name.length > 1;

    // Regenerate melody and bass if enabled
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
