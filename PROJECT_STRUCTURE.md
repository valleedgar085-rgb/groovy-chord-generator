# Groovy Chord Generator - Project Structure for Firebase

## Overview

This document outlines the complete project structure for the Groovy Chord Generator app, optimized for Firebase deployment. The app is built with Flutter and uses Firebase for cloud storage, authentication, and real-time synchronization.

## Architecture

The app follows a clean, layered architecture:

```
├── Presentation Layer (UI)
│   ├── Screens
│   └── Widgets
├── Business Logic Layer
│   └── Providers (State Management)
├── Data Layer
│   ├── Models
│   ├── Services
│   └── Utilities
```

## Complete File Structure

```
groovy-chord-generator/
├── lib/
│   ├── main.dart                      # App entry point with Firebase initialization
│   │
│   ├── models/                        # Data models and type definitions
│   │   ├── types.dart                 # Core data types (Chord, BassNote, etc.)
│   │   └── constants.dart             # App constants and music theory data
│   │
│   ├── providers/                     # State management
│   │   └── app_state.dart             # Main app state with Provider
│   │
│   ├── screens/                       # Main app screens
│   │   ├── home_screen.dart           # Main container screen
│   │   ├── generator_tab.dart         # Chord progression generator
│   │   ├── editor_tab.dart            # Piano roll editor
│   │   ├── bass_tab.dart              # Bass line generator
│   │   └── settings_tab.dart          # App settings
│   │
│   ├── widgets/                       # Reusable UI components
│   │   ├── header.dart                # App header
│   │   ├── bottom_navigation.dart     # Bottom navigation bar
│   │   ├── fab_menu.dart              # Floating action button menu
│   │   ├── chord_card.dart            # Chord display card
│   │   ├── preset_card.dart           # Preset selection card
│   │   ├── control_dropdown.dart      # Dropdown control widget
│   │   └── collapsible_section.dart   # Collapsible section widget
│   │
│   ├── services/                      # Business logic services
│   │   ├── firebase_service.dart      # Firebase initialization
│   │   ├── auth_service.dart          # Firebase Authentication
│   │   ├── firestore_service.dart     # Cloud Firestore operations
│   │   ├── firebase_favorites_service.dart  # Firebase-enabled favorites
│   │   ├── favorites_service.dart     # Original local favorites (legacy)
│   │   └── share_service.dart         # URL sharing functionality
│   │
│   ├── utilities/                     # Helper utilities
│   │   ├── helpers.dart               # General helper functions
│   │   └── validators.dart            # Input validation
│   │
│   └── utils/                         # Core utilities
│       ├── theme.dart                 # App theming and colors
│       └── music_theory.dart          # Music theory algorithms
│
├── android/                           # Android platform files
│   ├── app/
│   │   ├── google-services.json       # Firebase Android config (add this)
│   │   └── build.gradle               # Android app build config
│   └── build.gradle                   # Android project build config
│
├── ios/                               # iOS platform files
│   ├── Runner/
│   │   └── GoogleService-Info.plist   # Firebase iOS config (add this)
│   └── Podfile                        # iOS dependencies
│
├── web/                               # Web platform files
│   ├── index.html                     # Web entry point
│   └── assets/                        # Web assets
│
├── screenshots/                       # App screenshots
│
├── pubspec.yaml                       # Flutter dependencies
├── analysis_options.yaml              # Dart analysis config
├── README.md                          # Project README
├── FIREBASE_SETUP.md                  # Firebase setup guide
└── PROJECT_STRUCTURE.md               # This file

```

## Key Components

### 1. Entry Point (main.dart)

**Purpose**: Initialize Flutter app, Firebase, and authentication

**Key Functions**:
- Initialize Firebase using `FirebaseService`
- Sign in anonymously for immediate access
- Set up Provider for state management
- Launch the app

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  await AuthService.signInAnonymously();
  runApp(const GroovyChordGeneratorApp());
}
```

### 2. Models Layer

#### types.dart
Defines core data structures:
- `Chord`: Chord information (root, type, degree)
- `BassNote`: Bass line notes
- `MelodyNote`: Melody notes
- Enums: `KeyName`, `GenreKey`, `ComplexityLevel`, etc.

#### constants.dart
Contains:
- Genre profiles with music theory data
- Preset configurations
- Default values
- Music theory constants

### 3. Services Layer

#### firebase_service.dart
**Purpose**: Core Firebase initialization

**Features**:
- Initialize Firebase with platform-specific config
- Support for Web, Android, and iOS
- Configuration management

#### auth_service.dart
**Purpose**: User authentication

**Features**:
- Anonymous authentication (immediate access)
- Email/password authentication
- Account management (create, delete, password reset)
- Auth state monitoring

#### firestore_service.dart
**Purpose**: Cloud Firestore operations

**Features**:
- CRUD operations for favorites
- User settings storage
- Shared progressions (public sharing)
- Real-time data streams

#### firebase_favorites_service.dart
**Purpose**: Enhanced favorites with cloud sync

**Features**:
- Cloud storage via Firestore
- Local storage fallback (offline support)
- Automatic sync when online
- Backward compatible with original service

#### share_service.dart
**Purpose**: Share chord progressions

**Features**:
- Generate shareable URLs
- Generate compact share codes
- Parse shared data

### 4. Providers Layer

#### app_state.dart
**Purpose**: Centralized app state management

**Manages**:
- Current progression
- User preferences
- Playback state
- Favorites list
- History
- Settings

**Key Methods**:
- `generateProgression()`: Create new chord progressions
- `addToFavorites()`: Save progressions
- `loadFavorite()`: Load saved progressions
- `applyPreset()`: Apply genre presets

### 5. Screens Layer

#### generator_tab.dart
- Main chord progression generator
- Genre and key selection
- Complexity controls
- Generate, spice up, and lock chords

#### editor_tab.dart
- Piano roll editor for fine-tuning
- Visual chord editing
- MIDI-style interface

#### bass_tab.dart
- Bass line generator
- Multiple bass styles (walking, syncopated, root)
- Bass variety controls

#### settings_tab.dart
- App preferences
- Audio settings
- Display options
- About information

### 6. Widgets Layer

Reusable UI components:
- `chord_card.dart`: Display individual chords with animations
- `preset_card.dart`: Genre preset selection cards
- `fab_menu.dart`: Floating action button with menu
- `collapsible_section.dart`: Expandable sections
- `control_dropdown.dart`: Custom dropdown controls

### 7. Utils Layer

#### theme.dart
**Defines**:
- Color palette
- Typography
- Dark theme configuration
- Chord type colors
- Gradients and shadows

#### music_theory.dart
**Implements**:
- Chord generation algorithms
- Voice leading
- Modal interchange
- Advanced substitutions
- Bass line generation
- Scale and interval calculations

## Data Flow

### Creating a Chord Progression

```
User Input
    ↓
AppState.generateProgression()
    ↓
MusicTheory algorithms
    ↓
Chord list created
    ↓
UI updates (notifyListeners)
    ↓
Chord cards display
```

### Saving a Favorite

```
User taps "Add to Favorites"
    ↓
AppState.addToFavorites()
    ↓
FirebaseFavoritesService.addFavorite()
    ↓
┌─────────────┬──────────────┐
│             │              │
Firestore     Local Storage
(cloud)       (backup)
    │             │
    └─────┬───────┘
          ↓
    Favorites list updated
          ↓
    UI refreshes
```

### Authentication Flow

```
App Starts
    ↓
FirebaseService.initialize()
    ↓
AuthService.signInAnonymously()
    ↓
User gets anonymous ID
    ↓
Can use app immediately
    ↓
Optional: Convert to email/password
```

## Firebase Collections Structure

### Firestore Database

```
firestore/
├── users/                         # User-specific data
│   └── {userId}/
│       ├── favorites/             # User's saved progressions
│       │   └── {favoriteId}
│       │       ├── name
│       │       ├── progression[]
│       │       ├── key
│       │       ├── genre
│       │       ├── createdAt
│       │       └── updatedAt
│       │
│       └── settings/              # User preferences
│           └── preferences
│               ├── masterVolume
│               ├── soundType
│               ├── showNumerals
│               └── ... other settings
│
└── progressions/                  # Public shared progressions
    └── {progressionId}
        ├── name
        ├── progression[]
        ├── key
        ├── genre
        ├── tempo
        ├── userId
        ├── createdAt
        ├── likes
        └── plays
```

## State Management

The app uses the **Provider** pattern for state management:

```dart
// In main.dart
ChangeNotifierProvider(
  create: (_) => AppState(),
  child: MaterialApp(...),
)

// In any widget
final appState = Provider.of<AppState>(context);
appState.generateProgression();

// Or using Consumer
Consumer<AppState>(
  builder: (context, appState, child) {
    return Text(appState.currentKey.name);
  },
)
```

## Offline Support

The app maintains functionality offline:

1. **Local Storage**: SharedPreferences stores favorites locally
2. **Automatic Sync**: When online, syncs with Firestore
3. **Fallback Logic**: If Firebase unavailable, uses local storage
4. **Seamless UX**: Users don't notice offline/online transitions

## Build Process

### Development

```bash
# Get dependencies
flutter pub get

# Run on device
flutter run

# Run web version
flutter run -d chrome
```

### Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Security Considerations

### Firestore Security Rules

```javascript
// Only allow users to access their own data
match /users/{userId}/{document=**} {
  allow read, write: if request.auth.uid == userId;
}

// Public progressions readable by all
match /progressions/{progression} {
  allow read: if true;
  allow write: if request.auth != null;
}
```

### API Keys

- Keep Firebase config files secure
- Don't commit sensitive keys to public repos
- Use environment variables for production

## Testing Strategy

1. **Unit Tests**: Test music theory algorithms
2. **Widget Tests**: Test UI components
3. **Integration Tests**: Test Firebase integration
4. **Manual Testing**: Test on real devices

## Performance Optimization

1. **Lazy Loading**: Load favorites on demand
2. **Caching**: Cache frequently accessed data
3. **Indexed Queries**: Use Firestore indexes for complex queries
4. **Image Optimization**: Optimize any images/assets
5. **Code Splitting**: Split large files if needed

## Deployment Checklist

- [ ] Firebase project created
- [ ] All platform configs added (google-services.json, etc.)
- [ ] Firestore security rules configured
- [ ] Authentication methods enabled
- [ ] Tested on all target platforms
- [ ] App icons and splash screens configured
- [ ] Privacy policy and terms of service created
- [ ] Analytics configured
- [ ] Crash reporting enabled
- [ ] App store listings prepared

## Future Enhancements

Consider adding:
- **Cloud Functions**: Server-side logic
- **Cloud Storage**: Store audio samples
- **Remote Config**: Dynamic app configuration
- **Push Notifications**: Share and collaborate features
- **ML Kit**: AI-powered chord suggestions
- **Social Features**: User profiles and sharing

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)

---

**Last Updated**: December 2024
**Version**: 2.5
**Author**: Edgar Valle
