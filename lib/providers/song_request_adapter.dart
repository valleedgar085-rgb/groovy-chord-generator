import '../engine/song_request.dart';
import 'app_state.dart';

/// Converts the existing UI/settings provider into the immutable Producer Core
/// request used by both single-progression and full-song generation.
///
/// Keeping this adapter explicit prevents widgets from re-implementing the
/// mapping and gives the final AppState migration a single compatibility seam.
class SongRequestAdapter {
  const SongRequestAdapter._();

  static SongRequest fromAppState(
    AppState state, {
    int? seed,
  }) {
    final generationSeed =
        seed ?? (DateTime.now().microsecondsSinceEpoch & 0x7fffffff);

    return SongRequest(
      seed: generationSeed,
      key: state.currentKey,
      genre: state.genre,
      mood: state.currentMood,
      complexity: state.complexity,
      spice: state.spiceLevel,
      rhythm: state.rhythm,
      section: state.harmonySection,
      candidateCount: state.producerCandidateCount,
      chordVariety: state.chordVariety,
      useVoiceLeading: state.useVoiceLeading,
      useAdvancedTheory: state.useAdvancedTheory,
      useModalInterchange: state.useModalInterchange,
      useFunctionalHarmony: state.useFunctionalHarmony,
      includeMelody: state.includeMelody,
      includeBass: state.includeBass,
    );
  }
}
