import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';
import 'package:groovy_chord_generator/engine/song_candidate.dart';
import 'package:groovy_chord_generator/engine/song_draft.dart';
import 'package:groovy_chord_generator/models/types.dart';

Chord c(String root, String degree) => Chord(
      root: root,
      type: degree == 'ii' ? ChordTypeName.minor : ChordTypeName.major,
      degree: degree,
      numeral: degree,
    );

GeneratedSongSection generated(
  SongSectionPlan plan,
  List<Chord> progression,
  double score,
) {
  return GeneratedSongSection(
    plan: plan,
    candidate: SongCandidate(
      progression: progression,
      score: score,
      seed: 1,
      candidateIndex: 0,
      section: plan.harmonySection,
    ),
  );
}

void main() {
  group('SongDraft', () {
    test('retains previous generated progression in arrangement order', () {
      final plan = SongPlan.standard(seed: 1);
      var draft = SongDraft(plan: plan);
      draft = draft.withSection(generated(
        plan.sectionById('verse-1')!,
        [c('C', 'I'), c('F', 'IV')],
        80,
      ));
      draft = draft.withSection(generated(
        plan.sectionById('pre-1')!,
        [c('D', 'ii'), c('G', 'V')],
        84,
      ));

      expect(
        draft.previousProgressionFor('chorus-1').map((chord) => chord.degree),
        orderedEquals(['ii', 'V']),
      );
    });

    test('later repeated section can find its original musical identity', () {
      final plan = SongPlan.standard(seed: 2);
      var draft = SongDraft(plan: plan);
      final verse1 = generated(
        plan.sectionById('verse-1')!,
        [c('C', 'I'), c('F', 'IV')],
        77,
      );
      draft = draft.withSection(verse1);

      final reference = draft.repetitionReferenceFor('verse-2');
      expect(reference?.plan.id, 'verse-1');
      expect(reference?.progression.first.degree, 'I');
    });

    test('withSection replaces same id without duplicating it', () {
      final plan = SongPlan.standard(seed: 3);
      var draft = SongDraft(plan: plan);
      final sectionPlan = plan.sectionById('intro')!;
      draft = draft.withSection(generated(sectionPlan, [c('C', 'I'), c('F', 'IV')], 60));
      draft = draft.withSection(generated(sectionPlan, [c('C', 'I'), c('G', 'V')], 70));

      expect(draft.sections.where((s) => s.plan.id == 'intro').length, 1);
      expect(draft.sectionById('intro')?.candidate.score, 70);
    });

    test('average harmony score reflects retained sections', () {
      final plan = SongPlan.standard(seed: 4);
      var draft = SongDraft(plan: plan);
      draft = draft.withSection(generated(
        plan.sectionById('intro')!,
        [c('C', 'I'), c('F', 'IV')],
        70,
      ));
      draft = draft.withSection(generated(
        plan.sectionById('verse-1')!,
        [c('C', 'I'), c('G', 'V')],
        90,
      ));

      expect(draft.averageHarmonyScore, 80);
      expect(draft.isComplete, isFalse);
    });
  });
}
