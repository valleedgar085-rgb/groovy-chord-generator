import 'dart:math';

import '../models/types.dart';
import 'emotion_director.dart';
import 'song_architecture.dart';

/// Applies the Emotion Director to already-valid phrase material without
/// changing harmony or section boundaries.
///
/// This layer deliberately preserves pitch-class identity except for controlled
/// octave emphasis. It changes density, phrasing weights and dynamics so Mood is
/// audible in the internal performance rather than remaining UI metadata.
class EmotionPerformanceShaper {
  const EmotionPerformanceShaper({
    this.director = const EmotionDirector(),
  });

  final EmotionDirector director;

  List<MelodyNote> shapeMelody({
    required List<MelodyNote> melody,
    required MoodType mood,
    required SongSectionPlan section,
  }) {
    if (melody.isEmpty) return const <MelodyNote>[];
    final intent = director.intentFor(mood: mood, section: section);
    final thinned = _thinForSpace(melody, intent, section);
    final count = thinned.length;

    return List<MelodyNote>.unmodifiable(
      <MelodyNote>[
        for (var i = 0; i < count; i++)
          _shapeMelodyNote(
            thinned[i],
            index: i,
            count: count,
            intent: intent,
            section: section,
          ),
      ],
    );
  }

  List<BassNote> shapeBass({
    required List<BassNote> bass,
    required MoodType mood,
    required SongSectionPlan section,
  }) {
    if (bass.isEmpty) return const <BassNote>[];
    final intent = director.intentFor(mood: mood, section: section);
    final count = bass.length;
    return List<BassNote>.unmodifiable(
      <BassNote>[
        for (var i = 0; i < count; i++)
          BassNote(
            note: bass[i].note,
            duration: _bassDuration(bass[i].duration, intent, section),
            velocity: _bassVelocity(
              bass[i].velocity,
              intent,
              section,
              position: count <= 1 ? 0.0 : i / (count - 1),
            ),
            octave: bass[i].octave,
            chordIndex: bass[i].chordIndex,
            style: bass[i].style,
          ),
      ],
    );
  }

  List<MelodyNote> _thinForSpace(
    List<MelodyNote> melody,
    EmotionIntent intent,
    SongSectionPlan section,
  ) {
    if (melody.length < 5) return melody;

    final id = section.id.toLowerCase();
    final payoff = _isPayoff(section);
    final finalPayoff = id.contains('final') || id.contains('climax');
    if (payoff || finalPayoff) {
      // Payoff sections keep their available phrase events. The emotional arc
      // should arrive with more information than the setup, not by deleting the
      // hook notes the Phrase Composer just authored.
      return melody;
    }

    final roleSpace = switch (section.type) {
      SongSectionType.intro => 0.10,
      SongSectionType.verse => 0.08,
      SongSectionType.preChorus => 0.035,
      SongSectionType.chorus => 0.0,
      SongSectionType.bridge => 0.07,
      SongSectionType.outro => 0.14,
    };
    final effectiveSpace = (intent.space + roleSpace).clamp(0.0, 1.0).toDouble();
    if (effectiveSpace < 0.54) return melody;

    final byChord = <int, List<MelodyNote>>{};
    for (final note in melody) {
      byChord.putIfAbsent(note.chordIndex, () => <MelodyNote>[]).add(note);
    }
    final result = <MelodyNote>[];
    final aggressive = effectiveSpace >= 0.70;
    for (final entry in byChord.entries) {
      final notes = entry.value;
      if (notes.length <= 2) {
        result.addAll(notes);
        continue;
      }
      for (var i = 0; i < notes.length; i++) {
        final boundary = i == 0 || i == notes.length - 1;
        final keepInterior = aggressive ? i.isOdd : (i % 3 != 1);
        if (boundary || keepInterior) result.add(notes[i]);
      }
    }
    return result.isEmpty ? <MelodyNote>[melody.first, melody.last] : result;
  }

  MelodyNote _shapeMelodyNote(
    MelodyNote note, {
    required int index,
    required int count,
    required EmotionIntent intent,
    required SongSectionPlan section,
  }) {
    final position = count <= 1 ? 0.0 : index / (count - 1);
    final peak = _peakShape(position, section);
    var velocity = note.velocity + intent.velocityBias;
    velocity += _sectionDynamicBias(section);
    velocity += (section.targetEnergy - 0.55) * 0.12;
    velocity += peak * (intent.arousal - 0.50) * 0.10;
    velocity += peak * max(0.0, intent.contourLift) * 0.08;
    if (position > 0.82 && section.type == SongSectionType.outro) {
      velocity -= 0.06;
    }

    var octave = note.octave;
    // Octave emphasis is deliberately sparse: changing every note's register
    // would damage motif identity. Payoff peaks may lift one recognizable note;
    // dark/low-brightness material may ground selected interior notes.
    final payoff = _isPayoff(section);
    if (intent.registerShift >= 4 && payoff && peak > 0.82 && index % 3 == 0) {
      octave = min(6, octave + 1);
    } else if (intent.registerShift <= -4 && !payoff && peak < 0.40 && index % 4 == 1) {
      octave = max(3, octave - 1);
    }

    final durationScale = (1.0 +
            (intent.space - 0.50) * 0.20 -
            intent.arousal * 0.04 -
            (_isPayoff(section) ? 0.035 : 0.0))
        .clamp(0.82, 1.16)
        .toDouble();

    return MelodyNote(
      note: note.note,
      duration: (note.duration * durationScale).clamp(0.20, 4.5).toDouble(),
      velocity: velocity.clamp(0.32, 1.0).toDouble(),
      chordIndex: note.chordIndex,
      octave: octave,
    );
  }

  double _bassVelocity(
    double velocity,
    EmotionIntent intent,
    SongSectionPlan section, {
    required double position,
  }) {
    final pulse = sin(position * pi * 2).abs() * 0.018;
    return (velocity +
            intent.velocityBias * 0.58 +
            _sectionDynamicBias(section) * 0.72 +
            (section.targetEnergy - 0.55) * 0.075 +
            pulse)
        .clamp(0.30, 0.98)
        .toDouble();
  }

  double _bassDuration(
    double duration,
    EmotionIntent intent,
    SongSectionPlan section,
  ) {
    // High-arousal/payoff sections get a tighter low end; intimate/relaxed
    // sections are allowed more sustain.
    final payoffTightening = _isPayoff(section) ? 0.055 : 0.0;
    final scale = (1.04 +
            intent.intimacy * 0.10 -
            intent.arousal * 0.13 -
            payoffTightening)
        .clamp(0.78, 1.12)
        .toDouble();
    return (duration * scale).clamp(0.20, 4.5).toDouble();
  }

  double _sectionDynamicBias(SongSectionPlan section) {
    final id = section.id.toLowerCase();
    if (id.contains('final') || id.contains('climax')) return 0.13;
    if (id.contains('drop') || id.contains('hook')) return 0.10;
    return switch (section.type) {
      SongSectionType.intro => -0.07,
      SongSectionType.verse => -0.055,
      SongSectionType.preChorus => -0.015,
      SongSectionType.chorus => 0.085,
      SongSectionType.bridge => -0.035,
      SongSectionType.outro => -0.10,
    };
  }

  bool _isPayoff(SongSectionPlan section) {
    final id = section.id.toLowerCase();
    return section.type == SongSectionType.chorus ||
        id.contains('hook') ||
        id.contains('drop') ||
        id.contains('climax');
  }

  double _peakShape(double position, SongSectionPlan section) {
    final target = section.type == SongSectionType.preChorus
        ? 0.88
        : section.type == SongSectionType.chorus
            ? 0.64
            : section.type == SongSectionType.outro
                ? 0.20
                : 0.60;
    final distance = (position - target).abs();
    return (1.0 - distance / max(0.12, max(target, 1.0 - target)))
        .clamp(0.0, 1.0)
        .toDouble();
  }
}
