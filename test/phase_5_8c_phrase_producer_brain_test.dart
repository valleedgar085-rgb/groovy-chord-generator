import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/genre_song_architecture.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/phrase_model.dart';
import 'package:groovy_chord_generator/engine/phrase_producer_brain.dart';
import 'package:groovy_chord_generator/engine/producer_song_composer.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';
import 'package:groovy_chord_generator/engine/song_draft.dart';
import 'package:groovy_chord_generator/engine/song_memory_extractor.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/utils/music_theory.dart';

void main() {
  group('Phase 5.8C Phrase Producer Brain', () {
    test('scores every non-empty phrase across seven musical dimensions', () {
      final draft = _draft(580301);
      final memory = const SongMemoryExtractor().capture(draft);
      final analysis = const PhraseProducerAnalyzer().analyze(
        draft: draft,
        memory: memory,
      );

      final expectedPhraseCount = memory.sections.values
          .expand((section) => section.phrases)
          .where((phrase) => !phrase.isEmpty)
          .length;
      expect(analysis.phrases.length, expectedPhraseCount);
      expect(analysis.phrases, isNotEmpty);
      expect(analysis.overallScore, inInclusiveRange(0.0, 100.0));
      expect(analysis.weakestPhrase, isNotNull);

      for (final phrase in analysis.phrases) {
        expect(phrase.metrics.length, PhraseProducerDimension.values.length);
        for (final dimension in PhraseProducerDimension.values) {
          expect(
            phrase.metricFor(dimension).score,
            inInclusiveRange(0.0, 100.0),
            reason: '${phrase.phraseId}:${dimension.name}',
          );
        }
      }
    });

    test('same song produces exactly the same phrase diagnosis', () {
      final firstDraft = _draft(580302);
      final secondDraft = _draft(580302);
      const extractor = SongMemoryExtractor();
      const analyzer = PhraseProducerAnalyzer();

      final first = analyzer.analyze(
        draft: firstDraft,
        memory: extractor.capture(firstDraft),
      );
      final second = analyzer.analyze(
        draft: secondDraft,
        memory: extractor.capture(secondDraft),
      );

      expect(_analysisSignature(first), _analysisSignature(second));
      expect(first.overallScore, second.overallScore);
      expect(first.weakestPhrase?.phraseId, second.weakestPhrase?.phraseId);
      expect(first.guardrailViolations, second.guardrailViolations);
    });

    test('literal Chorus 2 copy is diagnosed as an identity guardrail violation', () {
      final original = _draft(580303);
      final chorus1 = original.sectionById('chorus-1')!;
      final chorus2 = original.sectionById('chorus-2')!;
      final copied = GeneratedSongSection(
        plan: chorus2.plan,
        candidate: chorus2.candidate,
        melody: chorus1.melody,
        bass: chorus2.bass,
        development: chorus2.development,
      );
      final degraded = original.withSection(copied);
      final memory = const SongMemoryExtractor().capture(degraded);
      final analysis = const PhraseProducerAnalyzer().analyze(
        draft: degraded,
        memory: memory,
      );
      final phrase = _assessment(analysis, 'chorus-2:p0');
      final lineage = phrase.lineage!;

      expect(lineage.relationship, PhraseRelationship.variation);
      expect(lineage.sourceSimilarity, closeTo(1.0, 0.0001));
      expect(lineage.sourceSimilarity, greaterThan(lineage.targetWindow.maximum));
      expect(phrase.lineageInsideGuardrail, isFalse);
      expect(
        phrase.metricFor(PhraseProducerDimension.lineage).score,
        lessThan(88.0),
      );
      expect(phrase.issue, contains('too literal'));
      expect(analysis.guardrailViolations, greaterThan(0));
    });

    test('breaking a resolved chorus landing lowers cadence quality', () {
      final original = _draft(580304);
      final baselineMemory = const SongMemoryExtractor().capture(original);
      final baseline = const PhraseProducerAnalyzer().analyze(
        draft: original,
        memory: baselineMemory,
      );
      final baselinePhrase = _assessment(baseline, 'chorus-1:p1');

      final chorus = original.sectionById('chorus-1')!;
      final melody = List<MelodyNote>.from(chorus.melody);
      expect(melody, isNotEmpty);
      final last = melody.last;
      final chord = chorus.progression[
        last.chordIndex.clamp(0, chorus.progression.length - 1).toInt()
      ];
      final brokenName = _nonChordTone(chord);
      melody[melody.length - 1] = MelodyNote(
        note: brokenName,
        duration: last.duration,
        velocity: last.velocity,
        chordIndex: last.chordIndex,
        octave: last.octave,
      );
      final degraded = original.withSection(
        GeneratedSongSection(
          plan: chorus.plan,
          candidate: chorus.candidate,
          melody: melody,
          bass: chorus.bass,
          development: chorus.development,
        ),
      );
      final degradedMemory = const SongMemoryExtractor().capture(degraded);
      final degradedAnalysis = const PhraseProducerAnalyzer().analyze(
        draft: degraded,
        memory: degradedMemory,
      );
      final degradedPhrase = _assessment(degradedAnalysis, 'chorus-1:p1');

      expect(
        degradedPhrase.metricFor(PhraseProducerDimension.cadence).score,
        lessThan(baselinePhrase.metricFor(PhraseProducerDimension.cadence).score),
      );
      expect(
        degradedPhrase.metricFor(PhraseProducerDimension.cadence).score,
        lessThanOrEqualTo(45.0),
      );
    });

    test('oversized alternating leaps are rejected by contour and playability', () {
      final original = _draft(580305);
      final verse = original.sectionById('verse-1')!;
      final melody = <MelodyNote>[];
      var targetOrdinal = 0;
      final chordCount = verse.progression.length;
      for (final note in verse.melody) {
        final safeChord = note.chordIndex.clamp(0, chordCount - 1).toInt();
        final inFirstPhrase = ((safeChord + 0.5) / chordCount) < 0.5;
        if (!inFirstPhrase) {
          melody.add(note);
          continue;
        }
        final high = targetOrdinal.isOdd;
        melody.add(
          MelodyNote(
            note: high ? 'B' : 'C',
            duration: note.duration,
            velocity: note.velocity,
            chordIndex: note.chordIndex,
            octave: high ? 5 : 4,
          ),
        );
        targetOrdinal++;
      }
      final degraded = original.withSection(
        GeneratedSongSection(
          plan: verse.plan,
          candidate: verse.candidate,
          melody: melody,
          bass: verse.bass,
          development: verse.development,
        ),
      );
      final memory = const SongMemoryExtractor().capture(degraded);
      final analysis = const PhraseProducerAnalyzer().analyze(
        draft: degraded,
        memory: memory,
      );
      final phrase = _assessment(analysis, 'verse-1:p0');

      expect(
        phrase.metricFor(PhraseProducerDimension.contour).score,
        lessThan(70.0),
      );
      expect(
        phrase.metricFor(PhraseProducerDimension.playability).score,
        lessThan(80.0),
      );
    });

    test('genre-specific song forms can all be diagnosed without special cases', () {
      const analyzer = PhraseProducerAnalyzer();
      const extractor = SongMemoryExtractor();
      for (final genre in <GenreKey>[
        GenreKey.energeticEdm,
        GenreKey.chillLofi,
        GenreKey.darkTrap,
        GenreKey.soulfulRnb,
        GenreKey.jazzFusion,
      ]) {
        final request = _request(580306 + genre.index, genre: genre);
        final draft = ProducerSongComposer().compose(
          request: request,
          plan: GenreSongArchitecture.build(
            genre: genre,
            seed: request.seed,
          ),
        );
        final analysis = analyzer.analyze(
          draft: draft,
          memory: extractor.capture(draft),
        );
        expect(analysis.phrases, isNotEmpty, reason: genre.name);
        expect(analysis.overallScore, inInclusiveRange(0.0, 100.0));
      }
    });

    test('melody-disabled songs do not invent phrase quality scores', () {
      final request = _request(580320).copyWith(includeMelody: false);
      final draft = ProducerSongComposer().compose(
        request: request,
        plan: SongPlan.standard(seed: request.seed),
      );
      final memory = const SongMemoryExtractor().capture(draft);
      final analysis = const PhraseProducerAnalyzer().analyze(
        draft: draft,
        memory: memory,
      );

      expect(analysis.phrases, isEmpty);
      expect(analysis.overallScore, 0.0);
      expect(analysis.weakestPhrase, isNull);
      expect(analysis.guardrailViolations, 0);
    });
  });
}

SongDraft _draft(int seed) {
  final request = _request(seed);
  return ProducerSongComposer().compose(
    request: request,
    plan: SongPlan.standard(seed: request.seed),
    bassStyle: BassStyle.fifths,
    bassVariety: 60,
    grooveTemplate: GrooveTemplate.straight,
  );
}

SongRequest _request(int seed, {GenreKey genre = GenreKey.happyPop}) => SongRequest(
      seed: seed,
      key: KeyName.C,
      genre: genre,
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

PhraseProducerAssessment _assessment(
  SongPhraseProducerAnalysis analysis,
  String phraseId,
) =>
    analysis.phrases.firstWhere((phrase) => phrase.phraseId == phraseId);

String _analysisSignature(SongPhraseProducerAnalysis analysis) => analysis.phrases
    .map(
      (phrase) => '${phrase.phraseId}:${phrase.score.toStringAsFixed(4)}:'
          '${phrase.lineageInsideGuardrail}:'
          '${phrase.metrics.map((metric) => '${metric.dimension.name}=${metric.score.toStringAsFixed(3)}').join(',')}',
    )
    .join('|');

String _nonChordTone(Chord chord) {
  final chordTones = getChordNotes(chord).toSet();
  const chromatic = <String>[
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];
  return chromatic.firstWhere((note) => !chordTones.contains(note));
}
