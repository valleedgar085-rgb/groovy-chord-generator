import 'dart:math';

import '../models/types.dart';
import '../utils/music_theory.dart';
import 'emotion_performance_shaper.dart';
import 'god_judge.dart';
import 'harmonic_realizer.dart';
import 'performance_profile.dart';
import 'phrase_composer.dart';
import 'producer_analysis.dart';
import 'producer_candidate_refiner.dart';
import 'seeded_music_generation.dart';
import 'song_architecture.dart';
import 'song_candidate.dart';
import 'song_draft.dart';
import 'song_quality_refiner.dart';
import 'song_request.dart';
import 'song_timeline.dart';
import 'song_timeline_builder.dart';

/// One complete Producer Brain interpretation of the current song.
///
/// Unlike the Phase 5.3 loop-level A/B/C candidates, this object owns a full
/// [SongDraft] plus the exact [SongTimeline] used for audition playback. Phase
/// 5.10 also attaches the final God Judge verdict that determines whether the
/// variation is ever allowed to reach the user-facing preview.
class ProducerSongVariation {
  ProducerSongVariation({
    required this.style,
    required this.draft,
    required this.timeline,
    required this.score,
    required this.baselineScore,
    required List<String> repairs,
    required this.changedSectionCount,
    required this.verdict,
  }) : repairs = List<String>.unmodifiable(repairs);

  final ProducerVariationStyle style;
  final SongDraft draft;
  final SongTimeline timeline;
  final double score;
  final double baselineScore;
  final List<String> repairs;
  final int changedSectionCount;
  final GodJudgeVerdict verdict;

  double get scoreDelta => score - baselineScore;
  double get finalQualityScore => verdict.score;
  bool get godApproved => verdict.approved;
}

class ProducerSongSelection {
  ProducerSongSelection({
    required List<ProducerSongVariation> evaluated,
    required List<ProducerSongVariation> visible,
  })  : evaluated = List<ProducerSongVariation>.unmodifiable(evaluated),
        visible = List<ProducerSongVariation>.unmodifiable(visible);

  factory ProducerSongSelection.empty() => ProducerSongSelection(
        evaluated: const <ProducerSongVariation>[],
        visible: const <ProducerSongVariation>[],
      );

  final List<ProducerSongVariation> evaluated;
  final List<ProducerSongVariation> visible;

  bool get satisfied =>
      visible.length == 3 && visible.every((item) => item.godApproved);
  int get approvedCount => evaluated.where((item) => item.godApproved).length;
  int get rejectedCount => evaluated.length - approvedCount;

  ProducerSongVariation? get bestEvaluated {
    if (evaluated.isEmpty) return null;
    return evaluated.reduce(
      (a, b) => a.finalQualityScore >= b.finalQualityScore ? a : b,
    );
  }

  List<String> get blockers {
    final result = <String>[];
    for (final variation in evaluated.where((item) => !item.godApproved)) {
      for (final blocker in variation.verdict.blockers.take(2)) {
        result.add('${variation.style.label}: $blocker');
      }
    }
    return List<String>.unmodifiable(result);
  }
}

/// Full-song Producer renderer plus Phase 5.10 final selection gate.
///
/// Four internal directions are evaluated: current/raw, Polished, Creative and
/// Hook. Before judging, every full-song direction is allowed the same proven
/// selective phrase-lineage cleanup. Exactly the best three are exposed only
/// when at least three pass the final God Judge. A weak direction can never be
/// shown merely to fill an A/B/C slot.
class ProducerSongVariationEngine {
  ProducerSongVariationEngine({
    ProducerCandidateRefiner? refiner,
    HarmonicRealizer? realizer,
    SeededMusicGeneration? generation,
    PhraseComposer? phraseComposer,
    ProducerAnalyzer? analyzer,
    SongTimelineBuilder? timelineBuilder,
    EmotionPerformanceShaper? emotionShaper,
    SongQualityRefiner? qualityRefiner,
    GodJudge? godJudge,
  })  : _refiner = refiner ?? const ProducerCandidateRefiner(),
        _realizer = realizer ?? const HarmonicRealizer(),
        _generation = generation ?? const SeededMusicGeneration(),
        _phraseComposer = phraseComposer ?? const PhraseComposer(),
        _analyzer = analyzer ?? ProducerAnalyzer(),
        _timelineBuilder = timelineBuilder ?? const SongTimelineBuilder(),
        _emotionShaper = emotionShaper ?? const EmotionPerformanceShaper(),
        _qualityRefiner = qualityRefiner ?? const SongQualityRefiner(),
        _godJudge = godJudge ?? const GodJudge();

  final ProducerCandidateRefiner _refiner;
  final HarmonicRealizer _realizer;
  final SeededMusicGeneration _generation;
  final PhraseComposer _phraseComposer;
  final ProducerAnalyzer _analyzer;
  final SongTimelineBuilder _timelineBuilder;
  final EmotionPerformanceShaper _emotionShaper;
  final SongQualityRefiner _qualityRefiner;
  final GodJudge _godJudge;

  ProducerSongSelection _lastSelection = ProducerSongSelection.empty();
  ProducerSongSelection get lastSelection => _lastSelection;

  List<ProducerSongVariation> build({
    required SongDraft baseDraft,
    required SongRequest request,
    required PerformanceProfile performanceProfile,
    required BassStyle bassStyle,
    required int bassVariety,
    required GrooveTemplate grooveTemplate,
    required int tempo,
    required double swing,
  }) {
    if (baseDraft.sections.isEmpty) {
      _lastSelection = ProducerSongSelection.empty();
      return const <ProducerSongVariation>[];
    }

    final judgedBase = request.includeMelody
        ? _qualityRefiner.refine(baseDraft)
        : baseDraft;
    final baselineScore = _draftScore(
      judgedBase,
      request: request,
      tempo: tempo,
      swing: swing,
      grooveTemplate: grooveTemplate,
    );
    final baselineTimeline = _timelineBuilder.build(
      judgedBase,
      performanceProfile: performanceProfile,
    );
    final baseline = ProducerSongVariation(
      style: ProducerVariationStyle.raw,
      draft: judgedBase,
      timeline: baselineTimeline,
      score: baselineScore,
      baselineScore: baselineScore,
      repairs: const <String>[],
      changedSectionCount: _changedSectionCount(baseDraft, judgedBase),
      verdict: _godJudge.evaluate(
        draft: judgedBase,
        request: request,
        timeline: baselineTimeline,
      ),
    );

    final evaluated = <ProducerSongVariation>[
      baseline,
      for (final style in const <ProducerVariationStyle>[
        ProducerVariationStyle.polished,
        ProducerVariationStyle.creative,
        ProducerVariationStyle.hook,
      ])
        _buildStyle(
          style: style,
          baseDraft: judgedBase,
          request: request,
          performanceProfile: performanceProfile,
          bassStyle: bassStyle,
          bassVariety: bassVariety,
          grooveTemplate: grooveTemplate,
          tempo: tempo,
          swing: swing,
          baselineScore: baselineScore,
        ),
    ];

    final approved = evaluated.where((item) => item.godApproved).toList()
      ..sort((a, b) {
        final byGod = b.finalQualityScore.compareTo(a.finalQualityScore);
        if (byGod != 0) return byGod;
        return b.score.compareTo(a.score);
      });

    final visible = approved.length >= 3
        ? List<ProducerSongVariation>.unmodifiable(approved.take(3))
        : const <ProducerSongVariation>[];
    _lastSelection = ProducerSongSelection(
      evaluated: evaluated,
      visible: visible,
    );
    return visible;
  }

  ProducerSongVariation _buildStyle({
    required ProducerVariationStyle style,
    required SongDraft baseDraft,
    required SongRequest request,
    required PerformanceProfile performanceProfile,
    required BassStyle bassStyle,
    required int bassVariety,
    required GrooveTemplate grooveTemplate,
    required int tempo,
    required double swing,
    required double baselineScore,
  }) {
    var variedDraft = SongDraft(plan: baseDraft.plan);
    final allRepairs = <String>[];
    var changedSections = 0;

    for (final section in baseDraft.sections) {
      final sectionSeed = baseDraft.plan.sectionSeed(section.plan.id);
      final sectionRequest = request.copyWith(
        seed: sectionSeed,
        section: section.plan.harmonySection,
      );
      final beforeAnalysis = _analyzer.analyze(
        progression: section.progression,
        melody: section.melody,
        bass: section.bass,
        genre: request.genre,
        rhythm: request.rhythm,
        section: section.plan.harmonySection,
        spice: request.spice,
        tempo: tempo,
        swing: swing,
        grooveTemplate: grooveTemplate,
      );
      final baseCandidate = SongCandidate(
        progression: section.progression,
        score: beforeAnalysis.overallScore,
        seed: section.candidate.seed,
        candidateIndex: section.candidate.candidateIndex,
        section: section.plan.harmonySection,
        producerAnalysis: beforeAnalysis,
      );
      final refinements = _refiner.evolve(
        base: baseCandidate,
        request: sectionRequest,
      );
      final refinement = refinements.firstWhere(
        (item) => item.style == style,
      );

      var progression = _realizer.repairProgression(
        refinement.progression,
        sectionRequest,
      );
      if (request.useVoiceLeading) {
        progression = applyVoiceLeading(progression);
      }
      progression = applyGrooveToProgression(progression, grooveTemplate);

      if (!_sameProgression(section.progression, progression)) {
        changedSections++;
      }

      final repetitionSource = _priorRepetitionReference(variedDraft, section.plan);
      final rawMelody = request.includeMelody
          ? _phraseComposer
              .compose(
                random: Random(sectionRequest.melodySeed),
                progression: progression,
                genre: request.genre,
                rhythm: request.rhythm,
                key: request.key,
                section: section.plan,
                sourceMelody:
                    repetitionSource?.melody ?? const <MelodyNote>[],
                sourceChordCount: repetitionSource?.progression.length ?? 0,
              )
              .melody
          : const <MelodyNote>[];
      final melody = request.includeMelody
          ? _emotionShaper.shapeMelody(
              melody: rawMelody,
              mood: request.mood,
              section: section.plan,
            )
          : const <MelodyNote>[];
      final rawBass = request.includeBass
          ? _generation.generateBass(
              random: Random(sectionRequest.bassSeed),
              progression: progression,
              style: bassStyle,
              variety: bassVariety,
              rhythm: request.rhythm,
            )
          : const <BassNote>[];
      final bass = request.includeBass
          ? _emotionShaper.shapeBass(
              bass: rawBass,
              mood: request.mood,
              section: section.plan,
            )
          : const <BassNote>[];
      final analysis = _analyzer.analyze(
        progression: progression,
        melody: melody,
        bass: bass,
        genre: request.genre,
        rhythm: request.rhythm,
        section: section.plan.harmonySection,
        spice: request.spice,
        tempo: tempo,
        swing: swing,
        grooveTemplate: grooveTemplate,
      );

      final candidate = SongCandidate(
        progression: progression,
        score: analysis.overallScore,
        seed: section.candidate.seed,
        candidateIndex: section.candidate.candidateIndex,
        section: section.plan.harmonySection,
        producerAnalysis: analysis,
        variationStyle: style,
        beforeRefineScore: beforeAnalysis.overallScore,
        repairs: refinement.repairs,
      );
      variedDraft = variedDraft.withSection(
        GeneratedSongSection(
          plan: section.plan,
          candidate: candidate,
          melody: melody,
          bass: bass,
          development: section.development,
        ),
      );

      for (final repair in refinement.repairs) {
        allRepairs.add('${section.plan.id}: $repair');
      }
    }

    final beforeQualityRefine = variedDraft;
    if (request.includeMelody) {
      variedDraft = _qualityRefiner.refine(variedDraft);
    }
    changedSections += _changedSectionCount(beforeQualityRefine, variedDraft);

    final score = _draftScore(
      variedDraft,
      request: request,
      tempo: tempo,
      swing: swing,
      grooveTemplate: grooveTemplate,
    );
    final timeline = _timelineBuilder.build(
      variedDraft,
      performanceProfile: performanceProfile,
    );
    final verdict = _godJudge.evaluate(
      draft: variedDraft,
      request: request,
      timeline: timeline,
    );

    return ProducerSongVariation(
      style: style,
      draft: variedDraft,
      timeline: timeline,
      score: score.clamp(0.0, 100.0).toDouble(),
      baselineScore: baselineScore,
      repairs: allRepairs,
      changedSectionCount: changedSections,
      verdict: verdict,
    );
  }

  GeneratedSongSection? _priorRepetitionReference(
    SongDraft draft,
    SongSectionPlan target,
  ) {
    final group = target.repetitionGroup;
    if (group == null || draft.sections.isEmpty) return null;
    final targetIndex =
        draft.plan.sections.indexWhere((section) => section.id == target.id);
    if (targetIndex <= 0) return null;

    for (var i = 0; i < targetIndex; i++) {
      final planSection = draft.plan.sections[i];
      if (planSection.repetitionGroup != group) continue;
      final generated = draft.sectionById(planSection.id);
      if (generated != null && generated.melody.isNotEmpty) return generated;
    }
    return null;
  }

  double _draftScore(
    SongDraft draft, {
    required SongRequest request,
    required int tempo,
    required double swing,
    required GrooveTemplate grooveTemplate,
  }) {
    if (draft.sections.isEmpty) return 0.0;
    var total = 0.0;
    for (final section in draft.sections) {
      total += _analyzer
          .analyze(
            progression: section.progression,
            melody: section.melody,
            bass: section.bass,
            genre: request.genre,
            rhythm: request.rhythm,
            section: section.plan.harmonySection,
            spice: request.spice,
            tempo: tempo,
            swing: swing,
            grooveTemplate: grooveTemplate,
          )
          .overallScore;
    }
    return total / draft.sections.length;
  }

  int _changedSectionCount(SongDraft before, SongDraft after) {
    var changed = 0;
    for (final section in before.sections) {
      final other = after.sectionById(section.plan.id);
      if (other == null ||
          _melodySignature(section.melody) != _melodySignature(other.melody) ||
          !_sameProgression(section.progression, other.progression)) {
        changed++;
      }
    }
    return changed;
  }

  String _melodySignature(List<MelodyNote> melody) => melody
      .map(
        (note) =>
            '${note.note}${note.octave}/${note.duration.toStringAsFixed(4)}/${note.velocity.toStringAsFixed(4)}/${note.chordIndex}',
      )
      .join('|');

  bool _sameProgression(List<Chord> a, List<Chord> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].root != b[i].root ||
          a[i].type != b[i].type ||
          a[i].degree != b[i].degree) {
        return false;
      }
    }
    return true;
  }
}
