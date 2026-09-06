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
    this.maxPhraseRepairs = 20,
    this.maxQualityPhraseRepairs = 8,
    this.maxTransitionRepairs = 10,
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
      (maxPhraseRepairs / 2).ceil(),
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
          final bySeverity = _lineageDistance(b).compareTo(_lineageDistance(a));
          if (bySeverity != 0) return bySeverity;
          final byLineage = a
              .metricFor(PhraseProducerDimension.lineage)
              .score
              .compareTo(b.metricFor(PhraseProducerDimension.lineage).score);
          if (byLineage != 0) return byLineage;
          return a.score.compareTo(b.score);
        });
      if (violations.isEmpty) break;

      final target = violations.first;
      final beforeDistance = _lineageDistance(target);
      final variants = phraseRepairEngine.build(
        draft: current,
        phraseId: target.phraseId,
      );
      if (variants.isEmpty) {
        blocked.add(target.phraseId);
        continue;
      }

      // Do not assume IDENTITY BALANCE is always the best rescue. Every repair
      // style is re-extracted through Song Memory, so choose the candidate that
      // gets closest to the actual A/A'/A'' similarity window while retaining
      // the non-regression guarantees already enforced by PhraseRepairEngine.
      PhraseRepairVariant? chosen;
      var chosenDistance = double.infinity;
      for (final variant in variants) {
        final distance = _lineageDistance(variant.after);
        if (distance + 0.0001 >= beforeDistance) continue;
        if (variant.afterSongScore + 0.01 < analysis.overallScore) continue;
        if (chosen == null ||
            distance + 0.0001 < chosenDistance ||
            ((distance - chosenDistance).abs() <= 0.0001 &&
                variant.after.score > chosen.after.score)) {
          chosen = variant;
          chosenDistance = distance;
        }
      }

      if (chosen == null) {
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
        if (variant.afterSongScore + 0.01 < analysis.overallScore) continue;
        if (_isSevereLineage(variant.after)) continue;
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
      double chosenDirectorScore = -1;
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
        // A microscopic whole-song phrase tradeoff is permitted only when no
        // severe identity issue is introduced. This lets a genuinely stronger
        // handoff win without damaging Musical DNA.
        if (afterPhrase.overallScore + 0.20 < beforePhrase.overallScore) {
          continue;
        }
        if (_severeLineageCount(afterPhrase) >
            _severeLineageCount(beforePhrase)) {
          continue;
        }
        final composite = variant.after.score * 0.72 +
            afterDirector.overallScore * 0.20 +
            afterPhrase.overallScore * 0.08;
        if (chosen == null || composite > chosenDirectorScore) {
          chosen = variant;
          chosenDirectorScore = composite;
        }
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

  double _lineageDistance(PhraseProducerAssessment phrase) {
    final lineage = phrase.lineage;
    if (lineage == null || lineage.isSource || lineage.insideGuardrail) {
      return 0.0;
    }
    final value = lineage.sourceSimilarity;
    final window = lineage.targetWindow;
    return value < window.minimum
        ? window.minimum - value
        : value - window.maximum;
  }

  bool _isSevereLineage(PhraseProducerAssessment phrase) {
    final lineage = phrase.lineage;
    if (lineage == null || lineage.isSource || lineage.insideGuardrail) {
      return false;
    }
    final similarity = lineage.sourceSimilarity;
    final gap = _lineageDistance(phrase);
    // Keep this definition exactly aligned with GodJudge. Pre-judge cleanup
    // must never call a phrase safe when the final gate will still veto it.
    return similarity >= 0.985 || gap >= 0.075;
  }
}
