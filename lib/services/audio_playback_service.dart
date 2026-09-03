import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../models/types.dart';
import '../utils/music_theory.dart';

/// UI-independent realtime playback layer for Chord Flow.
///
/// The service deliberately owns transport and synthesis state outside AppState
/// so the current waveform synth can later be swapped for SoundFonts/samples
/// without rewriting the generator UI or producer engine.
class AudioPlaybackService extends ChangeNotifier {
  AudioPlaybackService._();

  static final AudioPlaybackService instance = AudioPlaybackService._();

  final SoLoud _engine = SoLoud.instance;
  final Map<int, AudioSource> _noteSources = <int, AudioSource>{};
  final Set<SoundHandle> _activeHandles = <SoundHandle>{};

  bool _isReady = false;
  bool _isPlaying = false;
  bool _looping = false;
  int _transportGeneration = 0;
  int _bpm = 96;
  double _masterVolume = 0.72;
  double _chordVolume = 0.72;
  int _strumMs = 18;

  bool get isReady => _isReady;
  bool get isPlaying => _isPlaying;
  bool get looping => _looping;
  int get bpm => _bpm;
  double get masterVolume => _masterVolume;
  double get chordVolume => _chordVolume;
  int get strumMs => _strumMs;

  Future<void> initialize() async {
    if (_isReady) return;
    if (!_engine.isInitialized) {
      await _engine.init(
        sampleRate: 48000,
        bufferSize: 1024,
        lowLatency: true,
      );
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

  void setMasterVolume(double value) {
    _masterVolume = value.clamp(0.0, 1.0);
    if (_engine.isInitialized) _engine.setGlobalVolume(_masterVolume);
    notifyListeners();
  }

  void setChordVolume(double value) {
    _chordVolume = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setStrumMs(int value) {
    _strumMs = value.clamp(0, 80);
    notifyListeners();
  }

  Future<void> auditionChord(
    Chord chord, {
    Duration duration = const Duration(milliseconds: 1150),
  }) async {
    await initialize();
    final midiNotes = _voicedMidiNotes(chord);
    await _playMidiChord(midiNotes, duration: duration, velocity: 0.92);
  }

  Future<void> playProgression(
    List<Chord> progression, {
    int beatsPerChord = 4,
  }) async {
    if (progression.isEmpty) return;
    await initialize();
    await stop();

    final generation = ++_transportGeneration;
    _isPlaying = true;
    notifyListeners();

    do {
      for (final chord in progression) {
        if (generation != _transportGeneration) return;
        final chordDuration = Duration(
          milliseconds: ((60000 / _bpm) * beatsPerChord).round(),
        );
        final release = Duration(
          milliseconds: max(220, chordDuration.inMilliseconds - 90),
        );
        await _playMidiChord(
          _voicedMidiNotes(chord),
          duration: release,
          velocity: 0.82,
        );
        final remaining = chordDuration - release;
        if (remaining > Duration.zero) await Future<void>.delayed(remaining);
      }
    } while (_looping && generation == _transportGeneration);

    if (generation == _transportGeneration) {
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _transportGeneration++;
    final handles = List<SoundHandle>.from(_activeHandles);
    _activeHandles.clear();
    for (final handle in handles) {
      if (_engine.getIsValidVoiceHandle(handle)) {
        await _engine.stop(handle);
      }
    }
    if (_isPlaying) {
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> _playMidiChord(
    List<int> midiNotes, {
    required Duration duration,
    required double velocity,
  }) async {
    final handles = <SoundHandle>[];
    for (var i = 0; i < midiNotes.length; i++) {
      final source = await _sourceForMidi(midiNotes[i]);
      final emphasis = i == 0 ? 1.0 : 0.86;
      final pan = midiNotes.length <= 1
          ? 0.0
          : -0.24 + ((0.48 / (midiNotes.length - 1)) * i);
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
    for (final handle in handles) {
      if (_engine.getIsValidVoiceHandle(handle)) {
        _engine.fadeVolume(handle, 0.0, const Duration(milliseconds: 90));
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 95));
    for (final handle in handles) {
      _activeHandles.remove(handle);
      if (_engine.getIsValidVoiceHandle(handle)) await _engine.stop(handle);
    }
  }

  Future<AudioSource> _sourceForMidi(int midi) async {
    final existing = _noteSources[midi];
    if (existing != null) return existing;

    final source = await _engine.loadWaveform(
      WaveForm.triangle,
      true,
      0.20,
      0.035,
    );
    _engine.setWaveformFreq(source, _midiFrequency(midi));
    _noteSources[midi] = source;
    return source;
  }

  List<int> _voicedMidiNotes(Chord chord) {
    final notes = getChordNotes(chord);
    if (notes.isEmpty) return const <int>[60];

    final result = <int>[];
    var previous = 47;
    for (var i = 0; i < notes.length; i++) {
      final pitchClass = _pitchClass(notes[i]);
      var midi = 48 + pitchClass;
      while (midi <= previous) midi += 12;
      // Keep extensions from becoming piercing on phone speakers.
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
      'C': 0,
      'C#': 1,
      'Db': 1,
      'D': 2,
      'D#': 3,
      'Eb': 3,
      'E': 4,
      'F': 5,
      'F#': 6,
      'Gb': 6,
      'G': 7,
      'G#': 8,
      'Ab': 8,
      'A': 9,
      'A#': 10,
      'Bb': 10,
      'B': 11,
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
    _noteSources.clear();
    super.dispose();
  }
}
