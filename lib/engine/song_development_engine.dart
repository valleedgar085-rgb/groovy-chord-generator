import 'song_draft.dart';
import 'song_memory_extractor.dart';
import 'section_variation_engine.dart';

/// Converts repeated arrangement sections into controlled developments of their
/// canonical source identity.
///
/// Song Architect still creates the raw, section-fit material. This pass then
/// applies Song Memory so Verse 2 / Chorus 2 / Final Chorus are recognizably
/// related A′ / A″ returns instead of independent rolls.
class SongDevelopmentEngine {
  SongDevelopmentEngine({
    SongMemoryExtractor? memoryExtractor,
    SectionVariationEngine? variationEngine,
  })  : _memoryExtractor = memoryExtractor ?? const SongMemoryExtractor(),
        _variationEngine = variationEngine ?? SectionVariationEngine();

  final SongMemoryExtractor _memoryExtractor;
  final SectionVariationEngine _variationEngine;

  SongDraft develop(SongDraft draft) {
    if (draft.sections.isEmpty) return draft;

    var developed = draft;
    final rawMemory = _memoryExtractor.capture(draft);

    for (final planSection in draft.plan.sections) {
      if (planSection.variation <= 0 || planSection.repetitionGroup == null) {
        continue;
      }

      final target = developed.sectionById(planSection.id);
      final targetMemory = rawMemory.section(planSection.id);
      if (target == null || targetMemory == null) continue;

      final sourceId = targetMemory.sourceSectionId;
      if (sourceId == planSection.id) continue;
      final source = developed.sectionById(sourceId);
      final sourceMemory = rawMemory.section(sourceId);
      if (source == null || sourceMemory == null) continue;

      final transformed = _variationEngine.transform(
        source: source,
        target: target,
        sourceMemory: sourceMemory,
        targetMemory: targetMemory,
        seed: _variationSeed(
          draft.plan.sectionSeed(planSection.id),
          planSection.variation,
        ),
        level: _levelFor(planSection.variation),
      );
      developed = developed.withSection(transformed);
    }

    return developed;
  }

  /// Applies development to exactly one section inside an already generated
  /// draft. Used after local regeneration so a regenerated Verse 2 still
  /// behaves as a Verse 1-derived A′ rather than losing its family identity.
  GeneratedSongSection developSection(
    SongDraft draft,
    String sectionId,
  ) {
    final target = draft.sectionById(sectionId);
    if (target == null) {
      throw ArgumentError.value(sectionId, 'sectionId', 'Unknown song section');
    }
    final planSection = target.plan;
    if (planSection.variation <= 0 || planSection.repetitionGroup == null) {
      return target;
    }

    final memory = _memoryExtractor.capture(draft);
    final targetMemory = memory.section(sectionId);
    if (targetMemory == null || targetMemory.sourceSectionId == sectionId) {
      return target;
    }
    final source = draft.sectionById(targetMemory.sourceSectionId);
    final sourceMemory = memory.section(targetMemory.sourceSectionId);
    if (source == null || sourceMemory == null) return target;

    return _variationEngine.transform(
      source: source,
      target: target,
      sourceMemory: sourceMemory,
      targetMemory: targetMemory,
      seed: _variationSeed(
        draft.plan.sectionSeed(sectionId) ^ target.candidate.seed,
        planSection.variation,
      ),
      level: _levelFor(planSection.variation),
    );
  }

  SectionVariationLevel _levelFor(int variation) {
    return variation >= 2
        ? SectionVariationLevel.aDoublePrime
        : SectionVariationLevel.aPrime;
  }

  int _variationSeed(int sectionSeed, int variation) {
    var value = (sectionSeed & 0x7fffffff) ^
        ((variation * 0x27d4eb2d) & 0x7fffffff);
    value = ((value ^ (value >> 15)) * 0x45d9f3b) & 0x7fffffff;
    return (value ^ (value >> 16)) & 0x7fffffff;
  }
}
