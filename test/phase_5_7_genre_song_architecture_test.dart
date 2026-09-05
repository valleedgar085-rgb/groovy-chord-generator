import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/genre_song_architecture.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/app_state.dart';
import 'package:groovy_chord_generator/providers/create_mode_controller.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';
import 'package:groovy_chord_generator/widgets/create_mode_panel.dart';
import 'package:groovy_chord_generator/widgets/song_composer_sheet.dart';
import 'package:provider/provider.dart';

void main() {
  group('Phase 5.7 genre-aware song architecture', () {
    test('all genres produce deterministic valid arrangement blueprints', () {
      final signatures = <String>{};

      for (final genre in GenreKey.values) {
        final first = GenreSongArchitecture.build(genre: genre, seed: 570017);
        final second = GenreSongArchitecture.build(genre: genre, seed: 570017);

        expect(first.sections, isNotEmpty, reason: genre.name);
        expect(_signature(second), _signature(first), reason: genre.name);
        expect(
          first.sections.map((section) => section.id).toSet().length,
          first.sections.length,
          reason: '${genre.name} section ids must be unique',
        );
        expect(
          GenreSongArchitecture.totalBars(first),
          inInclusiveRange(32, 96),
          reason: genre.name,
        );

        for (final section in first.sections) {
          expect(section.bars, greaterThan(0), reason: '${genre.name}:${section.id}');
          expect(
            section.targetEnergy,
            inInclusiveRange(0.0, 1.0),
            reason: '${genre.name}:${section.id}',
          );
          expect(
            section.targetTension,
            inInclusiveRange(0.0, 1.0),
            reason: '${genre.name}:${section.id}',
          );
        }

        signatures.add(_signature(first));
      }

      expect(signatures.length, greaterThanOrEqualTo(10));
    });

    test('EDM uses build/drop/breakdown language with extended drops', () {
      final plan = GenreSongArchitecture.build(
        genre: GenreKey.energeticEdm,
        seed: 570021,
      );

      expect(plan.sections.map((section) => section.id), containsAllInOrder(<String>[
        'intro',
        'build-1',
        'drop-1',
        'breakdown',
        'build-2',
        'drop-2',
        'outro',
      ]));
      expect(plan.sectionById('drop-1')!.bars, 16);
      expect(plan.sectionById('drop-2')!.targetEnergy, 1.0);
      expect(plan.sectionById('build-2')!.targetTension, greaterThan(0.8));
    });

    test('Trap is hook-first and gives verses more structural space', () {
      final plan = GenreSongArchitecture.build(
        genre: GenreKey.darkTrap,
        seed: 570022,
      );

      expect(plan.sections[1].id, 'hook-1');
      expect(plan.sectionById('verse-1')!.bars, 16);
      expect(plan.sectionById('verse-2')!.bars, 16);
      expect(plan.sectionById('final-hook')!.variation, 2);
    });

    test('Blues keeps 12-bar statements instead of forcing pop form', () {
      final plan = GenreSongArchitecture.build(
        genre: GenreKey.blues,
        seed: 570023,
      );

      final statements = plan.sections
          .where((section) => section.id.startsWith('verse-'))
          .toList(growable: false);
      expect(statements.length, 3);
      expect(statements.every((section) => section.bars == 12), isTrue);
      expect(
        plan.sections.where((section) => section.type == SongSectionType.chorus),
        isEmpty,
      );
      expect(plan.sectionById('solo')!.bars, 12);
    });

    test('Lo-fi and cinematic plans expose their own development arcs', () {
      final lofi = GenreSongArchitecture.build(
        genre: GenreKey.chillLofi,
        seed: 570024,
      );
      final cinematic = GenreSongArchitecture.build(
        genre: GenreKey.cinematic,
        seed: 570025,
      );

      expect(lofi.sectionById('groove-a2')!.repetitionGroup, 'groove-a');
      expect(lofi.sectionById('groove-a3')!.variation, 2);
      expect(lofi.sectionById('breakdown'), isNotNull);

      expect(cinematic.sectionById('build-1'), isNotNull);
      expect(cinematic.sectionById('breakdown'), isNotNull);
      expect(cinematic.sectionById('final-climax')!.bars, 12);
      expect(cinematic.sectionById('final-climax')!.targetEnergy, 1.0);
    });

    testWidgets('Song Composer previews the selected genre form before generation',
        (tester) async {
      final appState = AppState()..setGenre(GenreKey.energeticEdm);
      final session = SongSessionController();
      await tester.binding.setSurfaceSize(const Size(620, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<SongSessionController>.value(value: session),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: SizedBox(
                height: 1100,
                child: SongComposerSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('genreArchitecturePreview')), findsOneWidget);
      expect(find.text('EDM BUILD / DROP'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('architectureSection-build-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('architectureSection-drop-1')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Create Full Song commits the current genre blueprint',
        (tester) async {
      final appState = AppState()..setGenre(GenreKey.darkTrap);
      final session = SongSessionController();
      final mode = CreateModeController()..setMode(CreateMode.fullSong);
      await tester.binding.setSurfaceSize(const Size(620, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<SongSessionController>.value(value: session),
            ChangeNotifierProvider<CreateModeController>.value(value: mode),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: CreateModePanel(),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('create-full-song-primary')));
      await tester.pump();

      final draft = session.currentDraft;
      expect(draft, isNotNull);
      expect(draft!.sectionById('hook-1'), isNotNull);
      expect(draft.sectionById('verse-1')!.plan.bars, 16);
      expect(draft.sectionById('final-hook'), isNotNull);
      expect(draft.sectionById('pre-1'), isNull);
      expect(tester.takeException(), isNull);
    });
  });
}

String _signature(SongPlan plan) => plan.sections
    .map(
      (section) => '${section.id}:${section.type.name}:${section.bars}:'
          '${section.targetTension.toStringAsFixed(2)}:'
          '${section.targetEnergy.toStringAsFixed(2)}:'
          '${section.repetitionGroup ?? '-'}:${section.variation}',
    )
    .join('|');
