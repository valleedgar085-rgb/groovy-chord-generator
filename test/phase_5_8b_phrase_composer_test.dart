import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/phrase_composer.dart';
import 'package:groovy_chord_generator/engine/phrase_model.dart';
import 'package:groovy_chord_generator/engine/producer_song_composer.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';
import 'package:groovy_chord_generator/engine/song_memory_extractor.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/utils/music_theory.dart';

void main() {
  group('Phase 5.8B Phrase Composer', () {
    test('plans verse question/answer, pre lift and chorus hook before notes', () {
      const composer = PhraseComposer();
      final progression = _progression();

      final verse = composer.compose(
        random: Random(580201),
        progression: progression,
        genre: GenreKey.happyPop,
        rhythm: RhythmLevel.moderate,
        key: KeyName.C,
        section: const SongSectionPlan(
          id: 'verse-1',
          type: SongSectionType.verse,
          bars: 8,
          targetTension: 0.35,
          targetEnergy: 0.44,
          repetitionGroup: 'verse',
        ),
      );
      final pre = composer.compose(
        random: Random(580202),
        progression: progression,
        genre: GenreKey.happyPop,
        rhythm: RhythmLevel.moderate,
        key: KeyName.C,
        section: const SongSectionPlan(
          id: 'pre-1',
          type: SongSectionType.preChorus,
          bars: 4,
          targetTension: 0.70,
          targetEnergy: 0.68,
        ),
      );
      final chorus = composer.compose(
        random: Random(580203),
        progression: progression,
        genre: GenreKey.happyPop,
        rhythm: RhythmLevel.moderate,
        key: KeyName.C,
        section: const SongSectionPlan(
          id: 'chorus-1',
          type: SongSectionType.chorus,
          bars: 8,
          targetTension: 0.88,
          targetEnergy: 0.92,
          repetitionGroup: 'chorus',
        ),
      );

      expect(verse.phrases.length, 2);
      expect(verse.phrases[0].role, PhraseRole.question);
      expect(verse.phrases[1].role, PhraseRole.answer);
      expect(verse.phrases[0].climaxPosition, greaterThan(verse.phrases[1].climaxPosition));

      expect(pre.phrases.single.role, PhraseRole.lift);
      expect(pre.phrases.single.cadenceIntent, PhraseCadenceIntent.half);
      expect(pre.phrases.single.climaxPosition, greaterThan(0.8));

      expect(chorus.phrases.length, 2);
      expect(chorus.phrases.first.role, PhraseRole.hook);
      expect(chorus.phrases.last.role, PhraseRole.answer);
      expect(chorus.phrases.last.cadenceIntent, PhraseCadenceIntent.resolved);
      expect(chorus.phrases.first.targetRange, greaterThan(verse.phrases.first.targetRange));
    });

    test('same phrase plan and seed replay exactly with safe melodic motion', () {
      const composer = PhraseComposer();
      final progression = _progression();
      const section = SongSectionPlan(
        id: 'chorus-1',
        type: SongSectionType.chorus,
        bars: 8,
        targetTension: 0.88,
        targetEnergy: 0.92,
        repetitionGroup: 'chorus',
      );

      final first = composer.compose(
        random: Random(580211),
        progression: progression,
        genre: GenreKey.soulfulRnb,
        rhythm: RhythmLevel.strong,
        key: KeyName.C,
        section: section,
      );
      final second = composer.compose(
        random: Random(580211),
        progression: progression,
        genre: GenreKey.soulfulRnb,
        rhythm: RhythmLevel.strong,
        key: KeyName.C,
        section: section,
      );

      expect(_melodySignature(first.melody), _melodySignature(second.melody));
      expect(first.melody, isNotEmpty);
      for (final note in first.melody) {
        expect(note.chordIndex, inInclusiveRange(0, progression.length - 1));
        expect(note.velocity, inInclusiveRange(0.0, 1.0));
        expect(note.duration, greaterThan(0.0));
        expect(noteToPitch(note.note, note.octave), inInclusiveRange(52, 91));
      }
      for (var i = 1; i < first.melody.length; i++) {
        final previous = noteToPitch(first.melody[i - 1].note, first.melody[i - 1].octave);
        final current = noteToPitch(first.melody[i].note, first.melody[i].octave);
        expect((current - previous).abs(), lessThanOrEqualTo(12));
      }
    });

    test('A-prime reuses source rhythm while final callback expands the hook', () {
      const composer = PhraseComposer();
      final progression = _progression();
      const sourcePlan = SongSectionPlan(
        id: 'chorus-1',
        type: SongSectionType.chorus,
        bars: 8,
        targetTension: 0.86,
        targetEnergy: 0.90,
        repetitionGroup: 'chorus',
      );
      const primePlan = SongSectionPlan(
        id: 'chorus-2',
        type: SongSectionType.chorus,
        bars: 8,
        targetTension: 0.90,
        targetEnergy: 0.95,
        repetitionGroup: 'chorus',
        variation: 1,
      );
      const finalPlan = SongSectionPlan(
        id: 'final-chorus',
        type: SongSectionType.chorus,
        bars: 8,
        targetTension: 0.96,
        targetEnergy: 1.0,
        repetitionGroup: 'chorus',
        variation: 2,
      );

      final source = composer.compose(
        random: Random(580221),
        progression: progression,
        genre: GenreKey.happyPop,
        rhythm: RhythmLevel.moderate,
        key: KeyName.C,
        section: sourcePlan,
      );
      final prime = composer.compose(
        random: Random(580222),
        progression: progression,
        genre: GenreKey.happyPop,
        rhythm: RhythmLevel.moderate,
        key: KeyName.C,
        section: primePlan,
        sourceMelody: source.melody,
        sourceChordCount: progression.length,
      );
      final finalCallback = composer.compose(
        random: Random(580223),
        progression: progression,
        genre: GenreKey.happyPop,
        rhythm: RhythmLevel.moderate,
        key: KeyName.C,
        section: finalPlan,
        sourceMelody: source.melody,
        sourceChordCount: progression.length,
      );

      expect(prime.phrases.every((phrase) => phrase.usesSourceIdentity), isTrue);
      expect(finalCallback.phrases.every((phrase) => phrase.usesSourceIdentity), isTrue);
      expect(_durationMatchRatio(source.melody, prime.melody), greaterThan(0.45));
      expect(
        finalCallback.phrases.first.targetRange,
        greaterThan(prime.phrases.first.targetRange),
      );
      expect(_maxPitch(finalCallback.melody), greaterThanOrEqualTo(_maxPitch(source.melody) - 2));
    });

    test('genre vocabulary changes phrase density without changing the phrase role contract', () {
      const composer = PhraseComposer();
      final progression = _progression();
      const section = SongSectionPlan(
        id: 'groove-a',
        type: SongSectionType.verse,
        bars: 8,
        targetTension: 0.30,
        targetEnergy: 0.44,
      );

      final lofi = composer.compose(
        random: Random(580231),
        progression: progression,
        genre: GenreKey.chillLofi,
        rhythm: RhythmLevel.moderate,
        key: KeyName.C,
        section: section,
      );
      final funk = composer.compose(
        random: Random(580231),
        progression: progression,
        genre: GenreKey.funk,
        rhythm: RhythmLevel.moderate,
        key: KeyName.C,
        section: section,
      );

      expect(lofi.phrases.first.role, PhraseRole.question);
      expect(funk.phrases.first.role, PhraseRole.question);
      expect(funk.phrases.first.targetDensity, greaterThan(lofi.phrases.first.targetDensity));
      expect(funk.melody.length, greaterThan(lofi.melody.length));
    });

    test('canonical full-song composition preserves explicit phrase ancestry', () {
      final request = _request(580241);
      final composer = ProducerSongComposer();
      final draft = composer.compose(
        request: request,
        plan: SongPlan.standard(seed: request.seed),
        bassStyle: BassStyle.fifths,
        bassVariety: 60,
        grooveTemplate: GrooveTemplate.straight,
      );
      final memory = const SongMemoryExtractor().capture(draft);

      final versePrime = memory.lineageFor('verse-2:p0')!;
      final chorusPrime = memory.lineageFor('chorus-2:p0')!;
      final finalHook = memory.lineageFor('final-chorus:p0')!;

      expect(versePrime.sourcePhraseId, 'verse-1:p0');
      expect(versePrime.relationship, PhraseRelationship.variation);
      expect(chorusPrime.sourcePhraseId, 'chorus-1:p0');
      expect(chorusPrime.relationship, PhraseRelationship.variation);
      expect(finalHook.sourcePhraseId, 'chorus-1:p0');
      expect(finalHook.relationship, PhraseRelationship.callback);
      expect(versePrime.sourceSimilarity, greaterThan(0.30));
      expect(chorusPrime.sourceSimilarity, greaterThan(0.40));
      expect(finalHook.sourceSimilarity, greaterThan(0.40));
    });

    test('melody-disabled songs still bypass Phrase Composer output', () {
      final request = _request(580251).copyWith(includeMelody: false);
      final draft = ProducerSongComposer().compose(
        request: request,
        plan: SongPlan.standard(seed: request.seed),
      );
      expect(draft.sections.every((section) => section.melody.isEmpty), isTrue);
    });
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

List<Chord> _progression() => const <Chord>[
      Chord(
        root: 'C',
        type: ChordTypeName.major,
        degree: 'I',
        numeral: 'I',
      ),
      Chord(
        root: 'G',
        type: ChordTypeName.major,
        degree: 'V',
        numeral: 'V',
      ),
      Chord(
        root: 'A',
        type: ChordTypeName.minor,
        degree: 'vi',
        numeral: 'vi',
      ),
      Chord(
        root: 'F',
        type: ChordTypeName.major,
        degree: 'IV',
        numeral: 'IV',
      ),
      Chord(
        root: 'D',
        type: ChordTypeName.minor,
        degree: 'ii',
        numeral: 'ii',
      ),
      Chord(
        root: 'G',
        type: ChordTypeName.dominant7,
        degree: 'V',
        numeral: 'V7',
      ),
      Chord(
        root: 'C',
        type: ChordTypeName.major7,
        degree: 'I',
        numeral: 'Imaj7',
      ),
      Chord(
        root: 'C',
        type: ChordTypeName.major,
        degree: 'I',
        numeral: 'I',
      ),
    ];

String _melodySignature(List<MelodyNote> melody) => melody
    .map(
      (note) => '${note.note}${note.octave}:${note.duration.toStringAsFixed(3)}:'
          '${note.velocity.toStringAsFixed(3)}:${note.chordIndex}',
    )
    .join('|');

double _durationMatchRatio(List<MelodyNote> a, List<MelodyNote> b) {
  final compared = min(a.length, b.length);
  if (compared == 0) return 0.0;
  var matches = 0;
  for (var i = 0; i < compared; i++) {
    if ((a[i].duration - b[i].duration).abs() < 0.001) matches++;
  }
  return matches / compared;
}

int _maxPitch(List<MelodyNote> melody) => melody
    .map((note) => noteToPitch(note.note, note.octave))
    .fold<int>(0, max);
