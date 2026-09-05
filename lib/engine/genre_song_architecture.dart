import '../models/types.dart';
import 'song_architecture.dart';

/// Phase 5.7 arrangement blueprints.
///
/// These plans intentionally reuse the existing broad [SongSectionType] roles
/// so the Producer Brain, Song Director, Song Memory and Transition Engine keep
/// one shared structural vocabulary. Genre-specific intent is carried by the
/// section ids (for example build-1, drop-1, hook-1, breakdown, solo-1) plus
/// tailored bar counts, repetition families, tension targets and energy arcs.
class GenreSongArchitecture {
  const GenreSongArchitecture._();

  static SongPlan build({
    required GenreKey genre,
    required int seed,
  }) {
    switch (genre) {
      case GenreKey.happyPop:
        return SongPlan.standard(seed: seed);
      case GenreKey.chillLofi:
        return _lofi(seed);
      case GenreKey.energeticEdm:
        return _edm(seed);
      case GenreKey.soulfulRnb:
        return _rnb(seed);
      case GenreKey.jazzFusion:
        return _jazzFusion(seed);
      case GenreKey.darkTrap:
        return _trap(seed);
      case GenreKey.cinematic:
        return _cinematic(seed);
      case GenreKey.indieRock:
        return _indieRock(seed);
      case GenreKey.reggae:
        return _reggae(seed);
      case GenreKey.blues:
        return _blues(seed);
      case GenreKey.country:
        return _country(seed);
      case GenreKey.funk:
        return _funk(seed);
    }
  }

  static String labelFor(GenreKey genre) {
    switch (genre) {
      case GenreKey.happyPop:
        return 'Modern Pop Arc';
      case GenreKey.chillLofi:
        return 'Lo-Fi Loop Journey';
      case GenreKey.energeticEdm:
        return 'EDM Build / Drop';
      case GenreKey.soulfulRnb:
        return 'R&B Hook Arc';
      case GenreKey.jazzFusion:
        return 'Fusion Head / Solo';
      case GenreKey.darkTrap:
        return 'Trap Hook / Verse';
      case GenreKey.cinematic:
        return 'Cinematic Rise';
      case GenreKey.indieRock:
        return 'Indie Rock Lift';
      case GenreKey.reggae:
        return 'Reggae Verse / Chorus';
      case GenreKey.blues:
        return '12-Bar Blues Journey';
      case GenreKey.country:
        return 'Country Story Arc';
      case GenreKey.funk:
        return 'Funk Groove / Hook';
    }
  }

  static String descriptionFor(GenreKey genre) {
    switch (genre) {
      case GenreKey.happyPop:
        return 'Verse development, pre-chorus lift, repeated chorus payoff and a final escalation.';
      case GenreKey.chillLofi:
        return 'Longer recurring groove families, a soft breakdown and restrained late-song development.';
      case GenreKey.energeticEdm:
        return 'Extended builds and drops separated by a breakdown, with the second drop carrying the peak.';
      case GenreKey.soulfulRnb:
        return 'Verses feed short tension ramps into recurring hooks, then a bridge opens space before the final hook.';
      case GenreKey.jazzFusion:
        return 'A recognizable head frames longer solo sections and a contrasting bridge before the head returns.';
      case GenreKey.darkTrap:
        return 'Hook-first form with long verses, a sparse breakdown and a final hook return.';
      case GenreKey.cinematic:
        return 'Theme statements grow through staged builds, contrast in a breakdown and reach a longer final climax.';
      case GenreKey.indieRock:
        return 'Direct verse-to-chorus momentum, bridge contrast and a stronger final chorus without mandatory pre-choruses.';
      case GenreKey.reggae:
        return 'Relaxed verse/chorus cycles with an instrumental contrast section before the final refrain.';
      case GenreKey.blues:
        return 'Multiple 12-bar statements with controlled development, a solo chorus and a compact turnaround outro.';
      case GenreKey.country:
        return 'Narrative verses alternate with choruses, then a bridge resets perspective before the last payoff.';
      case GenreKey.funk:
        return 'Groove-led sections alternate with hooks, drop to a breakdown, then rebuild into a final hook.';
    }
  }

  static int totalBars(SongPlan plan) =>
      plan.sections.fold<int>(0, (sum, section) => sum + section.bars);

  static String compactForm(SongPlan plan) =>
      plan.sections.map((section) => displaySectionId(section.id)).join(' → ');

  static String displaySectionId(String id) => id
      .replaceAll('-', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part.substring(0, 1).toUpperCase()}${part.substring(1)}')
      .join(' ');

  static SongPlan _lofi(int seed) => SongPlan(
        seed: seed,
        sections: const [
          SongSectionPlan(
            id: 'intro',
            type: SongSectionType.intro,
            bars: 4,
            targetTension: 0.14,
            targetEnergy: 0.20,
          ),
          SongSectionPlan(
            id: 'groove-a',
            type: SongSectionType.verse,
            bars: 8,
            targetTension: 0.28,
            targetEnergy: 0.38,
            repetitionGroup: 'groove-a',
          ),
          SongSectionPlan(
            id: 'groove-a2',
            type: SongSectionType.verse,
            bars: 8,
            targetTension: 0.32,
            targetEnergy: 0.44,
            repetitionGroup: 'groove-a',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'breakdown',
            type: SongSectionType.bridge,
            bars: 4,
            targetTension: 0.18,
            targetEnergy: 0.26,
          ),
          SongSectionPlan(
            id: 'groove-b',
            type: SongSectionType.verse,
            bars: 8,
            targetTension: 0.34,
            targetEnergy: 0.48,
            repetitionGroup: 'groove-b',
          ),
          SongSectionPlan(
            id: 'groove-a3',
            type: SongSectionType.verse,
            bars: 8,
            targetTension: 0.30,
            targetEnergy: 0.42,
            repetitionGroup: 'groove-a',
            variation: 2,
          ),
          SongSectionPlan(
            id: 'outro',
            type: SongSectionType.outro,
            bars: 4,
            targetTension: 0.12,
            targetEnergy: 0.18,
          ),
        ],
      );

  static SongPlan _edm(int seed) => SongPlan(
        seed: seed,
        sections: const [
          SongSectionPlan(
            id: 'intro',
            type: SongSectionType.intro,
            bars: 8,
            targetTension: 0.28,
            targetEnergy: 0.34,
          ),
          SongSectionPlan(
            id: 'build-1',
            type: SongSectionType.preChorus,
            bars: 8,
            targetTension: 0.78,
            targetEnergy: 0.70,
            repetitionGroup: 'build',
          ),
          SongSectionPlan(
            id: 'drop-1',
            type: SongSectionType.chorus,
            bars: 16,
            targetTension: 0.84,
            targetEnergy: 0.96,
            repetitionGroup: 'drop',
          ),
          SongSectionPlan(
            id: 'breakdown',
            type: SongSectionType.bridge,
            bars: 8,
            targetTension: 0.30,
            targetEnergy: 0.38,
          ),
          SongSectionPlan(
            id: 'build-2',
            type: SongSectionType.preChorus,
            bars: 8,
            targetTension: 0.88,
            targetEnergy: 0.80,
            repetitionGroup: 'build',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'drop-2',
            type: SongSectionType.chorus,
            bars: 16,
            targetTension: 0.92,
            targetEnergy: 1.0,
            repetitionGroup: 'drop',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'outro',
            type: SongSectionType.outro,
            bars: 8,
            targetTension: 0.18,
            targetEnergy: 0.28,
          ),
        ],
      );

  static SongPlan _rnb(int seed) => SongPlan(
        seed: seed,
        sections: const [
          SongSectionPlan(
            id: 'intro',
            type: SongSectionType.intro,
            bars: 4,
            targetTension: 0.20,
            targetEnergy: 0.28,
          ),
          SongSectionPlan(
            id: 'verse-1',
            type: SongSectionType.verse,
            bars: 8,
            targetTension: 0.38,
            targetEnergy: 0.44,
            repetitionGroup: 'verse',
          ),
          SongSectionPlan(
            id: 'pre-1',
            type: SongSectionType.preChorus,
            bars: 4,
            targetTension: 0.64,
            targetEnergy: 0.60,
            repetitionGroup: 'pre',
          ),
          SongSectionPlan(
            id: 'hook-1',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.74,
            targetEnergy: 0.78,
            repetitionGroup: 'hook',
          ),
          SongSectionPlan(
            id: 'verse-2',
            type: SongSectionType.verse,
            bars: 8,
            targetTension: 0.42,
            targetEnergy: 0.50,
            repetitionGroup: 'verse',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'pre-2',
            type: SongSectionType.preChorus,
            bars: 4,
            targetTension: 0.68,
            targetEnergy: 0.66,
            repetitionGroup: 'pre',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'hook-2',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.78,
            targetEnergy: 0.84,
            repetitionGroup: 'hook',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'bridge',
            type: SongSectionType.bridge,
            bars: 8,
            targetTension: 0.56,
            targetEnergy: 0.58,
          ),
          SongSectionPlan(
            id: 'final-hook',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.82,
            targetEnergy: 0.90,
            repetitionGroup: 'hook',
            variation: 2,
          ),
          SongSectionPlan(
            id: 'outro',
            type: SongSectionType.outro,
            bars: 4,
            targetTension: 0.16,
            targetEnergy: 0.28,
          ),
        ],
      );

  static SongPlan _jazzFusion(int seed) => SongPlan(
        seed: seed,
        sections: const [
          SongSectionPlan(
            id: 'intro',
            type: SongSectionType.intro,
            bars: 4,
            targetTension: 0.30,
            targetEnergy: 0.36,
          ),
          SongSectionPlan(
            id: 'head-1',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.58,
            targetEnergy: 0.66,
            repetitionGroup: 'head',
          ),
          SongSectionPlan(
            id: 'solo-1',
            type: SongSectionType.verse,
            bars: 16,
            targetTension: 0.70,
            targetEnergy: 0.74,
            repetitionGroup: 'solo',
          ),
          SongSectionPlan(
            id: 'bridge',
            type: SongSectionType.bridge,
            bars: 8,
            targetTension: 0.62,
            targetEnergy: 0.58,
          ),
          SongSectionPlan(
            id: 'solo-2',
            type: SongSectionType.verse,
            bars: 16,
            targetTension: 0.78,
            targetEnergy: 0.80,
            repetitionGroup: 'solo',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'head-2',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.60,
            targetEnergy: 0.70,
            repetitionGroup: 'head',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'outro',
            type: SongSectionType.outro,
            bars: 4,
            targetTension: 0.24,
            targetEnergy: 0.34,
          ),
        ],
      );

  static SongPlan _trap(int seed) => SongPlan(
        seed: seed,
        sections: const [
          SongSectionPlan(
            id: 'intro',
            type: SongSectionType.intro,
            bars: 4,
            targetTension: 0.34,
            targetEnergy: 0.38,
          ),
          SongSectionPlan(
            id: 'hook-1',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.76,
            targetEnergy: 0.84,
            repetitionGroup: 'hook',
          ),
          SongSectionPlan(
            id: 'verse-1',
            type: SongSectionType.verse,
            bars: 16,
            targetTension: 0.52,
            targetEnergy: 0.58,
            repetitionGroup: 'verse',
          ),
          SongSectionPlan(
            id: 'hook-2',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.80,
            targetEnergy: 0.88,
            repetitionGroup: 'hook',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'verse-2',
            type: SongSectionType.verse,
            bars: 16,
            targetTension: 0.58,
            targetEnergy: 0.64,
            repetitionGroup: 'verse',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'breakdown',
            type: SongSectionType.bridge,
            bars: 4,
            targetTension: 0.36,
            targetEnergy: 0.34,
          ),
          SongSectionPlan(
            id: 'final-hook',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.86,
            targetEnergy: 0.94,
            repetitionGroup: 'hook',
            variation: 2,
          ),
          SongSectionPlan(
            id: 'outro',
            type: SongSectionType.outro,
            bars: 4,
            targetTension: 0.20,
            targetEnergy: 0.28,
          ),
        ],
      );

  static SongPlan _cinematic(int seed) => SongPlan(
        seed: seed,
        sections: const [
          SongSectionPlan(
            id: 'intro',
            type: SongSectionType.intro,
            bars: 8,
            targetTension: 0.22,
            targetEnergy: 0.24,
          ),
          SongSectionPlan(
            id: 'theme-a',
            type: SongSectionType.verse,
            bars: 8,
            targetTension: 0.42,
            targetEnergy: 0.42,
            repetitionGroup: 'theme',
          ),
          SongSectionPlan(
            id: 'build-1',
            type: SongSectionType.preChorus,
            bars: 8,
            targetTension: 0.72,
            targetEnergy: 0.66,
            repetitionGroup: 'build',
          ),
          SongSectionPlan(
            id: 'climax-1',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.86,
            targetEnergy: 0.88,
            repetitionGroup: 'climax',
          ),
          SongSectionPlan(
            id: 'breakdown',
            type: SongSectionType.bridge,
            bars: 8,
            targetTension: 0.30,
            targetEnergy: 0.32,
          ),
          SongSectionPlan(
            id: 'theme-b',
            type: SongSectionType.verse,
            bars: 8,
            targetTension: 0.50,
            targetEnergy: 0.50,
            repetitionGroup: 'theme',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'build-2',
            type: SongSectionType.preChorus,
            bars: 8,
            targetTension: 0.84,
            targetEnergy: 0.78,
            repetitionGroup: 'build',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'final-climax',
            type: SongSectionType.chorus,
            bars: 12,
            targetTension: 0.96,
            targetEnergy: 1.0,
            repetitionGroup: 'climax',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'outro',
            type: SongSectionType.outro,
            bars: 8,
            targetTension: 0.16,
            targetEnergy: 0.22,
          ),
        ],
      );

  static SongPlan _indieRock(int seed) => SongPlan(
        seed: seed,
        sections: const [
          SongSectionPlan(
            id: 'intro',
            type: SongSectionType.intro,
            bars: 4,
            targetTension: 0.24,
            targetEnergy: 0.34,
          ),
          SongSectionPlan(
            id: 'verse-1',
            type: SongSectionType.verse,
            bars: 8,
            targetTension: 0.40,
            targetEnergy: 0.50,
            repetitionGroup: 'verse',
          ),
          SongSectionPlan(
            id: 'chorus-1',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.76,
            targetEnergy: 0.86,
            repetitionGroup: 'chorus',
          ),
          SongSectionPlan(
            id: 'verse-2',
            type: SongSectionType.verse,
            bars: 8,
            targetTension: 0.44,
            targetEnergy: 0.56,
            repetitionGroup: 'verse',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'chorus-2',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.80,
            targetEnergy: 0.90,
            repetitionGroup: 'chorus',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'bridge',
            type: SongSectionType.bridge,
            bars: 8,
            targetTension: 0.62,
            targetEnergy: 0.62,
          ),
          SongSectionPlan(
            id: 'final-chorus',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.88,
            targetEnergy: 0.98,
            repetitionGroup: 'chorus',
            variation: 2,
          ),
          SongSectionPlan(
            id: 'outro',
            type: SongSectionType.outro,
            bars: 4,
            targetTension: 0.18,
            targetEnergy: 0.32,
          ),
        ],
      );

  static SongPlan _reggae(int seed) => SongPlan(
        seed: seed,
        sections: const [
          SongSectionPlan(
            id: 'intro',
            type: SongSectionType.intro,
            bars: 4,
            targetTension: 0.18,
            targetEnergy: 0.30,
          ),
          SongSectionPlan(
            id: 'verse-1',
            type: SongSectionType.verse,
            bars: 8,
            targetTension: 0.34,
            targetEnergy: 0.46,
            repetitionGroup: 'verse',
          ),
          SongSectionPlan(
            id: 'chorus-1',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.56,
            targetEnergy: 0.68,
            repetitionGroup: 'chorus',
          ),
          SongSectionPlan(
            id: 'verse-2',
            type: SongSectionType.verse,
            bars: 8,
            targetTension: 0.38,
            targetEnergy: 0.50,
            repetitionGroup: 'verse',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'chorus-2',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.60,
            targetEnergy: 0.72,
            repetitionGroup: 'chorus',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'instrumental',
            type: SongSectionType.bridge,
            bars: 8,
            targetTension: 0.42,
            targetEnergy: 0.58,
          ),
          SongSectionPlan(
            id: 'final-chorus',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.64,
            targetEnergy: 0.76,
            repetitionGroup: 'chorus',
            variation: 2,
          ),
          SongSectionPlan(
            id: 'outro',
            type: SongSectionType.outro,
            bars: 4,
            targetTension: 0.14,
            targetEnergy: 0.24,
          ),
        ],
      );

  static SongPlan _blues(int seed) => SongPlan(
        seed: seed,
        sections: const [
          SongSectionPlan(
            id: 'intro',
            type: SongSectionType.intro,
            bars: 4,
            targetTension: 0.24,
            targetEnergy: 0.34,
          ),
          SongSectionPlan(
            id: 'verse-1',
            type: SongSectionType.verse,
            bars: 12,
            targetTension: 0.46,
            targetEnergy: 0.54,
            repetitionGroup: 'twelve-bar',
          ),
          SongSectionPlan(
            id: 'verse-2',
            type: SongSectionType.verse,
            bars: 12,
            targetTension: 0.50,
            targetEnergy: 0.60,
            repetitionGroup: 'twelve-bar',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'solo',
            type: SongSectionType.bridge,
            bars: 12,
            targetTension: 0.64,
            targetEnergy: 0.70,
          ),
          SongSectionPlan(
            id: 'verse-3',
            type: SongSectionType.verse,
            bars: 12,
            targetTension: 0.56,
            targetEnergy: 0.66,
            repetitionGroup: 'twelve-bar',
            variation: 2,
          ),
          SongSectionPlan(
            id: 'outro',
            type: SongSectionType.outro,
            bars: 4,
            targetTension: 0.18,
            targetEnergy: 0.30,
          ),
        ],
      );

  static SongPlan _country(int seed) => SongPlan(
        seed: seed,
        sections: const [
          SongSectionPlan(
            id: 'intro',
            type: SongSectionType.intro,
            bars: 4,
            targetTension: 0.18,
            targetEnergy: 0.30,
          ),
          SongSectionPlan(
            id: 'verse-1',
            type: SongSectionType.verse,
            bars: 8,
            targetTension: 0.34,
            targetEnergy: 0.42,
            repetitionGroup: 'verse',
          ),
          SongSectionPlan(
            id: 'chorus-1',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.64,
            targetEnergy: 0.76,
            repetitionGroup: 'chorus',
          ),
          SongSectionPlan(
            id: 'verse-2',
            type: SongSectionType.verse,
            bars: 8,
            targetTension: 0.38,
            targetEnergy: 0.48,
            repetitionGroup: 'verse',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'chorus-2',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.68,
            targetEnergy: 0.80,
            repetitionGroup: 'chorus',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'bridge',
            type: SongSectionType.bridge,
            bars: 8,
            targetTension: 0.54,
            targetEnergy: 0.58,
          ),
          SongSectionPlan(
            id: 'final-chorus',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.76,
            targetEnergy: 0.88,
            repetitionGroup: 'chorus',
            variation: 2,
          ),
          SongSectionPlan(
            id: 'outro',
            type: SongSectionType.outro,
            bars: 4,
            targetTension: 0.14,
            targetEnergy: 0.26,
          ),
        ],
      );

  static SongPlan _funk(int seed) => SongPlan(
        seed: seed,
        sections: const [
          SongSectionPlan(
            id: 'intro',
            type: SongSectionType.intro,
            bars: 4,
            targetTension: 0.20,
            targetEnergy: 0.42,
          ),
          SongSectionPlan(
            id: 'groove-a',
            type: SongSectionType.verse,
            bars: 8,
            targetTension: 0.38,
            targetEnergy: 0.64,
            repetitionGroup: 'groove',
          ),
          SongSectionPlan(
            id: 'hook-1',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.58,
            targetEnergy: 0.82,
            repetitionGroup: 'hook',
          ),
          SongSectionPlan(
            id: 'groove-a2',
            type: SongSectionType.verse,
            bars: 8,
            targetTension: 0.42,
            targetEnergy: 0.68,
            repetitionGroup: 'groove',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'breakdown',
            type: SongSectionType.bridge,
            bars: 4,
            targetTension: 0.28,
            targetEnergy: 0.38,
          ),
          SongSectionPlan(
            id: 'hook-2',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.62,
            targetEnergy: 0.86,
            repetitionGroup: 'hook',
            variation: 1,
          ),
          SongSectionPlan(
            id: 'instrumental',
            type: SongSectionType.bridge,
            bars: 8,
            targetTension: 0.52,
            targetEnergy: 0.72,
          ),
          SongSectionPlan(
            id: 'final-hook',
            type: SongSectionType.chorus,
            bars: 8,
            targetTension: 0.68,
            targetEnergy: 0.92,
            repetitionGroup: 'hook',
            variation: 2,
          ),
          SongSectionPlan(
            id: 'outro',
            type: SongSectionType.outro,
            bars: 4,
            targetTension: 0.16,
            targetEnergy: 0.34,
          ),
        ],
      );
}
