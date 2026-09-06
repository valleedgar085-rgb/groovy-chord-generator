import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/emotion_director.dart';
import 'package:groovy_chord_generator/engine/emotion_performance_shaper.dart';
import 'package:groovy_chord_generator/engine/genre_song_architecture.dart';
import 'package:groovy_chord_generator/engine/god_judge.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/performance_profile.dart';
import 'package:groovy_chord_generator/engine/producer_song_composer.dart';
import 'package:groovy_chord_generator/engine/producer_song_variation_engine.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';
import 'package:groovy_chord_generator/engine/song_draft.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/engine/song_timeline.dart';
import 'package:groovy_chord_generator/engine/song_timeline_builder.dart';
import 'package:groovy_chord_generator/models/types.dart';

void main() {
  group('GOD TEST — final output verification', () {
    test('emotion intent is materially different for opposite moods', () {
      const director = EmotionDirector();
      final chorus = SongPlan.standard(seed: 991001)
          .sections
          .firstWhere((section) => section.type == SongSectionType.chorus);
      final energetic = director.intentFor(
        mood: MoodType.energetic,
        section: chorus,
      );
      final relaxed = director.intentFor(
        mood: MoodType.relaxed,
        section: chorus,
      );
      final triumphant = director.intentFor(
        mood: MoodType.triumphant,
        section: chorus,
      );
      final dark = director.intentFor(
        mood: MoodType.dark,
        section: chorus,
      );

      expect(energetic.arousal, greaterThan(relaxed.arousal + 0.25));
      expect(energetic.velocityBias, greaterThan(relaxed.velocityBias));
      expect(triumphant.valence, greaterThan(dark.valence + 0.45));
      expect(triumphant.brightness, greaterThan(dark.brightness + 0.35));
      expect(dark.tension, greaterThan(relaxed.tension + 0.20));
    });

    test('emotion shaper changes expression but preserves musical identity', () {
      final request = _request(
        seed: 991002,
        genre: GenreKey.soulfulRnb,
        mood: MoodType.dreamy,
      );
      final draft = ProducerSongComposer().compose(
        request: request,
        plan: SongPlan.standard(seed: request.seed),
      );
      final section = draft.sections.firstWhere((item) => item.melody.length >= 5);
      final raw = section.melody;
      const shaper = EmotionPerformanceShaper();
      final energetic = shaper.shapeMelody(
        melody: raw,
        mood: MoodType.energetic,
        section: section.plan,
      );
      final relaxed = shaper.shapeMelody(
        melody: raw,
        mood: MoodType.relaxed,
        section: section.plan,
      );

      expect(_averageVelocity(energetic), greaterThan(_averageVelocity(relaxed)));
      expect(relaxed.length, lessThanOrEqualTo(energetic.length));
      expect(
        energetic.every((note) => note.chordIndex >= 0),
        isTrue,
      );
      expect(
        relaxed.every((note) => note.velocity >= 0.32 && note.velocity <= 1.0),
        isTrue,
      );
    });

    test('same song receives exactly the same God verdict every time', () {
      final request = _request(
        seed: 991003,
        genre: GenreKey.cinematic,
        mood: MoodType.triumphant,
      );
      final draft = ProducerSongComposer().compose(
        request: request,
        plan: GenreSongArchitecture.build(
          genre: request.genre,
          seed: request.seed,
        ),
      );
      final timeline = const SongTimelineBuilder().build(draft);
      const judge = GodJudge();

      final first = judge.evaluate(
        draft: draft,
        request: request,
        timeline: timeline,
      );
      final second = judge.evaluate(
        draft: draft,
        request: request,
        timeline: timeline,
      );

      expect(_verdictSignature(first), _verdictSignature(second));
      expect(first.score, second.score);
      expect(first.approved, second.approved);
      expect(first.blockers, orderedEquals(second.blockers));
    });

    test('God Judge rejects an emotionally dead one-note flatline', () {
      final request = _request(
        seed: 991004,
        genre: GenreKey.happyPop,
        mood: MoodType.energetic,
      );
      final good = ProducerSongComposer().compose(
        request: request,
        plan: SongPlan.standard(seed: request.seed),
      );
      final dead = _flattenSong(good);
      final verdict = const GodJudge().evaluate(
        draft: dead,
        request: request,
        timeline: const SongTimelineBuilder().build(dead),
      );

      expect(verdict.approved, isFalse);
      expect(verdict.blockers, isNotEmpty);
      expect(
        verdict.phrases.weakestPhrase?.score ?? 0,
        lessThan(70),
      );
    });

    test('God Judge rejects literal repeated-hook copy/paste', () {
      final request = _request(
        seed: 991005,
        genre: GenreKey.happyPop,
        mood: MoodType.happy,
      );
      final good = ProducerSongComposer().compose(
        request: request,
        plan: SongPlan.standard(seed: request.seed),
      );
      final copied = _copyFirstChorusIntoSecond(good);
      final verdict = const GodJudge().evaluate(
        draft: copied,
        request: request,
        timeline: const SongTimelineBuilder().build(copied),
      );

      expect(verdict.approved, isFalse);
      expect(verdict.phrases.guardrailViolations, greaterThan(0));
      expect(
        verdict.blockers.any((message) => message.contains('lineage')),
        isTrue,
      );
    });

    test('God Judge rejects unsafe long-gate playback even for a valid song', () {
      final request = _request(
        seed: 991006,
        genre: GenreKey.funk,
        mood: MoodType.energetic,
      );
      final draft = ProducerSongComposer().compose(
        request: request,
        plan: GenreSongArchitecture.build(
          genre: request.genre,
          seed: request.seed,
        ),
      );
      final safe = const SongTimelineBuilder().build(draft);
      final unsafe = _injectUnsafeMelodyGate(safe);
      final verdict = const GodJudge().evaluate(
        draft: draft,
        request: request,
        timeline: unsafe,
      );

      expect(verdict.approved, isFalse);
      expect(
        verdict.metrics
            .firstWhere((metric) => metric.dimension == GodJudgeDimension.performanceSafety)
            .passesFloor,
        isFalse,
      );
    });

    test('96-song genre x mood gauntlet never produces invalid judge state', () {
      const composer = ProducerSongComposer();
      const timelineBuilder = SongTimelineBuilder();
      const judge = GodJudge();
      var evaluated = 0;
      var approved = 0;

      for (final genre in GenreKey.values) {
        for (final mood in MoodType.values) {
          final seed = 992000 + genre.index * 100 + mood.index;
          final request = _request(seed: seed, genre: genre, mood: mood);
          final draft = ProducerSongComposer().compose(
            request: request,
            plan: GenreSongArchitecture.build(genre: genre, seed: seed),
          );
          final timeline = timelineBuilder.build(draft);
          final verdict = judge.evaluate(
            draft: draft,
            request: request,
            timeline: timeline,
          );
          evaluated++;
          if (verdict.approved) approved++;

          expect(draft.sections.length, draft.plan.sections.length, reason: '$genre/$mood');
          expect(verdict.score, inInclusiveRange(0.0, 100.0), reason: '$genre/$mood');
          expect(verdict.metrics, isNotEmpty, reason: '$genre/$mood');
          for (final metric in verdict.metrics) {
            expect(metric.score, inInclusiveRange(0.0, 100.0), reason: '$genre/$mood:${metric.label}');
          }
          if (verdict.approved) {
            expect(verdict.blockers, isEmpty, reason: '$genre/$mood');
            expect(verdict.metrics.where((metric) => metric.weight > 0).every((metric) => metric.passesFloor), isTrue);
          }
        }
      }

      expect(evaluated, 96);
      // This is not an acceptance-rate target. It simply proves the judge is not
      // impossible to satisfy while still allowing it to withhold weak material.
      expect(approved, greaterThan(0));
    });

    test('FINAL PREVIEW LAW: rejected songs can never appear in the selected three', () {
      var exposed = 0;
      var exposedRejected = 0;
      var evaluated = 0;
      var internallyApproved = 0;

      for (final genre in GenreKey.values) {
        final mood = _representativeMood(genre);
        final seed = 993000 + genre.index * 37;
        final request = _request(seed: seed, genre: genre, mood: mood);
        final base = ProducerSongComposer().compose(
          request: request,
          plan: GenreSongArchitecture.build(genre: genre, seed: seed),
          bassStyle: BassStyle.fifths,
          bassVariety: 62,
          grooveTemplate: _grooveFor(genre),
        );
        final engine = ProducerSongVariationEngine();
        final visible = engine.build(
          baseDraft: base,
          request: request,
          performanceProfile: const PerformanceProfile(
            looseness: 0.31,
            punch: 0.66,
            swing: 0.18,
          ),
          bassStyle: BassStyle.fifths,
          bassVariety: 62,
          grooveTemplate: _grooveFor(genre),
          tempo: 112,
          swing: 0.18,
        );
        final selection = engine.lastSelection;
        evaluated += selection.evaluated.length;
        internallyApproved += selection.approvedCount;

        expect(selection.evaluated.length, 4, reason: genre.name);
        expect(visible.length == 0 || visible.length == 3, isTrue, reason: genre.name);
        if (selection.approvedCount < 3) {
          expect(visible, isEmpty, reason: '${genre.name} leaked a partial preview');
        }
        if (visible.isNotEmpty) {
          expect(selection.satisfied, isTrue, reason: genre.name);
          for (final variation in visible) {
            exposed++;
            if (!variation.godApproved) exposedRejected++;
            expect(variation.verdict.blockers, isEmpty, reason: '${genre.name}/${variation.style.name}');
            expect(variation.verdict.score, greaterThanOrEqualTo(82.0));
          }
          for (var i = 1; i < visible.length; i++) {
            expect(
              visible[i - 1].finalQualityScore,
              greaterThanOrEqualTo(visible[i].finalQualityScore),
            );
          }
        }
      }

      expect(evaluated, GenreKey.values.length * 4);
      expect(internallyApproved, greaterThan(0));
      expect(exposedRejected, 0);
      // If anything is shown, exposure precision is literally 100% by contract.
      if (exposed > 0) {
        expect(exposedRejected / exposed, 0.0);
      }
    });
  });
}

SongRequest _request({
  required int seed,
  required GenreKey genre,
  required MoodType mood,
}) =>
    SongRequest(
      seed: seed,
      key: _keyFor(genre),
      genre: genre,
      mood: mood,
      complexity: ComplexityLevel.medium,
      spice: SpiceLevel.medium,
      rhythm: _rhythmFor(genre),
      section: HarmonySection.neutral,
      candidateCount: 8,
      chordVariety: 64,
      useVoiceLeading: true,
      useAdvancedTheory: true,
      useModalInterchange: mood == MoodType.dark || mood == MoodType.mysterious,
      useFunctionalHarmony: true,
      includeMelody: true,
      includeBass: true,
    );

SongDraft _flattenSong(SongDraft draft) {
  var result = SongDraft(plan: draft.plan);
  for (final section in draft.sections) {
    final melody = <MelodyNote>[
      for (final note in section.melody)
        MelodyNote(
          note: 'C',
          duration: 1.0,
          velocity: 0.55,
          chordIndex: note.chordIndex,
          octave: 4,
        ),
    ];
    result = result.withSection(
      GeneratedSongSection(
        plan: section.plan,
        candidate: section.candidate,
        melody: melody,
        bass: section.bass,
        development: section.development,
      ),
    );
  }
  return result;
}

SongDraft _copyFirstChorusIntoSecond(SongDraft draft) {
  final choruses = draft.sections
      .where((section) => section.plan.type == SongSectionType.chorus)
      .toList(growable: false);
  expect(choruses.length, greaterThanOrEqualTo(2));
  final source = choruses.first;
  final target = choruses[1];
  final sourceCount = source.progression.length;
  final targetCount = target.progression.length;
  final copied = <MelodyNote>[
    for (final note in source.melody)
      MelodyNote(
        note: note.note,
        duration: note.duration,
        velocity: note.velocity,
        chordIndex: sourceCount <= 1 || targetCount <= 1
            ? 0
            : ((note.chordIndex / (sourceCount - 1)) * (targetCount - 1))
                .round()
                .clamp(0, targetCount - 1),
        octave: note.octave,
      ),
  ];
  return draft.withSection(
    GeneratedSongSection(
      plan: target.plan,
      candidate: target.candidate,
      melody: copied,
      bass: target.bass,
      development: target.development,
    ),
  );
}

SongTimeline _injectUnsafeMelodyGate(SongTimeline timeline) {
  final events = List<MusicalTimelineEvent>.from(timeline.events);
  final index = events.indexWhere((event) => event.track == TimelineTrackType.melody);
  expect(index, greaterThanOrEqualTo(0));
  final original = events[index];
  events[index] = MusicalTimelineEvent(
    track: original.track,
    sectionId: original.sectionId,
    chordIndex: original.chordIndex,
    startBeat: original.startBeat,
    durationBeats: 8.0,
    velocity: original.velocity,
    midiPitches: original.midiPitches,
    label: original.label,
    performance: const PerformanceIntent(
      gateRatio: 1.0,
      velocityScale: 1.0,
      maxDurationBeats: double.infinity,
    ),
  );
  return SongTimeline(
    beatsPerBar: timeline.beatsPerBar,
    sections: timeline.sections,
    events: events,
    performanceProfile: timeline.performanceProfile,
  );
}

double _averageVelocity(List<MelodyNote> notes) => notes.isEmpty
    ? 0.0
    : notes.fold<double>(0.0, (sum, note) => sum + note.velocity) / notes.length;

String _verdictSignature(GodJudgeVerdict verdict) =>
    '${verdict.score.toStringAsFixed(6)}:${verdict.approved}:'
    '${verdict.metrics.map((metric) => '${metric.dimension.name}=${metric.score.toStringAsFixed(5)}').join('|')}:'
    '${verdict.blockers.join('~')}';

MoodType _representativeMood(GenreKey genre) => switch (genre) {
      GenreKey.happyPop => MoodType.happy,
      GenreKey.chillLofi => MoodType.relaxed,
      GenreKey.energeticEdm => MoodType.energetic,
      GenreKey.soulfulRnb => MoodType.dreamy,
      GenreKey.jazzFusion => MoodType.mysterious,
      GenreKey.darkTrap => MoodType.dark,
      GenreKey.cinematic => MoodType.triumphant,
      GenreKey.indieRock => MoodType.energetic,
      GenreKey.reggae => MoodType.relaxed,
      GenreKey.blues => MoodType.sad,
      GenreKey.country => MoodType.happy,
      GenreKey.funk => MoodType.energetic,
    };

GrooveTemplate _grooveFor(GenreKey genre) => switch (genre) {
      GenreKey.energeticEdm => GrooveTemplate.fourOnFloor,
      GenreKey.soulfulRnb => GrooveTemplate.neoSoulSwing,
      GenreKey.funk => GrooveTemplate.funkSyncopation,
      GenreKey.blues => GrooveTemplate.shuffle,
      GenreKey.darkTrap => GrooveTemplate.halfTime,
      _ => GrooveTemplate.straight,
    };

RhythmLevel _rhythmFor(GenreKey genre) => switch (genre) {
      GenreKey.chillLofi => RhythmLevel.soft,
      GenreKey.soulfulRnb => RhythmLevel.moderate,
      GenreKey.cinematic => RhythmLevel.moderate,
      GenreKey.energeticEdm => RhythmLevel.intense,
      GenreKey.darkTrap => RhythmLevel.strong,
      GenreKey.funk => RhythmLevel.intense,
      _ => RhythmLevel.strong,
    };

KeyName _keyFor(GenreKey genre) => switch (genre) {
      GenreKey.darkTrap => KeyName.Am,
      GenreKey.blues => KeyName.Em,
      GenreKey.soulfulRnb => KeyName.Dm,
      GenreKey.cinematic => KeyName.Dm,
      _ => KeyName.C,
    };
