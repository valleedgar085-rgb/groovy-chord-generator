import 'phrase_producer_brain.dart';
import 'phrase_repair_engine.dart';
import 'song_director.dart';
import 'song_draft.dart';
import 'song_memory_extractor.dart';
import 'transition_repair_engine.dart';

/// Deterministic pre-judge cleanup for issues Chord Flow already knows how to
/// repair safely.
///
/// This is not a score inflater. Phrase candidates still obey Phase 5.8D's
/// non-regression contract. Transition candidates still obey Phase 5.6's local
/// handoff contract, and this coordinator adds a second whole-song check before
/// accepting them. Strong material is therefore protected while weak identity,
/// weak-but-valid phrases, or boundary handoffs get a final self-correction pass.
class SongQualityRefiner {
  const SongQualityRefiner({
    this.memoryExtractor = const SongMemoryExtractor(),
    this.phraseAnalyzer = const PhraseProducerAnalyzer(),
    this.phraseRepairEngine = const PhraseRepairEngine(),
    this.director = const SongDirectorAnalyzer(),
    this.transitionRepairEngine = const TransitionRepairEngine(),
    this.maxPhraseRepairs = 14,
    this.maxQualityPhraseRepairs = 6,
    this.maxTransitionRepairs = 7,
    this.transitionTarget = 76.0,
    this.phraseQualityTarget = 80.0,
  });

  final SongMemoryExtractor memoryExtractor;
  final PhraseProducerAnalyzer phraseAnalyzer;
  final PhraseRepairEngine phraseRepairEngine;
  final SongDirectorAnalyzer director;
  final TransitionRepairEngine transitionRepairEngine;
  final int maxPhraseRepairs;
  final int maxQualityPhraseRepairs;
  final int maxTransitionRepairs;
  final double transitionTarget;
  final double phraseQualityTarget;

  SongDraft refine(SongDraft draft) {
    if (draft.sections.isEmpty) return draft;

    // Identity first: this gives transition repair the cleanest possible motif
    // state. Boundary repair may touch the first/last phrase of a section, so a
    // second identity pass runs afterward. Finally, weak-but-valid phrases get
    // the same selective repair treatment; the judge should not accept a phrase
    // merely because it avoided violating ancestry.
    var current = _refinePhraseLineage(draft, maxPhraseRepairs);
    current = _refineTransitions(current);
    current = _refinePhraseLineage(
      current,
      (maxPhraseRepairs / 2).ceil(),
    );
    current = _refineWeakPhrases(current);
    current = _refinePhraseLineage(
      current,
      (maxPhraseRepairs / 3).ceil(),
    );
    return current;
  }

  SongDraft _refinePhraseLineage(SongDraft draft, int limit) {
    if (limit <= 0) return draft;
    var current = draft;
    final blocked = <String>{};

    for (var pass = 0; pass < limit; pass++) {
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

      final beforeLineage =
          target.metricFor(PhraseProducerDimension.lineage).score;
      final afterLineage =
          chosen.after.metricFor(PhraseProducerDimension.lineage).score;
      if (afterLineage <= beforeLineage + 0.05) {
        blocked.add(target.phraseId);
        continue;
      }
      current = chosen.draft;
    }

    return current;
  }

  SongDraft _refineWeakPhrases(SongDraft draft) {
    if (maxQualityPhraseRepairs <= 0) return draft;
    var current = draft;
    final blocked = <String>{};

    for (var pass = 0; pass < maxQualityPhraseRepairs; pass++) {
      final memory = memoryExtractor.capture(current);
      final analysis = phraseAnalyzer.analyze(draft: current, memory: memory);
      final weak = analysis.phrases
          .where(
            (phrase) =>
                phrase.score + 0.01 < phraseQualityTarget &&
                !blocked.contains(phrase.phraseId),
          )
          .toList()
        ..sort((a, b) => a.score.compareTo(b.score));
      if (weak.isEmpty) break;

      final target = weak.first;
      final variants = phraseRepairEngine.build(
        draft: current,
        phraseId: target.phraseId,
      );
      PhraseRepairVariant? chosen;
      for (final variant in variants) {
        if (variant.after.score <= target.score + 0.15) continue;
        if (variant.afterOverallScore + 0.01 < analysis.overallScore) continue;
        final afterLineage = variant.after.lineage;
        if (afterLineage != null &&
            !afterLineage.isSource &&
            !variant.after.lineageInsideGuardrail &&
            _isSevereLineage(variant.after)) {
          continue;
        }
        chosen = variant;
        break;
      }

      if (chosen == null) {
        blocked.add(target.phraseId);
        continue;
      }
      current = chosen.draft;
    }

    return current;
  }

  SongDraft _refineTransitions(SongDraft draft) {
    if (maxTransitionRepairs <= 0 || draft.sections.length < 2) return draft;
    var current = draft;
    final blocked = <String>{};

    for (var pass = 0; pass < maxTransitionRepairs; pass++) {
      final beforeMemory = memoryExtractor.capture(current);
      final beforeDirector = director.analyze(
        draft: current,
        memory: beforeMemory,
      );
      final beforePhrase = phraseAnalyzer.analyze(
        draft: current,
        memory: beforeMemory,
      );
      final candidates = beforeDirector.transitions
          .where(
            (transition) =>
                transition.score + 0.01 < transitionTarget &&
                !blocked.contains(
                  '${transition.fromSectionId}->${transition.toSectionId}',
                ),
          )
          .toList()
        ..sort((a, b) => a.score.compareTo(b.score));
      if (candidates.isEmpty) break;

      final target = candidates.first;
      final key = '${target.fromSectionId}->${target.toSectionId}';
      final variants = transitionRepairEngine.build(
        draft: current,
        fromSectionId: target.fromSectionId,
        toSectionId: target.toSectionId,
      );
      if (variants.isEmpty) {
        blocked.add(key);
        continue;
      }

      TransitionRepairVariant? chosen;
      for (final variant in variants) {
        if (variant.after.score <= target.score + 0.05) continue;
        final afterMemory = memoryExtractor.capture(variant.draft);
        final afterDirector = director.analyze(
          draft: variant.draft,
          memory: afterMemory,
        );
        final afterPhrase = phraseAnalyzer.analyze(
          draft: variant.draft,
          memory: afterMemory,
        );
        if (afterDirector.overallScore + 0.01 < beforeDirector.overallScore) {
          continue;
        }
        if (afterPhrase.overallScore + 0.05 < beforePhrase.overallScore) {
          continue;
        }
        if (_severeLineageCount(afterPhrase) >
            _severeLineageCount(beforePhrase)) {
          continue;
        }
        chosen = variant;
        break;
      }

      if (chosen == null) {
        blocked.add(key);
        continue;
      }
      current = chosen.draft;
    }

    return current;
  }

  int _severeLineageCount(SongPhraseProducerAnalysis analysis) {
    var count = 0;
    for (final phrase in analysis.phrases) {
      if (_isSevereLineage(phrase)) count++;
    }
    return count;
  }

  bool _isSevereLineage(PhraseProducerAssessment phrase) {
    final lineage = phrase.lineage;
    if (lineage == null || lineage.isSource || lineage.insideGuardrail) {
      return false;
    }
    final similarity = lineage.sourceSimilarity;
    final window = lineage.targetWindow;
    final gap = similarity < window.minimum
        ? window.minimum - similarity
        : similarity - window.maximum;
    return similarity >= 0.985 || gap >= 0.10;
  }
}
