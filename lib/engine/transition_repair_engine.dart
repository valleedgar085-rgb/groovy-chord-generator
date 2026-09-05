import 'dart:math';

import '../models/types.dart';
import '../utils/music_theory.dart';
import 'song_candidate.dart';
import 'song_director.dart';
import 'song_draft.dart';

enum TransitionRepairStyle {
  dominantLift(
    'DOMINANT LIFT',
    'Turn the final harmony into a deliberate dominant arrival.',
  ),
  smoothHandoff(
    'SMOOTH HANDOFF',
    'Tighten melody and bass voice-leading across the section boundary.',
  ),
  bassApproach(
    'BASS APPROACH',
    'Lead the low end into the next section with a one- or two-semitone approach.',
  ),
  melodicPickup(
    'MELODY PICKUP',
    'Shape the outgoing melody as a pickup into the next section.',
  ),
  energyShape(
    'ENERGY SHAPE',
    'Create a clearer dynamic lift or release without rewriting the notes.',
  );

  const TransitionRepairStyle(this.label, this.description);

  final String label;
  final String description;

  String get id => switch (this) {
        TransitionRepairStyle.dominantLift => 'dominant-lift',
        TransitionRepairStyle.smoothHandoff => 'smooth-handoff',
        TransitionRepairStyle.bassApproach => 'bass-approach',
        TransitionRepairStyle.melodicPickup => 'melodic-pickup',
        TransitionRepairStyle.energyShape => 'energy-shape',
      };
}

class TransitionRepairVariant {
  TransitionRepairVariant({
    required this.style,
    required this.draft,
    required this.before,
    required this.after,
    required List<String> changedParts,
    required this.summary,
  }) : changedParts = List<String>.unmodifiable(changedParts);

  final TransitionRepairStyle style;
  final SongDraft draft;
  final SongTransitionAssessment before;
  final SongTransitionAssessment after;
  final List<String> changedParts;
  final String summary;

  String get fromSectionId => before.fromSectionId;
  String get toSectionId => before.toSectionId;
  double get scoreDelta => after.score - before.score;
  bool get improved => scoreDelta > 0.05;
}

/// Targeted Phase 5.6 transition repair.
///
/// The engine only changes material at the selected section boundary. Every
/// candidate is rescored through Song Director and candidates that make the
/// diagnosed handoff worse are discarded before they can reach the UI.
class TransitionRepairEngine {
  const TransitionRepairEngine({
    this.director = const SongDirectorAnalyzer(),
  });

  final SongDirectorAnalyzer director;

  List<TransitionRepairVariant> build({
    required SongDraft draft,
    required String fromSectionId,
    required String toSectionId,
  }) {
    final from = draft.sectionById(fromSectionId);
    final to = draft.sectionById(toSectionId);
    if (from == null || to == null) return const <TransitionRepairVariant>[];

    final next = draft.plan.nextOf(fromSectionId);
    if (next == null || next.id != toSectionId) {
      return const <TransitionRepairVariant>[];
    }

    final before = _assessment(draft, fromSectionId, toSectionId);
    if (before == null) return const <TransitionRepairVariant>[];

    final result = <TransitionRepairVariant>[];
    for (final style in TransitionRepairStyle.values) {
      final repaired = _apply(
        style,
        draft: draft,
        from: from,
        to: to,
      );
      if (_boundarySignature(repaired, fromSectionId, toSectionId) ==
          _boundarySignature(draft, fromSectionId, toSectionId)) {
        continue;
      }
      final after = _assessment(repaired, fromSectionId, toSectionId);
      if (after == null || after.score + 0.01 < before.score) continue;
      result.add(
        TransitionRepairVariant(
          style: style,
          draft: repaired,
          before: before,
          after: after,
          changedParts: _changedParts(style, from, to),
          summary: _summary(style, fromSectionId, toSectionId, before, after),
        ),
      );
    }

    result.sort((a, b) {
      final byScore = b.after.score.compareTo(a.after.score);
      if (byScore != 0) return byScore;
      final byDelta = b.scoreDelta.compareTo(a.scoreDelta);
      if (byDelta != 0) return byDelta;
      return a.style.index.compareTo(b.style.index);
    });
    return List<TransitionRepairVariant>.unmodifiable(result);
  }

  SongDraft _apply(
    TransitionRepairStyle style, {
    required SongDraft draft,
    required GeneratedSongSection from,
    required GeneratedSongSection to,
  }) {
    return switch (style) {
      TransitionRepairStyle.dominantLift => _dominantLift(draft, from, to),
      TransitionRepairStyle.smoothHandoff => _smoothHandoff(draft, from, to),
      TransitionRepairStyle.bassApproach => _bassApproach(draft, from, to),
      TransitionRepairStyle.melodicPickup => _melodicPickup(draft, from, to),
      TransitionRepairStyle.energyShape => _energyShape(draft, from, to),
    };
  }

  SongDraft _dominantLift(
    SongDraft draft,
    GeneratedSongSection from,
    GeneratedSongSection to,
  ) {
    if (from.progression.isEmpty || to.progression.isEmpty) return draft;
    final target = to.progression.first;
    final dominant = Chord(
      root: transposeNote(target.root, 7),
      type: ChordTypeName.dominant7,
      degree: 'V/${target.degree}',
      numeral: 'V7',
      isSecondaryDominant: true,
      harmonyFunction: HarmonyFunction.dominant,
    );
    final previousVoicing = from.progression.length > 1
        ? from.progression[from.progression.length - 2].voicedNotes
        : null;
    final voicedDominant = dominant.copyWith(
      voicedNotes: findBestVoicing(
        getChordNotes(dominant),
        previousVoicing,
        4,
      ),
    );
    final progression = List<Chord>.from(from.progression);
    progression[progression.length - 1] = voicedDominant;

    var melody = List<MelodyNote>.from(from.melody);
    if (melody.isNotEmpty) {
      final reference = to.melody.isNotEmpty
          ? noteToPitch(to.melody.first.note, to.melody.first.octave)
          : noteToPitch(melody.last.note, melody.last.octave);
      final pitch = _nearestPitch(
        getChordNotes(voicedDominant),
        reference,
        minPitch: 48,
        maxPitch: 88,
      );
      melody[melody.length - 1] = _melodyAtPitch(melody.last, pitch);
    }

    var bass = List<BassNote>.from(from.bass);
    if (bass.isNotEmpty) {
      final reference = noteToPitch(bass.last.note, bass.last.octave);
      final pitch = _nearestPitch(
        <String>[voicedDominant.root],
        reference,
        minPitch: 28,
        maxPitch: 60,
      );
      bass[bass.length - 1] = _bassAtPitch(bass.last, pitch);
    }

    return draft.withSection(
      _replaceSection(
        from,
        progression: progression,
        melody: melody,
        bass: bass,
        repair: 'Transition ${from.plan.id} → ${to.plan.id}: dominant lift',
      ),
    );
  }

  SongDraft _smoothHandoff(
    SongDraft draft,
    GeneratedSongSection from,
    GeneratedSongSection to,
  ) {
    if (to.progression.isEmpty) return draft;
    final targetNotes = getChordNotes(to.progression.first);
    var updated = draft;

    var fromMelody = List<MelodyNote>.from(from.melody);
    var toMelody = List<MelodyNote>.from(to.melody);
    if (fromMelody.isNotEmpty && toMelody.isNotEmpty) {
      final targetPitch = noteToPitch(toMelody.first.note, toMelody.first.octave);
      final fromPitch = _nearestPitch(
        targetNotes,
        targetPitch,
        minPitch: 48,
        maxPitch: 88,
      );
      fromMelody[fromMelody.length - 1] =
          _melodyAtPitch(fromMelody.last, fromPitch);
      final toPitch = _nearestPitch(
        targetNotes,
        fromPitch,
        minPitch: 48,
        maxPitch: 88,
      );
      toMelody[0] = _melodyAtPitch(toMelody.first, toPitch);
    }

    var fromBass = List<BassNote>.from(from.bass);
    var toBass = List<BassNote>.from(to.bass);
    if (fromBass.isNotEmpty && toBass.isNotEmpty) {
      final bassNotes = <String>[
        to.progression.first.root,
        transposeNote(to.progression.first.root, 7),
      ];
      final targetPitch = noteToPitch(toBass.first.note, toBass.first.octave);
      final fromPitch = _nearestPitch(
        bassNotes,
        targetPitch,
        minPitch: 28,
        maxPitch: 60,
      );
      fromBass[fromBass.length - 1] = _bassAtPitch(fromBass.last, fromPitch);
      final toPitch = _nearestPitch(
        bassNotes,
        fromPitch,
        minPitch: 28,
        maxPitch: 60,
      );
      toBass[0] = _bassAtPitch(toBass.first, toPitch);
    }

    updated = updated.withSection(
      _replaceSection(
        from,
        melody: fromMelody,
        bass: fromBass,
        repair: 'Transition ${from.plan.id} → ${to.plan.id}: smooth outgoing handoff',
      ),
    );
    updated = updated.withSection(
      _replaceSection(
        to,
        melody: toMelody,
        bass: toBass,
        repair: 'Transition ${from.plan.id} → ${to.plan.id}: smooth arrival handoff',
      ),
    );
    return updated;
  }

  SongDraft _bassApproach(
    SongDraft draft,
    GeneratedSongSection from,
    GeneratedSongSection to,
  ) {
    if (to.progression.isEmpty) return draft;
    final targetPitch = to.bass.isNotEmpty
        ? noteToPitch(to.bass.first.note, to.bass.first.octave)
        : _nearestPitch(
            <String>[to.progression.first.root],
            40,
            minPitch: 28,
            maxPitch: 60,
          );
    final bass = List<BassNote>.from(from.bass);
    final previousPitch = bass.length > 1
        ? noteToPitch(bass[bass.length - 2].note, bass[bass.length - 2].octave)
        : bass.isNotEmpty
            ? noteToPitch(bass.last.note, bass.last.octave)
            : targetPitch - 2;
    final approach = _bestApproachPitch(targetPitch, previousPitch);

    if (bass.isEmpty) {
      final note = pitchToNote(approach);
      bass.add(
        BassNote(
          note: note['note'] as String,
          octave: note['octave'] as int,
          duration: 0.5,
          velocity: 0.74,
          chordIndex: max(0, from.progression.length - 1),
          style: to.bass.isNotEmpty ? to.bass.first.style : BassStyle.root,
        ),
      );
    } else {
      bass[bass.length - 1] = _bassAtPitch(
        bass.last,
        approach,
        velocity: max(bass.last.velocity, 0.70),
      );
    }

    return draft.withSection(
      _replaceSection(
        from,
        bass: bass,
        repair: 'Transition ${from.plan.id} → ${to.plan.id}: bass approach',
      ),
    );
  }

  SongDraft _melodicPickup(
    SongDraft draft,
    GeneratedSongSection from,
    GeneratedSongSection to,
  ) {
    if (to.progression.isEmpty) return draft;
    final targetPitch = to.melody.isNotEmpty
        ? noteToPitch(to.melody.first.note, to.melody.first.octave)
        : _nearestPitch(
            getChordNotes(to.progression.first),
            64,
            minPitch: 48,
            maxPitch: 88,
          );
    final melody = List<MelodyNote>.from(from.melody);
    final previousPitch = melody.length > 1
        ? noteToPitch(
            melody[melody.length - 2].note,
            melody[melody.length - 2].octave,
          )
        : melody.isNotEmpty
            ? noteToPitch(melody.last.note, melody.last.octave)
            : targetPitch - 2;
    final pickup = _bestApproachPitch(targetPitch, previousPitch);

    if (melody.isEmpty) {
      final note = pitchToNote(pickup);
      melody.add(
        MelodyNote(
          note: note['note'] as String,
          octave: note['octave'] as int,
          duration: 0.5,
          velocity: 0.78,
          chordIndex: max(0, from.progression.length - 1),
        ),
      );
    } else {
      melody[melody.length - 1] = _melodyAtPitch(
        melody.last,
        pickup,
        velocity: max(melody.last.velocity, 0.74),
      );
    }

    return draft.withSection(
      _replaceSection(
        from,
        melody: melody,
        repair: 'Transition ${from.plan.id} → ${to.plan.id}: melodic pickup',
      ),
    );
  }

  SongDraft _energyShape(
    SongDraft draft,
    GeneratedSongSection from,
    GeneratedSongSection to,
  ) {
    final targetDelta = to.plan.targetEnergy - from.plan.targetEnergy;
    final bool lifting = targetDelta > 0.04;
    final bool releasing = targetDelta < -0.04;
    final fromShift = lifting
        ? -0.04
        : releasing
            ? 0.05
            : 0.0;
    final toShift = lifting
        ? 0.10
        : releasing
            ? -0.10
            : 0.0;
    if (fromShift == 0.0 && toShift == 0.0) return draft;

    final fromMelody = _shiftMelodyVelocity(from.melody, fromShift);
    final fromBass = _shiftBassVelocity(from.bass, fromShift);
    final toMelody = _shiftMelodyVelocity(to.melody, toShift);
    final toBass = _shiftBassVelocity(to.bass, toShift);

    var updated = draft.withSection(
      _replaceSection(
        from,
        melody: fromMelody,
        bass: fromBass,
        repair: 'Transition ${from.plan.id} → ${to.plan.id}: outgoing energy shape',
      ),
    );
    updated = updated.withSection(
      _replaceSection(
        to,
        melody: toMelody,
        bass: toBass,
        repair: 'Transition ${from.plan.id} → ${to.plan.id}: arrival energy shape',
      ),
    );
    return updated;
  }

  GeneratedSongSection _replaceSection(
    GeneratedSongSection section, {
    List<Chord>? progression,
    List<MelodyNote>? melody,
    List<BassNote>? bass,
    required String repair,
  }) {
    final candidate = SongCandidate(
      progression: progression ?? section.progression,
      score: section.candidate.score,
      seed: section.candidate.seed,
      candidateIndex: section.candidate.candidateIndex,
      section: section.candidate.section,
      producerAnalysis: section.candidate.producerAnalysis,
      variationStyle: section.candidate.variationStyle,
      beforeRefineScore: section.candidate.beforeRefineScore,
      repairs: <String>[...section.candidate.repairs, repair],
    );
    return GeneratedSongSection(
      plan: section.plan,
      candidate: candidate,
      melody: melody ?? section.melody,
      bass: bass ?? section.bass,
      development: section.development,
    );
  }

  SongTransitionAssessment? _assessment(
    SongDraft draft,
    String fromSectionId,
    String toSectionId,
  ) {
    final analysis = director.analyze(draft: draft);
    for (final transition in analysis.transitions) {
      if (transition.fromSectionId == fromSectionId &&
          transition.toSectionId == toSectionId) {
        return transition;
      }
    }
    return null;
  }

  List<String> _changedParts(
    TransitionRepairStyle style,
    GeneratedSongSection from,
    GeneratedSongSection to,
  ) {
    return switch (style) {
      TransitionRepairStyle.dominantLift => <String>[
          'outgoing harmony',
          if (from.bass.isNotEmpty) 'outgoing bass',
          if (from.melody.isNotEmpty) 'outgoing melody',
        ],
      TransitionRepairStyle.smoothHandoff => <String>[
          if (from.bass.isNotEmpty && to.bass.isNotEmpty) 'bass handoff',
          if (from.melody.isNotEmpty && to.melody.isNotEmpty) 'melody handoff',
        ],
      TransitionRepairStyle.bassApproach => const <String>['outgoing bass'],
      TransitionRepairStyle.melodicPickup => const <String>['outgoing melody'],
      TransitionRepairStyle.energyShape =>
        const <String>['outgoing dynamics', 'arrival dynamics'],
    };
  }

  String _summary(
    TransitionRepairStyle style,
    String from,
    String to,
    SongTransitionAssessment before,
    SongTransitionAssessment after,
  ) {
    final delta = after.score - before.score;
    return '${style.description} $from → $to ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} Director points.';
  }

  String _boundarySignature(
    SongDraft draft,
    String fromSectionId,
    String toSectionId,
  ) {
    final from = draft.sectionById(fromSectionId);
    final to = draft.sectionById(toSectionId);
    if (from == null || to == null) return '';
    String chord(Chord item) => '${item.root}:${item.type.index}:${item.degree}';
    String melody(MelodyNote item) =>
        '${item.note}${item.octave}:${item.velocity.toStringAsFixed(3)}:${item.chordIndex}';
    String bass(BassNote item) =>
        '${item.note}${item.octave}:${item.velocity.toStringAsFixed(3)}:${item.chordIndex}';
    return <String>[
      from.progression.isEmpty ? '-' : chord(from.progression.last),
      to.progression.isEmpty ? '-' : chord(to.progression.first),
      from.melody.isEmpty ? '-' : melody(from.melody.last),
      to.melody.isEmpty ? '-' : melody(to.melody.first),
      from.bass.isEmpty ? '-' : bass(from.bass.last),
      to.bass.isEmpty ? '-' : bass(to.bass.first),
    ].join('|');
  }

  int _nearestPitch(
    List<String> noteNames,
    int reference, {
    required int minPitch,
    required int maxPitch,
  }) {
    var bestPitch = reference.clamp(minPitch, maxPitch).toInt();
    var bestDistance = 9999;
    for (final noteName in noteNames) {
      for (var octave = -1; octave <= 8; octave++) {
        final pitch = noteToPitch(noteName, octave);
        if (pitch < minPitch || pitch > maxPitch) continue;
        final distance = (pitch - reference).abs();
        if (distance < bestDistance) {
          bestDistance = distance;
          bestPitch = pitch;
        }
      }
    }
    return bestPitch;
  }

  int _bestApproachPitch(int targetPitch, int previousPitch) {
    final candidates = <int>[
      targetPitch - 1,
      targetPitch + 1,
      targetPitch - 2,
      targetPitch + 2,
    ];
    candidates.sort((a, b) {
      final aDistance = (a - previousPitch).abs();
      final bDistance = (b - previousPitch).abs();
      if (aDistance != bDistance) return aDistance.compareTo(bDistance);
      return (a - targetPitch).abs().compareTo((b - targetPitch).abs());
    });
    return candidates.first;
  }

  MelodyNote _melodyAtPitch(
    MelodyNote source,
    int pitch, {
    double? velocity,
  }) {
    final note = pitchToNote(pitch);
    return MelodyNote(
      note: note['note'] as String,
      octave: note['octave'] as int,
      duration: source.duration,
      velocity: (velocity ?? source.velocity).clamp(0.0, 1.0).toDouble(),
      chordIndex: source.chordIndex,
    );
  }

  BassNote _bassAtPitch(
    BassNote source,
    int pitch, {
    double? velocity,
  }) {
    final note = pitchToNote(pitch);
    return BassNote(
      note: note['note'] as String,
      octave: note['octave'] as int,
      duration: source.duration,
      velocity: (velocity ?? source.velocity).clamp(0.0, 1.0).toDouble(),
      chordIndex: source.chordIndex,
      style: source.style,
    );
  }

  List<MelodyNote> _shiftMelodyVelocity(
    List<MelodyNote> notes,
    double shift,
  ) {
    return notes
        .map(
          (note) => MelodyNote(
            note: note.note,
            duration: note.duration,
            velocity: (note.velocity + shift).clamp(0.0, 1.0).toDouble(),
            chordIndex: note.chordIndex,
            octave: note.octave,
          ),
        )
        .toList(growable: false);
  }

  List<BassNote> _shiftBassVelocity(
    List<BassNote> notes,
    double shift,
  ) {
    return notes
        .map(
          (note) => BassNote(
            note: note.note,
            duration: note.duration,
            velocity: (note.velocity + shift).clamp(0.0, 1.0).toDouble(),
            octave: note.octave,
            chordIndex: note.chordIndex,
            style: note.style,
          ),
        )
        .toList(growable: false);
  }
}