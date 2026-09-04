import 'package:flutter_test/flutter_test.dart';

import 'package:groovy_chord_generator/engine/song_draft.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';

SongRequest dependencyRequest(int seed) => SongRequest(
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

List<String> _sectionSignature(GeneratedSongSection section) => [
      ...section.progression.map(
        (chord) => '${chord.root}:${chord.degree}:${chord.type.name}',
      ),
      '|melody|',
      ...section.melody.map(
        (note) =>
            '${note.note}:${note.octave}:${note.duration}:${note.velocity}:${note.chordIndex}',
      ),
      '|bass|',
      ...section.bass.map(
        (note) =>
            '${note.note}:${note.octave}:${note.duration}:${note.velocity}:${note.chordIndex}:${note.style.name}',
      ),
    ];

void main() {
  group('Phase 3 repetition dependency propagation', () {
    test('regenerating Verse 1 re-derives Verse 2 and replay restores both', () {
      final session = SongSessionController();
      session.generate(request: dependencyRequest(92001));
      expect(session.selectSection('verse-1'), isTrue);
      expect(session.regenerateSection(), isTrue);

      final verse1 = session.currentDraft!.sectionById('verse-1')!;
      final verse2 = session.currentDraft!.sectionById('verse-2')!;
      expect(verse2.progression.first.degree, verse1.progression.first.degree);
      expect(verse2.progression.last.degree, verse1.progression.last.degree);
      expect(session.currentMemory!.section('verse-2')!.sourceSectionId, 'verse-1');

      final verse1Signature = _sectionSignature(verse1);
      final verse2Signature = _sectionSignature(verse2);
      final verse2Similarity = session.currentMemory!.similarity('verse-1', 'verse-2');

      session.replay();
      expect(
        _sectionSignature(session.currentDraft!.sectionById('verse-1')!),
        verse1Signature,
      );
      expect(
        _sectionSignature(session.currentDraft!.sectionById('verse-2')!),
        verse2Signature,
      );
      expect(
        session.currentMemory!.similarity('verse-1', 'verse-2'),
        verse2Similarity,
      );
      expect(session.revisionFor('verse-1'), 1);
    });

    test('regenerating Chorus 1 refreshes both later chorus developments', () {
      final session = SongSessionController();
      session.generate(request: dependencyRequest(92002));
      expect(session.selectSection('chorus-1'), isTrue);
      expect(session.regenerateSection(), isTrue);

      final source = session.currentDraft!.sectionById('chorus-1')!;
      final chorus2 = session.currentDraft!.sectionById('chorus-2')!;
      final finalChorus = session.currentDraft!.sectionById('final-chorus')!;

      for (final dependent in [chorus2, finalChorus]) {
        expect(dependent.progression.first.degree, source.progression.first.degree);
        expect(dependent.progression.last.degree, source.progression.last.degree);
      }
      expect(session.currentMemory!.section('chorus-2')!.sourceSectionId, 'chorus-1');
      expect(
        session.currentMemory!.section('final-chorus')!.sourceSectionId,
        'chorus-1',
      );
    });
  });
}
