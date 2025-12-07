# Firebase Setup Guide for Groovy Chord Generator

This guide will help you set up Firebase for the Groovy Chord Generator app, enabling cloud storage, user authentication, and real-time synchronization.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Firebase Project Setup](#firebase-project-setup)
3. [Android Configuration](#android-configuration)
4. [iOS Configuration](#ios-configuration)
5. [Web Configuration](#web-configuration)
6. [Firestore Database Setup](#firestore-database-setup)
7. [Authentication Setup](#authentication-setup)
8. [Testing](#testing)

## Prerequisites

- Flutter SDK 3.0 or higher installed
- A Google account
- Android Studio / Xcode (for mobile development)
- Node.js (for Firebase CLI)

## Firebase Project Setup

### 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `groovy-chord-generator` (or your preferred name)
4. Optional: Enable Google Analytics
5. Click "Create project"

### 2. Install Firebase CLI

```bash
npm install -g firebase-tools
```

### 3. Login to Firebase

```bash
firebase login
```

### 4. Initialize FlutterFire

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Run FlutterFire configuration
flutterfire configure
```

This will automatically:
- Create/update Firebase configuration files
- Register your apps with Firebase
- Download necessary configuration files

## Android Configuration

### 1. Add google-services.json

The `flutterfire configure` command should have created this file. If not:

1. In Firebase Console, go to Project Settings
2. Click on the Android app (or add one if it doesn't exist)
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

### 2. Update android/build.gradle

Add Google services to your project-level `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        // ... other dependencies
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

### 3. Update android/app/build.gradle

Apply the Google services plugin at the bottom of `android/app/build.gradle`:

```gradle
// At the bottom of the file
apply plugin: 'com.google.gms.google-services'
```

### 4. Set minimum SDK version

Ensure `android/app/build.gradle` has minimum SDK 21:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
        // ... other config
    }
}
```

## iOS Configuration

### 1. Add GoogleService-Info.plist

The `flutterfire configure` command should have created this file. If not:

1. In Firebase Console, go to Project Settings
2. Click on the iOS app (or add one if it doesn't exist)
3. Download `GoogleService-Info.plist`
4. Place it in: `ios/Runner/GoogleService-Info.plist`

### 2. Update iOS Deployment Target

Ensure `ios/Podfile` has minimum iOS version 12.0:

```ruby
platform :ios, '12.0'
```

### 3. Install iOS dependencies

```bash
cd ios
pod install
cd ..
```

## Web Configuration

### 1. Get Web Configuration

1. In Firebase Console, go to Project Settings
2. Scroll to "Your apps" section
3. Click on the Web app (or add one)
4. Copy the Firebase configuration

### 2. Update lib/services/firebase_service.dart

Replace the placeholder values in `_getFirebaseOptions()` with your actual Firebase configuration:

```dart
static FirebaseOptions _getFirebaseOptions() {
  if (kIsWeb) {
    return const FirebaseOptions(
      apiKey: 'YOUR_WEB_API_KEY',              // From Firebase Console
      appId: 'YOUR_WEB_APP_ID',                // From Firebase Console
      messagingSenderId: 'YOUR_SENDER_ID',     // From Firebase Console
      projectId: 'your-project-id',            // From Firebase Console
      authDomain: 'your-project.firebaseapp.com',
      storageBucket: 'your-project.appspot.com',
      measurementId: 'G-XXXXX',                // From Firebase Console
    );
  } else {
    // Mobile configuration
    return const FirebaseOptions(
      apiKey: 'YOUR_MOBILE_API_KEY',           // From Firebase Console
      appId: 'YOUR_MOBILE_APP_ID',             // From Firebase Console
      messagingSenderId: 'YOUR_SENDER_ID',     // From Firebase Console
      projectId: 'your-project-id',            // From Firebase Console
      storageBucket: 'your-project.appspot.com',
    );
  }
}
```

## Firestore Database Setup

### 1. Create Firestore Database

1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location (choose closest to your users)
5. Click "Enable"

### 2. Set Up Security Rules

For **development**, use these rules (located in Firebase Console > Firestore > Rules):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow anyone to read shared progressions
    match /progressions/{progression} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

For **production**, tighten these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User data - only owner can access
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Shared progressions - authenticated users can write
    match /progressions/{progression} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
  }
}
```

### 3. Create Indexes (Optional)

If you need custom queries, create indexes:

1. Go to Firestore > Indexes
2. Add composite indexes as needed (Firebase will suggest these when queries fail)

## Authentication Setup

### 1. Enable Authentication Methods

1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Anonymous" authentication (for quick access)
5. Optionally enable "Email/Password" authentication

### 2. Configure Email Templates (Optional)

If using email/password auth:
1. Go to Authentication > Templates
2. Customize email verification and password reset templates

## Testing

### 1. Test Installation

```bash
flutter clean
flutter pub get
```

### 2. Run on Android

```bash
flutter run -d android
```

### 3. Run on iOS

```bash
flutter run -d ios
```

### 4. Run on Web

```bash
flutter run -d chrome
```

### 5. Verify Firebase Connection

Check the console output for:
```
Firebase initialized successfully
Signed in anonymously: [user-id]
```

### 6. Test Firestore

1. Open the app
2. Generate a chord progression
3. Add it to favorites
4. Check Firebase Console > Firestore Database
5. You should see the data under: `users/{userId}/favorites/`

## Data Structure

The app uses the following Firestore structure:

```
/users/{userId}/
  /favorites/{favoriteId}
    - name: string
    - progression: array
    - key: string
    - genre: string
    - createdAt: timestamp
    - updatedAt: timestamp
  
  /settings/preferences
    - various app settings

/progressions/{progressionId}
  - name: string
  - progression: array
  - key: string
  - genre: string
  - tempo: number
  - userId: string
  - createdAt: timestamp
  - likes: number
  - plays: number
```

## Troubleshooting

### Android Build Issues

**Error: "Could not find com.google.gms:google-services"**
- Ensure `google-services.json` is in `android/app/`
- Verify Google services plugin is added to gradle files

**Error: "Default FirebaseApp is not initialized"**
- Check that `google-services.json` is correctly placed
- Ensure FlutterFire configuration matches your package name

### iOS Build Issues

**Error: "FirebaseCore not found"**
- Run `cd ios && pod install && cd ..`
- Clean and rebuild: `flutter clean && flutter pub get`

**Error: "GoogleService-Info.plist not found"**
- Ensure file is in `ios/Runner/`
- Add it through Xcode: Right-click Runner > Add Files

### Web Issues

**Error: "Firebase not initialized"**
- Verify Firebase config in `firebase_service.dart`
- Check browser console for specific errors

### Firestore Permission Denied

**Error: "Missing or insufficient permissions"**
- Check Firestore security rules
- Ensure user is authenticated (check Auth state)
- Verify rules match your data structure

## Best Practices

1. **Security**: Always use proper Firestore security rules in production
2. **Offline Support**: The app maintains local storage as backup
3. **Anonymous Auth**: Users can start immediately, upgrade to email/password later
4. **Data Limits**: Set reasonable limits (e.g., max 50 favorites per user)
5. **Cost Management**: Monitor Firestore usage in Firebase Console

## Additional Features to Consider

1. **Cloud Storage**: Store audio files or custom sounds
2. **Analytics**: Track user behavior and popular chord progressions
3. **Cloud Functions**: Server-side processing (e.g., progression recommendations)
4. **Remote Config**: Dynamic app configuration without updates
5. **FCM**: Push notifications for sharing and collaboration

## Support

For more information:
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Documentation](https://flutter.dev/docs)

## Next Steps

After completing this setup:
1. Build and test on all target platforms
2. Verify Firestore data synchronization
3. Test offline functionality
4. Set up production security rules
5. Configure app for release (obfuscation, minification)
6. Submit to app stores

---

**Important**: Remember to keep your Firebase configuration files secure and never commit them to public repositories if they contain sensitive information.
