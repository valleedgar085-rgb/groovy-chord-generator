import 'dart:math';

import '../models/constants.dart';
import '../models/types.dart';
import 'harmonic_realizer.dart';
import 'harmony_engine.dart';
import 'producer_analysis.dart';
import 'producer_brain_telemetry.dart';
import 'producer_candidate_refiner.dart';
import 'seeded_music_generation.dart';
import 'song_candidate.dart';
import 'song_request.dart';

/// Builds several musical candidates and lets Producer Brain keep the best.
class HarmonyCandidatePool {
  HarmonyCandidatePool({
    HarmonyEngine? engine,
    HarmonicRealizer? realizer,
    SeededMusicGeneration? generation,
    ProducerAnalyzer? analyzer,
    ProducerCandidateRefiner? refiner,
  })  : _engine = engine ?? HarmonyEngine(),
        _realizer = realizer ?? const HarmonicRealizer(),
        _generation = generation ?? const SeededMusicGeneration(),
        _analyzer = analyzer ?? ProducerAnalyzer(harmonyEngine: engine),
        _refiner = refiner ?? const ProducerCandidateRefiner();

  final HarmonyEngine _engine;
  final HarmonicRealizer _realizer;
  final SeededMusicGeneration _generation;
  final ProducerAnalyzer _analyzer;
  final ProducerCandidateRefiner _refiner;

  List<Chord> generateBest({
    required List<Chord> Function() buildCandidate,
    int candidateCount = 8,
    HarmonySection section = HarmonySection.neutral,
    bool applyVoicing = true,
  }) {
    final count = candidateCount.clamp(1, 32).toInt();
    final candidates = List<List<Chord>>.generate(
      count,
      (_) => List<Chord>.from(buildCandidate()),
      growable: false,
    ).where((candidate) => candidate.length >= 2).toList(growable: false);

    if (candidates.isEmpty) return const <Chord>[];
    return _engine.selectBest(
      candidates,
      section: section,
      applyVoicing: applyVoicing,
    );
  }

  List<ScoredHarmonyCandidate> generateScored({
    required List<Chord> Function() buildCandidate,
    int candidateCount = 8,
    HarmonySection section = HarmonySection.neutral,
  }) {
    final count = candidateCount.clamp(1, 32).toInt();
    final scored = <ScoredHarmonyCandidate>[];
    for (var i = 0; i < count; i++) {
      final candidate = List<Chord>.from(buildCandidate());
      if (candidate.length < 2) continue;
      scored.add(ScoredHarmonyCandidate(
        progression: List<Chord>.unmodifiable(candidate),
        score: _engine.score(candidate, section: section),
      ));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return List<ScoredHarmonyCandidate>.unmodifiable(scored);
  }

  List<SongCandidate> generateScoredDeterministic({
    required SongRequest request,
    required List<Chord> Function(int candidateSeed) buildCandidate,
  }) {
    final scored = <SongCandidate>[];
    for (var i = 0; i < request.candidateCount; i++) {
      final candidateSeed = request.candidateSeed(i);
      final raw = List<Chord>.from(buildCandidate(candidateSeed));
      final progression = _realizer.repairProgression(raw, request);
      if (progression.length < 2) continue;
      scored.add(SongCandidate(
        progression: progression,
        score: _engine.score(progression, section: request.section),
        seed: candidateSeed,
        candidateIndex: i,
        section: request.section,
      ));
    }
    scored.sort(_compareCandidates);
    return List<SongCandidate>.unmodifiable(scored);
  }

  /// Phase 5.1 raw multidimensional pass across all requested candidates.
  List<SongCandidate> generateScoredMusicalForRequest({
    required SongRequest request,
    required List<Chord> Function(int candidateSeed, int candidateIndex)
        buildCandidate,
  }) {
    final candidates = <SongCandidate>[];
    for (var i = 0; i < request.candidateCount; i++) {
      final candidateSeed = request.candidateSeed(i);
      final raw = List<Chord>.from(buildCandidate(candidateSeed, i));
      final progression = _realizer.repairProgression(raw, request);
      if (progression.length < 2) continue;
      final analysis = _analyzeCandidate(progression, request);
      candidates.add(SongCandidate(
        progression: progression,
        score: analysis.overallScore,
        seed: candidateSeed,
        candidateIndex: i,
        section: request.section,
        producerAnalysis: analysis,
      ));
    }
    candidates.sort(_compareCandidates);
    return List<SongCandidate>.unmodifiable(candidates);
  }

  /// Phase 5.2 closed-loop pass.
  ///
  /// The top three raw candidates are each evolved into Polished, Creative and
  /// Hook-focused revisions. Every revision is repaired, regenerated through the
  /// deterministic melody/bass preview, then rescored. Revisions that regress
  /// the base candidate are discarded before final ranking.
  List<SongCandidate> generateRefinedMusicalForRequest({
    required SongRequest request,
    required List<Chord> Function(int candidateSeed, int candidateIndex)
        buildCandidate,
  }) {
    final raw = generateScoredMusicalForRequest(
      request: request,
      buildCandidate: buildCandidate,
    );
    if (raw.isEmpty) return raw;

    final contenders = <SongCandidate>[...raw];
    final topCount = min(3, raw.length);
    for (var i = 0; i < topCount; i++) {
      final base = raw[i];
      final refinements = _refiner.evolve(base: base, request: request);
      for (final refinement in refinements) {
        final repaired = _realizer.repairProgression(
          refinement.progression,
          request,
        );
        if (repaired.length < 2) continue;
        final analysis = _analyzeCandidate(repaired, request);
        if (analysis.overallScore + 0.01 < base.score) continue;
        contenders.add(SongCandidate(
          progression: repaired,
          score: analysis.overallScore,
          seed: base.seed,
          candidateIndex: base.candidateIndex,
          section: base.section,
          producerAnalysis: analysis,
          variationStyle: refinement.style,
          beforeRefineScore: base.score,
          repairs: refinement.repairs,
        ));
      }
    }

    contenders.sort(_compareCandidates);
    return List<SongCandidate>.unmodifiable(contenders);
  }

  SongCandidate? generateBestDeterministic({
    required SongRequest request,
    required List<Chord> Function(int candidateSeed) buildCandidate,
  }) {
    final candidates = generateScoredDeterministic(
      request: request,
      buildCandidate: buildCandidate,
    );
    if (candidates.isEmpty) return null;
    final best = candidates.first;
    final progression = request.useVoiceLeading
        ? _engine.selectBest(
            [best.progression],
            section: request.section,
            applyVoicing: true,
          )
        : List<Chord>.from(best.progression);
    return SongCandidate(
      progression: progression,
      score: best.score,
      seed: best.seed,
      candidateIndex: best.candidateIndex,
      section: best.section,
      producerAnalysis: best.producerAnalysis,
    );
  }

  SongCandidate generateBestForRequest({
    required SongRequest request,
    required List<Chord> Function(int candidateSeed, int candidateIndex)
        buildCandidate,
  }) {
    final candidates = generateRefinedMusicalForRequest(
      request: request,
      buildCandidate: buildCandidate,
    );
    ProducerBrainTelemetry.instance.publish(candidates);

    if (candidates.isNotEmpty) return candidates.first;
    return SongCandidate(
      progression: const <Chord>[],
      score: 0.0,
      seed: request.seed,
      candidateIndex: -1,
      section: request.section,
      producerAnalysis: ProducerAnalysis.empty(),
    );
  }

  ProducerAnalysis _analyzeCandidate(
    List<Chord> progression,
    SongRequest request,
  ) {
    final melody = request.includeMelody
        ? _generation.generateMelody(
            random: Random(request.melodySeed),
            progression: progression,
            genre: request.genre,
            rhythm: request.rhythm,
            key: request.key,
          )
        : const <MelodyNote>[];

    final bass = request.includeBass
        ? _generation.generateBass(
            random: Random(request.bassSeed),
            progression: progression,
            style: _proxyBassStyle(request.genre),
            variety: request.chordVariety.clamp(35, 75).toInt(),
            rhythm: request.rhythm,
          )
        : const <BassNote>[];

    final profile = genreProfiles[request.genre];
    return _analyzer.analyze(
      progression: progression,
      melody: melody,
      bass: bass,
      genre: request.genre,
      rhythm: request.rhythm,
      section: request.section,
      spice: request.spice,
      tempo: profile?.tempo ?? 120,
      swing: _proxySwing(request.genre),
      grooveTemplate: _proxyGroove(request.genre),
    );
  }

  BassStyle _proxyBassStyle(GenreKey genre) => switch (genre) {
        GenreKey.jazzFusion || GenreKey.blues => BassStyle.walking,
        GenreKey.funk || GenreKey.reggae || GenreKey.soulfulRnb =>
          BassStyle.syncopated,
        GenreKey.country => BassStyle.fifths,
        GenreKey.energeticEdm || GenreKey.darkTrap => BassStyle.octave,
        _ => BassStyle.root,
      };

  GrooveTemplate _proxyGroove(GenreKey genre) => switch (genre) {
        GenreKey.energeticEdm => GrooveTemplate.fourOnFloor,
        GenreKey.soulfulRnb => GrooveTemplate.neoSoulSwing,
        GenreKey.funk => GrooveTemplate.funkSyncopation,
        GenreKey.blues => GrooveTemplate.shuffle,
        GenreKey.darkTrap || GenreKey.reggae => GrooveTemplate.halfTime,
        _ => GrooveTemplate.straight,
      };

  double _proxySwing(GenreKey genre) => switch (genre) {
        GenreKey.chillLofi => 0.12,
        GenreKey.soulfulRnb => 0.16,
        GenreKey.jazzFusion => 0.18,
        GenreKey.funk => 0.12,
        GenreKey.blues => 0.14,
        _ => 0.0,
      };

  static int _compareCandidates(SongCandidate a, SongCandidate b) {
    final scoreOrder = b.score.compareTo(a.score);
    if (scoreOrder != 0) return scoreOrder;
    final deltaOrder = b.scoreDelta.compareTo(a.scoreDelta);
    if (deltaOrder != 0) return deltaOrder;
    return a.candidateIndex.compareTo(b.candidateIndex);
  }
}

class ScoredHarmonyCandidate {
  const ScoredHarmonyCandidate({
    required this.progression,
    required this.score,
  });

  final List<Chord> progression;
  final double score;
}
