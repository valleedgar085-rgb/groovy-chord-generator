/// Human-performance controls applied after composition timing is built.
///
/// Structural timeline boundaries remain untouched. Playback/export may use the
/// derived intent to perform notes with controlled timing, gate and dynamics.
class PerformanceProfile {
  const PerformanceProfile({
    this.looseness = 0.22,
    this.punch = 0.55,
    this.swing = 0.12,
  })  : assert(looseness >= 0 && looseness <= 1),
        assert(punch >= 0 && punch <= 1),
        assert(swing >= 0 && swing <= 1);

  final double looseness;
  final double punch;
  final double swing;

  PerformanceProfile copyWith({
    double? looseness,
    double? punch,
    double? swing,
  }) {
    return PerformanceProfile(
      looseness: looseness ?? this.looseness,
      punch: punch ?? this.punch,
      swing: swing ?? this.swing,
    );
  }
}

enum ArticulationIntent { legato, normal, detached, staccato, accent }

class PerformanceIntent {
  const PerformanceIntent({
    this.timingOffsetBeats = 0,
    this.gateRatio = 0.9,
    this.velocityScale = 1,
    this.accent = 0,
    this.articulation = ArticulationIntent.normal,
    this.maxDurationBeats = double.infinity,
  })  : assert(timingOffsetBeats >= -0.25 && timingOffsetBeats <= 0.35),
        assert(gateRatio >= 0.35 && gateRatio <= 1),
        assert(velocityScale >= 0.6 && velocityScale <= 1.4),
        assert(accent >= 0 && accent <= 1),
        assert(maxDurationBeats > 0);

  static const neutral = PerformanceIntent();

  final double timingOffsetBeats;
  final double gateRatio;
  final double velocityScale;
  final double accent;
  final ArticulationIntent articulation;

  /// Playback-only absolute gate ceiling. This prevents a sparse melody or
  /// bass note from inheriting an entire multi-beat harmony window and turning
  /// into an accidental drone. Canonical note duration remains unchanged.
  final double maxDurationBeats;
}