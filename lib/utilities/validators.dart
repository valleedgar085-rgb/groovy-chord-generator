// Groovy Chord Generator
// Validation Functions
// Version 2.5
//
// Utility validation functions for input validation across the application.

import '../models/types.dart';
import '../models/constants.dart';

/// Validation result class
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  static const ValidationResult valid = ValidationResult(isValid: true);

  factory ValidationResult.invalid(String message) {
    return ValidationResult(isValid: false, errorMessage: message);
  }
}

/// Chord validators
class ChordValidators {
  /// Valid root notes derived from music theory constants
  static const Set<String> _validRoots = {
    'C',
    'C#',
    'Db',
    'D',
    'D#',
    'Eb',
    'E',
    'F',
    'F#',
    'Gb',
    'G',
    'G#',
    'Ab',
    'A',
    'A#',
    'Bb',
    'B'
  };

  /// Validate a chord root note
  static ValidationResult validateRoot(String root) {
    if (root.isEmpty) {
      return ValidationResult.invalid('Root note cannot be empty');
    }
    if (_validRoots.contains(root)) {
      return ValidationResult.valid;
    }
    return ValidationResult.invalid('Invalid root note: $root');
  }

  /// Validate a chord type
  static ValidationResult validateChordType(ChordTypeName type) {
    if (chordTypes.containsKey(type)) {
      return ValidationResult.valid;
    }
    return ValidationResult.invalid('Invalid chord type');
  }

  /// Validate a complete chord
  static ValidationResult validateChord(Chord chord) {
    final rootValidation = validateRoot(chord.root);
    if (!rootValidation.isValid) return rootValidation;

    final typeValidation = validateChordType(chord.type);
    if (!typeValidation.isValid) return typeValidation;

    return ValidationResult.valid;
  }

  /// Validate a chord progression
  static ValidationResult validateProgression(List<Chord> progression) {
    if (progression.isEmpty) {
      return ValidationResult.invalid('Progression cannot be empty');
    }

    if (progression.length > 16) {
      return ValidationResult.invalid('Progression cannot exceed 16 chords');
    }

    for (var i = 0; i < progression.length; i++) {
      final chordValidation = validateChord(progression[i]);
      if (!chordValidation.isValid) {
        return ValidationResult.invalid(
            'Chord ${i + 1}: ${chordValidation.errorMessage}');
      }
    }

    return ValidationResult.valid;
  }
}

/// Music settings validators
class SettingsValidators {
  /// Validate tempo value
  static ValidationResult validateTempo(int tempo) {
    if (tempo < 20) {
      return ValidationResult.invalid('Tempo must be at least 20 BPM');
    }
    if (tempo > 300) {
      return ValidationResult.invalid('Tempo cannot exceed 300 BPM');
    }
    return ValidationResult.valid;
  }

  /// Validate volume value (0.0 to 1.0)
  static ValidationResult validateVolume(double volume) {
    if (volume < 0 || volume > 1) {
      return ValidationResult.invalid('Volume must be between 0 and 1');
    }
    return ValidationResult.valid;
  }

  /// Validate swing value (0.0 to 1.0)
  static ValidationResult validateSwing(double swing) {
    if (swing < 0 || swing > 1) {
      return ValidationResult.invalid('Swing must be between 0 and 1');
    }
    return ValidationResult.valid;
  }

  /// Validate variety value (0 to 100)
  static ValidationResult validateVariety(int variety) {
    if (variety < 0 || variety > 100) {
      return ValidationResult.invalid('Variety must be between 0 and 100');
    }
    return ValidationResult.valid;
  }

  /// Validate envelope values
  static ValidationResult validateEnvelope(Envelope envelope) {
    if (envelope.attack < 0 || envelope.attack > 2) {
      return ValidationResult.invalid('Attack must be between 0 and 2 seconds');
    }
    if (envelope.decay < 0 || envelope.decay > 2) {
      return ValidationResult.invalid('Decay must be between 0 and 2 seconds');
    }
    if (envelope.sustain < 0 || envelope.sustain > 1) {
      return ValidationResult.invalid('Sustain must be between 0 and 1');
    }
    if (envelope.release < 0 || envelope.release > 5) {
      return ValidationResult.invalid(
          'Release must be between 0 and 5 seconds');
    }
    return ValidationResult.valid;
  }
}

/// Input validators for user-provided text
class InputValidators {
  /// Validate favorite name
  static ValidationResult validateFavoriteName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return ValidationResult.invalid('Name cannot be empty');
    }
    if (trimmed.length < 2) {
      return ValidationResult.invalid('Name must be at least 2 characters');
    }
    if (trimmed.length > 50) {
      return ValidationResult.invalid('Name cannot exceed 50 characters');
    }
    // Check for invalid characters
    if (RegExp(r'[<>:"/\\|?*]').hasMatch(trimmed)) {
      return ValidationResult.invalid('Name contains invalid characters');
    }
    return ValidationResult.valid;
  }

  /// Validate share code format
  static ValidationResult validateShareCode(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      return ValidationResult.invalid('Share code cannot be empty');
    }
    // Share code format: keyIndex-genreIndex-chords
    if (!RegExp(r'^\d+-\d+-[A-G#b0-9_]+$').hasMatch(trimmed)) {
      return ValidationResult.invalid('Invalid share code format');
    }
    return ValidationResult.valid;
  }

  /// Validate URL format
  static ValidationResult validateUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return ValidationResult.invalid('URL cannot be empty');
    }
    try {
      final uri = Uri.parse(trimmed);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return ValidationResult.invalid('Invalid URL format');
      }
      return ValidationResult.valid;
    } catch (e) {
      return ValidationResult.invalid('Invalid URL format');
    }
  }
}

/// Scale and key validators
class MusicTheoryValidators {
  /// Validate scale name
  static ValidationResult validateScale(ScaleName scale) {
    if (scales.containsKey(scale)) {
      return ValidationResult.valid;
    }
    return ValidationResult.invalid('Invalid scale');
  }

  /// Validate key name
  static ValidationResult validateKey(KeyName key) {
    // All KeyName enum values are valid
    return ValidationResult.valid;
  }

  /// Validate genre
  static ValidationResult validateGenre(GenreKey genre) {
    if (genreProfiles.containsKey(genre)) {
      return ValidationResult.valid;
    }
    return ValidationResult.invalid('Invalid genre');
  }

  /// Validate MIDI note number (0-127)
  static ValidationResult validateMidiNote(int note) {
    if (note < 0 || note > 127) {
      return ValidationResult.invalid('MIDI note must be between 0 and 127');
    }
    return ValidationResult.valid;
  }

  /// Validate octave (typically -2 to 8 for standard piano range)
  static ValidationResult validateOctave(int octave) {
    if (octave < -2 || octave > 8) {
      return ValidationResult.invalid('Octave must be between -2 and 8');
    }
    return ValidationResult.valid;
  }
}
