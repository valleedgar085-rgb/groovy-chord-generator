import '../models/types.dart';
import 'song_architecture.dart';
import 'song_candidate.dart';

/// One generated section retained inside a full-song draft.
class GeneratedSongSection {
  GeneratedSongSection({
    required this.plan,
    required this.candidate,
    List<MelodyNote> melody = const <MelodyNote>[],
    List<BassNote> bass = const <BassNote>[],
  })  : melody = List<MelodyNote>.unmodifiable(melody),
        bass = List<BassNote>.unmodifiable(bass);

  final SongSectionPlan plan;
  final SongCandidate candidate;
  final List<MelodyNote> melody;
  final List<BassNote> bass;

  List<Chord> get progression => candidate.progression;
}

/// Immutable, progressively-built song result.
///
/// Keeping completed sections lets later sections reason about actual previous
/// harmony and reuse earlier repetition groups rather than regenerating every
/// section from scratch.
class SongDraft {
  SongDraft({
    required this.plan,
    List<GeneratedSongSection> sections = const <GeneratedSongSection>[],
  }) : sections = List<GeneratedSongSection>.unmodifiable(sections) {
    final knownIds = plan.sections.map((section) => section.id).toSet();
    final ids = <String>{};
    for (final section in sections) {
      if (!knownIds.contains(section.plan.id)) {
        throw ArgumentError('Draft contains section outside its SongPlan');
      }
      if (!ids.add(section.plan.id)) {
        throw ArgumentError('Draft contains duplicate section id: ${section.plan.id}');
      }
    }
  }

  final SongPlan plan;
  final List<GeneratedSongSection> sections;

  GeneratedSongSection? sectionById(String id) {
    for (final section in sections) {
      if (section.plan.id == id) return section;
    }
    return null;
  }

  List<Chord> previousProgressionFor(String sectionId) {
    final previousPlan = plan.previousOf(sectionId);
    if (previousPlan == null) return const <Chord>[];
    return sectionById(previousPlan.id)?.progression ?? const <Chord>[];
  }

  /// Returns the earliest generated section in the same repetition group.
  /// Verse 2 / Chorus 2 can use this as their recognizable source identity.
  GeneratedSongSection? repetitionReferenceFor(String sectionId) {
    final target = plan.sectionById(sectionId);
    final group = target?.repetitionGroup;
    if (target == null || group == null) return null;

    for (final section in sections) {
      if (section.plan.repetitionGroup == group &&
          section.plan.id != sectionId) {
        return section;
      }
    }
    return null;
  }

  SongDraft withSection(GeneratedSongSection section) {
    final target = plan.sectionById(section.plan.id);
    if (target == null) {
      throw ArgumentError.value(
        section.plan.id,
        'section',
        'Section is not part of this SongPlan',
      );
    }

    final updated = sections
        .where((existing) => existing.plan.id != section.plan.id)
        .toList(growable: true)
      ..add(section);

    updated.sort((a, b) {
      final aIndex = plan.sections.indexWhere((item) => item.id == a.plan.id);
      final bIndex = plan.sections.indexWhere((item) => item.id == b.plan.id);
      return aIndex.compareTo(bIndex);
    });

    return SongDraft(plan: plan, sections: updated);
  }

  bool get isComplete => sections.length == plan.sections.length;

  double get averageHarmonyScore {
    if (sections.isEmpty) return 0.0;
    final total = sections.fold<double>(
      0.0,
      (sum, section) => sum + section.candidate.score,
    );
    return total / sections.length;
  }
}
