import '../engine/song_timeline.dart';
import 'audio_playback_service.dart';
import 'timeline_transport.dart';

/// Production TimelineTransport backed by the native SoLoud service.
///
/// The singleton is lazy: importing this file does not initialize SoLoud. That
/// keeps static timeline widgets and Linux widget tests free from native FFI.
class AudioTimelineTransport implements TimelineTransport {
  AudioTimelineTransport._(this._audio);

  static AudioTimelineTransport? _instance;

  static AudioTimelineTransport get instance =>
      _instance ??= AudioTimelineTransport._(AudioPlaybackService.instance);

  final AudioPlaybackService _audio;

  @override
  void addListener(void Function() listener) => _audio.addListener(listener);

  @override
  void removeListener(void Function() listener) => _audio.removeListener(listener);

  @override
  bool get isPlaying => _audio.isPlaying;

  @override
  bool get isTimelinePlayback => _audio.isTimelinePlayback;

  @override
  bool get looping => _audio.looping;

  @override
  int get bpm => _audio.bpm;

  @override
  double get songBeat => _audio.songBeat;

  @override
  double get timelineRangeStart => _audio.timelineRangeStart;

  @override
  double get timelineRangeEnd => _audio.timelineRangeEnd;

  @override
  String? get activeSectionId => _audio.activeSectionId;

  @override
  bool isTrackMuted(TimelineTrackType track) => _audio.isTrackMuted(track);

  @override
  bool isTrackSoloed(TimelineTrackType track) => _audio.isTrackSoloed(track);

  @override
  void setBpm(int value) => _audio.setBpm(value);

  @override
  void setLooping(bool value) => _audio.setLooping(value);

  @override
  void setTrackMuted(TimelineTrackType track, bool muted) =>
      _audio.setTrackMuted(track, muted);

  @override
  void setTrackSoloed(TimelineTrackType track, bool soloed) =>
      _audio.setTrackSoloed(track, soloed);

  @override
  void clearTrackMix() => _audio.clearTrackMix();

  @override
  Future<void> playFullSong(
    SongTimeline timeline, {
    double startBeat = 0,
  }) =>
      _audio.playFullSong(timeline, startBeat: startBeat);

  @override
  Future<void> playSection(
    SongTimeline timeline,
    String sectionId, {
    bool loop = false,
    double? startBeat,
  }) =>
      _audio.playSection(
        timeline,
        sectionId,
        loop: loop,
        startBeat: startBeat,
      );

  @override
  Future<void> seekTimeline(
    SongTimeline timeline,
    double beat, {
    bool resume = true,
  }) =>
      _audio.seekTimeline(timeline, beat, resume: resume);

  @override
  Future<void> stop({bool resetTimelinePosition = true}) =>
      _audio.stop(resetTimelinePosition: resetTimelinePosition);
}
