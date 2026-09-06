import 'dart:math' as math;

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

  /// Playback duration is deliberately bounded separately from the canonical
  /// note value. This lets long written notes remain intact for editing/export
  /// while lead and bass voices release in a musically useful amount of time.
  double get performedDurationBeats => math.min(
        durationBeats * performance.gateRatio,
        performance.maxDurationBeats,
      );

  /// Velocity remains deterministic but now converts performance accents into
  /// audible dynamics and compensates dense chord stacks before they hit the
  /// mixer. The canonical written velocity is not mutated.
  double get performedVelocity {
    final accentGain = 1.0 + (performance.accent * 0.12);
    final articulationGain = switch (performance.articulation) {
      ArticulationIntent.legato => 0.98,
      ArticulationIntent.normal => 1.0,
      ArticulationIntent.detached => 0.97,
      ArticulationIntent.staccato => 0.94,
      ArticulationIntent.accent => 1.06,
    };
    final polyphonyCompensation = track == TimelineTrackType.harmony &&
            midiPitches.length > 1
        ? 1.0 / math.sqrt(1.0 + ((midiPitches.length - 1) * 0.18))
        : 1.0;
    return (velocity *
            performance.velocityScale *
            accentGain *
            articulationGain *
            polyphonyCompensation)
        .clamp(0.0, 1.0)
        .toDouble();
  }
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