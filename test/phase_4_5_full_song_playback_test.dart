import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/engine/song_timeline.dart';
import 'package:groovy_chord_generator/engine/timeline_playback_plan.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';
import 'package:groovy_chord_generator/services/audio_playback_service.dart';
import 'package:groovy_chord_generator/widgets/full_song_transport.dart';

SongRequest _request({int seed = 450001}) => SongRequest(
      seed: seed,
      key: KeyName.C,
      genre: GenreKey.soulfulRnb,
      mood: MoodType.dreamy,
      complexity: ComplexityLevel.medium,
      spice: SpiceLevel.medium,
      rhythm: RhythmLevel.moderate,
      candidateCount: 4,
      chordVariety: 58,
      useVoiceLeading: true,
      useAdvancedTheory: false,
      useModalInterchange: false,
      useFunctionalHarmony: true,
      includeMelody: true,
      includeBass: true,
    );

void main() {
  group('Phase 4.5 full-song playback planning', () {
    test('full-song plan contains performed harmony melody and bass', () {
      final session = SongSessionController()..generate(request: _request());
      final timeline = session.currentTimeline!;
      const planner = TimelinePlaybackPlanner();

      final plan = planner.build(timeline);

      expect(plan.startBeat, 0);
      expect(plan.endBeat, 256);
      expect(plan.durationBeats, 256);
      expect(plan.eventsForTrack(TimelineTrackType.harmony), isNotEmpty);
      expect(plan.eventsForTrack(TimelineTrackType.melody), isNotEmpty);
      expect(plan.eventsForTrack(TimelineTrackType.bass), isNotEmpty);
      for (final event in plan.events) {
        expect(event.startBeat, greaterThanOrEqualTo(0));
        expect(event.endBeat, lessThanOrEqualTo(256.000001));
        expect(event.durationBeats, greaterThan(0));
      }
    });

    test('mute and solo filtering follow mixer semantics', () {
      final session = SongSessionController()..generate(request: _request(seed: 450002));
      final timeline = session.currentTimeline!;
      const planner = TimelinePlaybackPlanner();

      final muted = planner.build(
        timeline,
        mutedTracks: const <TimelineTrackType>{TimelineTrackType.melody},
      );
      expect(muted.eventsForTrack(TimelineTrackType.melody), isEmpty);
      expect(muted.eventsForTrack(TimelineTrackType.harmony), isNotEmpty);
      expect(muted.eventsForTrack(TimelineTrackType.bass), isNotEmpty);

      final soloBass = planner.build(
        timeline,
        mutedTracks: const <TimelineTrackType>{TimelineTrackType.bass},
        soloTracks: const <TimelineTrackType>{TimelineTrackType.bass},
      );
      expect(soloBass.eventsForTrack(TimelineTrackType.bass), isNotEmpty);
      expect(soloBass.eventsForTrack(TimelineTrackType.harmony), isEmpty);
      expect(soloBass.eventsForTrack(TimelineTrackType.melody), isEmpty);
    });

    test('seeking into a sustained event clips only the playback manifest', () {
      final session = SongSessionController()..generate(request: _request(seed: 450003));
      final timeline = session.currentTimeline!;
      const planner = TimelinePlaybackPlanner();
      final source = timeline.eventsForTrack(TimelineTrackType.harmony).first;
      final performedStart = source.performedStartBeat.clamp(0.0, timeline.totalBeats);
      final seekBeat = performedStart + (source.performedDurationBeats * 0.5);

      final plan = planner.build(
        timeline,
        startBeat: seekBeat,
        endBeat: seekBeat + 1,
      );
      final clipped = plan.events.where((event) => identical(event.source, source)).first;

      expect(clipped.startBeat, closeTo(seekBeat, 0.000001));
      expect(clipped.durationBeats, lessThan(source.performedDurationBeats));
      // Canonical composition data must remain untouched by seeking.
      expect(source.startBeat, 0);
      expect(source.durationBeats, greaterThan(0));
    });

    test('section playback plan never escapes the selected section', () {
      final session = SongSessionController()..generate(request: _request(seed: 450004));
      final timeline = session.currentTimeline!;
      const planner = TimelinePlaybackPlanner();
      final section = timeline.sectionById('chorus-1')!;

      final plan = planner.section(timeline, section.id);

      expect(plan.startBeat, section.startBeat);
      expect(plan.endBeat, section.endBeat);
      expect(plan.events, isNotEmpty);
      for (final event in plan.events) {
        expect(event.startBeat, greaterThanOrEqualTo(section.startBeat));
        expect(event.endBeat, lessThanOrEqualTo(section.endBeat + 0.000001));
      }
    });

    testWidgets('full-song transport stays compact and navigates sections',
        (tester) async {
      final session = SongSessionController()..generate(request: _request(seed: 450005));
      final audio = AudioPlaybackService.instance;
      audio.setLooping(false);
      audio.clearTrackMix();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: FullSongTransport(session: session),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('full-song-transport')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('song-seek-slider')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('song-play-stop')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('song-play-section')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('song-section-loop')), findsOneWidget);
      expect(find.text('CHORD'), findsOneWidget);
      expect(find.text('MELODY'), findsOneWidget);
      expect(find.text('BASS'), findsOneWidget);
      expect(session.selectedSectionId, 'intro');

      await tester.tap(find.byKey(const ValueKey<String>('song-next-section')));
      await tester.pumpAndSettle();
      expect(session.selectedSectionId, 'verse-1');

      await tester.tap(find.byKey(const ValueKey<String>('song-section-loop')));
      await tester.pumpAndSettle();
      expect(audio.looping, isTrue);

      audio.setLooping(false);
      audio.clearTrackMix();
    });
  });
}
