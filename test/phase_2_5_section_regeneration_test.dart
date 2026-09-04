import 'package:flutter_test/flutter_test.dart';

import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/engine/song_draft.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';

SongRequest requestFor(int seed) => SongRequest(
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

String sectionSignature(GeneratedSongSection section) {
  final harmony = section.progression
      .map((chord) => '${chord.root}:${chord.type.name}:${chord.degree}')
      .join('|');
  final melody = section.melody
      .map((note) => '${note.note}:${note.octave}:${note.duration}:${note.velocity}')
      .join('|');
  final bass = section.bass
      .map((note) => '${note.note}:${note.octave}:${note.duration}:${note.velocity}')
      .join('|');
  return '${section.candidate.seed}#${section.candidate.candidateIndex}#$harmony#$melody#$bass';
}

Map<String, String> draftSignatures(SongDraft draft) => {
      for (final section in draft.sections)
        section.plan.id: sectionSignature(section),
    };

void main() {
  group('Phase 2.5 section regeneration', () {
    test('regeneration replaces only the requested section', () {
      final session = SongSessionController();
      session.generate(request: requestFor(41001));
      final before = draftSignatures(session.currentDraft!);

      expect(session.selectSection('chorus-1'), isTrue);
      expect(session.regenerateSection(), isTrue);

      final after = draftSignatures(session.currentDraft!);
      expect(session.selectedSectionId, 'chorus-1');
      expect(session.revisionFor('chorus-1'), 1);
      expect(session.sectionRevisions, {'chorus-1': 1});

      for (final entry in before.entries) {
        if (entry.key == 'chorus-1') continue;
        expect(after[entry.key], entry.value, reason: '${entry.key} must be preserved');
      }
      expect(
        session.currentDraft!.sectionById('chorus-1')!.candidate.seed,
        isNot(session.currentDraft!.sectionById('chorus-2')!.candidate.seed),
      );
    });

    test('same song and same revision reproduce the same replacement', () {
      final first = SongSessionController();
      final second = SongSessionController();
      final request = requestFor(41002);

      first.generate(request: request);
      second.generate(request: request);
      expect(first.regenerateSection('bridge'), isTrue);
      expect(second.regenerateSection('bridge'), isTrue);

      expect(
        sectionSignature(first.currentDraft!.sectionById('bridge')!),
        sectionSignature(second.currentDraft!.sectionById('bridge')!),
      );
    });

    test('later revisions receive a distinct deterministic candidate lineage', () {
      final session = SongSessionController();
      session.generate(request: requestFor(41003));

      expect(session.regenerateSection('verse-2'), isTrue);
      final revisionOneSeed =
          session.currentDraft!.sectionById('verse-2')!.candidate.seed;
      expect(session.revisionFor('verse-2'), 1);

      expect(session.regenerateSection('verse-2'), isTrue);
      final revisionTwoSeed =
          session.currentDraft!.sectionById('verse-2')!.candidate.seed;
      expect(session.revisionFor('verse-2'), 2);
      expect(revisionTwoSeed, isNot(revisionOneSeed));
    });

    test('replay reconstructs regeneration operations in their original order', () {
      final session = SongSessionController();
      session.generate(request: requestFor(41004));

      expect(session.regenerateSection('chorus-1'), isTrue);
      expect(session.regenerateSection('verse-1'), isTrue);
      expect(session.regenerateSection('chorus-1'), isTrue);
      expect(session.selectSection('chorus-1'), isTrue);

      final beforeReplay = draftSignatures(session.currentDraft!);
      final revisionsBefore = Map<String, int>.from(session.sectionRevisions);

      session.replay();

      expect(draftSignatures(session.currentDraft!), beforeReplay);
      expect(session.sectionRevisions, revisionsBefore);
      expect(session.revisionFor('chorus-1'), 2);
      expect(session.revisionFor('verse-1'), 1);
      expect(session.selectedSectionId, 'chorus-1');
    });

    test('unknown section regeneration is rejected without mutation', () {
      final session = SongSessionController();
      session.generate(request: requestFor(41005));
      final before = draftSignatures(session.currentDraft!);

      expect(session.regenerateSection('missing-section'), isFalse);
      expect(draftSignatures(session.currentDraft!), before);
      expect(session.sectionRevisions, isEmpty);
    });
  });
}
