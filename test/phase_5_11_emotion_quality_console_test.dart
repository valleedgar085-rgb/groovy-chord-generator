import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groovy_chord_generator/engine/emotion_director.dart';
import 'package:groovy_chord_generator/engine/god_judge.dart';
import 'package:groovy_chord_generator/engine/phrase_producer_brain.dart';
import 'package:groovy_chord_generator/engine/song_director.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/app_state.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';
import 'package:groovy_chord_generator/widgets/emotion_quality_console.dart';

GodJudgeVerdict _verdict({required bool approved}) {
  final score = approved ? 91.0 : 63.0;
  return GodJudgeVerdict(
    score: score,
    approved: approved,
    metrics: <GodJudgeMetric>[
      GodJudgeMetric(
        dimension: GodJudgeDimension.localCraft,
        label: 'Local Craft',
        score: approved ? 90.0 : 61.0,
        minimum: 72.0,
        weight: 0.12,
      ),
      GodJudgeMetric(
        dimension: GodJudgeDimension.emotion,
        label: 'Emotion',
        score: approved ? 88.0 : 52.0,
        minimum: 70.0,
        weight: 0.16,
      ),
    ],
    blockers: approved ? const <String>[] : const <String>['Emotion 52 < 70.'],
    emotion: EmotionSongAnalysis(
      overallScore: approved ? 88.0 : 52.0,
      metrics: <EmotionMetric>[
        EmotionMetric(
          dimension: EmotionDimension.moodFidelity,
          score: approved ? 86.0 : 50.0,
          label: 'Mood Fidelity',
          insight: 'Synthetic emotional diagnostic.',
        ),
      ],
      peakSectionId: 'chorus-1',
      dynamicRange: 0.31,
    ),
    director: SongDirectorAnalysis.empty(),
    phrases: SongPhraseProducerAnalysis.empty(),
  );
}

void main() {
  group('Phase 5.11 emotion + final quality UI', () {
    testWidgets('primary Emotion control changes the real AppState mood',
        (tester) async {
      final appState = AppState()..setMood(MoodType.dreamy);
      final session = SongSessionController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmotionQualityStrip(
              appState: appState,
              songSession: session,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('emotionControl')), findsOneWidget);
      expect(find.text('Dreamy'), findsOneWidget);
      expect(find.text('AFTER FULL SONG'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('emotionControl')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('mood-triumphant')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('mood-triumphant')),
      );
      await tester.pumpAndSettle();

      expect(appState.currentMood, MoodType.triumphant);
      expect(find.text('Triumphant'), findsOneWidget);
    });

    testWidgets('approved verdict is explained without weakening the gate',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GodQualityConsoleSheet(
              verdict: _verdict(approved: true),
              mood: MoodType.dreamy,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('APPROVED FOR PRODUCER PREVIEW'), findsOneWidget);
      expect(find.textContaining('ELITE'), findsOneWidget);
      expect(find.text('91.0'), findsOneWidget);
      expect(find.text('Local Craft'), findsOneWidget);
      expect(find.text('Emotion'), findsOneWidget);
      expect(find.textContaining('Mood Fidelity'), findsWidgets);
    });

    testWidgets('held verdict exposes blockers and weakest quality dimension',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GodQualityConsoleSheet(
              verdict: _verdict(approved: false),
              mood: MoodType.dark,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('QUALITY HOLD'), findsOneWidget);
      expect(find.textContaining('HELD'), findsOneWidget);
      expect(find.textContaining('Emotion 52 < 70.'), findsOneWidget);
      expect(find.textContaining('Weakest measurable link'), findsOneWidget);
      expect(find.text('63.0'), findsOneWidget);
    });
  });
}
