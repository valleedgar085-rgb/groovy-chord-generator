import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/producer_song_variation_engine.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';
import 'package:groovy_chord_generator/engine/song_candidate.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/engine/song_timeline.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/app_state.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';
import 'package:groovy_chord_generator/services/producer_preference_store.dart';
import 'package:groovy_chord_generator/widgets/producer_song_variation_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Phase 5.4 full-song Producer A/B/C', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('builds three complete deterministic song directions with all layers', () {
      final first = _session();
      final firstVariations = first.buildProducerSongVariations(
        tempo: 118,
        swing: 0.08,
      );

      expect(firstVariations.length, 3);
      expect(
        firstVariations.map((variation) => variation.style).toSet(),
        <ProducerVariationStyle>{
          ProducerVariationStyle.polished,
          ProducerVariationStyle.creative,
          ProducerVariationStyle.hook,
        },
      );

      for (final variation in firstVariations) {
        expect(variation.draft.isComplete, isTrue);
        expect(variation.timeline.totalBeats, greaterThan(0));
        expect(variation.changedSectionCount, greaterThan(0));
        expect(variation.score, inInclusiveRange(0.0, 100.0));
        final tracks = variation.timeline.events.map((event) => event.track).toSet();
        expect(tracks, contains(TimelineTrackType.harmony));
        expect(tracks, contains(TimelineTrackType.melody));
        expect(tracks, contains(TimelineTrackType.bass));
      }

      final second = _session();
      final secondVariations = second.buildProducerSongVariations(
        tempo: 118,
        swing: 0.08,
      );

      expect(
        secondVariations.map(_songSignature).toList(growable: false),
        firstVariations.map(_songSignature).toList(growable: false),
      );
      expect(
        secondVariations.map((variation) => variation.score).toList(),
        firstVariations.map((variation) => variation.score).toList(),
      );
    });

    test('committed direction becomes replay base without replacing A/B/C source', () {
      final session = _session();
      final variations = session.buildProducerSongVariations(
        tempo: 118,
        swing: 0.08,
      );
      final originalOptions =
          variations.map(_songSignature).toList(growable: false);
      final creative = variations.firstWhere(
        (variation) => variation.style == ProducerVariationStyle.creative,
      );

      expect(session.applyProducerSongVariation(creative), isTrue);
      expect(
        session.activeProducerSongStyle,
        ProducerVariationStyle.creative,
      );
      final committed = _draftSignature(session);

      session.replay();

      expect(_draftSignature(session), committed);
      expect(
        session.activeProducerSongStyle,
        ProducerVariationStyle.creative,
      );
      expect(
        session
            .buildProducerSongVariations(tempo: 118, swing: 0.08)
            .map(_songSignature)
            .toList(growable: false),
        originalOptions,
      );
    });

    test('taste memory persists Producer direction choice counts', () async {
      final store = ProducerPreferenceStore.instance;
      await store.record(ProducerVariationStyle.creative);
      await store.record(ProducerVariationStyle.creative);
      final snapshot = await store.record(ProducerVariationStyle.hook);

      expect(snapshot.totalChoices, 3);
      expect(snapshot.countFor(ProducerVariationStyle.creative), 2);
      expect(snapshot.countFor(ProducerVariationStyle.hook), 1);
      expect(snapshot.preferredStyle, ProducerVariationStyle.creative);
      expect(
        snapshot.affinityFor(ProducerVariationStyle.creative),
        closeTo(2 / 3, 0.0001),
      );
    });

    testWidgets('full-song chooser renders without initializing preview audio',
        (tester) async {
      final session = _session();
      final appState = AppState();
      appState.setTempo(118);
      appState.setSwing(0.08);

      await tester.binding.setSurfaceSize(const Size(600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SizedBox(
              height: 1100,
              child: ProducerSongVariationSheet(
                appState: appState,
                songSession: session,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Full Song Producer A / B / C'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('producerSongVariation-polished')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('producerSongVariation-creative')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('producerSongVariation-hook')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('previewSong-creative')), findsOneWidget);
      expect(find.byKey(const ValueKey('useSong-creative')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

SongSessionController _session() {
  final request = SongRequest(
    seed: 540054,
    key: KeyName.C,
    genre: GenreKey.happyPop,
    mood: MoodType.happy,
    complexity: ComplexityLevel.medium,
    spice: SpiceLevel.medium,
    rhythm: RhythmLevel.moderate,
    section: HarmonySection.neutral,
    candidateCount: 8,
    chordVariety: 58,
    includeMelody: true,
    includeBass: true,
  );
  final session = SongSessionController();
  session.generate(
    request: request,
    plan: SongPlan.standard(seed: request.seed),
    bassStyle: BassStyle.fifths,
    bassVariety: 62,
    grooveTemplate: GrooveTemplate.straight,
  );
  return session;
}

String _songSignature(ProducerSongVariation variation) => variation.draft.sections
    .map((section) =>
        '${section.plan.id}:${section.progression.map((chord) => '${chord.root}/${chord.type}/${chord.degree}').join(',')}:${section.melody.map((note) => '${note.note}${note.octave}/${note.duration}/${note.chordIndex}').join(',')}:${section.bass.map((note) => '${note.note}${note.octave}/${note.duration}/${note.chordIndex}').join(',')}')
    .join('|');

String _draftSignature(SongSessionController session) => session.currentDraft!.sections
    .map((section) =>
        '${section.plan.id}:${section.progression.map((chord) => '${chord.root}/${chord.type}/${chord.degree}').join(',')}:${section.melody.map((note) => '${note.note}${note.octave}/${note.duration}/${note.chordIndex}').join(',')}:${section.bass.map((note) => '${note.note}${note.octave}/${note.duration}/${note.chordIndex}').join(',')}')
    .join('|');
