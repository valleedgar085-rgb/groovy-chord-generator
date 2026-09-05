import 'song_candidate.dart';

class ProducerDecisionSnapshot {
  ProducerDecisionSnapshot({
    required this.winner,
    required List<SongCandidate> variations,
  }) : variations = List<SongCandidate>.unmodifiable(variations);

  final SongCandidate winner;
  final List<SongCandidate> variations;

  double get scoreDelta => winner.scoreDelta;
  bool get improved => scoreDelta > 0.05;
}

/// Lightweight read-only bridge from the generation engine to the scorecard UI.
/// AppState already rebuilds after generation, so no second notifier is needed.
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

    final variations = <SongCandidate>[
      if (bestFor(ProducerVariationStyle.polished) case final value?) value,
      if (bestFor(ProducerVariationStyle.creative) case final value?) value,
      if (bestFor(ProducerVariationStyle.hook) case final value?) value,
    ];

    latest = ProducerDecisionSnapshot(
      winner: ranked.first,
      variations: variations,
    );
  }

  void clear() => latest = null;
}
