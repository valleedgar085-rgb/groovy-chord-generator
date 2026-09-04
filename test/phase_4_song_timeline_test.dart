import 'package:flutter_test/flutter_test.dart';

import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';
import 'package:groovy_chord_generator/engine/song_candidate.dart';
import 'package:groovy_chord_generator/engine/song_draft.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/engine/song_timeline.dart';
import 'package:groovy_chord_generator/engine/song_timeline_builder.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';

SongRequest _request(int seed) => SongRequest(
      seed: seed,
      key: KeyName.C,
      genre: GenreKey.soulfulRnb,
      mood: MoodType.dreamy,
      complexity: ComplexityLevel.complex,
      spice: SpiceLevel.medium,
      rhythm: RhythmLevel.moderate,
      candidateCount: 8,
      chordVariety: 64,
      useVoiceLeading: true,
      useAdvancedTheory: true,
      useModalInterchange: true,
      useFunctionalHarmony: true,
      includeMelody: true,
      includeBass: true,
    );

List<String> _timelineSignature(SongTimeline timeline) => [
      ...timeline.sections.map(
        (section) =>
            'S:${section.id}:${section.startTick}:${section.durationTicks}',
      ),
      ...timeline.harmonyEvents.map(
        (event) =>
            'H:${event.id}:${event.startTick}:${event.durationTicks}:${event.chord.root}:${event.chord.type.name}',
      ),
      ...timeline.melodyEvents.map(
        (event) =>
            'M:${event.id}:${event.startTick}:${event.durationTicks}:${event.note}:${event.octave}:${event.velocity}',
      ),
      ...timeline.bassEvents.map(
        (event) =>
            'B:${event.id}:${event.startTick}:${event.durationTicks}:${event.note}:${event.octave}:${event.velocity}:${event.style.name}',
      ),
    ];

void main() {
  group('Phase 4 SongTimeline', () {
    test('standard song sections form one exact contiguous 4/4 clock', () {
      final session = SongSessionController();
      session.generate(request: _request(95001));
      final timeline = const SongTimelineBuilder().build(session.currentDraft!);

      expect(timeline.sections, hasLength(10));
      expect(timeline.totalBars, 64);
      expect(timeline.totalBeats, 256.0);
      expect(timeline.totalTicks, 64 * 4 * 960);
      expect(timeline.sections.first.startTick, 0);
      expect(timeline.sections.last.endTick, timeline.totalTicks);

      for (var i = 1; i < timeline.sections.length; i++) {
        expect(
          timeline.sections[i].startTick,
          timeline.sections[i - 1].endTick,
          reason: 'section boundaries must be contiguous',
        );
      }
    });

    test('harmony partitions every generated section without gaps or drift', () {
      final session = SongSessionController();
      session.generate(request: _request(95002));
      final timeline = const SongTimelineBuilder().build(session.currentDraft!);

      for (final section in timeline.sections) {
        final harmony = timeline.harmonyEvents
            .where((event) => event.sectionId == section.id)
            .toList(growable: false);
        expect(harmony, isNotEmpty, reason: '${section.id} needs harmony events');
        expect(harmony.first.startTick, section.startTick);
        expect(harmony.last.endTick, section.endTick);
        for (var i = 1; i < harmony.length; i++) {
          expect(harmony[i].startTick, harmony[i - 1].endTick);
        }
      }
    });

    test('melody and bass stay inside their referenced harmony slot', () {
      final session = SongSessionController();
      session.generate(request: _request(95003));
      final timeline = const SongTimelineBuilder().build(session.currentDraft!);
      final harmonyBySlot = <String, HarmonyTimelineEvent>{
        for (final event in timeline.harmonyEvents)
          '${event.sectionId}:${event.chordIndex}': event,
      };

      for (final event in timeline.melodyEvents) {
        final harmony = harmonyBySlot['${event.sectionId}:${event.chordIndex}'];
        expect(harmony, isNotNull);
        expect(event.startTick, greaterThanOrEqualTo(harmony!.startTick));
        expect(event.endTick, lessThanOrEqualTo(harmony.endTick));
      }
      for (final event in timeline.bassEvents) {
        final harmony = harmonyBySlot['${event.sectionId}:${event.chordIndex}'];
        expect(harmony, isNotNull);
        expect(event.startTick, greaterThanOrEqualTo(harmony!.startTick));
        expect(event.endTick, lessThanOrEqualTo(harmony.endTick));
      }
    });

    test('same deterministic song produces identical event ids and timing', () {
      final first = SongSessionController();
      final second = SongSessionController();
      first.generate(request: _request(95004));
      second.generate(request: _request(95004));

      final builder = const SongTimelineBuilder();
      final firstTimeline = builder.build(first.currentDraft!);
      final secondTimeline = builder.build(second.currentDraft!);
      expect(_timelineSignature(firstTimeline), _timelineSignature(secondTimeline));
    });

    test('local bridge regeneration preserves the arrangement clock', () {
      final session = SongSessionController();
      session.generate(request: _request(95005));
      const builder = SongTimelineBuilder();
      final before = builder.build(session.currentDraft!);

      expect(session.regenerateSection('bridge'), isTrue);
      final after = builder.build(session.currentDraft!);

      expect(
        after.sections
            .map((section) => '${section.id}:${section.startTick}:${section.durationTicks}')
            .toList(),
        before.sections
            .map((section) => '${section.id}:${section.startTick}:${section.durationTicks}')
            .toList(),
      );
      expect(after.totalTicks, before.totalTicks);
    });

    test('SongSession keeps timeline synchronized through regenerate replay clear', () {
      final session = SongSessionController();
      session.generate(request: _request(95007));

      expect(session.hasTimeline, isTrue);
      expect(session.currentTimeline, isNotNull);
      expect(session.selectedTimelineSection!.id, 'intro');
      expect(session.selectedTimelineEvents, isNotEmpty);

      expect(session.regenerateSection('bridge'), isTrue);
      expect(session.selectedSectionId, 'bridge');
      expect(session.selectedTimelineSection!.id, 'bridge');
      final regeneratedSignature = _timelineSignature(session.currentTimeline!);

      session.replay();
      expect(_timelineSignature(session.currentTimeline!), regeneratedSignature);
      expect(session.selectedTimelineSection!.id, 'bridge');

      session.clear();
      expect(session.currentTimeline, isNull);
      expect(session.hasTimeline, isFalse);
      expect(session.selectedTimelineEvents, isEmpty);
    });

    test('invalid note-to-chord references are rejected instead of hidden', () {
      const planSection = SongSectionPlan(
        id: 'verse',
        type: SongSectionType.verse,
        bars: 4,
        targetTension: 0.4,
        targetEnergy: 0.5,
      );
      final plan = SongPlan(seed: 95006, sections: const [planSection]);
      final badSection = GeneratedSongSection(
        plan: planSection,
        candidate: SongCandidate(
          progression: const [
            Chord(
              root: 'C',
              type: ChordTypeName.major,
              degree: 'I',
              numeral: 'I',
              harmonyFunction: HarmonyFunction.tonic,
            ),
          ],
          score: 80,
          seed: 1,
          candidateIndex: 0,
          section: HarmonySection.verse,
        ),
        melody: const [
          MelodyNote(
            note: 'E',
            duration: 1,
            velocity: 0.8,
            chordIndex: 2,
            octave: 4,
          ),
        ],
      );
      final draft = SongDraft(plan: plan).withSection(badSection);

      expect(
        () => const SongTimelineBuilder().build(draft),
        throwsA(isA<StateError>()),
      );
    });
  });
}
