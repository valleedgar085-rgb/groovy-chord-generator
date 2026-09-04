import '../models/types.dart';
import 'song_draft.dart';
import 'song_timeline.dart';

/// Converts a generated [SongDraft] into one exact beat/tick clock.
///
/// Harmony divides each section into equal chord slots. Melody and bass events
/// are then fitted proportionally inside the slot referenced by their
/// `chordIndex`. This preserves the generator's rhythmic relationships while
/// guaranteeing that every event stays inside its harmony and section boundary.
class SongTimelineBuilder {
  const SongTimelineBuilder({
    this.ticksPerBeat = 960,
    this.beatsPerBar = 4,
  })  : assert(ticksPerBeat > 0),
        assert(beatsPerBar > 0);

  final int ticksPerBeat;
  final int beatsPerBar;

  SongTimeline build(SongDraft draft) {
    final sections = <TimelineSection>[];
    final harmonyEvents = <HarmonyTimelineEvent>[];
    final melodyEvents = <MelodyTimelineEvent>[];
    final bassEvents = <BassTimelineEvent>[];

    var sectionStart = 0;
    for (var sectionIndex = 0;
        sectionIndex < draft.plan.sections.length;
        sectionIndex++) {
      final plan = draft.plan.sections[sectionIndex];
      final sectionTicks = plan.bars * beatsPerBar * ticksPerBeat;
      final timelineSection = TimelineSection(
        id: plan.id,
        type: plan.type,
        index: sectionIndex,
        bars: plan.bars,
        startTick: sectionStart,
        durationTicks: sectionTicks,
      );
      sections.add(timelineSection);

      final generated = draft.sectionById(plan.id);
      if (generated != null) {
        _appendSectionEvents(
          generated,
          timelineSection,
          harmonyEvents,
          melodyEvents,
          bassEvents,
        );
      }
      sectionStart += sectionTicks;
    }

    return SongTimeline(
      ticksPerBeat: ticksPerBeat,
      beatsPerBar: beatsPerBar,
      sections: sections,
      harmonyEvents: harmonyEvents,
      melodyEvents: melodyEvents,
      bassEvents: bassEvents,
    );
  }

  void _appendSectionEvents(
    GeneratedSongSection section,
    TimelineSection timelineSection,
    List<HarmonyTimelineEvent> harmonyEvents,
    List<MelodyTimelineEvent> melodyEvents,
    List<BassTimelineEvent> bassEvents,
  ) {
    final progression = section.progression;
    if (progression.isEmpty) {
      if (section.melody.isNotEmpty || section.bass.isNotEmpty) {
        throw StateError(
          'Section ${section.plan.id} has notes but no harmony slots.',
        );
      }
      return;
    }

    final slots = <_TickSpan>[];
    for (var chordIndex = 0; chordIndex < progression.length; chordIndex++) {
      final slot = _equalSlot(
        timelineSection.startTick,
        timelineSection.durationTicks,
        progression.length,
        chordIndex,
      );
      slots.add(slot);
      harmonyEvents.add(HarmonyTimelineEvent(
        id: '${section.plan.id}:harmony:$chordIndex',
        sectionId: section.plan.id,
        startTick: slot.start,
        durationTicks: slot.duration,
        chordIndex: chordIndex,
        chord: progression[chordIndex],
      ));
    }

    _appendMelody(section, slots, melodyEvents);
    _appendBass(section, slots, bassEvents);
  }

  void _appendMelody(
    GeneratedSongSection section,
    List<_TickSpan> slots,
    List<MelodyTimelineEvent> output,
  ) {
    final groups = <int, List<int>>{};
    for (var eventIndex = 0; eventIndex < section.melody.length; eventIndex++) {
      final note = section.melody[eventIndex];
      _validateChordIndex(
        section.plan.id,
        TimelineTrack.melody,
        eventIndex,
        note.chordIndex,
        slots.length,
      );
      groups.putIfAbsent(note.chordIndex, () => <int>[]).add(eventIndex);
    }

    for (var chordIndex = 0; chordIndex < slots.length; chordIndex++) {
      final indexes = groups[chordIndex];
      if (indexes == null || indexes.isEmpty) continue;
      final weights = indexes
          .map((index) => section.melody[index].duration)
          .toList(growable: false);
      final spans = _weightedSpans(slots[chordIndex], weights);
      for (var localIndex = 0; localIndex < indexes.length; localIndex++) {
        final eventIndex = indexes[localIndex];
        final note = section.melody[eventIndex];
        final span = spans[localIndex];
        output.add(MelodyTimelineEvent(
          id: '${section.plan.id}:melody:$eventIndex',
          sectionId: section.plan.id,
          startTick: span.start,
          durationTicks: span.duration,
          eventIndex: eventIndex,
          chordIndex: chordIndex,
          note: note.note,
          octave: note.octave,
          velocity: note.velocity.clamp(0.0, 1.0).toDouble(),
          sourceDuration: _positiveWeight(note.duration),
        ));
      }
    }
  }

  void _appendBass(
    GeneratedSongSection section,
    List<_TickSpan> slots,
    List<BassTimelineEvent> output,
  ) {
    final groups = <int, List<int>>{};
    for (var eventIndex = 0; eventIndex < section.bass.length; eventIndex++) {
      final note = section.bass[eventIndex];
      _validateChordIndex(
        section.plan.id,
        TimelineTrack.bass,
        eventIndex,
        note.chordIndex,
        slots.length,
      );
      groups.putIfAbsent(note.chordIndex, () => <int>[]).add(eventIndex);
    }

    for (var chordIndex = 0; chordIndex < slots.length; chordIndex++) {
      final indexes = groups[chordIndex];
      if (indexes == null || indexes.isEmpty) continue;
      final weights = indexes
          .map((index) => section.bass[index].duration)
          .toList(growable: false);
      final spans = _weightedSpans(slots[chordIndex], weights);
      for (var localIndex = 0; localIndex < indexes.length; localIndex++) {
        final eventIndex = indexes[localIndex];
        final note = section.bass[eventIndex];
        final span = spans[localIndex];
        output.add(BassTimelineEvent(
          id: '${section.plan.id}:bass:$eventIndex',
          sectionId: section.plan.id,
          startTick: span.start,
          durationTicks: span.duration,
          eventIndex: eventIndex,
          chordIndex: chordIndex,
          note: note.note,
          octave: note.octave,
          velocity: note.velocity.clamp(0.0, 1.0).toDouble(),
          sourceDuration: _positiveWeight(note.duration),
          style: note.style,
        ));
      }
    }
  }

  _TickSpan _equalSlot(
    int start,
    int duration,
    int count,
    int index,
  ) {
    final slotStart = start + (duration * index) ~/ count;
    final slotEnd = index == count - 1
        ? start + duration
        : start + (duration * (index + 1)) ~/ count;
    return _TickSpan(slotStart, slotEnd);
  }

  List<_TickSpan> _weightedSpans(_TickSpan container, List<double> weights) {
    if (weights.isEmpty) return const <_TickSpan>[];
    if (container.duration < weights.length) {
      throw StateError(
        'Timeline resolution is too low for ${weights.length} events inside '
        '${container.duration} ticks.',
      );
    }

    final normalized = weights.map(_positiveWeight).toList(growable: false);
    final total = normalized.fold<double>(0.0, (sum, weight) => sum + weight);
    final spans = <_TickSpan>[];
    var cumulative = 0.0;
    var cursor = container.start;

    for (var index = 0; index < normalized.length; index++) {
      final remainingAfter = normalized.length - index - 1;
      cumulative += normalized[index];
      final desiredEnd = index == normalized.length - 1
          ? container.end
          : container.start +
              (container.duration * (cumulative / total)).round();
      final minimumEnd = cursor + 1;
      final maximumEnd = container.end - remainingAfter;
      final end = desiredEnd.clamp(minimumEnd, maximumEnd).toInt();
      spans.add(_TickSpan(cursor, end));
      cursor = end;
    }

    return spans;
  }

  double _positiveWeight(double value) => value > 0 ? value : 1.0;

  void _validateChordIndex(
    String sectionId,
    TimelineTrack track,
    int eventIndex,
    int chordIndex,
    int chordCount,
  ) {
    if (chordIndex >= 0 && chordIndex < chordCount) return;
    throw StateError(
      '$sectionId ${track.name} event $eventIndex references chordIndex '
      '$chordIndex outside 0..${chordCount - 1}.',
    );
  }
}

class _TickSpan {
  const _TickSpan(this.start, this.end)
      : assert(start >= 0),
        assert(end > start);

  final int start;
  final int end;

  int get duration => end - start;
}
