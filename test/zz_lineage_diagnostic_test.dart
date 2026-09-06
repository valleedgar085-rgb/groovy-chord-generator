import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/engine/harmony_engine.dart';
import 'package:groovy_chord_generator/engine/performance_profile.dart';
import 'package:groovy_chord_generator/engine/producer_song_composer.dart';
import 'package:groovy_chord_generator/engine/producer_song_variation_engine.dart';
import 'package:groovy_chord_generator/engine/song_architecture.dart';
import 'package:groovy_chord_generator/engine/song_candidate.dart';
import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/models/types.dart';

void main() {
  test('GOD TEST — final A/B/C directions contain no severe lineage drift', () {
    final request = SongRequest(
      seed: 540054,
      key: KeyName.C,
      genre: GenreKey.happyPop,
      mood: MoodType.happy,
      complexity: ComplexityLevel.medium,
      spice: SpiceLevel.medium,
      rhythm: RhythmLevel.moderate,
      section: HarmonySection.neutral,
      candidateCount: 8,
      chordVariety: 58,
      includeMelody: true,
      includeBass: true,
    );
    final base = ProducerSongComposer().compose(
      request: request,
      plan: SongPlan.standard(seed: request.seed),
      bassStyle: BassStyle.fifths,
      bassVariety: 62,
      grooveTemplate: GrooveTemplate.straight,
    );
    final engine = ProducerSongVariationEngine();
    engine.build(
      baseDraft: base,
      request: request,
      performanceProfile: const PerformanceProfile(),
      bassStyle: BassStyle.fifths,
      bassVariety: 62,
      grooveTemplate: GrooveTemplate.straight,
      tempo: 118,
      swing: 0.08,
    );

    final details = <String>[];
    for (final variation in engine.lastSelection.evaluated) {
      if (variation.style == ProducerVariationStyle.raw) continue;
      for (final phrase in variation.verdict.phrases.phrases) {
        final lineage = phrase.lineage;
        if (lineage == null || lineage.isSource || lineage.insideGuardrail) {
          continue;
        }
        final value = lineage.sourceSimilarity;
        final window = lineage.targetWindow;
        final gap = value < window.minimum
            ? window.minimum - value
            : value - window.maximum;
        if (value >= 0.985 || gap >= 0.075) {
          details.add(
            '${variation.style.name}: ${phrase.phraseId} <- ${lineage.sourcePhraseId} '
            'sim=${value.toStringAsFixed(4)} '
            'window=${window.minimum.toStringAsFixed(2)}-${window.maximum.toStringAsFixed(2)} '
            'gap=${gap.toStringAsFixed(4)} phrase=${phrase.score.toStringAsFixed(1)}',
          );
        }
      }
    }

    expect(
      details,
      isEmpty,
      reason: details.join(' || '),
    );
  });
}
