import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/engine/song_timeline.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';
import 'package:groovy_chord_generator/widgets/song_timeline_preview.dart';

SongRequest _request({int seed = 404404}) => SongRequest(
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
      useFunctionalHarmony: false,
      includeMelody: true,
      includeBass: true,
    );

List<String> _timelineSignature(SongTimeline timeline) => timeline.events
    .map((event) =>
        '${event.track.name}:${event.sectionId}:${event.chordIndex}:${event.startBeat.toStringAsFixed(6)}:${event.durationBeats.toStringAsFixed(6)}:${event.midiPitches.join(',')}:${event.label}')
    .toList(growable: false);

void main() {
  group('Phase 4 unified musical timeline', () {
    test('standard song resolves to one exact 64-bar beat axis', () {
      final session = SongSessionController();
      session.generate(
        request: _request(),
        bassStyle: BassStyle.fifths,
        bassVariety: 60,
        grooveTemplate: GrooveTemplate.neoSoulSwing,
      );

      final timeline = session.currentTimeline;
      expect(timeline, isNotNull);
      expect(session.hasTimeline, isTrue);
      expect(timeline!.sections, hasLength(10));
      expect(timeline.totalBars, 64.0);
      expect(timeline.totalBeats, 256.0);
      expect(timeline.sections.first.id, 'intro');
      expect(timeline.sections.first.startBeat, 0.0);
      expect(timeline.sections.first.durationBeats, 16.0);
      expect(timeline.sectionById('verse-1')!.startBeat, 16.0);
      expect(timeline.sections.last.id, 'outro');
      expect(timeline.sections.last.endBeat, 256.0);
    });

    test('harmony melody and bass events stay inside their section windows', () {
      final session = SongSessionController();
      session.generate(request: _request(seed: 404405));
      final timeline = session.currentTimeline!;

      expect(timeline.eventsForTrack(TimelineTrackType.harmony), isNotEmpty);
      expect(timeline.eventsForTrack(TimelineTrackType.melody), isNotEmpty);
      expect(timeline.eventsForTrack(TimelineTrackType.bass), isNotEmpty);

      for (final event in timeline.events) {
        final section = timeline.sectionById(event.sectionId);
        expect(section, isNotNull);
        expect(event.startBeat, greaterThanOrEqualTo(section!.startBeat));
        expect(event.endBeat, lessThanOrEqualTo(section.endBeat + 0.000001));
        expect(event.durationBeats, greaterThan(0));
        expect(event.velocity, inInclusiveRange(0.0, 1.0));
        expect(event.midiPitches, isNotEmpty);
      }
    });

    test('selection regeneration and exact replay keep timeline synchronized', () {
      final session = SongSessionController();
      session.generate(request: _request(seed: 404406));

      expect(session.selectSection('chorus-2'), isTrue);
      expect(session.selectedTimelineSection!.id, 'chorus-2');
      expect(session.selectedTimelineSection!.startBeat, 144.0);

      expect(session.regenerateSection('chorus-1'), isTrue);
      final regenerated = _timelineSignature(session.currentTimeline!);
      final selectedBeforeReplay = session.selectedSectionId;

      session.replay();

      expect(session.selectedSectionId, selectedBeforeReplay);
      expect(
        _timelineSignature(session.currentTimeline!),
        orderedEquals(regenerated),
      );
    });

    testWidgets('timeline preview exposes tracks and section focus selection',
        (tester) async {
      final session = SongSessionController();
      session.generate(request: _request(seed: 404407));

      await tester.pumpWidget(
        ChangeNotifierProvider<SongSessionController>.value(
          value: session,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<SongSessionController>(
                builder: (context, liveSession, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: SongTimelinePreview(session: liveSession),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TIMELINE'), findsOneWidget);
      expect(find.text('64 BARS • 256 BEATS'), findsOneWidget);
      expect(find.text('HARMONY'), findsOneWidget);
      expect(find.text('MELODY'), findsOneWidget);
      expect(find.text('BASS'), findsOneWidget);
      expect(find.text('SECTION FOCUS • INTRO'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('timeline-section-verse-2')));
      await tester.pumpAndSettle();

      expect(session.selectedSectionId, 'verse-2');
      expect(find.text('SECTION FOCUS • V2'), findsOneWidget);
    });
  });
}
