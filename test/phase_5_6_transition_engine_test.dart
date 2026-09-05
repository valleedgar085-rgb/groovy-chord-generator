import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';
import 'package:groovy_chord_generator/engine/song_candidate.dart';
import 'package:groovy_chord_generator/engine/song_director.dart';
import 'package:groovy_chord_generator/engine/song_draft.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/engine/transition_repair_engine.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/app_state.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';
import 'package:groovy_chord_generator/widgets/transition_repair_sheet.dart';

void main() {
  group('Phase 5.6 Transition Engine', () {
    test('dominant lift repairs duplicated boundary harmony without regression', () {
      final session = _session();
      final degraded = _degradePreToChorus(session.currentDraft!);
      const engine = TransitionRepairEngine();
      final variants = engine.build(
        draft: degraded,
        fromSectionId: 'pre-1',
        toSectionId: 'chorus-1',
      );
      final dominant = variants.firstWhere(
        (variant) => variant.style == TransitionRepairStyle.dominantLift,
      );

      expect(dominant.before.harmonyContinuity, 46.0);
      expect(dominant.after.harmonyContinuity, greaterThanOrEqualTo(90.0));
      expect(dominant.after.score, greaterThanOrEqualTo(dominant.before.score));
      expect(dominant.scoreDelta, greaterThan(0.0));
      expect(dominant.changedParts, contains('outgoing harmony'));
    });

    test('safe repairs never mutate unrelated song sections', () {
      final session = _session();
      final draft = _degradePreToChorus(session.currentDraft!);
      final variants = const TransitionRepairEngine().build(
        draft: draft,
        fromSectionId: 'pre-1',
        toSectionId: 'chorus-1',
      );
      expect(variants, isNotEmpty);

      final repaired = variants.first.draft;
      for (final section in draft.sections) {
        if (section.plan.id == 'pre-1' || section.plan.id == 'chorus-1') {
          continue;
        }
        expect(
          _sectionSignature(repaired.sectionById(section.plan.id)!),
          _sectionSignature(section),
          reason: '${section.plan.id} should not change during boundary repair',
        );
      }
    });

    test('transition alternatives are deterministic and non-regressing', () {
      final draftA = _degradePreToChorus(_session().currentDraft!);
      final draftB = _degradePreToChorus(_session().currentDraft!);
      const engine = TransitionRepairEngine();
      final first = engine.build(
        draft: draftA,
        fromSectionId: 'pre-1',
        toSectionId: 'chorus-1',
      );
      final second = engine.build(
        draft: draftB,
        fromSectionId: 'pre-1',
        toSectionId: 'chorus-1',
      );

      expect(first.map((item) => item.style), second.map((item) => item.style));
      expect(
        first.map((item) => item.after.score),
        second.map((item) => item.after.score),
      );
      expect(
        first.every((item) => item.after.score + 0.01 >= item.before.score),
        isTrue,
      );
    });

    test('non-adjacent sections cannot receive a transition patch', () {
      final session = _session();
      final variants = const TransitionRepairEngine().build(
        draft: session.currentDraft!,
        fromSectionId: 'verse-1',
        toSectionId: 'chorus-1',
      );
      expect(variants, isEmpty);
    });

    test('committed transition repair becomes exact replay baseline', () {
      final session = _session();
      final director = const SongDirectorAnalyzer().analyze(
        draft: session.currentDraft!,
        memory: session.currentMemory,
      );
      final transition = director.weakestTransition!;
      final variants = session.buildTransitionRepairVariants(
        transition.fromSectionId,
        transition.toSectionId,
      );
      final improved = variants.where((variant) => variant.improved).toList();
      expect(improved, isNotEmpty);

      final chosen = improved.first;
      expect(session.applyTransitionRepairVariant(chosen), isTrue);
      final committed = _draftSignature(session.currentDraft!);
      expect(
        session.transitionRepairFor(
          transition.fromSectionId,
          transition.toSectionId,
        ),
        chosen.style,
      );
      expect(session.selectedSectionId, transition.toSectionId);

      session.replay();
      expect(_draftSignature(session.currentDraft!), committed);
      expect(
        session.transitionRepairFor(
          transition.fromSectionId,
          transition.toSectionId,
        ),
        chosen.style,
      );
    });

    testWidgets('Transition Lab renders without initializing preview audio',
        (tester) async {
      final session = _session();
      final analysis = const SongDirectorAnalyzer().analyze(
        draft: session.currentDraft!,
        memory: session.currentMemory,
      );
      final transition = analysis.weakestTransition!;
      final appState = AppState();
      await tester.binding.setSurfaceSize(const Size(620, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SizedBox(
              height: 1100,
              child: TransitionRepairSheet(
                appState: appState,
                songSession: session,
                fromSectionId: transition.fromSectionId,
                toSectionId: transition.toSectionId,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('TRANSITION LAB'), findsOneWidget);
      expect(find.byKey(const ValueKey('stopTransitionPreview')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

SongSessionController _session() {
  final request = SongRequest(
    seed: 560056,
    key: KeyName.C,
    genre: GenreKey.happyPop,
    mood: MoodType.happy,
    complexity: ComplexityLevel.medium,
    spice: SpiceLevel.medium,
    rhythm: RhythmLevel.moderate,
    section: HarmonySection.neutral,
    candidateCount: 8,
    chordVariety: 62,
    includeMelody: true,
    includeBass: true,
  );
  final session = SongSessionController();
  session.generate(
    request: request,
    plan: SongPlan.standard(seed: request.seed),
    bassStyle: BassStyle.fifths,
    bassVariety: 64,
    grooveTemplate: GrooveTemplate.straight,
  );
  return session;
}

SongDraft _degradePreToChorus(SongDraft draft) {
  final pre = draft.sectionById('pre-1')!;
  final chorus = draft.sectionById('chorus-1')!;
  final progression = <Chord>[
    pre.progression.last,
    ...chorus.progression.skip(1),
  ];
  final candidate = SongCandidate(
    progression: progression,
    score: chorus.candidate.score,
    seed: chorus.candidate.seed,
    candidateIndex: chorus.candidate.candidateIndex,
    section: chorus.candidate.section,
    producerAnalysis: chorus.candidate.producerAnalysis,
    variationStyle: chorus.candidate.variationStyle,
    beforeRefineScore: chorus.candidate.beforeRefineScore,
    repairs: chorus.candidate.repairs,
  );
  return draft.withSection(
    GeneratedSongSection(
      plan: chorus.plan,
      candidate: candidate,
      melody: chorus.melody,
      bass: chorus.bass,
      development: chorus.development,
    ),
  );
}

String _draftSignature(SongDraft draft) =>
    draft.sections.map(_sectionSignature).join('|');

String _sectionSignature(GeneratedSongSection section) {
  final harmony = section.progression
      .map((chord) => '${chord.root}:${chord.type.index}:${chord.degree}')
      .join(',');
  final melody = section.melody
      .map((note) =>
          '${note.note}${note.octave}:${note.duration}:${note.velocity}:${note.chordIndex}')
      .join(',');
  final bass = section.bass
      .map((note) =>
          '${note.note}${note.octave}:${note.duration}:${note.velocity}:${note.chordIndex}:${note.style.index}')
      .join(',');
  return '${section.plan.id}[$harmony][$melody][$bass]';
}