import 'package:flutter_test/flutter_test.dart';

import 'package:groovy_chord_generator/engine/section_variation_engine.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';
import 'package:groovy_chord_generator/engine/song_candidate.dart';
import 'package:groovy_chord_generator/engine/song_draft.dart';
import 'package:groovy_chord_generator/engine/song_memory_extractor.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';

SongRequest variationRequest(int seed) => SongRequest(
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

Chord _chord(String root, String degree, ChordTypeName type) => Chord(
      root: root,
      type: type,
      degree: degree,
      numeral: degree,
    );

GeneratedSongSection _section({
  required SongSectionPlan plan,
  required List<Chord> progression,
  required List<MelodyNote> melody,
  required List<BassNote> bass,
  required int seed,
}) {
  return GeneratedSongSection(
    plan: plan,
    candidate: SongCandidate(
      progression: progression,
      score: 80,
      seed: seed,
      candidateIndex: 0,
      section: plan.harmonySection,
    ),
    melody: melody,
    bass: bass,
  );
}

List<String> _degrees(GeneratedSongSection section) =>
    section.progression.map((chord) => chord.degree).toList(growable: false);

List<String> _melodySignature(GeneratedSongSection section) => section.melody
    .map((note) =>
        '${note.note}:${note.octave}:${note.duration}:${note.velocity}:${note.chordIndex}')
    .toList(growable: false);

List<String> _bassSignature(GeneratedSongSection section) => section.bass
    .map((note) =>
        '${note.note}:${note.octave}:${note.duration}:${note.velocity}:${note.chordIndex}:${note.style.name}')
    .toList(growable: false);

void main() {
  group('Phase 3 controlled variation', () {
    test('A-prime transform protects opening and cadence anchors', () {
      const sourcePlan = SongSectionPlan(
        id: 'verse-1',
        type: SongSectionType.verse,
        bars: 8,
        targetTension: 0.35,
        targetEnergy: 0.42,
        repetitionGroup: 'verse-a',
      );
      const targetPlan = SongSectionPlan(
        id: 'verse-2',
        type: SongSectionType.verse,
        bars: 8,
        targetTension: 0.44,
        targetEnergy: 0.52,
        repetitionGroup: 'verse-a',
        variation: 1,
      );
      final plan = SongPlan(seed: 91001, sections: const [sourcePlan, targetPlan]);
      final source = _section(
        plan: sourcePlan,
        progression: [
          _chord('C', 'I', ChordTypeName.major7),
          _chord('A', 'vi', ChordTypeName.minor7),
          _chord('F', 'IV', ChordTypeName.major7),
          _chord('G', 'V', ChordTypeName.dominant7),
        ],
        melody: const [
          MelodyNote(note: 'E', duration: 1, velocity: 0.8, chordIndex: 0, octave: 4),
          MelodyNote(note: 'G', duration: 1, velocity: 0.7, chordIndex: 1, octave: 4),
          MelodyNote(note: 'A', duration: 1, velocity: 0.75, chordIndex: 2, octave: 4),
          MelodyNote(note: 'G', duration: 1, velocity: 0.85, chordIndex: 3, octave: 4),
        ],
        bass: const [
          BassNote(note: 'C', duration: 1, velocity: 0.8, octave: 2, chordIndex: 0, style: BassStyle.root),
          BassNote(note: 'A', duration: 1, velocity: 0.8, octave: 2, chordIndex: 1, style: BassStyle.root),
          BassNote(note: 'F', duration: 1, velocity: 0.8, octave: 2, chordIndex: 2, style: BassStyle.root),
          BassNote(note: 'G', duration: 1, velocity: 0.8, octave: 2, chordIndex: 3, style: BassStyle.root),
        ],
        seed: 1,
      );
      final target = _section(
        plan: targetPlan,
        progression: [
          _chord('C', 'I', ChordTypeName.add9),
          _chord('D', 'ii', ChordTypeName.minor7),
          _chord('A', 'vi', ChordTypeName.minor9),
          _chord('G', 'V', ChordTypeName.dominant7),
        ],
        melody: const [
          MelodyNote(note: 'G', duration: 0.5, velocity: 0.9, chordIndex: 0, octave: 4),
          MelodyNote(note: 'A', duration: 0.5, velocity: 0.7, chordIndex: 1, octave: 4),
          MelodyNote(note: 'C', duration: 1, velocity: 0.8, chordIndex: 2, octave: 5),
          MelodyNote(note: 'B', duration: 2, velocity: 0.9, chordIndex: 3, octave: 4),
        ],
        bass: const [
          BassNote(note: 'C', duration: 0.5, velocity: 0.85, octave: 2, chordIndex: 0, style: BassStyle.syncopated),
          BassNote(note: 'D', duration: 0.5, velocity: 0.75, octave: 2, chordIndex: 1, style: BassStyle.syncopated),
          BassNote(note: 'A', duration: 1, velocity: 0.8, octave: 2, chordIndex: 2, style: BassStyle.syncopated),
          BassNote(note: 'G', duration: 2, velocity: 0.9, octave: 2, chordIndex: 3, style: BassStyle.syncopated),
        ],
        seed: 2,
      );
      final draft = SongDraft(plan: plan).withSection(source).withSection(target);
      final memory = const SongMemoryExtractor().capture(draft);
      final engine = SectionVariationEngine();

      final transformed = engine.transform(
        source: source,
        target: target,
        sourceMemory: memory.section('verse-1')!,
        targetMemory: memory.section('verse-2')!,
        seed: 777,
        level: SectionVariationLevel.aPrime,
      );

      expect(transformed.progression.first.degree, source.progression.first.degree);
      expect(transformed.progression.last.degree, source.progression.last.degree);
      expect(transformed.progression.first.root, source.progression.first.root);
      expect(transformed.progression.last.root, source.progression.last.root);
      expect(transformed.candidate.score, inInclusiveRange(0.0, 100.0));
      expect(
        transformed.melody.every((note) =>
            note.chordIndex >= 0 && note.chordIndex < transformed.progression.length),
        isTrue,
      );
      expect(
        transformed.bass.every((note) =>
            note.chordIndex >= 0 && note.chordIndex < transformed.progression.length),
        isTrue,
      );
    });

    test('same transformation seed reproduces exactly', () {
      final first = SongSessionController();
      final second = SongSessionController();
      first.generate(request: variationRequest(91002));
      second.generate(request: variationRequest(91002));

      for (final id in ['verse-2', 'chorus-2', 'final-chorus']) {
        final a = first.currentDraft!.sectionById(id)!;
        final b = second.currentDraft!.sectionById(id)!;
        expect(_degrees(a), _degrees(b));
        expect(_melodySignature(a), _melodySignature(b));
        expect(_bassSignature(a), _bassSignature(b));
      }
    });

    test('standard repeated sections retain source opening and cadence identity', () {
      final session = SongSessionController();
      session.generate(request: variationRequest(91003));
      final draft = session.currentDraft!;

      final verse1 = draft.sectionById('verse-1')!;
      final verse2 = draft.sectionById('verse-2')!;
      final chorus1 = draft.sectionById('chorus-1')!;
      final chorus2 = draft.sectionById('chorus-2')!;
      final finalChorus = draft.sectionById('final-chorus')!;

      expect(verse2.progression.first.degree, verse1.progression.first.degree);
      expect(verse2.progression.last.degree, verse1.progression.last.degree);
      expect(chorus2.progression.first.degree, chorus1.progression.first.degree);
      expect(chorus2.progression.last.degree, chorus1.progression.last.degree);
      expect(finalChorus.progression.first.degree, chorus1.progression.first.degree);
      expect(finalChorus.progression.last.degree, chorus1.progression.last.degree);

      expect(session.currentMemory!.section('verse-2')!.sourceSectionId, 'verse-1');
      expect(session.currentMemory!.section('chorus-2')!.sourceSectionId, 'chorus-1');
      expect(session.currentMemory!.section('final-chorus')!.sourceSectionId, 'chorus-1');
    });

    test('regenerated repeated section stays developed and exact replay restores it', () {
      final session = SongSessionController();
      session.generate(request: variationRequest(91004));
      expect(session.selectSection('verse-2'), isTrue);
      expect(session.regenerateSection(), isTrue);

      final source = session.currentDraft!.sectionById('verse-1')!;
      final regenerated = session.currentDraft!.sectionById('verse-2')!;
      expect(regenerated.progression.first.degree, source.progression.first.degree);
      expect(regenerated.progression.last.degree, source.progression.last.degree);

      final expectedDegrees = _degrees(regenerated);
      final expectedMelody = _melodySignature(regenerated);
      final expectedBass = _bassSignature(regenerated);
      final expectedSimilarity = session.selectedIdentitySimilarity;

      session.replay();
      final replayed = session.currentDraft!.sectionById('verse-2')!;
      expect(_degrees(replayed), expectedDegrees);
      expect(_melodySignature(replayed), expectedMelody);
      expect(_bassSignature(replayed), expectedBass);
      expect(session.selectedIdentitySimilarity, expectedSimilarity);
      expect(session.revisionFor('verse-2'), 1);
    });
  });
}
