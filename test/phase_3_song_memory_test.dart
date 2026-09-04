import 'package:flutter_test/flutter_test.dart';

import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';
import 'package:groovy_chord_generator/engine/song_candidate.dart';
import 'package:groovy_chord_generator/engine/song_draft.dart';
import 'package:groovy_chord_generator/engine/song_memory.dart';
import 'package:groovy_chord_generator/engine/song_memory_extractor.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';

SongRequest memoryRequest(int seed, {KeyName key = KeyName.C}) => SongRequest(
      seed: seed,
      key: key,
      genre: GenreKey.soulfulRnb,
      mood: MoodType.dreamy,
      complexity: ComplexityLevel.complex,
      spice: SpiceLevel.medium,
      rhythm: RhythmLevel.moderate,
      candidateCount: 8,
      chordVariety: 62,
      useVoiceLeading: true,
      useAdvancedTheory: true,
      useModalInterchange: true,
      useFunctionalHarmony: true,
      includeMelody: true,
      includeBass: true,
    );

Chord chord(String root, String degree, ChordTypeName type) => Chord(
      root: root,
      type: type,
      degree: degree,
      numeral: degree,
    );

GeneratedSongSection manualSection({
  required SongSectionPlan plan,
  required List<Chord> progression,
  List<MelodyNote> melody = const <MelodyNote>[],
  List<BassNote> bass = const <BassNote>[],
}) {
  return GeneratedSongSection(
    plan: plan,
    candidate: SongCandidate(
      progression: progression,
      score: 80,
      seed: 1,
      candidateIndex: 0,
      section: plan.harmonySection,
    ),
    melody: melody,
    bass: bass,
  );
}

void main() {
  group('Phase 3 Song Memory', () {
    test('complete standard song captures all sections and repetition sources', () {
      final session = SongSessionController();
      session.generate(request: memoryRequest(61001));

      final memory = session.currentMemory;
      expect(memory, isNotNull);
      expect(session.hasMemory, isTrue);
      expect(memory!.sections, hasLength(10));
      expect(memory.repetitionSources['verse-a'], 'verse-1');
      expect(memory.repetitionSources['pre-a'], 'pre-1');
      expect(memory.repetitionSources['chorus-a'], 'chorus-1');
      expect(memory.section('verse-2')!.sourceSectionId, 'verse-1');
      expect(memory.section('chorus-2')!.sourceSectionId, 'chorus-1');
      expect(memory.section('final-chorus')!.sourceSectionId, 'chorus-1');
      expect(memory.section('bridge')!.sourceSectionId, 'bridge');
    });

    test('harmonic memory is relative and survives transposition', () {
      final cSession = SongSessionController();
      final dSession = SongSessionController();
      cSession.generate(request: memoryRequest(61002, key: KeyName.C));
      dSession.generate(request: memoryRequest(61002, key: KeyName.D));

      final cVerse = cSession.currentMemory!.section('verse-1')!.harmony;
      final dVerse = dSession.currentMemory!.section('verse-1')!.harmony;

      expect(dVerse.degreePattern, cVerse.degreePattern);
      expect(dVerse.functionPattern, cVerse.functionPattern);
      expect(dVerse.cadence, cVerse.cadence);
    });

    test('melodic motif stores relative contour instead of absolute notes', () {
      const plan = SongSectionPlan(
        id: 'verse',
        type: SongSectionType.verse,
        bars: 4,
        targetTension: 0.4,
        targetEnergy: 0.5,
      );
      final songPlan = SongPlan(seed: 77, sections: const [plan]);

      final first = SongDraft(plan: songPlan).withSection(
        manualSection(
          plan: plan,
          progression: [
            chord('C', 'I', ChordTypeName.major7),
            chord('F', 'IV', ChordTypeName.major7),
          ],
          melody: const [
            MelodyNote(note: 'C', duration: 1, velocity: 0.8, chordIndex: 0, octave: 4),
            MelodyNote(note: 'D', duration: 0.5, velocity: 0.6, chordIndex: 0, octave: 4),
            MelodyNote(note: 'E', duration: 0.5, velocity: 0.7, chordIndex: 1, octave: 4),
            MelodyNote(note: 'G', duration: 2, velocity: 0.9, chordIndex: 1, octave: 4),
          ],
        ),
      );
      final transposed = SongDraft(plan: songPlan).withSection(
        manualSection(
          plan: plan,
          progression: [
            chord('D', 'I', ChordTypeName.major7),
            chord('G', 'IV', ChordTypeName.major7),
          ],
          melody: const [
            MelodyNote(note: 'D', duration: 1, velocity: 0.8, chordIndex: 0, octave: 4),
            MelodyNote(note: 'E', duration: 0.5, velocity: 0.6, chordIndex: 0, octave: 4),
            MelodyNote(note: 'F#', duration: 0.5, velocity: 0.7, chordIndex: 1, octave: 4),
            MelodyNote(note: 'A', duration: 2, velocity: 0.9, chordIndex: 1, octave: 4),
          ],
        ),
      );

      const extractor = SongMemoryExtractor();
      final firstMotif = extractor.capture(first).section('verse')!.melody;
      final secondMotif = extractor.capture(transposed).section('verse')!.melody;

      expect(firstMotif.intervalContour, [2, 2, 3]);
      expect(secondMotif.intervalContour, firstMotif.intervalContour);
      expect(secondMotif.durationTicks, firstMotif.durationTicks);
      expect(secondMotif.accentBuckets, firstMotif.accentBuckets);
      expect(firstMotif.similarityTo(secondMotif), 1.0);
    });

    test('cadence memory distinguishes authentic deceptive and half cadences', () {
      const authenticPlan = SongSectionPlan(
        id: 'authentic',
        type: SongSectionType.chorus,
        bars: 4,
        targetTension: 0.8,
        targetEnergy: 0.9,
      );
      const deceptivePlan = SongSectionPlan(
        id: 'deceptive',
        type: SongSectionType.verse,
        bars: 4,
        targetTension: 0.5,
        targetEnergy: 0.5,
      );
      const halfPlan = SongSectionPlan(
        id: 'half',
        type: SongSectionType.preChorus,
        bars: 4,
        targetTension: 0.7,
        targetEnergy: 0.7,
      );
      final plan = SongPlan(
        seed: 78,
        sections: const [authenticPlan, deceptivePlan, halfPlan],
      );
      var draft = SongDraft(plan: plan);
      draft = draft.withSection(manualSection(
        plan: authenticPlan,
        progression: [
          chord('G', 'V', ChordTypeName.dominant7),
          chord('C', 'I', ChordTypeName.major),
        ],
      ));
      draft = draft.withSection(manualSection(
        plan: deceptivePlan,
        progression: [
          chord('G', 'V', ChordTypeName.dominant7),
          chord('A', 'vi', ChordTypeName.minor),
        ],
      ));
      draft = draft.withSection(manualSection(
        plan: halfPlan,
        progression: [
          chord('F', 'IV', ChordTypeName.major),
          chord('G', 'V', ChordTypeName.dominant7),
        ],
      ));

      final memory = const SongMemoryExtractor().capture(draft);
      expect(memory.section('authentic')!.harmony.cadence, CadenceIdentity.authentic);
      expect(memory.section('deceptive')!.harmony.cadence, CadenceIdentity.deceptive);
      expect(memory.section('half')!.harmony.cadence, CadenceIdentity.half);
    });

    test('section regeneration refreshes memory and exact replay restores it', () {
      final session = SongSessionController();
      session.generate(request: memoryRequest(61003));
      expect(session.selectSection('chorus-1'), isTrue);

      final before = session.selectedSectionMemory!;
      final beforeSource = before.sourceSectionId;
      expect(session.regenerateSection(), isTrue);

      final after = session.selectedSectionMemory!;
      expect(after.sourceSectionId, beforeSource);
      expect(session.currentMemory!.songSeed, 61003);
      expect(session.revisionFor('chorus-1'), 1);

      final afterDegrees = List<String>.from(after.harmony.degreePattern);
      final afterContour = List<int>.from(after.melody.intervalContour);
      session.replay();

      expect(session.selectedSectionId, 'chorus-1');
      expect(session.selectedSectionMemory!.harmony.degreePattern, afterDegrees);
      expect(session.selectedSectionMemory!.melody.intervalContour, afterContour);
      expect(session.revisionFor('chorus-1'), 1);
    });

    test('source sections have perfect self identity similarity', () {
      final session = SongSessionController();
      session.generate(request: memoryRequest(61004));
      expect(session.selectSection('verse-1'), isTrue);
      expect(session.selectedSectionMemory!.sourceSectionId, 'verse-1');
      expect(session.selectedIdentitySimilarity, 1.0);

      expect(session.selectSection('verse-2'), isTrue);
      expect(session.selectedSourceMemory!.sectionId, 'verse-1');
      expect(session.selectedIdentitySimilarity, inInclusiveRange(0.0, 1.0));
    });
  });
}
