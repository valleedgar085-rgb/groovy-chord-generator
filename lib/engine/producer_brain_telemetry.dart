import 'song_candidate.dart';

class ProducerDecisionSnapshot {
  ProducerDecisionSnapshot({
    required this.winner,
    required List<SongCandidate> variations,
    ProducerVariationStyle? selectedStyle,
  })  : variations = List<SongCandidate>.unmodifiable(variations),
        selectedStyle = selectedStyle ?? winner.variationStyle;

  final SongCandidate winner;
  final List<SongCandidate> variations;
  final ProducerVariationStyle selectedStyle;

  double get scoreDelta => winner.scoreDelta;
  bool get improved => scoreDelta > 0.05;

  SongCandidate? candidateFor(ProducerVariationStyle style) {
    if (winner.variationStyle == style) return winner;
    for (final candidate in variations) {
      if (candidate.variationStyle == style) return candidate;
    }
    return null;
  }

  SongCandidate get activeCandidate => candidateFor(selectedStyle) ?? winner;

  bool isSelected(SongCandidate candidate) =>
      activeCandidate.variationStyle == candidate.variationStyle &&
      activeCandidate.candidateIndex == candidate.candidateIndex;

  ProducerDecisionSnapshot select(SongCandidate candidate) {
    final available = candidateFor(candidate.variationStyle);
    if (available == null) return this;
    return ProducerDecisionSnapshot(
      winner: winner,
      variations: variations,
      selectedStyle: available.variationStyle,
    );
  }
}

/// Lightweight bridge from the generation engine to Producer Brain UI.
///
/// Phase 5.3 adds an explicit active selection so the ranked winner can remain
/// visible while the musician auditions and chooses a different A/B/C producer
/// direction by taste.
class ProducerBrainTelemetry {
  ProducerBrainTelemetry._();

  static final ProducerBrainTelemetry instance = ProducerBrainTelemetry._();

  ProducerDecisionSnapshot? latest;

  void publish(List<SongCandidate> ranked) {
    if (ranked.isEmpty) {
      latest = null;
      return;
    }

    SongCandidate? bestFor(ProducerVariationStyle style) {
      for (final candidate in ranked) {
        if (candidate.variationStyle == style) return candidate;
      }
      return null;
    }

    final polished = bestFor(ProducerVariationStyle.polished);
    final creative = bestFor(ProducerVariationStyle.creative);
    final hook = bestFor(ProducerVariationStyle.hook);
    final variations = <SongCandidate>[
      if (polished != null) polished,
      if (creative != null) creative,
      if (hook != null) hook,
    ];

    latest = ProducerDecisionSnapshot(
      winner: ranked.first,
      variations: variations,
    );
  }

  void select(SongCandidate candidate) {
    final current = latest;
    if (current == null) return;
    latest = current.select(candidate);
  }

  void clear() => latest = null;
}
