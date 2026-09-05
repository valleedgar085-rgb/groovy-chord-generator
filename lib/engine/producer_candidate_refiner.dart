import '../models/types.dart';
import '../utils/music_theory.dart';
import 'harmony_engine.dart';
import 'producer_analysis.dart';
import 'song_candidate.dart';
import 'song_request.dart';

class ProducerRefinement {
  const ProducerRefinement({
    required this.progression,
    required this.style,
    required this.repairs,
  });

  final List<Chord> progression;
  final ProducerVariationStyle style;
  final List<String> repairs;
}

/// Phase 5.2 closed-loop refinement.
///
/// The top Producer Brain candidates are diagnosed using their scorecard and
/// evolved through three deterministic production intents. The pool rescoring
/// stage decides whether each revision is actually better; a mutation never wins
/// merely because it was attempted.
class ProducerCandidateRefiner {
  const ProducerCandidateRefiner();

  List<ProducerRefinement> evolve({
    required SongCandidate base,
    required SongRequest request,
  }) {
    if (base.progression.length < 2) return const <ProducerRefinement>[];
    return <ProducerRefinement>[
      _polished(base, request),
      _creative(base, request),
      _hook(base, request),
    ];
  }

  ProducerRefinement _polished(SongCandidate base, SongRequest request) {
    var progression = List<Chord>.from(base.progression);
    final repairs = <String>[];
    final analysis = base.producerAnalysis;

    if (_needs(analysis, ProducerDimension.repetition) ||
        _hasImmediateRepeat(progression)) {
      progression = _breakImmediateRepeats(progression, request);
      repairs.add('Reduced mechanical chord repetition');
    }

    if (_needs(analysis, ProducerDimension.harmony) ||
        _needs(analysis, ProducerDimension.tension)) {
      progression = _repairCadence(progression, request);
      repairs.add('Strengthened cadence and harmonic resolution');
    }

    if (_needs(analysis, ProducerDimension.playability)) {
      progression = _softenDenseColor(progression);
      repairs.add('Simplified dense color for cleaner voice leading');
    }

    if (repairs.isEmpty) {
      progression = _repairCadence(progression, request);
      repairs.add('Tightened final resolution');
    }

    return ProducerRefinement(
      progression: progression,
      style: ProducerVariationStyle.polished,
      repairs: repairs,
    );
  }

  ProducerRefinement _creative(SongCandidate base, SongRequest request) {
    var progression = List<Chord>.from(base.progression);
    final repairs = <String>[];

    progression = _addTastefulColor(progression);
    repairs.add('Added one controlled harmonic color event');

    if (_needs(base.producerAnalysis, ProducerDimension.tension) ||
        request.section == HarmonySection.preChorus ||
        request.section == HarmonySection.bridge) {
      progression = _strengthenApproach(progression, request);
      repairs.add('Shaped a stronger tension approach');
    }

    if (_hasImmediateRepeat(progression)) {
      progression = _breakImmediateRepeats(progression, request);
      repairs.add('Varied repeated harmony without changing the phrase length');
    }

    return ProducerRefinement(
      progression: progression,
      style: ProducerVariationStyle.creative,
      repairs: repairs,
    );
  }

  ProducerRefinement _hook(SongCandidate base, SongRequest request) {
    var progression = List<Chord>.from(base.progression);
    final repairs = <String>[];

    if (progression.length >= 6) {
      progression[4] = progression[0];
      progression[5] = progression[1];
      repairs.add('Recalled the opening two-chord motif later in the phrase');
    } else if (progression.length >= 4) {
      progression[2] = _hookColor(progression[0]);
      repairs.add('Created a recognizable tonic-family hook return');
    }

    progression = _repairCadence(progression, request);
    repairs.add('Kept the hook anchored with a clear ending');

    return ProducerRefinement(
      progression: progression,
      style: ProducerVariationStyle.hook,
      repairs: repairs,
    );
  }

  bool _needs(
    ProducerAnalysis? analysis,
    ProducerDimension dimension, [
    double threshold = 72,
  ]) {
    final metric = analysis?.metricFor(dimension);
    return metric != null && metric.active && metric.score < threshold;
  }

  bool _hasImmediateRepeat(List<Chord> progression) {
    for (var i = 1; i < progression.length; i++) {
      if (_sameChord(progression[i - 1], progression[i])) return true;
    }
    return false;
  }

  bool _sameChord(Chord a, Chord b) => a.root == b.root && a.type == b.type;

  List<Chord> _breakImmediateRepeats(
    List<Chord> progression,
    SongRequest request,
  ) {
    final result = List<Chord>.from(progression);
    final key = parseKey(keyNameToString(request.key));
    final root = key['root'] as String;
    final isMinor = key['isMinor'] as bool;

    for (var i = 1; i < result.length; i++) {
      if (!_sameChord(result[i - 1], result[i])) continue;
      final interval = i.isEven ? 5 : 7;
      result[i] = Chord(
        root: transposeNote(root, interval),
        type: interval == 7
            ? ChordTypeName.dominant7
            : (isMinor ? ChordTypeName.minor : ChordTypeName.major),
        degree: interval == 7 ? 'V' : (isMinor ? 'iv' : 'IV'),
        numeral: interval == 7 ? 'V' : 'IV',
      );
    }
    return result;
  }

  List<Chord> _repairCadence(List<Chord> progression, SongRequest request) {
    final result = List<Chord>.from(progression);
    final key = parseKey(keyNameToString(request.key));
    final root = key['root'] as String;
    final isMinor = key['isMinor'] as bool;

    if (result.length >= 3) {
      result[result.length - 2] = Chord(
        root: transposeNote(root, 7),
        type: ChordTypeName.dominant7,
        degree: 'V',
        numeral: 'V',
      );
    }
    result[result.length - 1] = Chord(
      root: root,
      type: isMinor ? ChordTypeName.minor : ChordTypeName.major,
      degree: isMinor ? 'i' : 'I',
      numeral: isMinor ? 'i' : 'I',
    );
    return result;
  }

  List<Chord> _strengthenApproach(
    List<Chord> progression,
    SongRequest request,
  ) {
    if (progression.length < 2) return progression;
    final result = List<Chord>.from(progression);
    final key = parseKey(keyNameToString(request.key));
    final root = key['root'] as String;
    result[result.length - 2] = Chord(
      root: transposeNote(root, 7),
      type: ChordTypeName.dominant7,
      degree: 'V',
      numeral: 'V',
    );
    return result;
  }

  List<Chord> _addTastefulColor(List<Chord> progression) {
    if (progression.isEmpty) return progression;
    final result = List<Chord>.from(progression);
    final index = (result.length ~/ 2).clamp(0, result.length - 1).toInt();
    final chord = result[index];
    final type = switch (chord.type) {
      ChordTypeName.major => ChordTypeName.add9,
      ChordTypeName.minor => ChordTypeName.minor7,
      ChordTypeName.major7 => ChordTypeName.major9,
      ChordTypeName.minor7 => ChordTypeName.minor9,
      _ => chord.type,
    };
    result[index] = chord.copyWith(type: type);
    return result;
  }

  List<Chord> _softenDenseColor(List<Chord> progression) {
    return progression.map((chord) {
      final type = switch (chord.type) {
        ChordTypeName.major9 => ChordTypeName.major7,
        ChordTypeName.minor9 => ChordTypeName.minor7,
        ChordTypeName.diminished7 => ChordTypeName.diminished,
        _ => chord.type,
      };
      return chord.copyWith(type: type);
    }).toList(growable: false);
  }

  Chord _hookColor(Chord chord) {
    final type = switch (chord.type) {
      ChordTypeName.major => ChordTypeName.add9,
      ChordTypeName.minor => ChordTypeName.minor7,
      _ => chord.type,
    };
    return chord.copyWith(type: type);
  }
}
