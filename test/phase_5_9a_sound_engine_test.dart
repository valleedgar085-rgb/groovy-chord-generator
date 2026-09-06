import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/performance_intelligence_engine.dart';
import 'package:groovy_chord_generator/engine/performance_profile.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/engine/song_timeline.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';

void main() {
  group('Phase 5.9A Sound Engine 2.0', () {
    test('long melody and bass notes receive absolute anti-drone gate caps', () {
      const engine = PerformanceIntelligenceEngine();
      const profile = PerformanceProfile(looseness: 0.2, punch: 0.7, swing: 0);

      final melody = engine.intentFor(
        profile: profile,
        seed: 5901,
        track: TimelineTrackType.melody,
        sectionId: 'verse-1',
        chordIndex: 0,
        ordinal: 0,
        startBeat: 0,
        durationBeats: 4,
        sectionStartBeat: 0,
      );
      final bass = engine.intentFor(
        profile: profile,
        seed: 5901,
        track: TimelineTrackType.bass,
        sectionId: 'verse-1',
        chordIndex: 0,
        ordinal: 0,
        startBeat: 0,
        durationBeats: 4,
        sectionStartBeat: 0,
      );

      expect(melody.maxDurationBeats, lessThanOrEqualTo(1.20));
      expect(bass.maxDurationBeats, lessThanOrEqualTo(0.72));
    });

    test('legato melody is allowed to breathe longer than normal melody', () {
      const engine = PerformanceIntelligenceEngine();
      final normal = engine.intentFor(
        profile: const PerformanceProfile(looseness: 0.2, punch: 0.35, swing: 0),
        seed: 5902,
        track: TimelineTrackType.melody,
        sectionId: 'verse-1',
        chordIndex: 1,
        ordinal: 1,
        startBeat: 1.0,
        durationBeats: 4,
        sectionStartBeat: 0,
      );
      final legato = engine.intentFor(
        profile: const PerformanceProfile(looseness: 0.9, punch: 0.2, swing: 0),
        seed: 5902,
        track: TimelineTrackType.melody,
        sectionId: 'verse-1',
        chordIndex: 1,
        ordinal: 1,
        startBeat: 1.0,
        durationBeats: 4,
        sectionStartBeat: 0,
      );

      expect(normal.articulation, ArticulationIntent.normal);
      expect(legato.articulation, ArticulationIntent.legato);
      expect(legato.maxDurationBeats, greaterThan(normal.maxDurationBeats));
    });

    test('performed duration is capped without changing written duration', () {
      final event = MusicalTimelineEvent(
        track: TimelineTrackType.melody,
        sectionId: 'chorus-1',
        chordIndex: 0,
        startBeat: 0,
        durationBeats: 4,
        velocity: 0.8,
        midiPitches: const <int>[72],
        label: 'C',
        performance: const PerformanceIntent(
          gateRatio: 0.9,
          maxDurationBeats: 1.2,
        ),
      );

      expect(event.durationBeats, 4);
      expect(event.performedDurationBeats, 1.2);
    });

    test('accent increases audible velocity while remaining bounded', () {
      final plain = MusicalTimelineEvent(
        track: TimelineTrackType.melody,
        sectionId: 'chorus-1',
        chordIndex: 0,
        startBeat: 0,
        durationBeats: 1,
        velocity: 0.72,
        midiPitches: const <int>[72],
        label: 'C',
        performance: const PerformanceIntent(
          velocityScale: 1.0,
          accent: 0,
          articulation: ArticulationIntent.normal,
        ),
      );
      final accented = MusicalTimelineEvent(
        track: TimelineTrackType.melody,
        sectionId: 'chorus-1',
        chordIndex: 0,
        startBeat: 0,
        durationBeats: 1,
        velocity: 0.72,
        midiPitches: const <int>[72],
        label: 'C',
        performance: const PerformanceIntent(
          velocityScale: 1.0,
          accent: 1,
          articulation: ArticulationIntent.accent,
        ),
      );

      expect(accented.performedVelocity, greaterThan(plain.performedVelocity));
      expect(accented.performedVelocity, inInclusiveRange(0.0, 1.0));
    });

    test('dense harmony receives automatic headroom compensation', () {
      final single = MusicalTimelineEvent(
        track: TimelineTrackType.harmony,
        sectionId: 'chorus-1',
        chordIndex: 0,
        startBeat: 0,
        durationBeats: 4,
        velocity: 0.8,
        midiPitches: const <int>[60],
        label: 'I',
      );
      final dense = MusicalTimelineEvent(
        track: TimelineTrackType.harmony,
        sectionId: 'chorus-1',
        chordIndex: 0,
        startBeat: 0,
        durationBeats: 4,
        velocity: 0.8,
        midiPitches: const <int>[60, 64, 67, 71, 74],
        label: 'Imaj9',
      );

      expect(dense.performedVelocity, lessThan(single.performedVelocity));
    });

    test('generated songs keep canonical structure while tightening playback gates', () {
      final session = SongSessionController();
      session.generate(
        request: const SongRequest(
          seed: 5906,
          key: KeyName.C,
          genre: GenreKey.soulfulRnb,
          mood: MoodType.dreamy,
          complexity: ComplexityLevel.medium,
          spice: SpiceLevel.medium,
          rhythm: RhythmLevel.moderate,
          candidateCount: 8,
          chordVariety: 60,
          includeMelody: true,
          includeBass: true,
        ),
      );
      final timeline = session.currentTimeline!;

      expect(timeline.totalBars, 64);
      for (final event in timeline.events) {
        expect(event.performedDurationBeats, lessThanOrEqualTo(event.durationBeats));
        expect(event.performedVelocity, inInclusiveRange(0.0, 1.0));
        if (event.track == TimelineTrackType.melody) {
          expect(event.performedDurationBeats, lessThanOrEqualTo(1.65));
        }
        if (event.track == TimelineTrackType.bass) {
          expect(event.performedDurationBeats, lessThanOrEqualTo(1.15));
        }
      }
    });
  });
}