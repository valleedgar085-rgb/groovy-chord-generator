import '../models/types.dart';
import 'harmony_engine.dart';
import 'producer_analysis.dart';

/// Immutable result from one producer-brain candidate pass.
///
/// Phase 5.1 keeps the multidimensional analysis alongside the seed and ranking
/// metadata so candidate decisions can be inspected, compared, and evolved
/// without recomputing the same musical judgment.
class SongCandidate {
  SongCandidate({
    required List<Chord> progression,
    required this.score,
    required this.seed,
    required this.candidateIndex,
    required this.section,
    this.producerAnalysis,
  }) : progression = List<Chord>.unmodifiable(progression);

  final List<Chord> progression;
  final double score;
  final int seed;
  final int candidateIndex;
  final HarmonySection section;
  final ProducerAnalysis? producerAnalysis;
}
