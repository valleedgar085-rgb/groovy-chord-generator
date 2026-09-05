import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/genre_song_architecture.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/phrase_model.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';

void main() {
  group('Phase 5.8A Musical DNA and phrase lineage', () {
    test('captures phrase windows across the complete section instead of only its opening', () {
      final session = _session();
      final memory = session.currentMemory!;

      expect(memory.section('verse-1')!.phrases.length, 2);
      expect(memory.section('pre-1')!.phrases.length, 1);
      expect(memory.section('chorus-1')!.phrases.length, 2);
      expect(memory.section('bridge')!.phrases.length, 2);

      expect(memory.section('verse-1')!.phrases[0].bars, 4);
      expect(memory.section('verse-1')!.phrases[1].bars, 4);
      expect(memory.section('verse-1')!.phrases[0].role, PhraseRole.question);
      expect(memory.section('verse-1')!.phrases[1].role, PhraseRole.answer);
      expect(memory.section('pre-1')!.phrases.single.role, PhraseRole.lift);
      expect(memory.section('chorus-1')!.phrases.first.role, PhraseRole.hook);
      expect(
        memory.section('chorus-1')!.phrases.last.cadenceIntent,
        PhraseCadenceIntent.resolved,
      );
    });

    test('repeated sections point phrase ancestry at canonical source phrases', () {
      final memory = _session().currentMemory!;

      final versePrime = memory.lineageFor('verse-2:p0')!;
      expect(versePrime.sourcePhraseId, 'verse-1:p0');
      expect(versePrime.relationship, PhraseRelationship.variation);
      expect(versePrime.sourceSimilarity, inInclusiveRange(0.0, 1.0));
      expect(versePrime.targetWindow.label, 'familiar verse development');

      final chorusPrime = memory.lineageFor('chorus-2:p0')!;
      expect(chorusPrime.sourcePhraseId, 'chorus-1:p0');
      expect(chorusPrime.relationship, PhraseRelationship.variation);
      expect(chorusPrime.targetWindow.minimum, greaterThan(versePrime.targetWindow.minimum));

      final finalChorus = memory.lineageFor('final-chorus:p0')!;
      expect(finalChorus.sourcePhraseId, 'chorus-1:p0');
      expect(finalChorus.relationship, PhraseRelationship.callback);
      expect(finalChorus.targetWindow.maximum, lessThan(chorusPrime.targetWindow.maximum));
    });

    test('canonical sections retain internal question and response ancestry', () {
      final memory = _session().currentMemory!;
      final response = memory.lineageFor('verse-1:p1')!;

      expect(response.sourcePhraseId, 'verse-1:p0');
      expect(response.relationship, PhraseRelationship.response);
      expect(response.targetWindow.label, 'related answer');
      expect(response.sourceSimilarity, inInclusiveRange(0.0, 1.0));
    });

    test('distills a song-level Musical DNA profile from actual phrase material', () {
      final memory = _session().currentMemory!;
      final dna = memory.musicalDna;

      expect(dna.hasIdentity, isTrue);
      expect(memory.primaryPhrase, isNotNull);
      expect(memory.phrase(dna.primaryPhraseId!), same(memory.primaryPhrase));
      expect(dna.hookPhraseId, isNotNull);
      expect(memory.phrase(dna.hookPhraseId!)!.role, PhraseRole.hook);
      expect(dna.hookSectionId, isNotNull);
      expect(dna.typicalPhraseBars, 4);
      expect(dna.primaryRhythmCell.isEmpty, isFalse);
      expect(dna.melodicRange, greaterThanOrEqualTo(0));
      expect(dna.confidence, greaterThanOrEqualTo(0.70));
    });

    test('same song replay produces identical phrase fingerprints, lineage and DNA', () {
      final first = _session().currentMemory!;
      final second = _session().currentMemory!;

      expect(_phraseSignature(first), _phraseSignature(second));
      expect(_lineageSignature(first), _lineageSignature(second));
      expect(first.musicalDna.primaryPhraseId, second.musicalDna.primaryPhraseId);
      expect(first.musicalDna.secondaryPhraseId, second.musicalDna.secondaryPhraseId);
      expect(first.musicalDna.hookPhraseId, second.musicalDna.hookPhraseId);
      expect(first.musicalDna.signatureInterval, second.musicalDna.signatureInterval);
      expect(first.musicalDna.confidence, second.musicalDna.confidence);
    });

    test('Lo-fi A-prime and A-double-prime phrases preserve explicit groove ancestry', () {
      final request = _request(580082, genre: GenreKey.chillLofi);
      final session = SongSessionController();
      session.generate(
        request: request,
        plan: GenreSongArchitecture.build(genre: request.genre, seed: request.seed),
        bassStyle: BassStyle.root,
        bassVariety: 55,
        grooveTemplate: GrooveTemplate.straight,
      );
      final memory = session.currentMemory!;

      final aPrime = memory.lineageFor('groove-a2:p0')!;
      final aDoublePrime = memory.lineageFor('groove-a3:p0')!;
      expect(aPrime.sourcePhraseId, 'groove-a:p0');
      expect(aPrime.relationship, PhraseRelationship.variation);
      expect(aDoublePrime.sourcePhraseId, 'groove-a:p0');
      expect(aDoublePrime.relationship, PhraseRelationship.callback);
    });

    test('songs without melody retain phrase windows without inventing Musical DNA', () {
      final request = SongRequest(
        seed: 580083,
        key: KeyName.C,
        genre: GenreKey.happyPop,
        mood: MoodType.dreamy,
        complexity: ComplexityLevel.medium,
        spice: SpiceLevel.medium,
        rhythm: RhythmLevel.moderate,
        section: HarmonySection.neutral,
        candidateCount: 8,
        chordVariety: 55,
        includeMelody: false,
        includeBass: true,
      );
      final session = SongSessionController();
      session.generate(
        request: request,
        plan: SongPlan.standard(seed: request.seed),
      );
      final memory = session.currentMemory!;

      expect(memory.section('verse-1')!.phrases.length, 2);
      expect(memory.section('verse-1')!.phrases.every((phrase) => phrase.isEmpty), isTrue);
      expect(memory.musicalDna.hasIdentity, isFalse);
      expect(memory.musicalDna.primaryRhythmCell.isEmpty, isTrue);
      expect(memory.musicalDna.confidence, lessThan(0.50));
    });
  });
}

SongSessionController _session() {
  final request = _request(580081);
  final session = SongSessionController();
  session.generate(
    request: request,
    plan: SongPlan.standard(seed: request.seed),
    bassStyle: BassStyle.fifths,
    bassVariety: 60,
    grooveTemplate: GrooveTemplate.straight,
  );
  return session;
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

String _phraseSignature(dynamic memory) {
  final parts = <String>[];
  for (final section in memory.sections.values) {
    for (final phrase in section.phrases) {
      parts.add(
        '${phrase.id}:${phrase.role.name}:${phrase.cadenceIntent.name}:'
        '${phrase.relativePitchPattern.join(',')}:'
        '${phrase.durationTicks.join(',')}:${phrase.accentBuckets.join(',')}:'
        '${phrase.chordIndexPattern.join(',')}:${phrase.pitchRange}:'
        '${phrase.climaxPosition.toStringAsFixed(4)}',
      );
    }
  }
  return parts.join('|');
}

String _lineageSignature(dynamic memory) {
  final keys = memory.phraseLineage.keys.toList()..sort();
  return keys.map((key) {
    final node = memory.phraseLineage[key];
    return '$key>${node.sourcePhraseId}:${node.relationship.name}:'
        '${node.sourceSimilarity.toStringAsFixed(4)}:'
        '${node.targetWindow.minimum}-${node.targetWindow.maximum}';
  }).join('|');
}
