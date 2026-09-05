import '../models/types.dart';
import '../utils/music_theory.dart';
import 'phrase_model.dart';
import 'song_architecture.dart';
import 'song_draft.dart';
import 'song_memory.dart';

/// Captures reusable musical identity from a generated SongDraft.
///
/// Phase 5.8A extends the original section-level memory with phrase-sized
/// fingerprints across the full section, explicit ancestry, similarity
/// guardrails and a song-level Musical DNA profile. Phase 5.8B aligns phrase
/// windows to harmonic/timeline position so composition and analysis agree on
/// the exact musical sentence boundaries.
class SongMemoryExtractor {
  const SongMemoryExtractor({
    this.motifNoteLimit = 8,
    this.phraseBars = 4,
  });

  final int motifNoteLimit;
  final int phraseBars;

  SongMemory capture(SongDraft draft) {
    final memories = <String, SectionMemory>{};
    final repetitionSources = <String, String>{};

    for (final section in draft.sections) {
      final group = section.plan.repetitionGroup;
      final sourceId = group == null
          ? section.plan.id
          : repetitionSources.putIfAbsent(group, () => section.plan.id);

      memories[section.plan.id] = SectionMemory(
        sectionId: section.plan.id,
        repetitionGroup: group,
        sourceSectionId: sourceId,
        harmony: _harmonicFingerprint(section),
        melody: _melodicMotif(section.melody),
        rhythm: _rhythmFingerprint(
          section.melody,
          section.progression.length,
        ),
        bass: _bassContour(section),
        phrases: _phraseFingerprints(section),
      );
    }

    final lineage = _buildPhraseLineage(draft, memories);
    final dna = _buildMusicalDna(
      draft,
      memories,
      repetitionSources,
    );

    return SongMemory(
      songSeed: draft.plan.seed,
      sections: memories,
      repetitionSources: repetitionSources,
      musicalDna: dna,
      phraseLineage: lineage,
    );
  }

  HarmonicFingerprint _harmonicFingerprint(GeneratedSongSection section) {
    final progression = section.progression;
    return HarmonicFingerprint(
      degreePattern: progression.map((chord) => chord.degree).toList(),
      functionPattern: progression.map(_functionOf).toList(),
      colorPattern: progression.map((chord) => chord.type).toList(),
      cadence: _cadenceOf(progression),
      sectionBars: section.plan.bars,
    );
  }

  MelodicMotif _melodicMotif(List<MelodyNote> melody) {
    final sample = melody.take(motifNoteLimit).toList(growable: false);
    final contour = <int>[];
    for (var i = 1; i < sample.length; i++) {
      final previous = _absolutePitch(sample[i - 1].note, sample[i - 1].octave);
      final current = _absolutePitch(sample[i].note, sample[i].octave);
      contour.add(_foldToNearestOctave(current - previous));
    }

    return MelodicMotif(
      intervalContour: contour,
      durationTicks: sample.map((note) => _durationTicks(note.duration)).toList(),
      accentBuckets: sample.map((note) => _accentBucket(note.velocity)).toList(),
    );
  }

  RhythmFingerprint _rhythmFingerprint(
    List<MelodyNote> melody,
    int chordCount,
  ) {
    final sample = melody.take(motifNoteLimit).toList(growable: false);
    return RhythmFingerprint(
      durationTicks: sample.map((note) => _durationTicks(note.duration)).toList(),
      accentBuckets: sample.map((note) => _accentBucket(note.velocity)).toList(),
      notesPerChord: chordCount == 0 ? 0.0 : melody.length / chordCount,
    );
  }

  List<PhraseFingerprint> _phraseFingerprints(GeneratedSongSection section) {
    final barsPerPhrase = phraseBars <= 0 ? 4 : phraseBars;
    final phraseCount =
        ((section.plan.bars + barsPerPhrase - 1) ~/ barsPerPhrase).clamp(1, 64);
    final melody = section.melody;
    final chordCount = section.progression.length;
    final buckets = List<List<MelodyNote>>.generate(
      phraseCount,
      (_) => <MelodyNote>[],
      growable: false,
    );

    // Timeline playback gives every harmony slot an equal share of the section
    // and then normalizes note durations inside that slot. Phrase memory must
    // therefore use harmonic position, not the raw sum of note.duration values.
    // This keeps Phrase Composer, Song Memory, playback and future repair on the
    // same exact sentence boundaries.
    if (melody.isNotEmpty) {
      for (final note in melody) {
        if (chordCount <= 0) {
          buckets.first.add(note);
          continue;
        }
        final safeChord = note.chordIndex.clamp(0, chordCount - 1).toInt();
        final normalized =
            ((safeChord + 0.5) / chordCount.toDouble()).clamp(0.0, 0.999999);
        final bucketIndex =
            (normalized * phraseCount).floor().clamp(0, phraseCount - 1).toInt();
        buckets[bucketIndex].add(note);
      }
    }

    final output = <PhraseFingerprint>[];
    for (var index = 0; index < phraseCount; index++) {
      final startBar = index * barsPerPhrase;
      final bars = (section.plan.bars - startBar).clamp(1, barsPerPhrase);
      output.add(
        _phraseFingerprint(
          section: section,
          notes: buckets[index],
          index: index,
          bars: bars,
          phraseCount: phraseCount,
        ),
      );
    }
    return output;
  }

  PhraseFingerprint _phraseFingerprint({
    required GeneratedSongSection section,
    required List<MelodyNote> notes,
    required int index,
    required int bars,
    required int phraseCount,
  }) {
    final absolute = notes
        .map((note) => _absolutePitch(note.note, note.octave))
        .toList(growable: false);
    final relative = <int>[];
    final contour = <int>[];
    if (absolute.isNotEmpty) {
      final origin = absolute.first;
      for (final pitch in absolute) {
        relative.add((pitch - origin).clamp(-36, 36).toInt());
      }
      for (var i = 1; i < absolute.length; i++) {
        contour.add(_foldToNearestOctave(absolute[i] - absolute[i - 1]));
      }
    }

    final chordPattern = <int>[];
    if (notes.isNotEmpty) {
      final originChord = notes.first.chordIndex;
      for (final note in notes) {
        chordPattern.add((note.chordIndex - originChord).clamp(-16, 16).toInt());
      }
    }

    var pitchRange = 0;
    var climaxPosition = 0.0;
    if (absolute.isNotEmpty) {
      var minimum = absolute.first;
      var maximum = absolute.first;
      var maximumIndex = 0;
      for (var i = 1; i < absolute.length; i++) {
        if (absolute[i] < minimum) minimum = absolute[i];
        if (absolute[i] > maximum) {
          maximum = absolute[i];
          maximumIndex = i;
        }
      }
      pitchRange = maximum - minimum;
      climaxPosition = absolute.length <= 1
          ? 0.0
          : maximumIndex / (absolute.length - 1).toDouble();
    }

    final averageVelocity = notes.isEmpty
        ? 0.0
        : notes.fold<double>(0.0, (sum, note) => sum + note.velocity) /
            notes.length;

    return PhraseFingerprint(
      id: '${section.plan.id}:p$index',
      sectionId: section.plan.id,
      index: index,
      bars: bars,
      role: _phraseRole(section.plan, index),
      cadenceIntent: _phraseCadenceIntent(
        section.plan,
        index,
        phraseCount,
      ),
      relativePitchPattern: relative,
      intervalContour: contour,
      durationTicks: notes.map((note) => _durationTicks(note.duration)).toList(),
      accentBuckets: notes.map((note) => _accentBucket(note.velocity)).toList(),
      chordIndexPattern: chordPattern,
      pitchRange: pitchRange,
      averageVelocity: averageVelocity.clamp(0.0, 1.0).toDouble(),
      noteDensity: notes.length / bars.toDouble(),
      climaxPosition: climaxPosition.clamp(0.0, 1.0).toDouble(),
    );
  }

  PhraseRole _phraseRole(SongSectionPlan plan, int index) {
    final id = plan.id.toLowerCase();
    if (id.contains('turnaround')) return PhraseRole.turnaround;
    if (id.contains('build')) return PhraseRole.lift;
    if (id.contains('drop') || id.contains('hook')) {
      return index.isEven ? PhraseRole.hook : PhraseRole.answer;
    }
    if (id.contains('breakdown') || id.contains('solo') || id.contains('bridge')) {
      return PhraseRole.contrast;
    }

    switch (plan.type) {
      case SongSectionType.intro:
        return PhraseRole.statement;
      case SongSectionType.verse:
        return index.isEven ? PhraseRole.question : PhraseRole.answer;
      case SongSectionType.preChorus:
        return PhraseRole.lift;
      case SongSectionType.chorus:
        return index.isEven ? PhraseRole.hook : PhraseRole.answer;
      case SongSectionType.bridge:
        return PhraseRole.contrast;
      case SongSectionType.outro:
        return PhraseRole.release;
    }
  }

  PhraseCadenceIntent _phraseCadenceIntent(
    SongSectionPlan plan,
    int index,
    int phraseCount,
  ) {
    if (index < phraseCount - 1) return PhraseCadenceIntent.open;
    switch (plan.type) {
      case SongSectionType.preChorus:
        return PhraseCadenceIntent.half;
      case SongSectionType.chorus:
      case SongSectionType.outro:
        return PhraseCadenceIntent.resolved;
      case SongSectionType.bridge:
        return PhraseCadenceIntent.suspended;
      case SongSectionType.intro:
      case SongSectionType.verse:
        return PhraseCadenceIntent.open;
    }
  }

  Map<String, PhraseLineageNode> _buildPhraseLineage(
    SongDraft draft,
    Map<String, SectionMemory> memories,
  ) {
    final lineage = <String, PhraseLineageNode>{};

    for (final section in draft.sections) {
      final memory = memories[section.plan.id];
      if (memory == null) continue;
      final canonical = memories[memory.sourceSectionId] ?? memory;

      for (final phrase in memory.phrases) {
        PhraseFingerprint sourcePhrase;
        PhraseRelationship relationship;

        if (memory.sourceSectionId != memory.sectionId &&
            canonical.phrases.isNotEmpty) {
          final sourceIndex = phrase.index.clamp(0, canonical.phrases.length - 1);
          sourcePhrase = canonical.phrases[sourceIndex];
          relationship = section.plan.variation >= 2
              ? PhraseRelationship.callback
              : PhraseRelationship.variation;
        } else if (phrase.index == 0 || memory.phrases.length == 1) {
          sourcePhrase = phrase;
          relationship = PhraseRelationship.source;
        } else if (phrase.role == PhraseRole.answer) {
          sourcePhrase = memory.phrases[phrase.index - 1];
          relationship = PhraseRelationship.response;
        } else {
          sourcePhrase = memory.phrases.first;
          relationship = phrase.role == PhraseRole.contrast
              ? PhraseRelationship.contrast
              : PhraseRelationship.variation;
        }

        final similarity = phrase.id == sourcePhrase.id
            ? 1.0
            : phrase.similarityTo(sourcePhrase);
        lineage[phrase.id] = PhraseLineageNode(
          phraseId: phrase.id,
          sourcePhraseId: sourcePhrase.id,
          relationship: relationship,
          sourceSimilarity: similarity,
          targetWindow: _similarityWindow(
            section.plan,
            relationship,
          ),
        );
      }
    }
    return lineage;
  }

  PhraseSimilarityWindow _similarityWindow(
    SongSectionPlan plan,
    PhraseRelationship relationship,
  ) {
    if (relationship == PhraseRelationship.source) {
      return const PhraseSimilarityWindow(
        minimum: 0.98,
        maximum: 1.0,
        label: 'canonical source',
      );
    }
    if (relationship == PhraseRelationship.response) {
      return const PhraseSimilarityWindow(
        minimum: 0.22,
        maximum: 0.82,
        label: 'related answer',
      );
    }
    if (relationship == PhraseRelationship.contrast) {
      return const PhraseSimilarityWindow(
        minimum: 0.12,
        maximum: 0.62,
        label: 'purposeful contrast',
      );
    }

    if (plan.type == SongSectionType.chorus) {
      if (plan.variation >= 2) {
        return const PhraseSimilarityWindow(
          minimum: 0.65,
          maximum: 0.90,
          label: 'recognizable final-hook evolution',
        );
      }
      return const PhraseSimilarityWindow(
        minimum: 0.72,
        maximum: 0.94,
        label: 'strong hook recall',
      );
    }
    if (plan.type == SongSectionType.verse) {
      if (plan.variation >= 2) {
        return const PhraseSimilarityWindow(
          minimum: 0.50,
          maximum: 0.80,
          label: 'developed verse callback',
        );
      }
      return const PhraseSimilarityWindow(
        minimum: 0.58,
        maximum: 0.84,
        label: 'familiar verse development',
      );
    }
    return const PhraseSimilarityWindow(
      minimum: 0.52,
      maximum: 0.88,
      label: 'controlled development',
    );
  }

  SongMusicalDna _buildMusicalDna(
    SongDraft draft,
    Map<String, SectionMemory> memories,
    Map<String, String> repetitionSources,
  ) {
    final candidates = <_PhraseCandidate>[];
    for (var sectionIndex = 0; sectionIndex < draft.sections.length; sectionIndex++) {
      final section = draft.sections[sectionIndex];
      final memory = memories[section.plan.id];
      if (memory == null) continue;
      for (final phrase in memory.phrases) {
        if (phrase.isEmpty) continue;
        candidates.add(
          _PhraseCandidate(
            section: section,
            phrase: phrase,
            score: _dnaCandidateScore(section, memory, phrase),
            sectionIndex: sectionIndex,
          ),
        );
      }
    }

    candidates.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      final section = a.sectionIndex.compareTo(b.sectionIndex);
      if (section != 0) return section;
      return a.phrase.index.compareTo(b.phrase.index);
    });

    final primary = candidates.isEmpty ? null : candidates.first;
    _PhraseCandidate? secondary;
    if (primary != null) {
      for (final candidate in candidates.skip(1)) {
        if (candidate.section.plan.id == primary.section.plan.id) continue;
        final similarity = candidate.phrase.similarityTo(primary.phrase);
        if (similarity >= 0.18 && similarity <= 0.88) {
          secondary = candidate;
          break;
        }
      }
      secondary ??= candidates.length > 1 ? candidates[1] : null;
    }

    _PhraseCandidate? hook;
    for (final candidate in candidates) {
      if (candidate.phrase.role == PhraseRole.hook) {
        hook = candidate;
        break;
      }
    }
    hook ??= primary;

    final signatureInterval =
        primary == null ? null : _signatureInterval(primary.phrase.intervalContour);
    final typicalBars = _typicalPhraseBars(candidates);
    final rhythm = primary == null
        ? RhythmCell(
            durationTicks: const <int>[],
            accentBuckets: const <int>[],
          )
        : RhythmCell(
            durationTicks: primary.phrase.durationTicks.take(4).toList(),
            accentBuckets: primary.phrase.accentBuckets.take(4).toList(),
          );

    var confidence = 0.0;
    if (primary != null) confidence += 0.35;
    if (repetitionSources.isNotEmpty) confidence += 0.20;
    if (hook?.phrase.role == PhraseRole.hook) confidence += 0.15;
    if ((primary?.phrase.noteCount ?? 0) >= 4) confidence += 0.10;
    if (secondary != null) confidence += 0.10;
    if (!rhythm.isEmpty && rhythm.durationTicks.length >= 3) confidence += 0.10;

    return SongMusicalDna(
      songSeed: draft.plan.seed,
      primaryPhraseId: primary?.phrase.id,
      secondaryPhraseId: secondary?.phrase.id,
      hookSectionId: hook?.section.plan.id,
      hookPhraseId: hook?.phrase.id,
      signatureInterval: signatureInterval,
      typicalPhraseBars: typicalBars,
      primaryRhythmCell: rhythm,
      melodicRange: primary?.phrase.pitchRange ?? 0,
      confidence: confidence.clamp(0.0, 1.0).toDouble(),
    );
  }

  double _dnaCandidateScore(
    GeneratedSongSection section,
    SectionMemory memory,
    PhraseFingerprint phrase,
  ) {
    var score = section.plan.targetEnergy * 30.0;
    if (section.plan.type == SongSectionType.chorus) score += 14.0;
    if (memory.repetitionGroup != null) score += 12.0;
    if (memory.sourceSectionId == memory.sectionId) score += 5.0;
    if (phrase.noteCount >= 4) score += 9.0;
    if (phrase.noteCount >= 4 && phrase.noteCount <= 16) score += 5.0;
    switch (phrase.role) {
      case PhraseRole.hook:
        score += 34.0;
        break;
      case PhraseRole.answer:
        score += 10.0;
        break;
      case PhraseRole.question:
        score += 8.0;
        break;
      case PhraseRole.statement:
        score += 7.0;
        break;
      case PhraseRole.lift:
        score += 6.0;
        break;
      case PhraseRole.contrast:
      case PhraseRole.release:
      case PhraseRole.turnaround:
        score += 4.0;
        break;
    }
    return score;
  }

  int? _signatureInterval(List<int> intervals) {
    final usable = intervals.where((interval) => interval != 0).toList();
    if (usable.isEmpty) return null;
    final counts = <int, int>{};
    for (final interval in usable) {
      counts[interval] = (counts[interval] ?? 0) + 1;
    }
    var winner = usable.first;
    var winnerCount = counts[winner] ?? 0;
    for (final interval in usable) {
      final count = counts[interval] ?? 0;
      if (count > winnerCount) {
        winner = interval;
        winnerCount = count;
      }
    }
    return winner;
  }

  int _typicalPhraseBars(List<_PhraseCandidate> candidates) {
    if (candidates.isEmpty) return phraseBars <= 0 ? 4 : phraseBars;
    final counts = <int, int>{};
    for (final candidate in candidates) {
      final bars = candidate.phrase.bars;
      counts[bars] = (counts[bars] ?? 0) + 1;
    }
    final ordered = counts.keys.toList()..sort();
    var winner = ordered.first;
    var winnerCount = counts[winner] ?? 0;
    for (final bars in ordered.skip(1)) {
      final count = counts[bars] ?? 0;
      if (count > winnerCount) {
        winner = bars;
        winnerCount = count;
      }
    }
    return winner;
  }

  BassContour _bassContour(GeneratedSongSection section) {
    final sample = section.bass.take(motifNoteLimit).toList(growable: false);
    final intervals = <int>[];
    for (var i = 1; i < sample.length; i++) {
      final previous = _absolutePitch(sample[i - 1].note, sample[i - 1].octave);
      final current = _absolutePitch(sample[i].note, sample[i].octave);
      intervals.add((current - previous).clamp(-12, 12).toInt());
    }

    final rootOffsets = <int>[];
    for (final note in sample) {
      if (note.chordIndex < 0 || note.chordIndex >= section.progression.length) {
        rootOffsets.add(0);
        continue;
      }
      final chord = section.progression[note.chordIndex];
      final notePitch = getNoteIndex(note.note);
      final rootPitch = getNoteIndex(chord.root);
      rootOffsets.add((notePitch - rootPitch) % 12);
    }

    return BassContour(
      intervalSteps: intervals,
      rootOffsets: rootOffsets,
    );
  }

  HarmonyFunction _functionOf(Chord chord) {
    if (chord.harmonyFunction != null) return chord.harmonyFunction!;
    final degree = chord.degree;

    if (_isPrimaryTonic(degree) ||
        degree == 'iii' ||
        degree == 'III' ||
        degree == 'vi' ||
        degree == 'VI') {
      return HarmonyFunction.tonic;
    }
    if (degree == 'ii' ||
        degree == 'II' ||
        degree == 'IV' ||
        degree == 'iv') {
      return HarmonyFunction.subdominant;
    }
    if (_isDominant(degree) || degree == 'vii' || degree == 'VII') {
      return HarmonyFunction.dominant;
    }
    return HarmonyFunction.passing;
  }

  CadenceIdentity _cadenceOf(List<Chord> progression) {
    if (progression.isEmpty) return CadenceIdentity.unresolved;
    final last = progression.last.degree;
    if (progression.length == 1) {
      return _isDominant(last) ? CadenceIdentity.half : CadenceIdentity.unresolved;
    }

    final previous = progression[progression.length - 2].degree;
    if (_isDominant(previous) && _isPrimaryTonic(last)) {
      return CadenceIdentity.authentic;
    }
    if (_isSubdominant(previous) && _isPrimaryTonic(last)) {
      return CadenceIdentity.plagal;
    }
    if (_isDominant(previous) && (last == 'vi' || last == 'VI')) {
      return CadenceIdentity.deceptive;
    }
    if (_isDominant(last)) return CadenceIdentity.half;
    return CadenceIdentity.unresolved;
  }

  bool _isPrimaryTonic(String degree) => degree == 'I' || degree == 'i';

  bool _isDominant(String degree) =>
      degree == 'V' ||
      degree == 'v' ||
      degree == 'V7' ||
      degree == 'V/V';

  bool _isSubdominant(String degree) =>
      degree == 'IV' ||
      degree == 'iv' ||
      degree == 'ii' ||
      degree == 'II';

  int _absolutePitch(String note, int octave) =>
      getNoteIndex(note) + octave * 12;

  int _foldToNearestOctave(int interval) {
    var folded = interval;
    while (folded > 6) {
      folded -= 12;
    }
    while (folded < -6) {
      folded += 12;
    }
    return folded;
  }

  int _durationTicks(double duration) =>
      (duration * 4).round().clamp(1, 64).toInt();

  int _accentBucket(double velocity) {
    if (velocity < 0.50) return 0;
    if (velocity < 0.78) return 1;
    return 2;
  }
}

class _PhraseCandidate {
  const _PhraseCandidate({
    required this.section,
    required this.phrase,
    required this.score,
    required this.sectionIndex,
  });

  final GeneratedSongSection section;
  final PhraseFingerprint phrase;
  final double score;
  final int sectionIndex;
}
