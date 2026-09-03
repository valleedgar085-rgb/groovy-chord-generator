import 'harmony_engine.dart';

/// Arrangement-level section identity. This is intentionally broader than
/// [HarmonySection], which describes only harmonic scoring intent.
enum SongSectionType {
  intro,
  verse,
  preChorus,
  chorus,
  bridge,
  outro,
}

/// One immutable section target inside a song plan.
///
/// Tension and energy are normalized to 0..1 so later melody, bass, rhythm,
/// dynamics, and harmony engines can all consume the same arrangement intent.
class SongSectionPlan {
  const SongSectionPlan({
    required this.id,
    required this.type,
    required this.bars,
    required this.targetTension,
    required this.targetEnergy,
    this.repetitionGroup,
    this.variation = 0,
  })  : assert(bars > 0),
        assert(targetTension >= 0 && targetTension <= 1),
        assert(targetEnergy >= 0 && targetEnergy <= 1),
        assert(variation >= 0);

  final String id;
  final SongSectionType type;
  final int bars;
  final double targetTension;
  final double targetEnergy;

  /// Sections sharing a group should retain recognizable musical identity.
  /// Example: verse1 and verse2 can both use `verse-a` while variation tells
  /// the future motif engine how far the repeat may evolve.
  final String? repetitionGroup;
  final int variation;

  HarmonySection get harmonySection {
    switch (type) {
      case SongSectionType.verse:
        return HarmonySection.verse;
      case SongSectionType.preChorus:
        return HarmonySection.preChorus;
      case SongSectionType.chorus:
        return HarmonySection.chorus;
      case SongSectionType.bridge:
        return HarmonySection.bridge;
      case SongSectionType.intro:
      case SongSectionType.outro:
        return HarmonySection.neutral;
    }
  }
}

/// Immutable arrangement blueprint consumed by the future Song Architect.
class SongPlan {
  SongPlan({
    required this.seed,
    required List<SongSectionPlan> sections,
  }) : sections = List<SongSectionPlan>.unmodifiable(sections) {
    if (sections.isEmpty) {
      throw ArgumentError.value(sections, 'sections', 'SongPlan cannot be empty');
    }
    final ids = sections.map((section) => section.id).toSet();
    if (ids.length != sections.length) {
      throw ArgumentError.value(sections, 'sections', 'Section ids must be unique');
    }
  }

  final int seed;
  final List<SongSectionPlan> sections;

  SongSectionPlan? sectionById(String id) {
    for (final section in sections) {
      if (section.id == id) return section;
    }
    return null;
  }

  SongSectionPlan? previousOf(String id) {
    final index = sections.indexWhere((section) => section.id == id);
    return index > 0 ? sections[index - 1] : null;
  }

  SongSectionPlan? nextOf(String id) {
    final index = sections.indexWhere((section) => section.id == id);
    return index >= 0 && index + 1 < sections.length
        ? sections[index + 1]
        : null;
  }

  /// Stable section seed gives every part its own reproducible random stream.
  int sectionSeed(String id) {
    final index = sections.indexWhere((section) => section.id == id);
    if (index < 0) throw ArgumentError.value(id, 'id', 'Unknown section');
    var value = (seed & 0x7fffffff) ^ ((index + 101) * 0x45d9f3b);
    value = ((value ^ (value >> 16)) * 0x45d9f3b) & 0x7fffffff;
    value = (value ^ (value >> 16)) & 0x7fffffff;
    return value;
  }

  /// General-purpose modern song arc. Genre-specific templates can layer on
  /// top later without changing the core data contract.
  factory SongPlan.standard({required int seed}) {
    return SongPlan(
      seed: seed,
      sections: const [
        SongSectionPlan(
          id: 'intro',
          type: SongSectionType.intro,
          bars: 4,
          targetTension: 0.20,
          targetEnergy: 0.25,
        ),
        SongSectionPlan(
          id: 'verse-1',
          type: SongSectionType.verse,
          bars: 8,
          targetTension: 0.35,
          targetEnergy: 0.42,
          repetitionGroup: 'verse-a',
        ),
        SongSectionPlan(
          id: 'pre-1',
          type: SongSectionType.preChorus,
          bars: 4,
          targetTension: 0.68,
          targetEnergy: 0.68,
          repetitionGroup: 'pre-a',
        ),
        SongSectionPlan(
          id: 'chorus-1',
          type: SongSectionType.chorus,
          bars: 8,
          targetTension: 0.88,
          targetEnergy: 0.92,
          repetitionGroup: 'chorus-a',
        ),
        SongSectionPlan(
          id: 'verse-2',
          type: SongSectionType.verse,
          bars: 8,
          targetTension: 0.44,
          targetEnergy: 0.52,
          repetitionGroup: 'verse-a',
          variation: 1,
        ),
        SongSectionPlan(
          id: 'pre-2',
          type: SongSectionType.preChorus,
          bars: 4,
          targetTension: 0.72,
          targetEnergy: 0.74,
          repetitionGroup: 'pre-a',
          variation: 1,
        ),
        SongSectionPlan(
          id: 'chorus-2',
          type: SongSectionType.chorus,
          bars: 8,
          targetTension: 0.91,
          targetEnergy: 0.96,
          repetitionGroup: 'chorus-a',
          variation: 1,
        ),
        SongSectionPlan(
          id: 'bridge',
          type: SongSectionType.bridge,
          bars: 8,
          targetTension: 0.70,
          targetEnergy: 0.66,
        ),
        SongSectionPlan(
          id: 'final-chorus',
          type: SongSectionType.chorus,
          bars: 8,
          targetTension: 0.96,
          targetEnergy: 1.0,
          repetitionGroup: 'chorus-a',
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
  }
}
