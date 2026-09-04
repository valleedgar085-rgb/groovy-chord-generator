import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:groovy_chord_generator/engine/harmony_candidate_pool.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/seeded_harmony_builder.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/app_state.dart';
import 'package:groovy_chord_generator/providers/song_request_adapter.dart';
import 'package:groovy_chord_generator/screens/generator_workspace.dart';

String _chordSignature(Chord chord) =>
    '${chord.root}:${chord.type.name}:${chord.degree}:${chord.numeral}';

void main() {
  group('Phase 3.75 generator unification', () {
    test('AppState progression matches the canonical shared harmony builder', () {
      final state = AppState();
      state.setGenre(GenreKey.soulfulRnb);
      state.setCurrentKey(KeyName.C);
      state.setUseVoiceLeading(false);
      state.setUseFunctionalHarmony(true);
      state.setUseAdvancedTheory(true);
      state.setUseModalInterchange(true);
      state.setChordVariety(67);

      const seed = 375207;
      final request = SongRequestAdapter.fromAppState(state, seed: seed);
      const builder = SeededHarmonyBuilder();
      final pool = HarmonyCandidatePool(engine: HarmonyEngine());
      final expected = pool.generateBestForRequest(
        request: request,
        buildCandidate: (candidateSeed, candidateIndex) => builder.build(
          request: request,
          random: Random(candidateSeed),
        ),
      );

      state.generateProgression(seed: seed);

      expect(state.currentProgression, isNotEmpty);
      expect(
        state.currentProgression.map(_chordSignature).toList(),
        expected.progression.map(_chordSignature).toList(),
      );
      expect(state.lastHarmonyScore, expected.score);
    });

    test('locked chord survives shared-builder regeneration', () {
      final state = AppState();
      state.setUseVoiceLeading(false);
      state.generateProgression(seed: 375301);
      expect(state.currentProgression, isNotEmpty);

      final locked = _chordSignature(state.currentProgression.first);
      state.toggleChordLock(0);
      state.generateProgression(seed: 375302);

      expect(_chordSignature(state.currentProgression.first), locked);
    });

    testWidgets('compact Create workspace replaces the old primary FAB flow',
        (tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(body: GeneratorWorkspace()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SESSION SETUP'), findsOneWidget);
      expect(find.text('PROGRESSION STAGE'), findsOneWidget);
      expect(find.text('MORE TOOLS'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}
