import 'motif_transformation_engine.dart';

/// Musical identity of a generated section inside its repetition family.
enum SectionDevelopmentIdentity { original, aPrime, aDoublePrime }

extension SectionDevelopmentIdentityX on SectionDevelopmentIdentity {
  String get label {
    switch (this) {
      case SectionDevelopmentIdentity.original:
        return 'A';
      case SectionDevelopmentIdentity.aPrime:
        return 'A′';
      case SectionDevelopmentIdentity.aDoublePrime:
        return 'A″';
    }
  }
}

/// Immutable development metadata retained with a generated song section.
///
/// This records what the engine actually did so replay/export/UI can report the
/// section's musical lineage without guessing from a section id or variation
/// number.
class SectionDevelopmentMetadata {
  SectionDevelopmentMetadata({
    required this.identity,
    required this.sourceSectionId,
    List<MotifOperation> operations = const <MotifOperation>[],
  }) : operations = List<MotifOperation>.unmodifiable(operations);

  factory SectionDevelopmentMetadata.original(String sectionId) {
    return SectionDevelopmentMetadata(
      identity: SectionDevelopmentIdentity.original,
      sourceSectionId: sectionId,
    );
  }

  final SectionDevelopmentIdentity identity;
  final String sourceSectionId;
  final List<MotifOperation> operations;

  bool get isDeveloped => identity != SectionDevelopmentIdentity.original;
}
