import 'dart:math' as math;

import 'song_timeline.dart';

/// One performed timeline event clipped to the requested playback range.
class PlannedTimelineEvent {
  const PlannedTimelineEvent({
    required this.source,
    required this.startBeat,
    required this.durationBeats,
  });

  final MusicalTimelineEvent source;
  final double startBeat;
  final double durationBeats;

  double get endBeat => startBeat + durationBeats;
}

/// Immutable scheduling manifest consumed by the audio engine.
class TimelinePlaybackPlan {
  TimelinePlaybackPlan({
    required this.startBeat,
    required this.endBeat,
    required List<PlannedTimelineEvent> events,
  }) : events = List<PlannedTimelineEvent>.unmodifiable(events) {
    if (startBeat < 0 || endBeat < startBeat) {
      throw ArgumentError('Invalid playback range $startBeat → $endBeat');
    }
  }

  final double startBeat;
  final double endBeat;
  final List<PlannedTimelineEvent> events;

  double get durationBeats => endBeat - startBeat;

  List<PlannedTimelineEvent> eventsForTrack(TimelineTrackType track) =>
      List<PlannedTimelineEvent>.unmodifiable(
        events.where((event) => event.source.track == track),
      );
}

/// Converts canonical song events plus PerformanceIntent into a range-safe,
/// track-filtered scheduling manifest.
///
/// The underlying SongTimeline is never mutated. Seeking into the middle of a
/// sustained event clips that event to its remaining performed duration so the
/// scheduler can resume immediately at the requested beat.
class TimelinePlaybackPlanner {
  const TimelinePlaybackPlanner();

  TimelinePlaybackPlan build(
    SongTimeline timeline, {
    double startBeat = 0,
    double? endBeat,
    Set<TimelineTrackType> mutedTracks = const <TimelineTrackType>{},
    Set<TimelineTrackType> soloTracks = const <TimelineTrackType>{},
  }) {
    final safeStart = startBeat.clamp(0.0, timeline.totalBeats).toDouble();
    final safeEnd = (endBeat ?? timeline.totalBeats)
        .clamp(safeStart, timeline.totalBeats)
        .toDouble();
    final planned = <PlannedTimelineEvent>[];

    for (final event in timeline.events) {
      if (!_trackEnabled(event.track, mutedTracks, soloTracks)) continue;

      // Performance timing may push an attack slightly before its canonical
      // beat. Clamp only for scheduling; structural timing stays unchanged.
      final performedStart = event.performedStartBeat.clamp(0.0, timeline.totalBeats);
      final performedEnd = (event.performedStartBeat + event.performedDurationBeats)
          .clamp(0.0, timeline.totalBeats);
      if (performedEnd <= safeStart || performedStart >= safeEnd) continue;

      final clippedStart = math.max(performedStart, safeStart).toDouble();
      final clippedEnd = math.min(performedEnd, safeEnd).toDouble();
      final clippedDuration = clippedEnd - clippedStart;
      if (clippedDuration <= 0) continue;

      planned.add(
        PlannedTimelineEvent(
          source: event,
          startBeat: clippedStart,
          durationBeats: clippedDuration,
        ),
      );
    }

    planned.sort((a, b) {
      final byBeat = a.startBeat.compareTo(b.startBeat);
      if (byBeat != 0) return byBeat;
      final byTrack = a.source.track.index.compareTo(b.source.track.index);
      if (byTrack != 0) return byTrack;
      return a.source.chordIndex.compareTo(b.source.chordIndex);
    });

    return TimelinePlaybackPlan(
      startBeat: safeStart,
      endBeat: safeEnd,
      events: planned,
    );
  }

  TimelinePlaybackPlan section(
    SongTimeline timeline,
    String sectionId, {
    Set<TimelineTrackType> mutedTracks = const <TimelineTrackType>{},
    Set<TimelineTrackType> soloTracks = const <TimelineTrackType>{},
  }) {
    final section = timeline.sectionById(sectionId);
    if (section == null) {
      return TimelinePlaybackPlan(
        startBeat: 0,
        endBeat: 0,
        events: const <PlannedTimelineEvent>[],
      );
    }
    return build(
      timeline,
      startBeat: section.startBeat,
      endBeat: section.endBeat,
      mutedTracks: mutedTracks,
      soloTracks: soloTracks,
    );
  }

  bool _trackEnabled(
    TimelineTrackType track,
    Set<TimelineTrackType> mutedTracks,
    Set<TimelineTrackType> soloTracks,
  ) {
    // Solo takes precedence over mute, matching conventional mixer behavior.
    if (soloTracks.isNotEmpty) return soloTracks.contains(track);
    return !mutedTracks.contains(track);
  }
}
