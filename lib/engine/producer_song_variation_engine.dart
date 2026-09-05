import 'dart:math';

import '../models/types.dart';
import '../utils/music_theory.dart';
import 'harmonic_realizer.dart';
import 'performance_profile.dart';
import 'producer_analysis.dart';
import 'producer_candidate_refiner.dart';
import 'seeded_music_generation.dart';
import 'song_candidate.dart';
import 'song_draft.dart';
import 'song_request.dart';
import 'song_timeline.dart';
import 'song_timeline_builder.dart';

/// One complete Producer Brain interpretation of the current song.
///
/// Unlike the Phase 5.3 loop-level A/B/C candidates, this object owns a full
/// [SongDraft] plus the exact [SongTimeline] used for audition playback.
class ProducerSongVariation {
  ProducerSongVariation({
    required this.style,
    required this.draft,
    required this.timeline,
    required this.score,
    required this.baselineScore,
    required List<String> repairs,
    required this.changedSectionCount,
  }) : repairs = List<String>.unmodifiable(repairs);

  final ProducerVariationStyle style;
  final SongDraft draft;
  final SongTimeline timeline;
  final double score;
  final double baselineScore;
  final List<String> repairs;
  final int changedSectionCount;

  double get scoreDelta => score - baselineScore;
}

/// Phase 5.4 full-song Producer A/B/C renderer.
///
/// It deliberately starts from the already-generated canonical SongDraft. Each
/// section is diagnosed, transformed through the same Phase 5.2 Producer
/// refiner, repaired, then has deterministic melody/bass rebuilt against the
/// new harmony. The resulting draft is converted by the normal timeline builder
/// so preview playback uses exactly the same transport path as the active song.
class ProducerSongVariationEngine {
  ProducerSongVariationEngine({
    ProducerCandidateRefiner? refiner,
    HarmonicRealizer? realizer,
    SeededMusicGeneration? generation,
    ProducerAnalyzer? analyzer,
    SongTimelineBuilder? timelineBuilder,
  })  : _refiner = refiner ?? const ProducerCandidateRefiner(),
        _realizer = realizer ?? const HarmonicRealizer(),
        _generation = generation ?? const SeededMusicGeneration(),
        _analyzer = analyzer ?? ProducerAnalyzer(),
        _timelineBuilder = timelineBuilder ?? const SongTimelineBuilder();

  final ProducerCandidateRefiner _refiner;
  final HarmonicRealizer _realizer;
  final SeededMusicGeneration _generation;
  final ProducerAnalyzer _analyzer;
  final SongTimelineBuilder _timelineBuilder;

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
      return const <ProducerSongVariation>[];
    }

    final baselineScore = _draftScore(
      baseDraft,
      request: request,
      tempo: tempo,
      swing: swing,
      grooveTemplate: grooveTemplate,
    );

    return <ProducerSongVariation>[
      for (final style in const <ProducerVariationStyle>[
        ProducerVariationStyle.polished,
        ProducerVariationStyle.creative,
        ProducerVariationStyle.hook,
      ])
        _buildStyle(
          style: style,
          baseDraft: baseDraft,
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
    var scoreTotal = 0.0;
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

      final melody = request.includeMelody
          ? _generation.generateMelody(
              random: Random(sectionRequest.melodySeed),
              progression: progression,
              genre: request.genre,
              rhythm: request.rhythm,
              key: request.key,
            )
          : const <MelodyNote>[];
      final bass = request.includeBass
          ? _generation.generateBass(
              random: Random(sectionRequest.bassSeed),
              progression: progression,
              style: bassStyle,
              variety: bassVariety,
              rhythm: request.rhythm,
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
      scoreTotal += analysis.overallScore;

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

    final score = scoreTotal / max(1, variedDraft.sections.length);
    final timeline = _timelineBuilder.build(
      variedDraft,
      performanceProfile: performanceProfile,
    );

    return ProducerSongVariation(
      style: style,
      draft: variedDraft,
      timeline: timeline,
      score: score.clamp(0.0, 100.0).toDouble(),
      baselineScore: baselineScore,
      repairs: allRepairs,
      changedSectionCount: changedSections,
    );
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
