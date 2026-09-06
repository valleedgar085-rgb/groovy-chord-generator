import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/phrase_model.dart';
import 'package:groovy_chord_generator/engine/phrase_producer_brain.dart';
import 'package:groovy_chord_generator/engine/phrase_repair_engine.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';
import 'package:groovy_chord_generator/engine/song_draft.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/app_state.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';
import 'package:groovy_chord_generator/utils/music_theory.dart';
import 'package:groovy_chord_generator/widgets/producer_brain_panel.dart';

void main() {
  group('Phase 5.8D SongSession phrase repair', () {
    test('committed phrase repair becomes exact replay baseline', () {
      final stub = _StubPhraseRepairEngine();
      final session = SongSessionController(phraseRepairEngine: stub)
        ..generate(request: _request(580451));
      final baseline = session.currentDraft!;
      final section = baseline.sectionById('intro')!;
      expect(section.melody, isNotEmpty);

      final repairedSection = _changeFirstMelodyNote(section);
      final repairedDraft = baseline.withSection(repairedSection);
      final variant = _variant(
        draft: repairedDraft,
        beforeScore: 62.0,
        afterScore: 78.0,
      );
      stub.variant = variant;

      expect(session.applyPhraseRepairVariant(variant), isTrue);
      expect(session.phraseRepairFor('intro:p0'), PhraseRepairStyle.contourSmooth);
      expect(session.selectedSectionId, 'intro');
      final committed = _draftSignature(session.currentDraft!);
      expect(committed, isNot(_draftSignature(baseline)));

      session.replay();
      expect(_draftSignature(session.currentDraft!), committed);
      expect(session.phraseRepairFor('intro:p0'), PhraseRepairStyle.contourSmooth);
    });

    test('stale phrase repair preview is rejected before commit', () {
      final stub = _StubPhraseRepairEngine();
      final session = SongSessionController(phraseRepairEngine: stub)
        ..generate(request: _request(580452));
      final baseline = session.currentDraft!;
      final repairedDraft = baseline.withSection(
        _changeFirstMelodyNote(baseline.sectionById('intro')!),
      );
      final previewed = _variant(
        draft: repairedDraft,
        beforeScore: 60.0,
        afterScore: 76.0,
      );
      stub.variant = _variant(
        draft: repairedDraft,
        beforeScore: 61.0,
        afterScore: 77.0,
      );

      expect(session.applyPhraseRepairVariant(previewed), isFalse);
      expect(_draftSignature(session.currentDraft!), _draftSignature(baseline));
      expect(session.activePhraseRepairs, isEmpty);
    });
  });

  testWidgets('Producer strip exposes Phrase Repair Lab on a small Android width',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final appState = AppState();
    final session = SongSessionController()..generate(request: _request(580453));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          ChangeNotifierProvider<SongSessionController>.value(value: session),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProducerBrainPanel(appState: appState),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('phraseRepairButton')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('phraseRepairButton')));
    await tester.pumpAndSettle();

    expect(find.text('PHRASE REPAIR LAB'), findsOneWidget);
    expect(find.byType(OverflowBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

SongRequest _request(int seed) => SongRequest(
      seed: seed,
      key: KeyName.C,
      genre: GenreKey.happyPop,
      mood: MoodType.dreamy,
      complexity: ComplexityLevel.medium,
      spice: SpiceLevel.medium,
      rhythm: RhythmLevel.moderate,
      section: HarmonySection.neutral,
      candidateCount: 8,
      chordVariety: 60,
      includeMelody: true,
      includeBass: true,
    );

GeneratedSongSection _changeFirstMelodyNote(GeneratedSongSection section) {
  final melody = List<MelodyNote>.from(section.melody);
  final first = melody.first;
  final pitch = noteToPitch(first.note, first.octave);
  final changed = pitchToNote((pitch + 2).clamp(48, 96).toInt());
  melody[0] = MelodyNote(
    note: changed['note'] as String,
    octave: changed['octave'] as int,
    duration: first.duration,
    velocity: first.velocity,
    chordIndex: first.chordIndex,
  );
  return GeneratedSongSection(
    plan: section.plan,
    candidate: section.candidate,
    melody: melody,
    bass: section.bass,
    development: section.development,
  );
}

PhraseRepairVariant _variant({
  required SongDraft draft,
  required double beforeScore,
  required double afterScore,
}) {
  final before = _assessment(beforeScore);
  final after = _assessment(afterScore);
  return PhraseRepairVariant(
    style: PhraseRepairStyle.contourSmooth,
    draft: draft,
    before: before,
    after: after,
    beforeSongScore: 70.0,
    afterSongScore: 71.0,
    changedNoteCount: 1,
    summary: 'test repair',
  );
}

PhraseProducerAssessment _assessment(double score) => PhraseProducerAssessment(
      phraseId: 'intro:p0',
      sectionId: 'intro',
      phraseIndex: 0,
      role: PhraseRole.statement,
      score: score,
      metrics: [
        for (final dimension in PhraseProducerDimension.values)
          PhraseProducerMetric(dimension: dimension, score: score),
      ],
      lineage: PhraseLineageNode(
        phraseId: 'intro:p0',
        sourcePhraseId: 'intro:p0',
        relationship: PhraseRelationship.source,
        sourceSimilarity: 1.0,
        targetWindow: const PhraseSimilarityWindow(
          minimum: 0.98,
          maximum: 1.0,
          label: 'canonical source',
        ),
      ),
      issue: 'test issue',
      action: 'test action',
    );

class _StubPhraseRepairEngine extends PhraseRepairEngine {
  PhraseRepairVariant? variant;

  @override
  List<PhraseRepairVariant> build({
    required SongDraft draft,
    String? phraseId,
  }) {
    final current = variant;
    if (current == null) return const <PhraseRepairVariant>[];
    if (phraseId != null && phraseId != current.phraseId) {
      return const <PhraseRepairVariant>[];
    }
    return <PhraseRepairVariant>[current];
  }
}

String _draftSignature(SongDraft draft) => draft.sections.map((section) {
      final melody = section.melody
          .map((note) =>
              '${note.note}${note.octave}:${note.duration.toStringAsFixed(4)}:'
              '${note.velocity.toStringAsFixed(4)}:${note.chordIndex}')
          .join('|');
      final bass = section.bass
          .map((note) =>
              '${note.note}${note.octave}:${note.duration.toStringAsFixed(4)}:'
              '${note.velocity.toStringAsFixed(4)}:${note.chordIndex}')
          .join('|');
      return '${section.plan.id}#$melody#$bass';
    }).join('||');
