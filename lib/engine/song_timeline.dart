import 'performance_profile.dart';
import 'song_architecture.dart';

/// Canonical track identities used by playback, editing and export.
enum TimelineTrackType { harmony, melody, bass }

/// One immutable musical event placed on the full-song beat axis.
class MusicalTimelineEvent {
  MusicalTimelineEvent({
    required this.track,
    required this.sectionId,
    required this.chordIndex,
    required this.startBeat,
    required this.durationBeats,
    required this.velocity,
    required List<int> midiPitches,
    required this.label,
    this.performance = PerformanceIntent.neutral,
  }) : midiPitches = List<int>.unmodifiable(midiPitches) {
    if (startBeat < 0) {
      throw ArgumentError.value(startBeat, 'startBeat', 'Must be non-negative');
    }
    if (durationBeats <= 0) {
      throw ArgumentError.value(
        durationBeats,
        'durationBeats',
        'Must be greater than zero',
      );
    }
    if (velocity < 0 || velocity > 1) {
      throw ArgumentError.value(velocity, 'velocity', 'Must be between 0 and 1');
    }
  }

  final TimelineTrackType track;
  final String sectionId;
  final int chordIndex;
  final double startBeat;
  final double durationBeats;
  final double velocity;
  final List<int> midiPitches;
  final String label;
  final PerformanceIntent performance;

  double get endBeat => startBeat + durationBeats;
  double get performedStartBeat => startBeat + performance.timingOffsetBeats;
  double get performedDurationBeats => durationBeats * performance.gateRatio;
  double get performedVelocity =>
      (velocity * performance.velocityScale).clamp(0.0, 1.0).toDouble();
}

/// Beat-range metadata for one arrangement section.
class TimelineSection {
  const TimelineSection({
    required this.id,
    required this.type,
    required this.bars,
    required this.startBeat,
    required this.durationBeats,
    required this.targetEnergy,
    required this.targetTension,
    required this.variation,
  });

  final String id;
  final SongSectionType type;
  final int bars;
  final double startBeat;
  final double durationBeats;
  final double targetEnergy;
  final double targetTension;
  final int variation;

  double get endBeat => startBeat + durationBeats;
}

/// One timing model for composition, playback, editing and future export.
class SongTimeline {
  SongTimeline({
    required this.beatsPerBar,
    required List<TimelineSection> sections,
    required List<MusicalTimelineEvent> events,
    this.performanceProfile = const PerformanceProfile(),
  })  : sections = List<TimelineSection>.unmodifiable(sections),
        events = List<MusicalTimelineEvent>.unmodifiable(events) {
    if (beatsPerBar <= 0) {
      throw ArgumentError.value(beatsPerBar, 'beatsPerBar', 'Must be positive');
    }
  }

  final int beatsPerBar;
  final List<TimelineSection> sections;
  final List<MusicalTimelineEvent> events;
  final PerformanceProfile performanceProfile;

  double get totalBeats => sections.isEmpty ? 0.0 : sections.last.endBeat;
  double get totalBars => totalBeats / beatsPerBar;

  TimelineSection? sectionById(String id) {
    for (final section in sections) {
      if (section.id == id) return section;
    }
    return null;
  }

  TimelineSection? sectionAtBeat(double beat) {
    for (final section in sections) {
      if (beat >= section.startBeat && beat < section.endBeat) return section;
    }
    if (sections.isNotEmpty && beat == totalBeats) return sections.last;
    return null;
  }

  List<MusicalTimelineEvent> eventsForSection(String sectionId) =>
      List<MusicalTimelineEvent>.unmodifiable(
        events.where((event) => event.sectionId == sectionId),
      );

  List<MusicalTimelineEvent> eventsForTrack(TimelineTrackType track) =>
      List<MusicalTimelineEvent>.unmodifiable(
        events.where((event) => event.track == track),
      );
}
