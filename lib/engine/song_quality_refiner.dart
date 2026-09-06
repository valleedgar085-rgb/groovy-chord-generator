import 'phrase_producer_brain.dart';
import 'phrase_repair_engine.dart';
import 'song_draft.dart';
import 'song_memory_extractor.dart';

/// Deterministic pre-judge cleanup for issues we already know how to repair
/// safely.
///
/// This is not a score inflater. It delegates to Phase 5.8D, whose repair
/// candidates must improve the target phrase, preserve the whole-song phrase
/// score, preserve unrelated material, and never regress lineage. The refiner
/// simply applies that proven closed loop automatically before the final judge.
class SongQualityRefiner {
  const SongQualityRefiner({
    this.memoryExtractor = const SongMemoryExtractor(),
    this.phraseAnalyzer = const PhraseProducerAnalyzer(),
    this.phraseRepairEngine = const PhraseRepairEngine(),
    this.maxRepairs = 10,
  });

  final SongMemoryExtractor memoryExtractor;
  final PhraseProducerAnalyzer phraseAnalyzer;
  final PhraseRepairEngine phraseRepairEngine;
  final int maxRepairs;

  SongDraft refine(SongDraft draft) {
    if (draft.sections.isEmpty || maxRepairs <= 0) return draft;
    var current = draft;
    final blocked = <String>{};

    for (var pass = 0; pass < maxRepairs; pass++) {
      final memory = memoryExtractor.capture(current);
      final analysis = phraseAnalyzer.analyze(draft: current, memory: memory);
      final violations = analysis.phrases
          .where(
            (phrase) =>
                phrase.lineage != null &&
                !phrase.lineage!.isSource &&
                !phrase.lineageInsideGuardrail &&
                !blocked.contains(phrase.phraseId),
          )
          .toList()
        ..sort((a, b) {
          final byLineage = a
              .metricFor(PhraseProducerDimension.lineage)
              .score
              .compareTo(b.metricFor(PhraseProducerDimension.lineage).score);
          if (byLineage != 0) return byLineage;
          return a.score.compareTo(b.score);
        });
      if (violations.isEmpty) break;

      final target = violations.first;
      final variants = phraseRepairEngine.build(
        draft: current,
        phraseId: target.phraseId,
      );
      if (variants.isEmpty) {
        blocked.add(target.phraseId);
        continue;
      }

      PhraseRepairVariant? chosen;
      for (final variant in variants) {
        if (variant.after.lineageInsideGuardrail) {
          chosen = variant;
          break;
        }
      }
      chosen ??= variants.firstWhere(
        (variant) => variant.style == PhraseRepairStyle.identityBalance,
        orElse: () => variants.first,
      );

      final beforeLineage = target
          .metricFor(PhraseProducerDimension.lineage)
          .score;
      final afterLineage = chosen.after
          .metricFor(PhraseProducerDimension.lineage)
          .score;
      if (afterLineage <= beforeLineage + 0.05) {
        blocked.add(target.phraseId);
        continue;
      }
      current = chosen.draft;
    }

    return current;
  }
}
