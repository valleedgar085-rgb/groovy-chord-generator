// Groovy Chord Generator
// Firebase Authentication Service
// Version 2.5
//
// Handles user authentication with Firebase Auth.
// Supports anonymous login for quick access and optional email/password auth.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Authentication service for Firebase
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user
  static User? get currentUser => _auth.currentUser;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is signed in
  static bool get isSignedIn => _auth.currentUser != null;

  /// Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in anonymously (for quick access without account)
  /// This is perfect for music apps where users want to start creating immediately
  static Future<UserCredential?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      if (kDebugMode) {
        print('Signed in anonymously: ${userCredential.user?.uid}');
      }
      return userCredential;
    } catch (e) {
      if (kDebugMode) {
        print('Error signing in anonymously: $e');
      }
      return null;
    }
  }

  /// Sign in with email and password
  static Future<UserCredential?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (kDebugMode) {
        print('Signed in with email: ${userCredential.user?.email}');
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuth error: ${e.code} - ${e.message}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error signing in: $e');
      }
      return null;
    }
  }

  /// Create account with email and password
  static Future<UserCredential?> createAccountWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (kDebugMode) {
        print('Account created: ${userCredential.user?.email}');
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuth error: ${e.code} - ${e.message}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating account: $e');
      }
      return null;
    }
  }

  /// Sign out current user
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (kDebugMode) {
        print('User signed out');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
    }
  }

  /// Send password reset email
  static Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      if (kDebugMode) {
        print('Password reset email sent to: $email');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending password reset email: $e');
      }
      return false;
    }
  }

  /// Convert anonymous account to permanent account
  static Future<UserCredential?> linkAnonymousWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      final userCredential =
          await _auth.currentUser?.linkWithCredential(credential);
      if (kDebugMode) {
        print(
            'Anonymous account linked with email: ${userCredential?.user?.email}');
      }
      return userCredential;
    } catch (e) {
      if (kDebugMode) {
        print('Error linking anonymous account: $e');
      }
      return null;
    }
  }

  /// Delete current user account
  static Future<bool> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      if (kDebugMode) {
        print('User account deleted');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting account: $e');
      }
      return false;
    }
  }
}
