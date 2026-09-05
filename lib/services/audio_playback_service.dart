import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../engine/song_timeline.dart';
import '../engine/timeline_playback_plan.dart';
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

/// Low-latency audition, progression and full-song timeline playback.
///
/// Phase 4.5 schedules SongTimeline events on SoLoud's engine clock. Canonical
/// composition beats remain untouched; PerformanceIntent supplies the performed
/// attack, gate and velocity values used here.
class AudioPlaybackService extends ChangeNotifier {
  AudioPlaybackService._();

  static final AudioPlaybackService instance = AudioPlaybackService._();

  final SoLoud _engine = SoLoud.instance;
  final TimelinePlaybackPlanner _timelinePlanner = const TimelinePlaybackPlanner();
  final Map<String, AudioSource> _noteSources = <String, AudioSource>{};
  final Map<int, AudioSource> _melodySources = <int, AudioSource>{};
  final Map<int, AudioSource> _bassSources = <int, AudioSource>{};
  final Set<SoundHandle> _activeHandles = <SoundHandle>{};
  final Set<TimelineTrackType> _mutedTracks = <TimelineTrackType>{};
  final Set<TimelineTrackType> _soloTracks = <TimelineTrackType>{};

  bool _isReady = false;
  bool _isPlaying = false;
  bool _isTimelinePlayback = false;
  bool _looping = false;
  bool _bassEnabled = true;
  int _playbackSession = 0;
  int _activeChordIndex = -1;
  int _bpm = 96;
  double _masterVolume = 0.72;
  double _chordVolume = 0.72;
  double _melodyVolume = 0.58;
  double _bassVolume = 0.42;
  double _stereoWidth = 0.65;
  int _strumMs = 18;
  SynthCharacter _synthCharacter = SynthCharacter.warm;

  SongTimeline? _activeTimeline;
  TimelinePlaybackPlan? _loopPlan;
  Timer? _playheadTimer;
  Duration _timelineEngineAnchor = Duration.zero;
  double _songBeat = 0;
  double _timelineInitialBeat = 0;
  double _timelineRangeStart = 0;
  double _timelineRangeEnd = 0;
  String? _activeSectionId;
  int _scheduledLoopCycles = 0;

  bool get isReady => _isReady;
  bool get isPlaying => _isPlaying;
  bool get isTimelinePlayback => _isTimelinePlayback;
  bool get looping => _looping;
  bool get bassEnabled => _bassEnabled;
  int get activeChordIndex => _activeChordIndex;
  int get bpm => _bpm;
  double get masterVolume => _masterVolume;
  double get chordVolume => _chordVolume;
  double get melodyVolume => _melodyVolume;
  double get bassVolume => _bassVolume;
  double get stereoWidth => _stereoWidth;
  int get strumMs => _strumMs;
  SynthCharacter get synthCharacter => _synthCharacter;
  double get songBeat => _songBeat;
  double get timelineRangeStart => _timelineRangeStart;
  double get timelineRangeEnd => _timelineRangeEnd;
  String? get activeSectionId => _activeSectionId;
  Set<TimelineTrackType> get mutedTracks => Set.unmodifiable(_mutedTracks);
  Set<TimelineTrackType> get soloTracks => Set.unmodifiable(_soloTracks);

  bool isTrackMuted(TimelineTrackType track) => _mutedTracks.contains(track);
  bool isTrackSoloed(TimelineTrackType track) => _soloTracks.contains(track);

  Future<void> initialize() async {
    if (_isReady) return;
    if (!_engine.isInitialized) {
      await _engine.init(sampleRate: 48000, bufferSize: 1024, lowLatency: true);
    }
    _engine.setMaxActiveVoiceCount(64);
    _engine.setGlobalVolume(_masterVolume);
    _isReady = true;
    notifyListeners();
  }

  void setBpm(int value) {
    final next = value.clamp(55, 180);
    if (_bpm == next) return;
    _bpm = next;
    notifyListeners();
    if (_isTimelinePlayback && _isPlaying && _activeTimeline != null) {
      unawaited(_restartActiveTimeline());
    }
  }

  void setLooping(bool value) {
    if (_looping == value) return;
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

  void setMelodyVolume(double value) {
    _melodyVolume = value.clamp(0.0, 1.0);
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

  void setTrackMuted(TimelineTrackType track, bool muted) {
    final changed = muted ? _mutedTracks.add(track) : _mutedTracks.remove(track);
    if (!changed) return;
    notifyListeners();
    if (_isTimelinePlayback && _isPlaying && _activeTimeline != null) {
      unawaited(_restartActiveTimeline());
    }
  }

  void setTrackSoloed(TimelineTrackType track, bool soloed) {
    final changed = soloed ? _soloTracks.add(track) : _soloTracks.remove(track);
    if (!changed) return;
    notifyListeners();
    if (_isTimelinePlayback && _isPlaying && _activeTimeline != null) {
      unawaited(_restartActiveTimeline());
    }
  }

  void clearTrackMix() {
    if (_mutedTracks.isEmpty && _soloTracks.isEmpty) return;
    _mutedTracks.clear();
    _soloTracks.clear();
    notifyListeners();
    if (_isTimelinePlayback && _isPlaying && _activeTimeline != null) {
      unawaited(_restartActiveTimeline());
    }
  }

  /// Tapping a chord starts a new bounded playback session. It intentionally
  /// cancels a running song/progression or previous audition.
  Future<void> auditionChord(
    Chord chord, {
    Duration duration = const Duration(milliseconds: 1150),
  }) async {
    await initialize();
    await stop();
    final session = ++_playbackSession;
    await _playLayeredChord(
      _voicedMidiNotes(chord),
      duration: duration,
      velocity: 0.92,
      includeBass: false,
      session: session,
    );
  }

  /// Legacy single-progression transport retained for Progression mode.
  Future<void> playProgression(
    List<Chord> progression, {
    int beatsPerChord = 4,
  }) async {
    if (progression.isEmpty) return;
    await initialize();
    await stop();

    final session = ++_playbackSession;
    _isPlaying = true;
    _isTimelinePlayback = false;
    notifyListeners();

    do {
      for (var index = 0; index < progression.length; index++) {
        if (!_sessionIsActive(session)) return;
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
          session: session,
        );
        if (!_sessionIsActive(session)) return;
        final remaining = chordDuration - release;
        if (remaining > Duration.zero) {
          await Future<void>.delayed(remaining);
        }
      }
    } while (_looping && _sessionIsActive(session));

    if (_sessionIsActive(session)) {
      _isPlaying = false;
      _activeChordIndex = -1;
      notifyListeners();
    }
  }

  /// Plays the complete song from [startBeat] to the end without looping.
  Future<void> playFullSong(
    SongTimeline timeline, {
    double startBeat = 0,
  }) {
    return playTimeline(
      timeline,
      startBeat: startBeat,
      rangeStartBeat: 0,
      endBeat: timeline.totalBeats,
      loop: false,
    );
  }

  /// Plays one arrangement section. With [loop] enabled the first partial
  /// fragment (after a live restart/seek) resolves to the section end, then
  /// subsequent cycles restart at the exact section boundary.
  Future<void> playSection(
    SongTimeline timeline,
    String sectionId, {
    bool loop = false,
    double? startBeat,
  }) async {
    final section = timeline.sectionById(sectionId);
    if (section == null) return;
    final initial = (startBeat ?? section.startBeat)
        .clamp(section.startBeat, section.endBeat)
        .toDouble();
    await playTimeline(
      timeline,
      startBeat: initial,
      rangeStartBeat: section.startBeat,
      endBeat: section.endBeat,
      loop: loop,
    );
  }

  /// Schedules a performed timeline range on SoLoud's absolute engine clock.
  Future<void> playTimeline(
    SongTimeline timeline, {
    double startBeat = 0,
    double? rangeStartBeat,
    double? endBeat,
    bool loop = false,
  }) async {
    if (timeline.totalBeats <= 0) return;
    await initialize();

    final initial = startBeat.clamp(0.0, timeline.totalBeats).toDouble();
    final rangeStart = (rangeStartBeat ?? initial)
        .clamp(0.0, initial)
        .toDouble();
    final rangeEnd = (endBeat ?? timeline.totalBeats)
        .clamp(initial, timeline.totalBeats)
        .toDouble();
    if (rangeEnd <= initial) return;

    final firstPlan = _timelinePlanner.build(
      timeline,
      startBeat: initial,
      endBeat: rangeEnd,
      mutedTracks: _mutedTracks,
      soloTracks: _soloTracks,
    );
    final loopPlan = loop
        ? _timelinePlanner.build(
            timeline,
            startBeat: rangeStart,
            endBeat: rangeEnd,
            mutedTracks: _mutedTracks,
            soloTracks: _soloTracks,
          )
        : null;

    await stop(resetTimelinePosition: false);
    await _preloadTimelinePlan(firstPlan);
    if (loopPlan != null) await _preloadTimelinePlan(loopPlan);

    final session = ++_playbackSession;
    _isPlaying = true;
    _isTimelinePlayback = true;
    _looping = loop;
    _activeTimeline = timeline;
    _timelineInitialBeat = initial;
    _timelineRangeStart = rangeStart;
    _timelineRangeEnd = rangeEnd;
    _songBeat = initial;
    _activeSectionId = timeline.sectionAtBeat(initial)?.id;
    _loopPlan = loopPlan;
    _scheduledLoopCycles = 0;
    _activeChordIndex = -1;

    // Leave a short scheduling runway so every source can land on the native
    // engine clock before the first attack is due.
    _timelineEngineAnchor =
        _engine.getEngineTime() + const Duration(milliseconds: 120);
    _schedulePlanAt(firstPlan, _timelineEngineAnchor);

    if (loopPlan != null && loopPlan.durationBeats > 0) {
      final firstEnd = _timelineEngineAnchor + _durationForBeats(firstPlan.durationBeats);
      _schedulePlanAt(loopPlan, firstEnd);
      _scheduledLoopCycles = 1;
    }

    _startTimelinePlayhead(session, firstPlan);
    notifyListeners();
  }

  /// Moves the full-song playhead. If [resume] is true playback is rescheduled
  /// from the requested beat; otherwise only the visible playhead moves.
  Future<void> seekTimeline(
    SongTimeline timeline,
    double beat, {
    bool resume = true,
  }) async {
    final target = beat.clamp(0.0, timeline.totalBeats).toDouble();
    if (!resume) {
      _songBeat = target;
      _activeSectionId = timeline.sectionAtBeat(target)?.id;
      notifyListeners();
      return;
    }
    await playFullSong(timeline, startBeat: target);
  }

  Future<void> _restartActiveTimeline() async {
    final timeline = _activeTimeline;
    if (timeline == null || !_isTimelinePlayback || !_isPlaying) return;
    final beat = _songBeat.clamp(_timelineRangeStart, _timelineRangeEnd).toDouble();
    final loop = _looping;
    final rangeStart = _timelineRangeStart;
    final rangeEnd = _timelineRangeEnd;
    await playTimeline(
      timeline,
      startBeat: beat,
      rangeStartBeat: rangeStart,
      endBeat: rangeEnd,
      loop: loop,
    );
  }

  /// Cancels current Dart/native playback and stops every live or future voice
  /// known to all waveform sources. Scheduled voices are included in handles.
  Future<void> stop({bool resetTimelinePosition = true}) async {
    _playbackSession++;
    _playheadTimer?.cancel();
    _playheadTimer = null;

    final handles = <SoundHandle>{..._activeHandles};
    for (final source in _noteSources.values) {
      handles.addAll(source.handles);
    }
    for (final source in _melodySources.values) {
      handles.addAll(source.handles);
    }
    for (final source in _bassSources.values) {
      handles.addAll(source.handles);
    }
    _activeHandles.clear();

    for (final handle in handles) {
      if (_engine.getIsValidVoiceHandle(handle)) {
        await _engine.stop(handle);
      }
    }

    final changed = _isPlaying || _activeChordIndex != -1 || _isTimelinePlayback;
    _isPlaying = false;
    _isTimelinePlayback = false;
    _activeChordIndex = -1;
    _activeSectionId = null;
    _loopPlan = null;
    _scheduledLoopCycles = 0;
    if (resetTimelinePosition) {
      _songBeat = 0;
      _timelineInitialBeat = 0;
      _timelineRangeStart = 0;
      _timelineRangeEnd = 0;
      _activeTimeline = null;
    }
    if (changed) notifyListeners();
  }

  void _startTimelinePlayhead(
    int session,
    TimelinePlaybackPlan firstPlan,
  ) {
    _playheadTimer?.cancel();
    _playheadTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!_sessionIsActive(session) || !_isTimelinePlayback || !_isPlaying) {
        _playheadTimer?.cancel();
        return;
      }

      final elapsedMicros =
          _engine.getEngineTime().inMicroseconds - _timelineEngineAnchor.inMicroseconds;
      if (elapsedMicros <= 0) {
        _songBeat = _timelineInitialBeat;
        notifyListeners();
        return;
      }

      final microsPerBeat = _microsPerBeat;
      final firstMicros = _durationForBeats(firstPlan.durationBeats).inMicroseconds;

      if (elapsedMicros < firstMicros) {
        _songBeat = (_timelineInitialBeat + (elapsedMicros / microsPerBeat))
            .clamp(_timelineInitialBeat, _timelineRangeEnd)
            .toDouble();
      } else if (_looping && _loopPlan != null && _loopPlan!.durationBeats > 0) {
        final loopMicros = _durationForBeats(_loopPlan!.durationBeats).inMicroseconds;
        final loopElapsed = elapsedMicros - firstMicros;
        final withinLoop = loopElapsed % loopMicros;
        final cycle = loopElapsed ~/ loopMicros;
        _songBeat = (_timelineRangeStart + (withinLoop / microsPerBeat))
            .clamp(_timelineRangeStart, _timelineRangeEnd)
            .toDouble();

        // Keep one complete loop cycle scheduled ahead to avoid Dart-timer gaps.
        final remainingInCycle = loopMicros - withinLoop;
        if (remainingInCycle <= 1500000 && _scheduledLoopCycles <= cycle + 1) {
          final nextCycleStart = _timelineEngineAnchor +
              Duration(
                microseconds: firstMicros + (loopMicros * (cycle + 1)),
              );
          _schedulePlanAt(_loopPlan!, nextCycleStart);
          _scheduledLoopCycles = cycle + 2;
        }
      } else {
        _songBeat = _timelineRangeEnd;
        _finishTimelinePlayback(session);
        return;
      }

      _activeSectionId = _activeTimeline?.sectionAtBeat(_songBeat)?.id;
      _pruneFinishedHandles();
      notifyListeners();
    });
  }

  void _finishTimelinePlayback(int session) {
    if (!_sessionIsActive(session)) return;
    _playheadTimer?.cancel();
    _playheadTimer = null;
    _isPlaying = false;
    _isTimelinePlayback = false;
    _activeSectionId = _activeTimeline?.sectionAtBeat(_timelineRangeEnd)?.id;
    _pruneFinishedHandles();
    notifyListeners();
  }

  Future<void> _preloadTimelinePlan(TimelinePlaybackPlan plan) async {
    final futures = <Future<AudioSource>>[];
    final seen = <String>{};
    for (final planned in plan.events) {
      for (final midi in planned.source.midiPitches) {
        final key = '${planned.source.track.name}:$midi:${_synthCharacter.name}';
        if (!seen.add(key)) continue;
        futures.add(_timelineSourceForMidi(planned.source.track, midi));
      }
    }
    if (futures.isNotEmpty) await Future.wait(futures);
  }

  void _schedulePlanAt(TimelinePlaybackPlan plan, Duration engineStart) {
    for (final planned in plan.events) {
      final sourceEvent = planned.source;
      final relativeBeat = planned.startBeat - plan.startBeat;
      final atTime = engineStart + _durationForBeats(relativeBeat);
      final eventDuration = _durationForBeats(planned.durationBeats);
      final safeDuration = eventDuration.inMilliseconds < 30
          ? const Duration(milliseconds: 30)
          : eventDuration;

      for (var pitchIndex = 0;
          pitchIndex < sourceEvent.midiPitches.length;
          pitchIndex++) {
        final midi = sourceEvent.midiPitches[pitchIndex];
        final source = _cachedTimelineSource(sourceEvent.track, midi);
        if (source == null) continue;
        final handle = _engine.playScheduled(
          source,
          atTime,
          duration: safeDuration,
          volume: _timelineVolume(sourceEvent, pitchIndex),
          pan: _timelinePan(sourceEvent, pitchIndex),
        );
        _activeHandles.add(handle);
      }
    }
  }

  double _timelineVolume(MusicalTimelineEvent event, int pitchIndex) {
    final velocity = event.performedVelocity;
    switch (event.track) {
      case TimelineTrackType.harmony:
        final emphasis = pitchIndex == 0 ? 1.0 : 0.84;
        return (_chordVolume * velocity * emphasis).clamp(0.0, 1.0).toDouble();
      case TimelineTrackType.melody:
        return (_melodyVolume * velocity).clamp(0.0, 1.0).toDouble();
      case TimelineTrackType.bass:
        return (_bassVolume * velocity).clamp(0.0, 1.0).toDouble();
    }
  }

  double _timelinePan(MusicalTimelineEvent event, int pitchIndex) {
    switch (event.track) {
      case TimelineTrackType.harmony:
        final count = event.midiPitches.length;
        if (count <= 1) return 0;
        final maxPan = 0.28 * _stereoWidth;
        return -maxPan + (((maxPan * 2) / (count - 1)) * pitchIndex);
      case TimelineTrackType.melody:
        return 0.08 * _stereoWidth;
      case TimelineTrackType.bass:
        return 0;
    }
  }

  Future<AudioSource> _timelineSourceForMidi(
    TimelineTrackType track,
    int midi,
  ) {
    switch (track) {
      case TimelineTrackType.harmony:
        return _sourceForMidi(midi);
      case TimelineTrackType.melody:
        return _melodySourceForMidi(midi);
      case TimelineTrackType.bass:
        return _bassSourceForMidi(midi);
    }
  }

  AudioSource? _cachedTimelineSource(TimelineTrackType track, int midi) {
    switch (track) {
      case TimelineTrackType.harmony:
        return _noteSources['${_synthCharacter.name}:$midi'];
      case TimelineTrackType.melody:
        return _melodySources[midi];
      case TimelineTrackType.bass:
        return _bassSources[midi];
    }
  }

  Duration _durationForBeats(double beats) => Duration(
        microseconds: max(0, (beats * _microsPerBeat).round()),
      );

  double get _microsPerBeat => 60000000 / _bpm;

  void _pruneFinishedHandles() {
    _activeHandles.removeWhere(
      (handle) => !_engine.getIsValidVoiceHandle(handle),
    );
  }

  Future<void> _playLayeredChord(
    List<int> midiNotes, {
    required Duration duration,
    required double velocity,
    required bool includeBass,
    required int session,
  }) async {
    final handles = <SoundHandle>[];

    Future<void> stopHandles() async {
      for (final handle in handles) {
        _activeHandles.remove(handle);
        if (_engine.getIsValidVoiceHandle(handle)) {
          await _engine.stop(handle);
        }
      }
    }

    if (includeBass && midiNotes.isNotEmpty) {
      final bassSource = await _bassSourceForMidi(_bassMidiFor(midiNotes.first));
      if (!_sessionIsActive(session)) {
        await stopHandles();
        return;
      }
      final bassHandle = _engine.play(
        bassSource,
        volume: (_bassVolume * velocity).clamp(0.0, 1.0),
      );
      _registerHandle(bassHandle, handles, duration);
    }

    for (var i = 0; i < midiNotes.length; i++) {
      if (!_sessionIsActive(session)) {
        await stopHandles();
        return;
      }
      final source = await _sourceForMidi(midiNotes[i]);
      if (!_sessionIsActive(session)) {
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
      _registerHandle(handle, handles, duration);

      if (_strumMs > 0 && i + 1 < midiNotes.length) {
        await Future<void>.delayed(Duration(milliseconds: _strumMs));
      }
    }

    await Future<void>.delayed(duration);
    if (!_sessionIsActive(session)) {
      await stopHandles();
      return;
    }

    for (final handle in handles) {
      if (_engine.getIsValidVoiceHandle(handle)) {
        _engine.fadeVolume(handle, 0.0, const Duration(milliseconds: 90));
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await stopHandles();
  }

  void _registerHandle(
    SoundHandle handle,
    List<SoundHandle> localHandles,
    Duration requestedDuration,
  ) {
    localHandles.add(handle);
    _activeHandles.add(handle);
    final hardStop = requestedDuration + const Duration(milliseconds: 450);
    _engine.scheduleStop(handle, hardStop);
  }

  bool _sessionIsActive(int session) => session == _playbackSession;

  Future<AudioSource> _sourceForMidi(int midi) async {
    final key = '${_synthCharacter.name}:$midi';
    final existing = _noteSources[key];
    if (existing != null) return existing;
    final source = await _engine.loadWaveform(
      _waveformForCharacter(_synthCharacter),
      _usesSuperWave(_synthCharacter),
      _scaleForCharacter(_synthCharacter),
      _detuneForCharacter(_synthCharacter),
    );
    _engine.setWaveformFreq(source, _midiFrequency(midi));
    _noteSources[key] = source;
    return source;
  }

  Future<AudioSource> _melodySourceForMidi(int midi) async {
    final existing = _melodySources[midi];
    if (existing != null) return existing;
    final source = await _engine.loadWaveform(WaveForm.triangle, false, 0.03, 0.0);
    _engine.setWaveformFreq(source, _midiFrequency(midi));
    _melodySources[midi] = source;
    return source;
  }

  Future<AudioSource> _bassSourceForMidi(int midi) async {
    final existing = _bassSources[midi];
    if (existing != null) return existing;
    final source = await _engine.loadWaveform(WaveForm.sin, false, 0.10, 0.0);
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

  bool _usesSuperWave(SynthCharacter character) =>
      character == SynthCharacter.analog;

  double _scaleForCharacter(SynthCharacter character) {
    switch (character) {
      case SynthCharacter.warm:
        return 0.10;
      case SynthCharacter.clean:
        return 0.0;
      case SynthCharacter.analog:
        return 0.12;
    }
  }

  double _detuneForCharacter(SynthCharacter character) {
    switch (character) {
      case SynthCharacter.warm:
        return 0.0;
      case SynthCharacter.clean:
        return 0.0;
      case SynthCharacter.analog:
        return 0.04;
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
      while (midi > 76 && midi - 12 > previous) midi -= 12;
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
    for (final source in _melodySources.values) {
      unawaited(_engine.disposeSource(source));
    }
    for (final source in _bassSources.values) {
      unawaited(_engine.disposeSource(source));
    }
    _noteSources.clear();
    _melodySources.clear();
    _bassSources.clear();
    super.dispose();
  }
}
