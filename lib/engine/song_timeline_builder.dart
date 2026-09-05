import '../models/types.dart';
import '../utils/music_theory.dart';
import 'performance_intelligence_engine.dart';
import 'performance_profile.dart';
import 'song_draft.dart';
import 'song_timeline.dart';

/// Converts generated section-relative music into one absolute beat timeline.
///
/// Structural timing stays canonical. [PerformanceProfile] is applied as a
/// separate deterministic intent layer so playback can feel human without
/// mutating section/bar boundaries used by editing and export.
class SongTimelineBuilder {
  const SongTimelineBuilder({
    this.beatsPerBar = 4,
    this.performanceEngine = const PerformanceIntelligenceEngine(),
  });

  final int beatsPerBar;
  final PerformanceIntelligenceEngine performanceEngine;

  SongTimeline build(
    SongDraft draft, {
    PerformanceProfile performanceProfile = const PerformanceProfile(),
  }) {
    if (beatsPerBar <= 0) {
      throw ArgumentError.value(beatsPerBar, 'beatsPerBar', 'Must be positive');
    }

    final sections = <TimelineSection>[];
    final events = <MusicalTimelineEvent>[];
    var songCursor = 0.0;

    for (final generated in draft.sections) {
      final plan = generated.plan;
      final sectionBeats = plan.bars * beatsPerBar.toDouble();
      final timelineSection = TimelineSection(
        id: plan.id,
        type: plan.type,
        bars: plan.bars,
        startBeat: songCursor,
        durationBeats: sectionBeats,
        targetEnergy: plan.targetEnergy,
        targetTension: plan.targetTension,
        variation: plan.variation,
      );
      sections.add(timelineSection);

      final chords = generated.progression;
      if (chords.isNotEmpty) {
        final chordBeats = sectionBeats / chords.length;
        for (var chordIndex = 0; chordIndex < chords.length; chordIndex++) {
          final chord = chords[chordIndex];
          final chordStart = songCursor + (chordIndex * chordBeats);
          final baseVelocity = (0.58 + (plan.targetEnergy * 0.34))
              .clamp(0.0, 1.0)
              .toDouble();
          events.add(
            MusicalTimelineEvent(
              track: TimelineTrackType.harmony,
              sectionId: plan.id,
              chordIndex: chordIndex,
              startBeat: chordStart,
              durationBeats: chordBeats,
              velocity: baseVelocity,
              midiPitches: _chordMidiPitches(chord),
              label: chord.numeral.isNotEmpty ? chord.numeral : chord.root,
              performance: performanceEngine.intentFor(
                profile: performanceProfile,
                seed: draft.plan.seed,
                track: TimelineTrackType.harmony,
                sectionId: plan.id,
                chordIndex: chordIndex,
                ordinal: chordIndex,
                startBeat: chordStart,
                durationBeats: chordBeats,
                sectionStartBeat: songCursor,
              ),
            ),
          );
        }

        _appendMelodyEvents(
          events,
          generated,
          seed: draft.plan.seed,
          profile: performanceProfile,
          sectionStart: songCursor,
          chordBeats: chordBeats,
        );
        _appendBassEvents(
          events,
          generated,
          seed: draft.plan.seed,
          profile: performanceProfile,
          sectionStart: songCursor,
          chordBeats: chordBeats,
        );
      }

      songCursor += sectionBeats;
    }

    events.sort((a, b) {
      final byBeat = a.startBeat.compareTo(b.startBeat);
      if (byBeat != 0) return byBeat;
      return a.track.index.compareTo(b.track.index);
    });

    return SongTimeline(
      beatsPerBar: beatsPerBar,
      sections: sections,
      events: events,
      performanceProfile: performanceProfile,
    );
  }

  void _appendMelodyEvents(
    List<MusicalTimelineEvent> target,
    GeneratedSongSection section, {
    required int seed,
    required PerformanceProfile profile,
    required double sectionStart,
    required double chordBeats,
  }) {
    final chordCount = section.progression.length;
    var ordinal = 0;
    for (var chordIndex = 0; chordIndex < chordCount; chordIndex++) {
      final notes = section.melody
          .where((note) => note.chordIndex == chordIndex)
          .toList(growable: false);
      if (notes.isEmpty) continue;

      final weights = notes
          .map((note) => note.duration > 0 ? note.duration : 0.01)
          .toList(growable: false);
      final totalWeight = weights.fold<double>(0.0, (sum, value) => sum + value);
      final chordStart = sectionStart + (chordIndex * chordBeats);
      final chordEnd = chordStart + chordBeats;
      var cursor = chordStart;

      for (var index = 0; index < notes.length; index++) {
        final note = notes[index];
        final duration = index == notes.length - 1
            ? chordEnd - cursor
            : chordBeats * (weights[index] / totalWeight);
        if (duration <= 0) continue;
        target.add(
          MusicalTimelineEvent(
            track: TimelineTrackType.melody,
            sectionId: section.plan.id,
            chordIndex: chordIndex,
            startBeat: cursor,
            durationBeats: duration,
            velocity: note.velocity.clamp(0.0, 1.0).toDouble(),
            midiPitches: <int>[noteToPitch(note.note, note.octave)],
            label: note.note,
            performance: performanceEngine.intentFor(
              profile: profile,
              seed: seed,
              track: TimelineTrackType.melody,
              sectionId: section.plan.id,
              chordIndex: chordIndex,
              ordinal: ordinal,
              startBeat: cursor,
              durationBeats: duration,
              sectionStartBeat: sectionStart,
            ),
          ),
        );
        ordinal++;
        cursor += duration;
      }
    }
  }

  void _appendBassEvents(
    List<MusicalTimelineEvent> target,
    GeneratedSongSection section, {
    required int seed,
    required PerformanceProfile profile,
    required double sectionStart,
    required double chordBeats,
  }) {
    final chordCount = section.progression.length;
    var ordinal = 0;
    for (var chordIndex = 0; chordIndex < chordCount; chordIndex++) {
      final notes = section.bass
          .where((note) => note.chordIndex == chordIndex)
          .toList(growable: false);
      if (notes.isEmpty) continue;

      final weights = notes
          .map((note) => note.duration > 0 ? note.duration : 0.01)
          .toList(growable: false);
      final totalWeight = weights.fold<double>(0.0, (sum, value) => sum + value);
      final chordStart = sectionStart + (chordIndex * chordBeats);
      final chordEnd = chordStart + chordBeats;
      var cursor = chordStart;

      for (var index = 0; index < notes.length; index++) {
        final note = notes[index];
        final duration = index == notes.length - 1
            ? chordEnd - cursor
            : chordBeats * (weights[index] / totalWeight);
        if (duration <= 0) continue;
        target.add(
          MusicalTimelineEvent(
            track: TimelineTrackType.bass,
            sectionId: section.plan.id,
            chordIndex: chordIndex,
            startBeat: cursor,
            durationBeats: duration,
            velocity: note.velocity.clamp(0.0, 1.0).toDouble(),
            midiPitches: <int>[noteToPitch(note.note, note.octave)],
            label: note.note,
            performance: performanceEngine.intentFor(
              profile: profile,
              seed: seed,
              track: TimelineTrackType.bass,
              sectionId: section.plan.id,
              chordIndex: chordIndex,
              ordinal: ordinal,
              startBeat: cursor,
              durationBeats: duration,
              sectionStartBeat: sectionStart,
            ),
          ),
        );
        ordinal++;
        cursor += duration;
      }
    }
  }

  List<int> _chordMidiPitches(Chord chord) {
    final voiced = chord.voicedNotes;
    if (voiced != null && voiced.isNotEmpty) {
      return voiced.map((note) => note.pitch).toList(growable: false);
    }

    final chordNotes = getChordNotes(chord);
    final pitches = <int>[];
    var previous = -1;
    for (final note in chordNotes) {
      var pitch = noteToPitch(note, 4);
      while (previous >= 0 && pitch <= previous) {
        pitch += 12;
      }
      pitches.add(pitch);
      previous = pitch;
    }
    return pitches;
  }
}
