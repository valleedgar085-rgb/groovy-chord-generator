import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groovy_chord_generator/engine/performance_intelligence_engine.dart';
import 'package:groovy_chord_generator/engine/performance_profile.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/engine/song_timeline.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';
import 'package:groovy_chord_generator/widgets/performance_controls.dart';

SongRequest _request({int seed = 425001}) => SongRequest(
      seed: seed,
      key: KeyName.C,
      genre: GenreKey.funk,
      mood: MoodType.energetic,
      complexity: ComplexityLevel.medium,
      spice: SpiceLevel.medium,
      rhythm: RhythmLevel.strong,
      candidateCount: 4,
      chordVariety: 58,
      useVoiceLeading: true,
      useAdvancedTheory: false,
      useModalInterchange: false,
      useFunctionalHarmony: true,
      includeMelody: true,
      includeBass: true,
    );

List<String> _structuralSignature(SongTimeline timeline) => timeline.events
    .map((event) =>
        '${event.track.name}:${event.sectionId}:${event.chordIndex}:${event.startBeat.toStringAsFixed(6)}:${event.durationBeats.toStringAsFixed(6)}:${event.midiPitches.join(',')}')
    .toList(growable: false);

List<String> _performanceSignature(SongTimeline timeline) => timeline.events
    .map((event) =>
        '${event.performance.timingOffsetBeats.toStringAsFixed(6)}:${event.performance.gateRatio.toStringAsFixed(6)}:${event.performance.velocityScale.toStringAsFixed(6)}:${event.performance.articulation.name}')
    .toList(growable: false);

void main() {
  group('Phase 4.25 performance intelligence', () {
    test('same seed and profile produce identical performance intent', () {
      const engine = PerformanceIntelligenceEngine();
      const profile = PerformanceProfile(looseness: 0.61, punch: 0.72, swing: 0.48);

      final first = engine.intentFor(
        profile: profile,
        seed: 99,
        track: TimelineTrackType.melody,
        sectionId: 'verse-1',
        chordIndex: 1,
        ordinal: 5,
        startBeat: 18.5,
        durationBeats: 0.5,
        sectionStartBeat: 16,
      );
      final second = engine.intentFor(
        profile: profile,
        seed: 99,
        track: TimelineTrackType.melody,
        sectionId: 'verse-1',
        chordIndex: 1,
        ordinal: 5,
        startBeat: 18.5,
        durationBeats: 0.5,
        sectionStartBeat: 16,
      );

      expect(second.timingOffsetBeats, first.timingOffsetBeats);
      expect(second.gateRatio, first.gateRatio);
      expect(second.velocityScale, first.velocityScale);
      expect(second.articulation, first.articulation);
    });

    test('swing delays off-eighth timing without mutating canonical beat', () {
      const engine = PerformanceIntelligenceEngine();
      final straight = engine.intentFor(
        profile: const PerformanceProfile(looseness: 0, punch: 0.5, swing: 0),
        seed: 1,
        track: TimelineTrackType.melody,
        sectionId: 'verse-1',
        chordIndex: 0,
        ordinal: 0,
        startBeat: 16.5,
        durationBeats: 0.5,
        sectionStartBeat: 16,
      );
      final swung = engine.intentFor(
        profile: const PerformanceProfile(looseness: 0, punch: 0.5, swing: 1),
        seed: 1,
        track: TimelineTrackType.melody,
        sectionId: 'verse-1',
        chordIndex: 0,
        ordinal: 0,
        startBeat: 16.5,
        durationBeats: 0.5,
        sectionStartBeat: 16,
      );

      expect(straight.timingOffsetBeats, 0);
      expect(swung.timingOffsetBeats, closeTo(0.16, 0.000001));
    });

    test('changing feel rebuilds performance but preserves song structure', () {
      final session = SongSessionController();
      session.generate(request: _request());
      final before = session.currentTimeline!;
      final beforeStructure = _structuralSignature(before);
      final beforePerformance = _performanceSignature(before);

      session.setPerformanceLooseness(0.82);
      session.setPerformancePunch(0.88);
      session.setPerformanceSwing(0.67);

      final after = session.currentTimeline!;
      expect(_structuralSignature(after), orderedEquals(beforeStructure));
      expect(_performanceSignature(after), isNot(orderedEquals(beforePerformance)));
      expect(after.totalBars, 64);
      expect(after.totalBeats, 256);
      for (final event in after.events) {
        expect(event.performedVelocity, inInclusiveRange(0.0, 1.0));
        expect(event.performance.gateRatio, inInclusiveRange(0.35, 1.0));
      }
    });

    test('replay preserves the active performance profile exactly', () {
      final session = SongSessionController();
      session.generate(request: _request(seed: 425002));
      session.setPerformanceLooseness(0.7);
      session.setPerformancePunch(0.76);
      session.setPerformanceSwing(0.52);
      final before = _performanceSignature(session.currentTimeline!);

      session.replay();

      expect(session.performanceProfile.looseness, 0.7);
      expect(session.performanceProfile.punch, 0.76);
      expect(session.performanceProfile.swing, 0.52);
      expect(_performanceSignature(session.currentTimeline!), orderedEquals(before));
    });

    testWidgets('performance UI stays compact and updates session feel',
        (tester) async {
      final session = SongSessionController();
      session.generate(request: _request(seed: 425003));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: PerformanceControls(session: session),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PERFORMANCE'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('performance-looseness')), findsNothing);

      await tester.tap(find.byKey(const ValueKey<String>('performance-toggle')));
      await tester.pumpAndSettle();

      expect(find.text('TIGHT'), findsOneWidget);
      expect(find.text('LOOSE'), findsOneWidget);
      expect(find.text('SOFT'), findsOneWidget);
      expect(find.text('PUNCHY'), findsOneWidget);
      expect(find.text('STRAIGHT'), findsOneWidget);
      expect(find.text('SWING'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('performance-looseness')), findsOneWidget);
    });
  });
}
