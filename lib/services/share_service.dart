/// Groovy Chord Generator
/// Share Service
/// Version 2.5
///
/// Service for generating and parsing shareable URLs for chord progressions.
/// Enables users to share their chord selections with others via URL.

import 'dart:convert';
import '../models/types.dart';
import '../models/constants.dart';

/// Represents shared chord set data
class SharedChordSet {
  final List<Chord> progression;
  final KeyName key;
  final GenreKey genre;
  final int tempo;
  final String? name;

  const SharedChordSet({
    required this.progression,
    required this.key,
    required this.genre,
    required this.tempo,
    this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'p': progression.map((c) => _encodeChord(c)).toList(),
      'k': key.index,
      'g': genre.index,
      't': tempo,
      if (name != null) 'n': name,
    };
  }

  static SharedChordSet fromJson(Map<String, dynamic> json) {
    return SharedChordSet(
      progression: (json['p'] as List)
          .map((c) => _decodeChord(c as String))
          .toList(),
      key: KeyName.values[json['k'] as int? ?? 0],
      genre: GenreKey.values[json['g'] as int? ?? 0],
      tempo: json['t'] as int? ?? 120,
      name: json['n'] as String?,
    );
  }

  /// Encode a chord to compact string format: "root:typeIndex:degree"
  static String _encodeChord(Chord chord) {
    return '${chord.root}:${chord.type.index}:${chord.degree}';
  }

  /// Decode a chord from compact string format
  static Chord _decodeChord(String encoded) {
    final parts = encoded.split(':');
    return Chord(
      root: parts[0],
      type: ChordTypeName.values[int.parse(parts[1])],
      degree: parts.length > 2 ? parts[2] : 'I',
      numeral: parts.length > 2 ? parts[2] : 'I',
    );
  }
}

/// Service for sharing chord progressions
class ShareService {
  static const String _baseScheme = 'groovychords';
  static const String _sharePrefix = 'share';

  /// Generate a shareable URL for a chord progression
  static String generateShareUrl({
    required List<Chord> progression,
    required KeyName key,
    required GenreKey genre,
    required int tempo,
    String? name,
  }) {
    if (progression.isEmpty) {
      return '';
    }

    final sharedSet = SharedChordSet(
      progression: progression,
      key: key,
      genre: genre,
      tempo: tempo,
      name: name,
    );

    final jsonString = jsonEncode(sharedSet.toJson());
    final encoded = base64UrlEncode(utf8.encode(jsonString));

    // For web deployment, use https URL
    // For mobile deep links, use custom scheme
    return 'https://groovychords.app/$_sharePrefix/$encoded';
  }

  /// Generate a compact share code (shorter alternative to full URL)
  static String generateShareCode({
    required List<Chord> progression,
    required KeyName key,
    required GenreKey genre,
  }) {
    if (progression.isEmpty) {
      return '';
    }

    // Create compact encoding: keyIndex-genreIndex-chord1_chord2_chord3...
    final chordPart = progression
        .map((c) => '${c.root}${c.type.index}')
        .join('_');
    
    return '${key.index}-${genre.index}-$chordPart';
  }

  /// Parse a share URL to extract chord set data
  static SharedChordSet? parseShareUrl(String url) {
    try {
      // Extract the encoded data from the URL
      final uri = Uri.parse(url);
      String? encoded;

      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == _sharePrefix) {
        encoded = uri.pathSegments[1];
      } else if (uri.pathSegments.isNotEmpty) {
        encoded = uri.pathSegments.last;
      }

      if (encoded == null || encoded.isEmpty) {
        return null;
      }

      final jsonString = utf8.decode(base64Url.decode(encoded));
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return SharedChordSet.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Parse a compact share code
  static SharedChordSet? parseShareCode(String code) {
    try {
      final parts = code.split('-');
      if (parts.length < 3) return null;

      final keyIndex = int.parse(parts[0]);
      final genreIndex = int.parse(parts[1]);
      final chordStrings = parts[2].split('_');

      final progression = chordStrings.map((cs) {
        // Parse format: RootTypeIndex (e.g., "C0" for C Major)
        final match = RegExp(r'([A-G][#b]?)(\d+)').firstMatch(cs);
        if (match == null) {
          return Chord(
            root: 'C',
            type: ChordTypeName.major,
            degree: 'I',
            numeral: 'I',
          );
        }
        return Chord(
          root: match.group(1)!,
          type: ChordTypeName.values[int.parse(match.group(2)!)],
          degree: 'I',
          numeral: 'I',
        );
      }).toList();

      return SharedChordSet(
        progression: progression,
        key: KeyName.values[keyIndex],
        genre: GenreKey.values[genreIndex],
        tempo: genreProfiles[GenreKey.values[genreIndex]]?.tempo ?? 120,
      );
    } catch (e) {
      return null;
    }
  }

  /// Copy share URL to clipboard (to be called from UI)
  static String getShareableText({
    required List<Chord> progression,
    required KeyName key,
    required GenreKey genre,
    required int tempo,
  }) {
    final url = generateShareUrl(
      progression: progression,
      key: key,
      genre: genre,
      tempo: tempo,
    );
    
    final chordNames = progression
        .map((c) => '${c.root}${chordTypes[c.type]?.symbol ?? ''}')
        .join(' - ');
    
    final genreName = genreProfiles[genre]?.name ?? 'Custom';
    
    return '''🎵 Check out my chord progression!

$chordNames
Key: ${_keyToDisplayName(key)} | Genre: $genreName | Tempo: $tempo BPM

$url

Made with Groovy Chord Generator''';
  }

  static String _keyToDisplayName(KeyName key) {
    switch (key) {
      case KeyName.C: return 'C Major';
      case KeyName.G: return 'G Major';
      case KeyName.D: return 'D Major';
      case KeyName.A: return 'A Major';
      case KeyName.E: return 'E Major';
      case KeyName.F: return 'F Major';
      case KeyName.Bb: return 'Bb Major';
      case KeyName.Am: return 'A Minor';
      case KeyName.Em: return 'E Minor';
      case KeyName.Dm: return 'D Minor';
      case KeyName.Bm: return 'B Minor';
      case KeyName.Fm: return 'F Minor';
    }
  }
}
