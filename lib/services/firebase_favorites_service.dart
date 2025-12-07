/// Groovy Chord Generator
/// Firebase Favorites Service
/// Version 2.5
/// 
/// Enhanced favorites service that uses Firebase Firestore for cloud storage
/// with fallback to local SharedPreferences for offline support.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/types.dart';
import '../models/constants.dart';
import '../utilities/helpers.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

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

  /// Create from Firestore document
  static FavoriteProgression fromFirestore(Map<String, dynamic> data) {
    return FavoriteProgression(
      id: data['id'] as String,
      name: data['name'] as String,
      progression: (data['progression'] as List)
          .map((c) => FirestoreService.mapToChord(c as Map<String, dynamic>))
          .toList(),
      key: KeyName.values.firstWhere(
        (k) => k.name == data['key'],
        orElse: () => KeyName.C,
      ),
      genre: GenreKey.values.firstWhere(
        (g) => g.name == data['genre'],
        orElse: () => GenreKey.happyPop,
      ),
      createdAt: _timestampToMillis(data['createdAt']),
      updatedAt: _timestampToMillis(data['updatedAt']),
    );
  }

  static int _timestampToMillis(dynamic timestamp) {
    if (timestamp == null) return DateTime.now().millisecondsSinceEpoch;
    if (timestamp is int) return timestamp;
    // Handle Firestore Timestamp
    try {
      return (timestamp.seconds as int) * 1000;
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch;
    }
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

/// Enhanced favorites service with Firebase cloud storage
class FavoritesService {
  static const String _storageKey = 'favorites';
  static const int maxFavorites = 50;
  static bool _useFirebase = true;

  /// Get all favorites (from Firebase or local storage)
  static Future<List<FavoriteProgression>> getFavorites() async {
    // Try Firebase first if user is authenticated
    if (_useFirebase && AuthService.isSignedIn) {
      try {
        final firestoreData = await FirestoreService.getFavorites();
        final favorites = firestoreData
            .map((data) => FavoriteProgression.fromFirestore(data))
            .toList();
        
        if (kDebugMode) {
          print('Loaded ${favorites.length} favorites from Firebase');
        }
        
        // Sync to local storage as backup
        await _saveToLocalStorage(favorites);
        return favorites;
      } catch (e) {
        if (kDebugMode) {
          print('Error loading from Firebase, falling back to local: $e');
        }
      }
    }

    // Fallback to local storage
    return _getFromLocalStorage();
  }

  /// Get favorites from local storage only
  static Future<List<FavoriteProgression>> _getFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => FavoriteProgression.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading from local storage: $e');
      }
      return [];
    }
  }

  /// Save favorites to local storage
  static Future<void> _saveToLocalStorage(List<FavoriteProgression> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = favorites.map((f) => f.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  /// Add a new favorite
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

    String? id;
    
    // Try adding to Firebase first
    if (_useFirebase && AuthService.isSignedIn) {
      try {
        id = await FirestoreService.addFavorite(
          name: name,
          progression: progression,
          key: key,
          genre: genre,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error adding to Firebase: $e');
        }
      }
    }

    // Create favorite with Firebase ID or generate local ID
    final favorite = FavoriteProgression(
      id: id ?? IdGenerator.generate(),
      name: name.trim(),
      progression: progression,
      key: key,
      genre: genre,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    // Always save to local storage as backup
    favorites.insert(0, favorite);
    await _saveToLocalStorage(favorites);

    return favorite;
  }

  /// Update an existing favorite
  static Future<bool> updateFavorite(FavoriteProgression favorite) async {
    // Try updating in Firebase
    if (_useFirebase && AuthService.isSignedIn) {
      try {
        await FirestoreService.updateFavorite(
          favorite.id,
          name: favorite.name,
          progression: favorite.progression,
          key: favorite.key,
          genre: favorite.genre,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error updating in Firebase: $e');
        }
      }
    }

    // Update in local storage
    final favorites = await _getFromLocalStorage();
    final index = favorites.indexWhere((f) => f.id == favorite.id);
    if (index == -1) {
      return false;
    }

    favorites[index] = favorite.copyWith(
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _saveToLocalStorage(favorites);
    return true;
  }

  /// Remove a favorite
  static Future<bool> removeFavorite(String id) async {
    // Try removing from Firebase
    if (_useFirebase && AuthService.isSignedIn) {
      try {
        await FirestoreService.deleteFavorite(id);
      } catch (e) {
        if (kDebugMode) {
          print('Error removing from Firebase: $e');
        }
      }
    }

    // Remove from local storage
    final favorites = await _getFromLocalStorage();
    final initialLength = favorites.length;
    favorites.removeWhere((f) => f.id == id);
    
    if (favorites.length == initialLength) {
      return false;
    }

    await _saveToLocalStorage(favorites);
    return true;
  }

  /// Check if a progression is in favorites
  static Future<bool> isFavorite(List<Chord> progression) async {
    final favorites = await getFavorites();
    return favorites.any((f) => _progressionsMatch(f.progression, progression));
  }

  /// Sync local favorites to Firebase (useful after sign in)
  static Future<void> syncToFirebase() async {
    if (!AuthService.isSignedIn) return;

    try {
      final localFavorites = await _getFromLocalStorage();
      final firestoreFavorites = await FirestoreService.getFavorites();
      
      // Upload local favorites that aren't in Firebase
      for (final local in localFavorites) {
        final existsInFirestore = firestoreFavorites.any((f) => 
          _progressionsMatch(
            FavoriteProgression.fromFirestore(f).progression,
            local.progression,
          ),
        );
        
        if (!existsInFirestore) {
          await FirestoreService.addFavorite(
            name: local.name,
            progression: local.progression,
            key: local.key,
            genre: local.genre,
          );
        }
      }
      
      if (kDebugMode) {
        print('Favorites synced to Firebase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing to Firebase: $e');
      }
    }
  }

  /// Enable/disable Firebase usage
  static void setUseFirebase(bool value) {
    _useFirebase = value;
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
