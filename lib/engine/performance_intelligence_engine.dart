import 'performance_profile.dart';
import 'song_timeline.dart';

/// Deterministically derives human-performance intent from canonical timing.
class PerformanceIntelligenceEngine {
  const PerformanceIntelligenceEngine();

  PerformanceIntent intentFor({
    required PerformanceProfile profile,
    required int seed,
    required TimelineTrackType track,
    required String sectionId,
    required int chordIndex,
    required int ordinal,
    required double startBeat,
    required double durationBeats,
    required double sectionStartBeat,
  }) {
    final noise = _signedNoise(
      seed: seed,
      sectionId: sectionId,
      track: track,
      chordIndex: chordIndex,
      ordinal: ordinal,
    );

    final eighthPosition = (startBeat * 2).round();
    final onEighthGrid = ((startBeat * 2) - eighthPosition).abs() < 0.08;
    final offEighth = onEighthGrid && eighthPosition.isOdd;
    final swingOffset = offEighth ? profile.swing * 0.16 : 0.0;
    final humanOffset = noise * profile.looseness * 0.035;
    var timingOffset = swingOffset + humanOffset;
    if (startBeat + timingOffset < sectionStartBeat) {
      timingOffset = sectionStartBeat - startBeat;
    }
    timingOffset = timingOffset.clamp(-0.25, 0.35).toDouble();

    final beatInBar = startBeat % 4.0;
    final downbeat = beatInBar < 0.08 || beatInBar > 3.92;
    final quarterBeat = (beatInBar - beatInBar.round()).abs() < 0.08;
    final metricStrength = downbeat ? 1.0 : (quarterBeat ? 0.52 : 0.18);
    final accent = (metricStrength * profile.punch).clamp(0.0, 1.0).toDouble();

    final trackBaseGate = switch (track) {
      TimelineTrackType.harmony => 0.91,
      TimelineTrackType.melody => 0.86,
      TimelineTrackType.bass => 0.78,
    };
    final gateRatio = (trackBaseGate +
            (profile.looseness * 0.07) -
            (profile.punch * (track == TimelineTrackType.bass ? 0.12 : 0.07)))
        .clamp(0.48, 0.98)
        .toDouble();

    final velocityScale = (0.84 +
            (profile.punch * 0.27) +
            (accent * 0.09) +
            (noise * profile.looseness * 0.04))
        .clamp(0.68, 1.32)
        .toDouble();

    final articulation = _articulationFor(
      track: track,
      durationBeats: durationBeats,
      profile: profile,
      accent: accent,
    );

    return PerformanceIntent(
      timingOffsetBeats: timingOffset,
      gateRatio: gateRatio,
      velocityScale: velocityScale,
      accent: accent,
      articulation: articulation,
    );
  }

  ArticulationIntent _articulationFor({
    required TimelineTrackType track,
    required double durationBeats,
    required PerformanceProfile profile,
    required double accent,
  }) {
    if (accent > 0.72 && profile.punch > 0.7) {
      return ArticulationIntent.accent;
    }
    switch (track) {
      case TimelineTrackType.harmony:
        return profile.punch < 0.35
            ? ArticulationIntent.legato
            : ArticulationIntent.normal;
      case TimelineTrackType.melody:
        if (durationBeats <= 0.5 && profile.punch > 0.6) {
          return ArticulationIntent.staccato;
        }
        return profile.looseness > 0.68
            ? ArticulationIntent.legato
            : ArticulationIntent.normal;
      case TimelineTrackType.bass:
        return profile.punch > 0.48
            ? ArticulationIntent.detached
            : ArticulationIntent.normal;
    }
  }

  double _signedNoise({
    required int seed,
    required String sectionId,
    required TimelineTrackType track,
    required int chordIndex,
    required int ordinal,
  }) {
    var hash = seed & 0x7fffffff;
    for (final code in sectionId.codeUnits) {
      hash = ((hash * 16777619) ^ code) & 0x7fffffff;
    }
    hash = ((hash * 1103515245) + track.index * 7919 + chordIndex * 3571 + ordinal * 1013) &
        0x7fffffff;
    hash ^= (hash >> 13);
    hash = (hash * 1274126177) & 0x7fffffff;
    final unit = (hash & 0xffff) / 65535.0;
    return (unit * 2.0) - 1.0;
  }
}
