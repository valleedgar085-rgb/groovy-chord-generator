import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../models/types.dart';
import '../utils/music_theory.dart';

enum SynthCharacter { warm, clean, analog }

extension SynthCharacterLabel on SynthCharacter {
  String get label {
    switch (this) {
      case SynthCharacter.warm:
        return 'Warm';
      case SynthCharacter.clean:
        return 'Clean';
      case SynthCharacter.analog:
        return 'Analog';
    }
  }
}

class AudioPlaybackService extends ChangeNotifier {
  AudioPlaybackService._();

  static final AudioPlaybackService instance = AudioPlaybackService._();

  final SoLoud _engine = SoLoud.instance;
  final Map<String, AudioSource> _noteSources = <String, AudioSource>{};
  final Map<int, AudioSource> _bassSources = <int, AudioSource>{};
  final Set<SoundHandle> _activeHandles = <SoundHandle>{};

  bool _isReady = false;
  bool _isPlaying = false;
  bool _looping = false;
  bool _bassEnabled = true;
  int _transportGeneration = 0;
  int _activeChordIndex = -1;
  int _bpm = 96;
  double _masterVolume = 0.72;
  double _chordVolume = 0.72;
  double _bassVolume = 0.42;
  double _stereoWidth = 0.65;
  int _strumMs = 18;
  SynthCharacter _synthCharacter = SynthCharacter.warm;

  bool get isReady => _isReady;
  bool get isPlaying => _isPlaying;
  bool get looping => _looping;
  bool get bassEnabled => _bassEnabled;
  int get activeChordIndex => _activeChordIndex;
  int get bpm => _bpm;
  double get masterVolume => _masterVolume;
  double get chordVolume => _chordVolume;
  double get bassVolume => _bassVolume;
  double get stereoWidth => _stereoWidth;
  int get strumMs => _strumMs;
  SynthCharacter get synthCharacter => _synthCharacter;

  Future<void> initialize() async {
    if (_isReady) return;
    if (!_engine.isInitialized) {
      await _engine.init(sampleRate: 48000, bufferSize: 1024, lowLatency: true);
    }
    _engine.setGlobalVolume(_masterVolume);
    _isReady = true;
    notifyListeners();
  }

  void setBpm(int value) {
    _bpm = value.clamp(55, 180);
    notifyListeners();
  }

  void setLooping(bool value) {
    _looping = value;
    notifyListeners();
  }

  void setBassEnabled(bool value) {
    _bassEnabled = value;
    notifyListeners();
  }

  void setMasterVolume(double value) {
    _masterVolume = value.clamp(0.0, 1.0);
    if (_engine.isInitialized) _engine.setGlobalVolume(_masterVolume);
    notifyListeners();
  }

  void setChordVolume(double value) {
    _chordVolume = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setBassVolume(double value) {
    _bassVolume = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setStereoWidth(double value) {
    _stereoWidth = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setStrumMs(int value) {
    _strumMs = value.clamp(0, 80);
    notifyListeners();
  }

  void setSynthCharacter(SynthCharacter value) {
    _synthCharacter = value;
    notifyListeners();
  }

  Future<void> auditionChord(Chord chord, {
    Duration duration = const Duration(milliseconds: 1150),
  }) async {
    await initialize();
    await _playLayeredChord(
      _voicedMidiNotes(chord),
      duration: duration,
      velocity: 0.92,
      includeBass: false,
    );
  }

  Future<void> playProgression(List<Chord> progression, {
    int beatsPerChord = 4,
  }) async {
    if (progression.isEmpty) return;
    await initialize();
    await stop();

    final generation = ++_transportGeneration;
    _isPlaying = true;
    notifyListeners();

    do {
      for (var index = 0; index < progression.length; index++) {
        if (generation != _transportGeneration) return;
        _activeChordIndex = index;
        notifyListeners();

        final chordDuration = Duration(
          milliseconds: ((60000 / _bpm) * beatsPerChord).round(),
        );
        final release = Duration(
          milliseconds: max(220, chordDuration.inMilliseconds - 90),
        );
        await _playLayeredChord(
          _voicedMidiNotes(progression[index]),
          duration: release,
          velocity: 0.82,
          includeBass: _bassEnabled,
          generation: generation,
        );
        final remaining = chordDuration - release;
        if (remaining > Duration.zero) await Future<void>.delayed(remaining);
      }
    } while (_looping && generation == _transportGeneration);

    if (generation == _transportGeneration) {
      _isPlaying = false;
      _activeChordIndex = -1;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _transportGeneration++;
    final handles = List<SoundHandle>.from(_activeHandles);
    _activeHandles.clear();
    for (final handle in handles) {
      if (_engine.getIsValidVoiceHandle(handle)) await _engine.stop(handle);
    }
    final changed = _isPlaying || _activeChordIndex != -1;
    _isPlaying = false;
    _activeChordIndex = -1;
    if (changed) notifyListeners();
  }

  Future<void> _playLayeredChord(List<int> midiNotes, {
    required Duration duration,
    required double velocity,
    required bool includeBass,
    int? generation,
  }) async {
    final handles = <SoundHandle>[];
    final hasBeenCancelled = () =>
        generation != null && generation != _transportGeneration;

    Future<void> stopHandles() async {
      for (final handle in handles) {
        _activeHandles.remove(handle);
        if (_engine.getIsValidVoiceHandle(handle)) await _engine.stop(handle);
      }
    }

    if (includeBass && midiNotes.isNotEmpty) {
      final bassSource = await _bassSourceForMidi(_bassMidiFor(midiNotes.first));
      if (hasBeenCancelled()) {
        await stopHandles();
        return;
      }
      final bassHandle = _engine.play(
        bassSource,
        volume: (_bassVolume * velocity).clamp(0.0, 1.0),
      );
      handles.add(bassHandle);
      _activeHandles.add(bassHandle);
    }

    for (var i = 0; i < midiNotes.length; i++) {
      if (hasBeenCancelled()) {
        await stopHandles();
        return;
      }
      final source = await _sourceForMidi(midiNotes[i]);
      if (hasBeenCancelled()) {
        await stopHandles();
        return;
      }
      final emphasis = i == 0 ? 1.0 : 0.86;
      final maxPan = 0.34 * _stereoWidth;
      final pan = midiNotes.length <= 1
          ? 0.0
          : -maxPan + (((maxPan * 2) / (midiNotes.length - 1)) * i);
      final handle = _engine.play(
        source,
        volume: (_chordVolume * velocity * emphasis).clamp(0.0, 1.0),
        pan: pan,
      );
      handles.add(handle);
      _activeHandles.add(handle);
      if (_strumMs > 0 && i + 1 < midiNotes.length) {
        await Future<void>.delayed(Duration(milliseconds: _strumMs));
      }
    }

    await Future<void>.delayed(duration);
    if (hasBeenCancelled()) {
      await stopHandles();
      return;
    }
    for (final handle in handles) {
      if (_engine.getIsValidVoiceHandle(handle)) {
        _engine.fadeVolume(handle, 0.0, const Duration(milliseconds: 110));
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 115));
    await stopHandles();
  }

  Future<AudioSource> _sourceForMidi(int midi) async {
    final key = '${_synthCharacter.name}:$midi';
    final existing = _noteSources[key];
    if (existing != null) return existing;
    final source = await _engine.loadWaveform(
      _waveformForCharacter(_synthCharacter),
      true,
      _scaleForCharacter(_synthCharacter),
      _detuneForCharacter(_synthCharacter),
    );
    _engine.setWaveformFreq(source, _midiFrequency(midi));
    _noteSources[key] = source;
    return source;
  }

  Future<AudioSource> _bassSourceForMidi(int midi) async {
    final existing = _bassSources[midi];
    if (existing != null) return existing;
    final source = await _engine.loadWaveform(WaveForm.sin, true, 0.10, 0.01);
    _engine.setWaveformFreq(source, _midiFrequency(midi));
    _bassSources[midi] = source;
    return source;
  }

  WaveForm _waveformForCharacter(SynthCharacter character) {
    switch (character) {
      case SynthCharacter.warm:
        return WaveForm.triangle;
      case SynthCharacter.clean:
        return WaveForm.sin;
      case SynthCharacter.analog:
        return WaveForm.fSaw;
    }
  }

  double _scaleForCharacter(SynthCharacter character) {
    switch (character) {
      case SynthCharacter.warm:
        return 0.20;
      case SynthCharacter.clean:
        return 0.08;
      case SynthCharacter.analog:
        return 0.13;
    }
  }

  double _detuneForCharacter(SynthCharacter character) {
    switch (character) {
      case SynthCharacter.warm:
        return 0.035;
      case SynthCharacter.clean:
        return 0.0;
      case SynthCharacter.analog:
        return 0.055;
    }
  }

  int _bassMidiFor(int midi) {
    var value = midi;
    while (value > 47) value -= 12;
    while (value < 36) value += 12;
    return value;
  }

  List<int> _voicedMidiNotes(Chord chord) {
    final notes = getChordNotes(chord);
    if (notes.isEmpty) return const <int>[60];
    final result = <int>[];
    var previous = 47;
    for (final note in notes) {
      final pitchClass = _pitchClass(note);
      var midi = 48 + pitchClass;
      while (midi <= previous) midi += 12;
      while (midi > 76) midi -= 12;
      if (result.contains(midi)) midi += 12;
      result.add(midi);
      previous = midi;
    }
    result.sort();
    return result;
  }

  int _pitchClass(String note) {
    const pitchClasses = <String, int>{
      'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3,
      'E': 4, 'F': 5, 'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8,
      'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11,
    };
    final normalized = note.length >= 2 && (note[1] == '#' || note[1] == 'b')
        ? note.substring(0, 2)
        : note.substring(0, 1);
    return pitchClasses[normalized] ?? 0;
  }

  double _midiFrequency(int midi) =>
      440.0 * pow(2.0, (midi - 69) / 12.0).toDouble();

  @override
  void dispose() {
    unawaited(stop());
    for (final source in _noteSources.values) {
      unawaited(_engine.disposeSource(source));
    }
    for (final source in _bassSources.values) {
      unawaited(_engine.disposeSource(source));
    }
    _noteSources.clear();
    _bassSources.clear();
    super.dispose();
  }
}
