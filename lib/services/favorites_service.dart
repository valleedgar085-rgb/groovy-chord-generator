/// Groovy Chord Generator
/// Favorites Service
/// Version 2.5
///
/// Service for managing favorite chord progressions.
/// Allows users to save, load, and manage their favorite progressions.
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/types.dart';
import '../utilities/helpers.dart';

/// Represents a saved favorite progression
class FavoriteProgression {
  final String id;
  final String name;
  final List<Chord> progression;
  final KeyName key;
  final GenreKey genre;
  final int createdAt;
  final int? updatedAt;

  const FavoriteProgression({
    required this.id,
    required this.name,
    required this.progression,
    required this.key,
    required this.genre,
    required this.createdAt,
    this.updatedAt,
  });

  FavoriteProgression copyWith({
    String? id,
    String? name,
    List<Chord>? progression,
    KeyName? key,
    GenreKey? genre,
    int? createdAt,
    int? updatedAt,
  }) {
    return FavoriteProgression(
      id: id ?? this.id,
      name: name ?? this.name,
      progression: progression ?? this.progression,
      key: key ?? this.key,
      genre: genre ?? this.genre,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'progression': progression.map((c) => _chordToJson(c)).toList(),
      'key': key.name,
      'genre': genre.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static FavoriteProgression fromJson(Map<String, dynamic> json) {
    return FavoriteProgression(
      id: json['id'] as String,
      name: json['name'] as String,
      progression: (json['progression'] as List)
          .map((c) => _chordFromJson(c as Map<String, dynamic>))
          .toList(),
      key: KeyName.values.firstWhere(
        (k) => k.name == json['key'],
        orElse: () => KeyName.C,
      ),
      genre: GenreKey.values.firstWhere(
        (g) => g.name == json['genre'],
        orElse: () => GenreKey.happyPop,
      ),
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
    );
  }

  static Map<String, dynamic> _chordToJson(Chord chord) {
    return {
      'root': chord.root,
      'type': chord.type.name,
      'degree': chord.degree,
      'numeral': chord.numeral,
      'isSecondaryDominant': chord.isSecondaryDominant,
      'isBorrowed': chord.isBorrowed,
      'isTritoneSubstitution': chord.isTritoneSubstitution,
      'borrowedDescription': chord.borrowedDescription,
      'harmonyFunction': chord.harmonyFunction?.name,
    };
  }

  static Chord _chordFromJson(Map<String, dynamic> json) {
    return Chord(
      root: json['root'] as String,
      type: ChordTypeName.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ChordTypeName.major,
      ),
      degree: json['degree'] as String,
      numeral: json['numeral'] as String,
      isSecondaryDominant: json['isSecondaryDominant'] as bool? ?? false,
      isBorrowed: json['isBorrowed'] as bool? ?? false,
      isTritoneSubstitution: json['isTritoneSubstitution'] as bool? ?? false,
      borrowedDescription: json['borrowedDescription'] as String?,
      harmonyFunction: json['harmonyFunction'] != null
          ? HarmonyFunction.values.firstWhere(
              (h) => h.name == json['harmonyFunction'],
              orElse: () => HarmonyFunction.tonic,
            )
          : null,
    );
  }
}

/// Service for managing favorites
class FavoritesService {
  static const String _storageKey = 'favorites';
  static const int maxFavorites = 50;

  /// Get all favorites
  static Future<List<FavoriteProgression>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) =>
              FavoriteProgression.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save a new favorite
  static Future<FavoriteProgression?> addFavorite({
    required String name,
    required List<Chord> progression,
    required KeyName key,
    required GenreKey genre,
  }) async {
    if (progression.isEmpty || name.trim().isEmpty) {
      return null;
    }

    final favorites = await getFavorites();
    if (favorites.length >= maxFavorites) {
      return null; // Maximum favorites reached
    }

    final favorite = FavoriteProgression(
      id: IdGenerator.generate(),
      name: name.trim(),
      progression: progression,
      key: key,
      genre: genre,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    favorites.insert(0, favorite);
    await _saveFavorites(favorites);
    return favorite;
  }

  /// Update an existing favorite
  static Future<bool> updateFavorite(FavoriteProgression favorite) async {
    final favorites = await getFavorites();
    final index = favorites.indexWhere((f) => f.id == favorite.id);
    if (index == -1) {
      return false;
    }

    favorites[index] = favorite.copyWith(
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _saveFavorites(favorites);
    return true;
  }

  /// Remove a favorite
  static Future<bool> removeFavorite(String id) async {
    final favorites = await getFavorites();
    final initialLength = favorites.length;
    favorites.removeWhere((f) => f.id == id);

    if (favorites.length == initialLength) {
      return false;
    }

    await _saveFavorites(favorites);
    return true;
  }

  /// Check if a progression is in favorites
  static Future<bool> isFavorite(List<Chord> progression) async {
    final favorites = await getFavorites();
    return favorites.any((f) => _progressionsMatch(f.progression, progression));
  }

  /// Private helper to save favorites list
  static Future<void> _saveFavorites(
      List<FavoriteProgression> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = favorites.map((f) => f.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  /// Private helper to compare progressions
  static bool _progressionsMatch(List<Chord> a, List<Chord> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].root != b[i].root || a[i].type != b[i].type) {
        return false;
      }
    }
    return true;
  }
}
