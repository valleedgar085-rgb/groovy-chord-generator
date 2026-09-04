import '../models/constants.dart';
import '../models/types.dart';
import 'song_request.dart';

/// Canonicalizes generated chord symbols into musically valid roots and chord
/// families. This is intentionally kept between stochastic generation and
/// producer scoring so every generation path shares the same theory rules.
class HarmonicRealizer {
  const HarmonicRealizer();

  List<Chord> repairProgression(
    List<Chord> progression,
    SongRequest request,
  ) {
    return progression
        .map((chord) => repairChord(chord, request))
        .toList(growable: false);
  }

  Chord repairChord(Chord chord, SongRequest request) {
    final parsed = _DegreeSymbol.tryParse(chord.degree);
    if (parsed == null) return chord;

    final key = _keyContext(request.key);
    final scale = _effectiveScale(request, key.isMinor);
    final intervals = scales[scale] ?? scales[key.isMinor ? ScaleName.minor : ScaleName.major]!;
    final rootOffset = _rootOffset(parsed, intervals);
    final root = _transpose(key.root, rootOffset);
    final expectedBase = _expectedBaseType(parsed, intervals);
    final repairedType = _repairType(
      chord.type,
      expectedBase,
      parsed,
      request.genre,
      chord.harmonyFunction,
    );

    return chord.copyWith(
      root: root,
      type: repairedType,
      numeral: chord.degree,
      isSecondaryDominant:
          chord.isSecondaryDominant || parsed.secondaryTarget != null,
    );
  }

  ScaleName _effectiveScale(SongRequest request, bool keyIsMinor) {
    final genreScale = genreProfiles[request.genre]?.scale ?? ScaleName.major;
    if (keyIsMinor) {
      switch (genreScale) {
        case ScaleName.minor:
        case ScaleName.harmonicMinor:
        case ScaleName.melodicMinor:
        case ScaleName.dorian:
        case ScaleName.phrygian:
          return genreScale;
        default:
          return ScaleName.minor;
      }
    }

    switch (genreScale) {
      case ScaleName.major:
      case ScaleName.lydian:
      case ScaleName.mixolydian:
        return genreScale;
      default:
        return ScaleName.major;
    }
  }

  int _rootOffset(_DegreeSymbol degree, List<int> scaleIntervals) {
    if (degree.secondaryTarget != null) {
      final target = degree.secondaryTarget!;
      final targetOffset = _simpleDegreeOffset(target, scaleIntervals);
      // A secondary dominant is the dominant (perfect fifth) of its target.
      return (targetOffset + 7) % 12;
    }
    return _simpleDegreeOffset(degree, scaleIntervals);
  }

  int _simpleDegreeOffset(_DegreeSymbol degree, List<int> scaleIntervals) {
    final index = degree.index;
    if (degree.accidental != 0) {
      // Altered Roman numerals are conventionally measured against the major
      // scale (bVII=10, bVI=8, bIII=3), regardless of the current mode.
      const major = <int>[0, 2, 4, 5, 7, 9, 11];
      return (major[index] + degree.accidental) % 12;
    }
    if (scaleIntervals.length >= 7) return scaleIntervals[index] % 12;
    const major = <int>[0, 2, 4, 5, 7, 9, 11];
    return major[index];
  }

  ChordTypeName _expectedBaseType(
    _DegreeSymbol degree,
    List<int> scaleIntervals,
  ) {
    if (degree.secondaryTarget != null) return ChordTypeName.dominant7;

    final suffix = degree.suffix;
    if (suffix == 'maj7') return ChordTypeName.major7;
    if (suffix == 'm7') return ChordTypeName.minor7;
    if (suffix == 'dim7') return ChordTypeName.diminished7;

    final diatonic = _diatonicTriad(degree.index, scaleIntervals);
    ChordTypeName base;
    if (diatonic == ChordTypeName.diminished ||
        diatonic == ChordTypeName.augmented) {
      base = diatonic;
    } else if (degree.isLowerCase) {
      base = ChordTypeName.minor;
    } else {
      base = ChordTypeName.major;
    }

    // Common leading-tone symbols should never be repaired into a plain minor
    // triad when the scale itself identifies them as diminished.
    if (degree.roman.toLowerCase() == 'vii' &&
        diatonic == ChordTypeName.diminished) {
      base = ChordTypeName.diminished;
    }

    if (suffix == '7') {
      if (base == ChordTypeName.minor) return ChordTypeName.minor7;
      if (base == ChordTypeName.diminished) return ChordTypeName.diminished7;
      return ChordTypeName.dominant7;
    }
    return base;
  }

  ChordTypeName _diatonicTriad(int index, List<int> scaleIntervals) {
    if (scaleIntervals.length < 7) return ChordTypeName.major;
    final root = scaleIntervals[index];
    var third = scaleIntervals[(index + 2) % 7];
    var fifth = scaleIntervals[(index + 4) % 7];
    if ((index + 2) >= 7) third += 12;
    if ((index + 4) >= 7) fifth += 12;
    final thirdDistance = third - root;
    final fifthDistance = fifth - root;

    if (thirdDistance == 4 && fifthDistance == 7) return ChordTypeName.major;
    if (thirdDistance == 3 && fifthDistance == 7) return ChordTypeName.minor;
    if (thirdDistance == 3 && fifthDistance == 6) return ChordTypeName.diminished;
    if (thirdDistance == 4 && fifthDistance == 8) return ChordTypeName.augmented;
    return ChordTypeName.major;
  }

  ChordTypeName _repairType(
    ChordTypeName current,
    ChordTypeName expected,
    _DegreeSymbol degree,
    GenreKey genre,
    HarmonyFunction? function,
  ) {
    if (degree.secondaryTarget != null) return ChordTypeName.dominant7;

    if (_isCompatible(current, expected, degree, genre, function)) {
      return current;
    }

    final wantsNinth = current == ChordTypeName.major9 ||
        current == ChordTypeName.minor9 ||
        current == ChordTypeName.add9;
    final wantsSeventh = wantsNinth ||
        current == ChordTypeName.major7 ||
        current == ChordTypeName.minor7 ||
        current == ChordTypeName.dominant7 ||
        current == ChordTypeName.diminished7 ||
        current == ChordTypeName.halfDim7;

    switch (expected) {
      case ChordTypeName.major:
      case ChordTypeName.major7:
      case ChordTypeName.major9:
      case ChordTypeName.add9:
        if (_isDominantRole(degree, function) && wantsSeventh) {
          return ChordTypeName.dominant7;
        }
        if (wantsNinth) return ChordTypeName.major9;
        if (wantsSeventh) return ChordTypeName.major7;
        return ChordTypeName.major;
      case ChordTypeName.minor:
      case ChordTypeName.minor7:
      case ChordTypeName.minor9:
        if (wantsNinth) return ChordTypeName.minor9;
        if (wantsSeventh) return ChordTypeName.minor7;
        return ChordTypeName.minor;
      case ChordTypeName.diminished:
      case ChordTypeName.diminished7:
      case ChordTypeName.halfDim7:
        return wantsSeventh ? ChordTypeName.halfDim7 : ChordTypeName.diminished;
      case ChordTypeName.augmented:
        return ChordTypeName.augmented;
      case ChordTypeName.dominant7:
        return ChordTypeName.dominant7;
      case ChordTypeName.sus2:
      case ChordTypeName.sus4:
        return expected;
    }
  }

  bool _isCompatible(
    ChordTypeName current,
    ChordTypeName expected,
    _DegreeSymbol degree,
    GenreKey genre,
    HarmonyFunction? function,
  ) {
    if (expected == ChordTypeName.dominant7) {
      return current == ChordTypeName.dominant7;
    }

    if (_isMajorFamily(expected)) {
      if (_isMajorFamily(current)) return true;
      if (current == ChordTypeName.dominant7) {
        return _isDominantRole(degree, function) ||
            (genre == GenreKey.blues &&
                const {'I', 'IV', 'V'}.contains(degree.roman));
      }
      return false;
    }
    if (_isMinorFamily(expected)) return _isMinorFamily(current);
    if (_isDiminishedFamily(expected)) return _isDiminishedFamily(current);
    return current == expected;
  }

  bool _isMajorFamily(ChordTypeName type) =>
      type == ChordTypeName.major ||
      type == ChordTypeName.major7 ||
      type == ChordTypeName.major9 ||
      type == ChordTypeName.add9 ||
      type == ChordTypeName.sus2 ||
      type == ChordTypeName.sus4;

  bool _isMinorFamily(ChordTypeName type) =>
      type == ChordTypeName.minor ||
      type == ChordTypeName.minor7 ||
      type == ChordTypeName.minor9;

  bool _isDiminishedFamily(ChordTypeName type) =>
      type == ChordTypeName.diminished ||
      type == ChordTypeName.diminished7 ||
      type == ChordTypeName.halfDim7;

  bool _isDominantRole(_DegreeSymbol degree, HarmonyFunction? function) =>
      degree.roman == 'V' || function == HarmonyFunction.dominant;

  _KeyContext _keyContext(KeyName key) {
    switch (key) {
      case KeyName.C:
        return const _KeyContext('C', false);
      case KeyName.G:
        return const _KeyContext('G', false);
      case KeyName.D:
        return const _KeyContext('D', false);
      case KeyName.A:
        return const _KeyContext('A', false);
      case KeyName.E:
        return const _KeyContext('E', false);
      case KeyName.F:
        return const _KeyContext('F', false);
      case KeyName.Bb:
        return const _KeyContext('Bb', false);
      case KeyName.Am:
        return const _KeyContext('A', true);
      case KeyName.Em:
        return const _KeyContext('E', true);
      case KeyName.Dm:
        return const _KeyContext('D', true);
      case KeyName.Bm:
        return const _KeyContext('B', true);
      case KeyName.Fm:
        return const _KeyContext('F', true);
    }
  }

  String _transpose(String root, int interval) {
    const enharmonic = <String, int>{
      'C': 0,
      'C#': 1,
      'Db': 1,
      'D': 2,
      'D#': 3,
      'Eb': 3,
      'E': 4,
      'F': 5,
      'F#': 6,
      'Gb': 6,
      'G': 7,
      'G#': 8,
      'Ab': 8,
      'A': 9,
      'A#': 10,
      'Bb': 10,
      'B': 11,
    };
    final rootIndex = enharmonic[root] ?? 0;
    final index = (rootIndex + interval) % 12;
    return notes[index];
  }
}

class _KeyContext {
  const _KeyContext(this.root, this.isMinor);

  final String root;
  final bool isMinor;
}

class _DegreeSymbol {
  const _DegreeSymbol({
    required this.accidental,
    required this.roman,
    required this.suffix,
    this.secondaryTarget,
  });

  final int accidental;
  final String roman;
  final String suffix;
  final _DegreeSymbol? secondaryTarget;

  int get index {
    switch (roman.toUpperCase()) {
      case 'I':
        return 0;
      case 'II':
        return 1;
      case 'III':
        return 2;
      case 'IV':
        return 3;
      case 'V':
        return 4;
      case 'VI':
        return 5;
      case 'VII':
        return 6;
      default:
        return 0;
    }
  }

  bool get isLowerCase => roman == roman.toLowerCase();

  static _DegreeSymbol? tryParse(String raw) {
    final match = RegExp(
      r'^([b#]?)([IViv]+)(?:/([b#]?[IViv]+))?(maj7|m7|dim7|7)?$',
    ).firstMatch(raw.trim());
    if (match == null) return null;

    final accidentalToken = match.group(1) ?? '';
    final accidental = accidentalToken == 'b'
        ? -1
        : accidentalToken == '#'
            ? 1
            : 0;
    final targetRaw = match.group(3);

    return _DegreeSymbol(
      accidental: accidental,
      roman: match.group(2)!,
      suffix: match.group(4) ?? '',
      secondaryTarget: targetRaw == null ? null : tryParse(targetRaw),
    );
  }
}
