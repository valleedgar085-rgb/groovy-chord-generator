import '../models/types.dart';
import 'song_architecture.dart';

/// Canonical musical tracks represented on the song timeline.
enum TimelineTrack { harmony, melody, bass }

/// Immutable section boundary on the canonical song clock.
class TimelineSection {
  const TimelineSection({
    required this.id,
    required this.type,
    required this.index,
    required this.bars,
    required this.startTick,
    required this.durationTicks,
  })  : assert(index >= 0),
        assert(bars > 0),
        assert(startTick >= 0),
        assert(durationTicks > 0);

  final String id;
  final SongSectionType type;
  final int index;
  final int bars;
  final int startTick;
  final int durationTicks;

  int get endTick => startTick + durationTicks;

  bool containsTick(int tick) => tick >= startTick && tick < endTick;
}

/// Common timing contract for every playable/exportable musical event.
abstract class SongTimelineEvent {
  const SongTimelineEvent({
    required this.id,
    required this.sectionId,
    required this.startTick,
    required this.durationTicks,
  })  : assert(startTick >= 0),
        assert(durationTicks > 0);

  final String id;
  final String sectionId;
  final int startTick;
  final int durationTicks;

  TimelineTrack get track;
  int get endTick => startTick + durationTicks;
}

/// Harmony occupies explicit spans instead of relying on progression-list order
/// at playback/export time.
class HarmonyTimelineEvent extends SongTimelineEvent {
  const HarmonyTimelineEvent({
    required super.id,
    required super.sectionId,
    required super.startTick,
    required super.durationTicks,
    required this.chordIndex,
    required this.chord,
  }) : assert(chordIndex >= 0);

  final int chordIndex;
  final Chord chord;

  @override
  TimelineTrack get track => TimelineTrack.harmony;
}

/// Canonical melody event. [sourceDuration] retains the generator's original
/// rhythmic weight while [durationTicks] is the exact normalized timeline span.
class MelodyTimelineEvent extends SongTimelineEvent {
  const MelodyTimelineEvent({
    required super.id,
    required super.sectionId,
    required super.startTick,
    required super.durationTicks,
    required this.eventIndex,
    required this.chordIndex,
    required this.note,
    required this.octave,
    required this.velocity,
    required this.sourceDuration,
  })  : assert(eventIndex >= 0),
        assert(chordIndex >= 0),
        assert(velocity >= 0 && velocity <= 1),
        assert(sourceDuration > 0);

  final int eventIndex;
  final int chordIndex;
  final String note;
  final int octave;
  final double velocity;
  final double sourceDuration;

  @override
  TimelineTrack get track => TimelineTrack.melody;
}

/// Canonical bass event with its performance style retained for later playback
/// engines and export adapters.
class BassTimelineEvent extends SongTimelineEvent {
  const BassTimelineEvent({
    required super.id,
    required super.sectionId,
    required super.startTick,
    required super.durationTicks,
    required this.eventIndex,
    required this.chordIndex,
    required this.note,
    required this.octave,
    required this.velocity,
    required this.sourceDuration,
    required this.style,
  })  : assert(eventIndex >= 0),
        assert(chordIndex >= 0),
        assert(velocity >= 0 && velocity <= 1),
        assert(sourceDuration > 0);

  final int eventIndex;
  final int chordIndex;
  final String note;
  final int octave;
  final double velocity;
  final double sourceDuration;
  final BassStyle style;

  @override
  TimelineTrack get track => TimelineTrack.bass;
}

/// One exact song clock shared by playback, editing, visualization, and export.
///
/// Phase 4 starts with 4/4 defaults but keeps clock resolution and beats-per-bar
/// explicit so a future schema can support other meters without replacing this
/// event model.
class SongTimeline {
  SongTimeline({
    required this.ticksPerBeat,
    required this.beatsPerBar,
    required List<TimelineSection> sections,
    required List<HarmonyTimelineEvent> harmonyEvents,
    required List<MelodyTimelineEvent> melodyEvents,
    required List<BassTimelineEvent> bassEvents,
  })  : assert(ticksPerBeat > 0),
        assert(beatsPerBar > 0),
        sections = List<TimelineSection>.unmodifiable(sections),
        harmonyEvents = List<HarmonyTimelineEvent>.unmodifiable(harmonyEvents),
        melodyEvents = List<MelodyTimelineEvent>.unmodifiable(melodyEvents),
        bassEvents = List<BassTimelineEvent>.unmodifiable(bassEvents);

  final int ticksPerBeat;
  final int beatsPerBar;
  final List<TimelineSection> sections;
  final List<HarmonyTimelineEvent> harmonyEvents;
  final List<MelodyTimelineEvent> melodyEvents;
  final List<BassTimelineEvent> bassEvents;

  int get totalTicks => sections.isEmpty ? 0 : sections.last.endTick;
  double get totalBeats => totalTicks / ticksPerBeat;
  int get totalBars =>
      sections.fold<int>(0, (total, section) => total + section.bars);

  TimelineSection? sectionById(String sectionId) {
    for (final section in sections) {
      if (section.id == sectionId) return section;
    }
    return null;
  }

  TimelineSection? sectionAtTick(int tick) {
    for (final section in sections) {
      if (section.containsTick(tick)) return section;
    }
    return null;
  }

  List<SongTimelineEvent> eventsInSection(String sectionId) {
    final events = <SongTimelineEvent>[
      ...harmonyEvents.where((event) => event.sectionId == sectionId),
      ...melodyEvents.where((event) => event.sectionId == sectionId),
      ...bassEvents.where((event) => event.sectionId == sectionId),
    ];
    events.sort(_eventOrder);
    return List<SongTimelineEvent>.unmodifiable(events);
  }

  List<SongTimelineEvent> get allEvents {
    final events = <SongTimelineEvent>[
      ...harmonyEvents,
      ...melodyEvents,
      ...bassEvents,
    ]..sort(_eventOrder);
    return List<SongTimelineEvent>.unmodifiable(events);
  }

  static int _eventOrder(SongTimelineEvent a, SongTimelineEvent b) {
    final byStart = a.startTick.compareTo(b.startTick);
    if (byStart != 0) return byStart;
    final byTrack = a.track.index.compareTo(b.track.index);
    if (byTrack != 0) return byTrack;
    return a.id.compareTo(b.id);
  }
}
