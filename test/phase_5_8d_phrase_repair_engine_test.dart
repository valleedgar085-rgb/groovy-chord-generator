import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/phrase_model.dart';
import 'package:groovy_chord_generator/engine/phrase_repair_engine.dart';
import 'package:groovy_chord_generator/engine/producer_song_composer.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';
import 'package:groovy_chord_generator/engine/song_draft.dart';
import 'package:groovy_chord_generator/engine/song_memory_extractor.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/utils/music_theory.dart';

void main() {
  group('Phase 5.8D selective phrase repair', () {
    test('repairs an over-copied Chorus 2 toward the identity window', () {
      final original = _draft(580401);
      final chorus1 = original.sectionById('chorus-1')!;
      final chorus2 = original.sectionById('chorus-2')!;
      final degraded = original.withSection(
        GeneratedSongSection(
          plan: chorus2.plan,
          candidate: chorus2.candidate,
          melody: chorus1.melody,
          bass: chorus2.bass,
          development: chorus2.development,
        ),
      );

      const engine = PhraseRepairEngine();
      final variants = engine.build(
        draft: degraded,
        phraseId: 'chorus-2:p0',
      );
      final identity = variants.firstWhere(
        (variant) => variant.style == PhraseRepairStyle.identityBalance,
      );

      expect(identity.improved, isTrue);
      expect(identity.scoreDelta, greaterThan(0.05));
      expect(identity.songScoreDelta, greaterThanOrEqualTo(-0.01));
      expect(identity.before.lineageInsideGuardrail, isFalse);
      expect(identity.after.lineage, isNotNull);
      expect(
        _guardrailDistance(identity.after.lineage!),
        lessThan(_guardrailDistance(identity.before.lineage!)),
      );
    });

    test('cadence repair fixes a deliberately broken resolved chorus landing', () {
      final original = _draft(580402);
      final chorus = original.sectionById('chorus-1')!;
      final memory = const SongMemoryExtractor().capture(original);
      final phraseCount = memory.section('chorus-1')!.phrases.length;
      final indices = _phraseIndices(chorus, 1, phraseCount);
      expect(indices, isNotEmpty);

      final melody = List<MelodyNote>.from(chorus.melody);
      final lastIndex = indices.last;
      final last = melody[lastIndex];
      final chord = chorus.progression[
        last.chordIndex.clamp(0, chorus.progression.length - 1).toInt()
      ];
      final brokenName = _nonChordTone(chord);
      melody[lastIndex] = MelodyNote(
        note: brokenName,
        octave: last.octave,
        duration: last.duration,
        velocity: last.velocity,
        chordIndex: last.chordIndex,
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

      final variants = const PhraseRepairEngine().build(
        draft: degraded,
        phraseId: 'chorus-1:p1',
      );
      final cadence = variants.firstWhere(
        (variant) => variant.style == PhraseRepairStyle.cadenceTarget,
      );

      expect(cadence.after.score, greaterThan(cadence.before.score));
      expect(cadence.after.lineageInsideGuardrail, isTrue);
      final repaired = cadence.draft.sectionById('chorus-1')!;
      final repairedLast = repaired.melody[lastIndex];
      expect(repairedLast.note, chord.root);
    });

    test('contour repair improves oversized alternating leaps', () {
      final original = _draft(580403);
      final verse = original.sectionById('verse-1')!;
      final memory = const SongMemoryExtractor().capture(original);
      final phraseCount = memory.section('verse-1')!.phrases.length;
      final indices = _phraseIndices(verse, 0, phraseCount);
      expect(indices.length, greaterThan(3));

      final melody = List<MelodyNote>.from(verse.melody);
      for (var ordinal = 0; ordinal < indices.length; ordinal++) {
        final index = indices[ordinal];
        final source = melody[index];
        melody[index] = MelodyNote(
          note: ordinal.isEven ? 'C' : 'B',
          octave: ordinal.isEven ? 4 : 5,
          duration: source.duration,
          velocity: source.velocity,
          chordIndex: source.chordIndex,
        );
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

      final variants = const PhraseRepairEngine().build(
        draft: degraded,
        phraseId: 'verse-1:p0',
      );
      final smooth = variants.firstWhere(
        (variant) => variant.style == PhraseRepairStyle.contourSmooth,
      );

      expect(smooth.scoreDelta, greaterThan(0.05));
      expect(_maxLeap(smooth.draft.sectionById('verse-1')!, indices), lessThan(13));
    });

    test('every accepted repair preserves all unrelated song material exactly', () {
      final original = _draft(580404);
      final chorus = original.sectionById('chorus-1')!;
      final memory = const SongMemoryExtractor().capture(original);
      final phraseCount = memory.section('chorus-1')!.phrases.length;
      final targetIndices = _phraseIndices(chorus, 1, phraseCount).toSet();
      final melody = List<MelodyNote>.from(chorus.melody);
      final lastIndex = targetIndices.reduce(max);
      final last = melody[lastIndex];
      final chord = chorus.progression[last.chordIndex];
      melody[lastIndex] = MelodyNote(
        note: _nonChordTone(chord),
        octave: last.octave,
        duration: last.duration,
        velocity: last.velocity,
        chordIndex: last.chordIndex,
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

      final variants = const PhraseRepairEngine().build(
        draft: degraded,
        phraseId: 'chorus-1:p1',
      );
      expect(variants, isNotEmpty);

      for (final variant in variants) {
        for (final section in degraded.sections) {
          final repaired = variant.draft.sectionById(section.plan.id)!;
          if (section.plan.id != 'chorus-1') {
            expect(_sectionSignature(repaired), _sectionSignature(section));
            continue;
          }
          expect(_bassSignature(repaired.bass), _bassSignature(section.bass));
          expect(_progressionSignature(repaired.progression), _progressionSignature(section.progression));
          for (var i = 0; i < section.melody.length; i++) {
            if (targetIndices.contains(i)) continue;
            expect(_noteSignature(repaired.melody[i]), _noteSignature(section.melody[i]));
          }
        }
      }
    });

    test('same degraded draft produces deterministic repair variants', () {
      final original = _draft(580405);
      final verse = original.sectionById('verse-1')!;
      final memory = const SongMemoryExtractor().capture(original);
      final phraseCount = memory.section('verse-1')!.phrases.length;
      final indices = _phraseIndices(verse, 0, phraseCount);
      final melody = List<MelodyNote>.from(verse.melody);
      for (var ordinal = 0; ordinal < indices.length; ordinal++) {
        final index = indices[ordinal];
        final source = melody[index];
        melody[index] = MelodyNote(
          note: ordinal.isEven ? 'C' : 'B',
          octave: ordinal.isEven ? 4 : 5,
          duration: source.duration,
          velocity: source.velocity,
          chordIndex: source.chordIndex,
        );
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

      const engine = PhraseRepairEngine();
      final first = engine.build(draft: degraded, phraseId: 'verse-1:p0');
      final second = engine.build(draft: degraded, phraseId: 'verse-1:p0');

      expect(_variantSignature(first), _variantSignature(second));
    });

    test('unknown and melody-disabled phrases safely produce no repairs', () {
      final draft = _draft(580406);
      expect(
        const PhraseRepairEngine().build(draft: draft, phraseId: 'missing:p0'),
        isEmpty,
      );

      final request = _request(580407).copyWith(includeMelody: false);
      final noMelody = ProducerSongComposer().compose(
        request: request,
        plan: SongPlan.standard(seed: request.seed),
      );
      expect(const PhraseRepairEngine().build(draft: noMelody), isEmpty);
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

List<int> _phraseIndices(
  GeneratedSongSection section,
  int phraseIndex,
  int phraseCount,
) {
  final output = <int>[];
  final chordCount = section.progression.length;
  for (var i = 0; i < section.melody.length; i++) {
    final note = section.melody[i];
    final safeChord = note.chordIndex.clamp(0, chordCount - 1).toInt();
    final normalized = ((safeChord + 0.5) / chordCount).clamp(0.0, 0.999999);
    final bucket =
        (normalized * phraseCount).floor().clamp(0, phraseCount - 1).toInt();
    if (bucket == phraseIndex) output.add(i);
  }
  return output;
}

double _guardrailDistance(PhraseLineageNode node) {
  final value = node.sourceSimilarity;
  final window = node.targetWindow;
  if (window.contains(value)) return 0.0;
  return value < window.minimum
      ? window.minimum - value
      : value - window.maximum;
}

String _nonChordTone(Chord chord) {
  final chordTones = getChordNotes(chord).toSet();
  const chromatic = <String>[
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];
  return chromatic.firstWhere((note) => !chordTones.contains(note));
}

int _maxLeap(GeneratedSongSection section, List<int> indices) {
  var result = 0;
  for (var i = 1; i < indices.length; i++) {
    final previous = section.melody[indices[i - 1]];
    final current = section.melody[indices[i]];
    result = max(
      result,
      (noteToPitch(current.note, current.octave) -
              noteToPitch(previous.note, previous.octave))
          .abs(),
    );
  }
  return result;
}

String _variantSignature(List<PhraseRepairVariant> variants) => variants
    .map((variant) =>
        '${variant.style.name}:${variant.scoreDelta.toStringAsFixed(4)}:'
        '${variant.songScoreDelta.toStringAsFixed(4)}:${variant.changedNoteCount}:'
        '${_sectionSignature(variant.draft.sectionById(variant.sectionId)!)}')
    .join('|');

String _sectionSignature(GeneratedSongSection section) =>
    '${_progressionSignature(section.progression)}#${section.melody.map(_noteSignature).join('|')}#${_bassSignature(section.bass)}';

String _progressionSignature(List<Chord> progression) => progression
    .map((chord) => '${chord.root}:${chord.type.name}:${chord.degree}:${chord.numeral}')
    .join('|');

String _bassSignature(List<BassNote> bass) => bass
    .map((note) =>
        '${note.note}${note.octave}:${note.duration.toStringAsFixed(4)}:'
        '${note.velocity.toStringAsFixed(4)}:${note.chordIndex}:${note.style.name}')
    .join('|');

String _noteSignature(MelodyNote note) =>
    '${note.note}${note.octave}:${note.duration.toStringAsFixed(4)}:'
    '${note.velocity.toStringAsFixed(4)}:${note.chordIndex}';
