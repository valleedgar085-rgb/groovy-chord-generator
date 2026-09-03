import '../models/types.dart';
import 'harmony_engine.dart';

/// Immutable result from one producer-brain candidate pass.
///
/// The candidate keeps the seed and ranking metadata alongside the harmony so
/// results can be replayed, compared, exported, and evolved by future phases.
class SongCandidate {
  SongCandidate({
    required List<Chord> progression,
    required this.score,
    required this.seed,
    required this.candidateIndex,
    required this.section,
  }) : progression = List<Chord>.unmodifiable(progression);

  final List<Chord> progression;
  final double score;
  final int seed;
  final int candidateIndex;
  final HarmonySection section;
}
