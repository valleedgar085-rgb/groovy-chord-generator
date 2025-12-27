/// Groovy Chord Generator
/// Firebase Service
/// Version 2.5
/// 
/// Core Firebase initialization and configuration service.
/// This service handles all Firebase setup and provides a centralized
/// point for Firebase functionality.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase initialization and configuration service
class FirebaseService {
  static bool _initialized = false;

  /// Initialize Firebase with the app
  /// Call this once during app startup
  static Future<void> initialize() async {
    if (_initialized) {
      if (kDebugMode) {
        print('Firebase already initialized');
      }
      return;
    }

    try {
      await Firebase.initializeApp(
        options: _getFirebaseOptions(),
      );
      _initialized = true;
      if (kDebugMode) {
        print('Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase: $e');
      }
      rethrow;
    }
  }

  /// Get Firebase options based on platform
  /// These should be replaced with your actual Firebase project credentials
  static FirebaseOptions _getFirebaseOptions() {
    if (kIsWeb) {
      // Web configuration
      return const FirebaseOptions(
        apiKey: 'YOUR_WEB_API_KEY',
        appId: '1:YOUR_PROJECT_NUMBER:web:YOUR_WEB_APP_ID',
        messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
        projectId: 'YOUR_PROJECT_ID',
        authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
        storageBucket: 'YOUR_PROJECT_ID.appspot.com',
        measurementId: 'G-YOUR_MEASUREMENT_ID',
      );
    } else {
      // Android/iOS configuration
      // Note: For Android, you should also add google-services.json to android/app/
      // For iOS, add GoogleService-Info.plist to ios/Runner/
      return const FirebaseOptions(
        apiKey: 'YOUR_MOBILE_API_KEY',
        appId: '1:YOUR_PROJECT_NUMBER:android:YOUR_ANDROID_APP_ID',
        messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
        projectId: 'YOUR_PROJECT_ID',
        storageBucket: 'YOUR_PROJECT_ID.appspot.com',
      );
    }
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _initialized;
}
