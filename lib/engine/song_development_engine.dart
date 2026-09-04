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
  /// draft. [sourceSectionId] can pin a known canonical source during dependency
  /// propagation so every dependent in the family derives from the same source
  /// even while earlier dependents are being replaced in the same pass.
  GeneratedSongSection developSection(
    SongDraft draft,
    String sectionId, {
    String? sourceSectionId,
  }) {
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
    final resolvedSourceId = sourceSectionId ?? targetMemory?.sourceSectionId;
    if (targetMemory == null ||
        resolvedSourceId == null ||
        resolvedSourceId == sectionId) {
      return target;
    }
    final source = draft.sectionById(resolvedSourceId);
    final sourceMemory = memory.section(resolvedSourceId);
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

  /// If [sourceSectionId] is the canonical source of a repetition family,
  /// re-derive all later A′ / A″ members from the new source. This keeps the
  /// dependency graph coherent when Verse 1 or Chorus 1 is regenerated.
  SongDraft redevelopDependents(
    SongDraft draft,
    String sourceSectionId,
  ) {
    final sourcePlan = draft.plan.sectionById(sourceSectionId);
    final group = sourcePlan?.repetitionGroup;
    if (sourcePlan == null || group == null || sourcePlan.variation > 0) {
      return draft;
    }

    final sourceIndex = draft.plan.sections.indexWhere(
      (section) => section.id == sourceSectionId,
    );
    if (sourceIndex < 0) return draft;

    var updated = draft;
    for (var index = sourceIndex + 1; index < draft.plan.sections.length; index++) {
      final candidatePlan = draft.plan.sections[index];
      if (candidatePlan.repetitionGroup != group || candidatePlan.variation <= 0) {
        continue;
      }
      if (updated.sectionById(candidatePlan.id) == null) continue;
      final transformed = developSection(
        updated,
        candidatePlan.id,
        sourceSectionId: sourceSectionId,
      );
      updated = updated.withSection(transformed);
    }
    return updated;
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
