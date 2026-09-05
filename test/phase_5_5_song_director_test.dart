import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';
import 'package:groovy_chord_generator/engine/song_candidate.dart';
import 'package:groovy_chord_generator/engine/song_director.dart';
import 'package:groovy_chord_generator/engine/song_draft.dart';
import 'package:groovy_chord_generator/engine/song_memory_extractor.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';
import 'package:groovy_chord_generator/widgets/song_director_sheet.dart';

void main() {
  group('Phase 5.5 Song Director', () {
    test('scores complete arrangement across seven song-level dimensions', () {
      final session = _session();
      final draft = session.currentDraft!;
      final analysis = const SongDirectorAnalyzer().analyze(
        draft: draft,
        memory: session.currentMemory,
      );

      expect(analysis.metrics.length, 7);
      expect(analysis.sections.length, draft.sections.length);
      expect(analysis.transitions.length, draft.sections.length - 1);
      expect(analysis.overallScore, inInclusiveRange(0.0, 100.0));
      expect(analysis.weakestLinkLabel, isNotEmpty);
      expect(
        analysis.metricFor(SongDirectorDimension.structure),
        isNotNull,
      );
      expect(
        analysis.metricFor(SongDirectorDimension.transitions),
        isNotNull,
      );
      expect(
        analysis.metricFor(SongDirectorDimension.chorusPayoff),
        isNotNull,
      );
      expect(
        analysis.metricFor(SongDirectorDimension.motifRecall),
        isNotNull,
      );
      expect(
        analysis.metricFor(SongDirectorDimension.energyCurve),
        isNotNull,
      );
      expect(
        analysis.metricFor(SongDirectorDimension.sectionContrast),
        isNotNull,
      );
      expect(
        analysis.metricFor(SongDirectorDimension.ending),
        isNotNull,
      );
    });

    test('transition map exposes duplicated boundary harmony as a weak handoff', () {
      final session = _session();
      final draft = session.currentDraft!;
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
      final changed = GeneratedSongSection(
        plan: chorus.plan,
        candidate: candidate,
        melody: chorus.melody,
        bass: chorus.bass,
        development: chorus.development,
      );
      final degraded = draft.withSection(changed);
      final memory = const SongMemoryExtractor().capture(degraded);
      final analysis = const SongDirectorAnalyzer().analyze(
        draft: degraded,
        memory: memory,
      );
      final transition = analysis.transitions.firstWhere(
        (item) => item.fromSectionId == 'pre-1' && item.toSectionId == 'chorus-1',
      );

      expect(transition.harmonyContinuity, 46.0);
      expect(transition.action, contains('pre-1'));
      expect(transition.action, contains('chorus-1'));
    });

    test('same generated song produces identical Director analysis', () {
      final first = _session();
      final second = _session();
      final analyzer = const SongDirectorAnalyzer();
      final a = analyzer.analyze(
        draft: first.currentDraft!,
        memory: first.currentMemory,
      );
      final b = analyzer.analyze(
        draft: second.currentDraft!,
        memory: second.currentMemory,
      );

      expect(b.overallScore, a.overallScore);
      expect(
        b.metrics.map((metric) => metric.score).toList(),
        a.metrics.map((metric) => metric.score).toList(),
      );
      expect(
        b.transitions.map((transition) => transition.score).toList(),
        a.transitions.map((transition) => transition.score).toList(),
      );
      expect(b.weakestLinkLabel, a.weakestLinkLabel);
    });

    testWidgets('Director sheet renders song map and navigates to a section',
        (tester) async {
      final session = _session();
      await tester.binding.setSurfaceSize(const Size(620, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SizedBox(
              height: 1100,
              child: SongDirectorSheet(songSession: session),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('SONG DIRECTOR'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('songDirectorWeakestLink')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('songDirectorMetric-transitions')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('songDirectorSection-chorus-1')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('songDirectorSection-chorus-1')),
      );
      await tester.pump();

      expect(session.selectedSectionId, 'chorus-1');
      expect(tester.takeException(), isNull);
    });
  });
}

SongSessionController _session() {
  final request = SongRequest(
    seed: 550055,
    key: KeyName.C,
    genre: GenreKey.happyPop,
    mood: MoodType.happy,
    complexity: ComplexityLevel.medium,
    spice: SpiceLevel.medium,
    rhythm: RhythmLevel.moderate,
    section: HarmonySection.neutral,
    candidateCount: 8,
    chordVariety: 60,
    includeMelody: true,
    includeBass: true,
  );
  final session = SongSessionController();
  session.generate(
    request: request,
    plan: SongPlan.standard(seed: request.seed),
    bassStyle: BassStyle.fifths,
    bassVariety: 60,
    grooveTemplate: GrooveTemplate.straight,
  );
  return session;
}
