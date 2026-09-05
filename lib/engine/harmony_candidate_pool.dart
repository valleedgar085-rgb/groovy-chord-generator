import 'dart:math';

import '../models/constants.dart';
import '../models/types.dart';
import 'harmonic_realizer.dart';
import 'harmony_engine.dart';
import 'producer_analysis.dart';
import 'seeded_music_generation.dart';
import 'song_candidate.dart';
import 'song_request.dart';

/// Builds several musical candidates and lets Producer Brain keep the best.
///
/// Legacy APIs remain harmony-only for compatibility. The app-facing
/// [generateBestForRequest] path performs Phase 5.1 multidimensional preflight:
/// each repaired harmony candidate receives deterministic melody and bass
/// previews and is judged by the same ten-dimensional [ProducerAnalyzer] used
/// by the Producer Analysis UI.
class HarmonyCandidatePool {
  HarmonyCandidatePool({
    HarmonyEngine? engine,
    HarmonicRealizer? realizer,
    SeededMusicGeneration? generation,
    ProducerAnalyzer? analyzer,
  })  : _engine = engine ?? HarmonyEngine(),
        _realizer = realizer ?? const HarmonicRealizer(),
        _generation = generation ?? const SeededMusicGeneration(),
        _analyzer = analyzer ?? ProducerAnalyzer(harmonyEngine: engine);

  final HarmonyEngine _engine;
  final HarmonicRealizer _realizer;
  final SeededMusicGeneration _generation;
  final ProducerAnalyzer _analyzer;

  /// Generate [candidateCount] alternatives with [buildCandidate], then select
  /// the strongest progression for the requested song [section].
  ///
  /// This legacy-compatible API remains available while generation call sites
  /// migrate to the deterministic [SongRequest] contract.
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

  /// Returns every candidate and its harmony score for diagnostics and legacy
  /// callers that intentionally need harmony-only ranking.
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

  /// Deterministic harmony-only producer-core API retained for engine tests and
  /// callers that do not yet have a complete performance context.
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
        progression: List<Chord>.unmodifiable(progression),
        score: _engine.score(progression, section: request.section),
        seed: candidateSeed,
        candidateIndex: i,
        section: request.section,
      ));
    }

    scored.sort(_compareCandidates);
    return List<SongCandidate>.unmodifiable(scored);
  }

  /// Phase 5.1 multidimensional candidate diagnostics.
  ///
  /// Melody uses the exact deterministic request stream that AppState will use
  /// after the winner is committed. Bass uses a conservative genre-aware style
  /// proxy because the current SongRequest contract predates bass-style state;
  /// the post-generation Producer Analysis remains authoritative for the exact
  /// user-selected bass style, swing, tempo, and groove.
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
        progression: List<Chord>.unmodifiable(progression),
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

  /// Returns the best deterministic harmony candidate and optionally applies
  /// final voice leading after ranking, matching the legacy producer workflow.
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
      progression: List<Chord>.unmodifiable(progression),
      score: best.score,
      seed: best.seed,
      candidateIndex: best.candidateIndex,
      section: best.section,
      producerAnalysis: best.producerAnalysis,
    );
  }

  /// App-facing deterministic API.
  ///
  /// Phase 5.1 changes the actual selection criterion from harmony-only to the
  /// full Producer Brain score. The callback still receives stable candidate
  /// identity, so replay and future A/B/C tooling remain deterministic.
  SongCandidate generateBestForRequest({
    required SongRequest request,
    required List<Chord> Function(int candidateSeed, int candidateIndex)
        buildCandidate,
  }) {
    final candidates = generateScoredMusicalForRequest(
      request: request,
      buildCandidate: buildCandidate,
    );

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
