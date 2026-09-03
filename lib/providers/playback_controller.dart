import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/types.dart';
import '../services/studio_audio_engine.dart';

/// UI-facing transport state for chord and progression playback.
class PlaybackController extends ChangeNotifier {
  PlaybackController({StudioAudioEngine? engine})
      : _engine = engine ?? StudioAudioEngine();

  final StudioAudioEngine _engine;
  bool _isPlaying = false;
  bool _isInitializing = false;
  bool _audioUnavailable = false;
  int _currentChordIndex = -1;
  double _tempo = 96;
  int _playbackToken = 0;

  bool get isPlaying => _isPlaying;
  bool get isInitializing => _isInitializing;
  bool get audioUnavailable => _audioUnavailable;
  int get currentChordIndex => _currentChordIndex;
  double get tempo => _tempo;

  Future<bool> ensureReady() async {
    if (_engine.isReady) return true;
    if (_audioUnavailable) return false;
    _isInitializing = true;
    notifyListeners();
    final ready = await _engine.initialize();
    _isInitializing = false;
    _audioUnavailable = !ready;
    notifyListeners();
    return ready;
  }

  void setTempo(double value) {
    _tempo = value.clamp(60.0, 160.0).toDouble();
    notifyListeners();
  }

  Future<void> previewChord(Chord chord, int index) async {
    final token = ++_playbackToken;
    _isPlaying = false;
    _currentChordIndex = index;
    notifyListeners();
    if (!await ensureReady() || token != _playbackToken) return;
    await _engine.playChord(
      chord,
      duration: const Duration(milliseconds: 950),
    );
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (token == _playbackToken) {
      _currentChordIndex = -1;
      notifyListeners();
    }
  }

  Future<void> playProgression(List<Chord> progression) async {
    if (progression.isEmpty) return;
    if (_isPlaying) {
      await stop();
      return;
    }

    final token = ++_playbackToken;
    if (!await ensureReady() || token != _playbackToken) return;

    _isPlaying = true;
    notifyListeners();
    final beat = Duration(milliseconds: (60000 / _tempo).round());
    final chordLength = Duration(milliseconds: (beat.inMilliseconds * 1.65).round());

    for (var i = 0; i < progression.length; i++) {
      if (token != _playbackToken) break;
      _currentChordIndex = i;
      notifyListeners();
      await _engine.playChord(
        progression[i],
        duration: chordLength,
        velocity: i == 0 ? 0.9 : 0.82,
      );
      await Future<void>.delayed(beat * 2);
    }

    if (token == _playbackToken) {
      _isPlaying = false;
      _currentChordIndex = -1;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _playbackToken++;
    _isPlaying = false;
    _currentChordIndex = -1;
    notifyListeners();
    await _engine.stop(fade: const Duration(milliseconds: 40));
  }

  @override
  void dispose() {
    unawaited(_engine.dispose());
    super.dispose();
  }
}
