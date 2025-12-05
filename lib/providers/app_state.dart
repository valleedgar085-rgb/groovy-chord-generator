/// Groovy Chord Generator
/// App State Provider
/// Version 2.5

import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/types.dart';
import '../models/constants.dart';
import '../utils/music_theory.dart';

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

      chords = degreeSequence.map((degree) {
        var chord = getChordFromDegree(root, degree, isMinor, scale);
        if (complexityConfig.useExtensions && Random().nextDouble() > 0.5) {
          final extensions = profile.chordTypes.where((t) =>
            t.name.contains('7') || t.name.contains('9') ||
            t.name.contains('sus') || t.name.contains('add')
          ).toList();
          if (extensions.isNotEmpty && Random().nextDouble() > 0.6) {
            chord = chord.copyWith(type: randomChoice(extensions));
          }
        }
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

    while (progression.length < targetLength) {
      final insertIndex = randomInt(0, progression.length);
      final newChord = randomChoice(['ii', 'IV', 'V', 'vi', 'iii']);
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
        final useChordTone = Random().nextDouble() > 0.3;
        final sourcePool = useChordTone ? chordTones : scaleNotes;

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
}
