/// Groovy Chord Generator
/// Firebase Firestore Service
/// Version 2.5
/// 
/// Service for managing chord progressions and user data in Cloud Firestore.
/// Provides cloud storage and synchronization for favorites and user preferences.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/types.dart';
import '../models/constants.dart';
import 'auth_service.dart';

/// Firestore service for cloud data management
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  static const String _usersCollection = 'users';
  static const String _favoritesCollection = 'favorites';
  static const String _progressionsCollection = 'progressions';
  static const String _settingsCollection = 'settings';

  /// Get user's favorites collection reference
  static CollectionReference? _getUserFavoritesCollection() {
    final userId = AuthService.currentUserId;
    if (userId == null) return null;
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_favoritesCollection);
  }

  /// Get user's settings document reference
  static DocumentReference? _getUserSettingsDoc() {
    final userId = AuthService.currentUserId;
    if (userId == null) return null;
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_settingsCollection)
        .doc('preferences');
  }

  // ===================================
  // Favorites Management
  // ===================================

  /// Add a favorite progression to Firestore
  static Future<String?> addFavorite({
    required String name,
    required List<Chord> progression,
    required KeyName key,
    required GenreKey genre,
  }) async {
    try {
      final collection = _getUserFavoritesCollection();
      if (collection == null) {
        if (kDebugMode) {
          print('User not authenticated');
        }
        return null;
      }

      final docRef = await collection.add({
        'name': name.trim(),
        'progression': progression.map((c) => _chordToMap(c)).toList(),
        'key': key.name,
        'genre': genre.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('Favorite added with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding favorite: $e');
      }
      return null;
    }
  }

  /// Get all favorites for current user
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final collection = _getUserFavoritesCollection();
      if (collection == null) {
        if (kDebugMode) {
          print('User not authenticated');
        }
        return [];
      }

      final snapshot = await collection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting favorites: $e');
      }
      return [];
    }
  }

  /// Get favorites as a stream (real-time updates)
  static Stream<List<Map<String, dynamic>>>? getFavoritesStream() {
    final collection = _getUserFavoritesCollection();
    if (collection == null) return null;

    return collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  /// Update a favorite
  static Future<bool> updateFavorite(
    String id, {
    String? name,
    List<Chord>? progression,
    KeyName? key,
    GenreKey? genre,
  }) async {
    try {
      final collection = _getUserFavoritesCollection();
      if (collection == null) return false;

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name.trim();
      if (progression != null) {
        updateData['progression'] = progression.map((c) => _chordToMap(c)).toList();
      }
      if (key != null) updateData['key'] = key.name;
      if (genre != null) updateData['genre'] = genre.name;

      await collection.doc(id).update(updateData);

      if (kDebugMode) {
        print('Favorite updated: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating favorite: $e');
      }
      return false;
    }
  }

  /// Delete a favorite
  static Future<bool> deleteFavorite(String id) async {
    try {
      final collection = _getUserFavoritesCollection();
      if (collection == null) return false;

      await collection.doc(id).delete();

      if (kDebugMode) {
        print('Favorite deleted: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting favorite: $e');
      }
      return false;
    }
  }

  // ===================================
  // User Settings
  // ===================================

  /// Save user settings to Firestore
  static Future<bool> saveSettings(Map<String, dynamic> settings) async {
    try {
      final doc = _getUserSettingsDoc();
      if (doc == null) return false;

      await doc.set(settings, SetOptions(merge: true));

      if (kDebugMode) {
        print('Settings saved to Firestore');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving settings: $e');
      }
      return false;
    }
  }

  /// Load user settings from Firestore
  static Future<Map<String, dynamic>?> loadSettings() async {
    try {
      final doc = _getUserSettingsDoc();
      if (doc == null) return null;

      final snapshot = await doc.get();
      if (!snapshot.exists) return null;

      return snapshot.data() as Map<String, dynamic>?;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading settings: $e');
      }
      return null;
    }
  }

  // ===================================
  // Shared Progressions
  // ===================================

  /// Share a progression publicly (optional feature)
  static Future<String?> shareProgression({
    required String name,
    required List<Chord> progression,
    required KeyName key,
    required GenreKey genre,
    required int tempo,
  }) async {
    try {
      final docRef = await _firestore.collection(_progressionsCollection).add({
        'name': name.trim(),
        'progression': progression.map((c) => _chordToMap(c)).toList(),
        'key': key.name,
        'genre': genre.name,
        'tempo': tempo,
        'userId': AuthService.currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'plays': 0,
      });

      if (kDebugMode) {
        print('Progression shared with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing progression: $e');
      }
      return null;
    }
  }

  /// Get a shared progression by ID
  static Future<Map<String, dynamic>?> getSharedProgression(String id) async {
    try {
      final doc = await _firestore
          .collection(_progressionsCollection)
          .doc(id)
          .get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        ...data,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting shared progression: $e');
      }
      return null;
    }
  }

  // ===================================
  // Helper Methods
  // ===================================

  /// Convert Chord to Map for Firestore
  static Map<String, dynamic> _chordToMap(Chord chord) {
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

  /// Convert Map from Firestore to Chord
  static Chord mapToChord(Map<String, dynamic> map) {
    return Chord(
      root: map['root'] as String,
      type: ChordTypeName.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => ChordTypeName.major,
      ),
      degree: map['degree'] as String,
      numeral: map['numeral'] as String,
      isSecondaryDominant: map['isSecondaryDominant'] as bool? ?? false,
      isBorrowed: map['isBorrowed'] as bool? ?? false,
      isTritoneSubstitution: map['isTritoneSubstitution'] as bool? ?? false,
      borrowedDescription: map['borrowedDescription'] as String?,
      harmonyFunction: map['harmonyFunction'] != null
          ? HarmonyFunction.values.firstWhere(
              (h) => h.name == map['harmonyFunction'],
              orElse: () => HarmonyFunction.tonic,
            )
          : null,
    );
  }
}
