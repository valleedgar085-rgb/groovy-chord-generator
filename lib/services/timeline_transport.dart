import 'package:flutter/foundation.dart';

import '../engine/song_timeline.dart';

/// UI-facing contract for full-song transport state and commands.
///
/// Keeping widgets dependent on this lightweight interface prevents native
/// SoLoud FFI from being loaded in ordinary widget tests and leaves room for
/// future transport/audio-engine implementations without rewriting the UI.
abstract interface class TimelineTransport implements Listenable {
  bool get isPlaying;
  bool get isTimelinePlayback;
  bool get looping;
  int get bpm;
  double get songBeat;
  double get timelineRangeStart;
  double get timelineRangeEnd;
  String? get activeSectionId;

  bool isTrackMuted(TimelineTrackType track);
  bool isTrackSoloed(TimelineTrackType track);

  void setBpm(int value);
  void setLooping(bool value);
  void setTrackMuted(TimelineTrackType track, bool muted);
  void setTrackSoloed(TimelineTrackType track, bool soloed);
  void clearTrackMix();

  Future<void> playFullSong(
    SongTimeline timeline, {
    double startBeat = 0,
  });

  Future<void> playSection(
    SongTimeline timeline,
    String sectionId, {
    bool loop = false,
    double? startBeat,
  });

  Future<void> seekTimeline(
    SongTimeline timeline,
    double beat, {
    bool resume = true,
  });

  Future<void> stop({bool resetTimelinePosition = true});
}
