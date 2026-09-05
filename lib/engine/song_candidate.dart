import '../models/types.dart';
import 'harmony_engine.dart';
import 'producer_analysis.dart';

enum ProducerVariationStyle { raw, polished, creative, hook }

extension ProducerVariationStyleLabel on ProducerVariationStyle {
  String get label => switch (this) {
        ProducerVariationStyle.raw => 'RAW',
        ProducerVariationStyle.polished => 'POLISHED',
        ProducerVariationStyle.creative => 'CREATIVE',
        ProducerVariationStyle.hook => 'HOOK',
      };
}

/// Immutable result from one Producer Brain candidate pass.
class SongCandidate {
  SongCandidate({
    required List<Chord> progression,
    required this.score,
    required this.seed,
    required this.candidateIndex,
    required this.section,
    this.producerAnalysis,
    this.variationStyle = ProducerVariationStyle.raw,
    this.beforeRefineScore,
    List<String> repairs = const <String>[],
  })  : progression = List<Chord>.unmodifiable(progression),
        repairs = List<String>.unmodifiable(repairs);

  final List<Chord> progression;
  final double score;
  final int seed;
  final int candidateIndex;
  final HarmonySection section;
  final ProducerAnalysis? producerAnalysis;
  final ProducerVariationStyle variationStyle;
  final double? beforeRefineScore;
  final List<String> repairs;

  double get scoreDelta => score - (beforeRefineScore ?? score);
  bool get wasRefined => variationStyle != ProducerVariationStyle.raw;
}
