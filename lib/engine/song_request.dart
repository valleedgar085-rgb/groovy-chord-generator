import '../models/types.dart';
import 'harmony_engine.dart';

/// Immutable input contract for producer-grade generation.
///
/// UI state should be translated into one of these requests before generation.
/// Keeping the request independent from widgets/provider mutations lets the
/// engine become reproducible, testable, portable, and eventually shareable
/// with other Chord Flow clients.
class SongRequest {
  const SongRequest({
    required this.seed,
    required this.key,
    required this.genre,
    required this.mood,
    required this.complexity,
    required this.spice,
    required this.rhythm,
    this.section = HarmonySection.neutral,
    this.candidateCount = 8,
    this.chordVariety = 50,
    this.useVoiceLeading = true,
    this.useAdvancedTheory = true,
    this.useModalInterchange = true,
    this.useFunctionalHarmony = true,
    this.includeMelody = true,
    this.includeBass = true,
  })  : assert(candidateCount >= 1 && candidateCount <= 32),
        assert(chordVariety >= 0 && chordVariety <= 100);

  final int seed;
  final KeyName key;
  final GenreKey genre;
  final MoodType mood;
  final ComplexityLevel complexity;
  final SpiceLevel spice;
  final RhythmLevel rhythm;
  final HarmonySection section;
  final int candidateCount;
  final int chordVariety;
  final bool useVoiceLeading;
  final bool useAdvancedTheory;
  final bool useModalInterchange;
  final bool useFunctionalHarmony;
  final bool includeMelody;
  final bool includeBass;

  /// Stable, independent seed for one candidate in this request.
  ///
  /// Candidate generation must use this seed (or a Random created from it)
  /// instead of creating unseeded Random instances. That makes a request fully
  /// replayable and gives future A/B/C variations a stable identity.
  int candidateSeed(int index) {
    if (index < 0 || index >= candidateCount) {
      throw RangeError.range(index, 0, candidateCount - 1, 'index');
    }
    return _mixSeed(index + 1);
  }

  /// Stable stream seeds keep harmony, melody, bass, and performance randomness
  /// independent. Changing one generator later will not silently reshuffle all
  /// of the other musical layers for the same project seed.
  int get melodySeed => _mixSeed(0x4d454c4f);
  int get bassSeed => _mixSeed(0x42415353);
  int get performanceSeed => _mixSeed(0x50455246);

  int streamSeed(int streamId) => _mixSeed(streamId);

  int _mixSeed(int salt) {
    var value = (seed & 0x7fffffff) ^ (salt * 0x45d9f3b);
    value = ((value ^ (value >> 16)) * 0x45d9f3b) & 0x7fffffff;
    value = ((value ^ (value >> 16)) * 0x45d9f3b) & 0x7fffffff;
    value = (value ^ (value >> 16)) & 0x7fffffff;
    return value;
  }

  SongRequest copyWith({
    int? seed,
    KeyName? key,
    GenreKey? genre,
    MoodType? mood,
    ComplexityLevel? complexity,
    SpiceLevel? spice,
    RhythmLevel? rhythm,
    HarmonySection? section,
    int? candidateCount,
    int? chordVariety,
    bool? useVoiceLeading,
    bool? useAdvancedTheory,
    bool? useModalInterchange,
    bool? useFunctionalHarmony,
    bool? includeMelody,
    bool? includeBass,
  }) {
    return SongRequest(
      seed: seed ?? this.seed,
      key: key ?? this.key,
      genre: genre ?? this.genre,
      mood: mood ?? this.mood,
      complexity: complexity ?? this.complexity,
      spice: spice ?? this.spice,
      rhythm: rhythm ?? this.rhythm,
      section: section ?? this.section,
      candidateCount: candidateCount ?? this.candidateCount,
      chordVariety: chordVariety ?? this.chordVariety,
      useVoiceLeading: useVoiceLeading ?? this.useVoiceLeading,
      useAdvancedTheory: useAdvancedTheory ?? this.useAdvancedTheory,
      useModalInterchange: useModalInterchange ?? this.useModalInterchange,
      useFunctionalHarmony:
          useFunctionalHarmony ?? this.useFunctionalHarmony,
      includeMelody: includeMelody ?? this.includeMelody,
      includeBass: includeBass ?? this.includeBass,
    );
  }
}
