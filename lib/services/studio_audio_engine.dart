import 'dart:math' as math;

import 'package:flutter_soloud/flutter_soloud.dart';

import '../models/types.dart';
import '../utils/music_theory.dart';

/// Small realtime synth backend for Chord Flow's interactive playback.
///
/// UI and producer code talk to this service through musical [Chord] objects;
/// no screen needs to know about oscillator handles or note frequencies. That
/// keeps the backend replaceable by SoundFonts or a native sampler later.
class StudioAudioEngine {
  StudioAudioEngine();

  static const int _maxVoices = 6;
  final SoLoud _soloud = SoLoud.instance;
  final List<AudioSource> _voices = <AudioSource>[];
  final List<SoundHandle> _activeHandles = <SoundHandle>[];
  bool _ready = false;
  bool _failed = false;

  bool get isReady => _ready;
  bool get hasFailed => _failed;

  Future<bool> initialize() async {
    if (_ready) return true;
    if (_failed) return false;
    try {
      if (!_soloud.isInitialized) {
        await _soloud.init(
          lowLatency: true,
          bufferSize: 1024,
          androidAAudioAttributes: AndroidAAudioAttributes.mediaMusic,
        );
      }
      for (var i = 0; i < _maxVoices; i++) {
        _voices.add(
          await _soloud.loadWaveform(
            WaveForm.triangle,
            false,
            1.0,
            0.0,
          ),
        );
      }
      _soloud.setGlobalVolume(0.72);
      _ready = true;
      return true;
    } catch (_) {
      _failed = true;
      return false;
    }
  }

  /// Audition one chord. A short fade avoids clicks when changing harmony.
  Future<void> playChord(
    Chord chord, {
    Duration duration = const Duration(milliseconds: 900),
    double velocity = 0.82,
  }) async {
    if (!await initialize()) return;
    await stop(fade: const Duration(milliseconds: 28));

    final midiNotes = chordMidiNotes(chord);
    final count = math.min(midiNotes.length, _voices.length);
    for (var i = 0; i < count; i++) {
      final source = _voices[i];
      _soloud.setWaveformFreq(source, midiToFrequency(midiNotes[i]));
      final handle = _soloud.play(
        source,
        volume: (velocity / math.max(1, count)) * 1.7,
        pan: count <= 1 ? 0 : (-0.18 + (0.36 * i / math.max(1, count - 1))),
      );
      _activeHandles.add(handle);
      _soloud.fadeVolume(
        handle,
        0.0,
        duration - const Duration(milliseconds: 30),
      );
      _soloud.scheduleStop(handle, duration);
    }
  }

  Future<void> stop({Duration fade = Duration.zero}) async {
    final handles = List<SoundHandle>.from(_activeHandles);
    _activeHandles.clear();
    for (final handle in handles) {
      try {
        if (fade > Duration.zero) {
          _soloud.fadeVolume(handle, 0.0, fade, thenStop: true);
        } else {
          await _soloud.stop(handle);
        }
      } catch (_) {
        // Playback cleanup must never break generation or navigation.
      }
    }
  }

  Future<void> dispose() async {
    await stop();
    for (final source in List<AudioSource>.from(_voices)) {
      try {
        await _soloud.disposeSource(source);
      } catch (_) {}
    }
    _voices.clear();
    _ready = false;
  }

  /// Converts a Chord Flow chord to a compact ascending keyboard voicing.
  List<int> chordMidiNotes(Chord chord) {
    final names = getChordNotes(chord);
    if (names.isEmpty) return const <int>[];

    final result = <int>[];
    var previous = 47;
    for (final name in names.take(_maxVoices)) {
      var midi = _pitchClass(name) + 48;
      while (midi <= previous) {
        midi += 12;
      }
      // Keep interactive voicings centered in a comfortable keyboard range.
      while (midi > 79) {
        midi -= 12;
      }
      if (midi <= previous) midi += 12;
      result.add(midi);
      previous = midi;
    }
    return result;
  }

  double midiToFrequency(int midi) =>
      440.0 * math.pow(2.0, (midi - 69) / 12.0).toDouble();

  int _pitchClass(String note) {
    const pitchClasses = <String, int>{
      'C': 0,
      'C#': 1,
      'Db': 1,
      'D': 2,
      'D#': 3,
      'Eb': 3,
      'E': 4,
      'Fb': 4,
      'E#': 5,
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
      'Cb': 11,
      'B#': 0,
    };
    return pitchClasses[note] ?? pitchClasses[note.replaceAll(RegExp(r'\d'), '')] ?? 0;
  }
}
