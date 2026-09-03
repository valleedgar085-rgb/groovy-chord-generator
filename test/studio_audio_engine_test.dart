import 'package:flutter_test/flutter_test.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/services/studio_audio_engine.dart';

void main() {
  group('StudioAudioEngine musical mapping', () {
    test('C major maps to an ascending playable triad', () {
      final engine = StudioAudioEngine();
      const chord = Chord(
        root: 'C',
        type: ChordTypeName.major,
        degree: 'I',
        numeral: 'I',
      );

      final notes = engine.chordMidiNotes(chord);
      expect(notes, hasLength(3));
      expect(notes[0] % 12, 0);
      expect(notes[1] % 12, 4);
      expect(notes[2] % 12, 7);
      expect(notes[0], lessThan(notes[1]));
      expect(notes[1], lessThan(notes[2]));
    });

    test('A4 MIDI tuning remains exactly 440 Hz', () {
      final engine = StudioAudioEngine();
      expect(engine.midiToFrequency(69), closeTo(440.0, 0.0001));
    });

    test('extended chords remain within supported polyphony', () {
      final engine = StudioAudioEngine();
      const chord = Chord(
        root: 'D',
        type: ChordTypeName.minor9,
        degree: 'ii',
        numeral: 'ii',
      );
      expect(engine.chordMidiNotes(chord).length, lessThanOrEqualTo(6));
    });
  });
}
