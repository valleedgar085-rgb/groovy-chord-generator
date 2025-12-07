# Architecture Diagrams - Groovy Chord Generator

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Interface                           │
│  ┌──────────────┬──────────────┬──────────────┬──────────────┐ │
│  │  Generator   │    Editor    │     Bass     │   Settings   │ │
│  │     Tab      │     Tab      │     Tab      │     Tab      │ │
│  └──────────────┴──────────────┴──────────────┴──────────────┘ │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                     Widgets Layer                            ││
│  │  ChordCard │ PresetCard │ FABMenu │ CollapsibleSection      ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      State Management                            │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                   AppState (Provider)                        ││
│  │  • Current progression    • Favorites list                   ││
│  │  • User preferences       • Playback state                   ││
│  │  • Generate/Edit methods  • Settings                         ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Services Layer                              │
│  ┌────────────────┬──────────────────┬────────────────────────┐│
│  │   Firebase     │   Firestore      │   Auth Service         ││
│  │   Service      │   Service        │   • Anonymous auth     ││
│  │   • Init       │   • CRUD ops     │   • Email/password     ││
│  │   • Config     │   • Real-time    │   • Account mgmt       ││
│  └────────────────┴──────────────────┴────────────────────────┘│
│  ┌────────────────┬──────────────────┬────────────────────────┐│
│  │   Favorites    │   Share          │   Music Theory         ││
│  │   Service      │   Service        │   • Chord generation   ││
│  │   • Cloud sync │   • URL sharing  │   • Voice leading      ││
│  │   • Local cache│   • Share codes  │   • Modal interchange  ││
│  └────────────────┴──────────────────┴────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Data Layer                                  │
│  ┌────────────────────────────┬──────────────────────────────┐ │
│  │     Cloud (Firebase)       │     Local (Device)           │ │
│  │  ┌──────────────────────┐  │  ┌────────────────────────┐ │ │
│  │  │  Cloud Firestore     │  │  │  SharedPreferences     │ │ │
│  │  │  • users/{uid}/      │  │  │  • Cached favorites    │ │ │
│  │  │    favorites/        │  │  │  • App settings        │ │ │
│  │  │  • progressions/     │  │  │  • Offline data        │ │ │
│  │  └──────────────────────┘  │  └────────────────────────┘ │ │
│  │  ┌──────────────────────┐  │                              │ │
│  │  │  Authentication      │  │                              │ │
│  │  │  • Anonymous users   │  │                              │ │
│  │  │  • Email/password    │  │                              │ │
│  │  └──────────────────────┘  │                              │ │
│  └────────────────────────────┴──────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow: Creating and Saving a Progression

```
┌─────────────┐
│    User     │
│  taps       │
│ "Generate"  │
└──────┬──────┘
       │
       ↓
┌──────────────────────────────────────────────────────────┐
│  AppState.generateProgression()                          │
│  1. Get current settings (key, genre, complexity)        │
│  2. Build degree sequence                                │
│  3. Apply music theory algorithms                        │
│  4. Apply voice leading (if enabled)                     │
│  5. Apply spice and groove                               │
└──────┬───────────────────────────────────────────────────┘
       │
       ↓
┌──────────────────────────────────────────────────────────┐
│  MusicTheory.getChordFromDegree()                        │
│  • Parse key and scale                                   │
│  • Calculate intervals                                   │
│  • Apply chord types                                     │
│  • Return Chord objects                                  │
└──────┬───────────────────────────────────────────────────┘
       │
       ↓
┌──────────────────────────────────────────────────────────┐
│  AppState updates _currentProgression                     │
│  notifyListeners() → UI rebuilds                         │
└──────┬───────────────────────────────────────────────────┘
       │
       ↓
┌──────────────────────────────────────────────────────────┐
│  User sees new chord progression                         │
│  Taps heart icon to save as favorite                     │
└──────┬───────────────────────────────────────────────────┘
       │
       ↓
┌──────────────────────────────────────────────────────────┐
│  AppState.addToFavorites(name)                           │
└──────┬───────────────────────────────────────────────────┘
       │
       ↓
┌──────────────────────────────────────────────────────────┐
│  FirebaseFavoritesService.addFavorite()                  │
│  ┌──────────────────┬────────────────────────────────┐  │
│  │  Try Firebase    │  Save to Local Storage        │  │
│  │  (if online)     │  (always, as backup)          │  │
│  └────┬─────────────┴─────────┬──────────────────────┘  │
└───────┼───────────────────────┼──────────────────────────┘
        │                       │
        ↓                       ↓
┌──────────────────┐   ┌──────────────────────┐
│  Firestore       │   │  SharedPreferences   │
│  users/{uid}/    │   │  Encoded JSON        │
│  favorites/      │   │  in local storage    │
│  {favoriteId}    │   │                      │
└────────┬─────────┘   └──────────┬───────────┘
         │                        │
         └────────────┬───────────┘
                      │
                      ↓
        ┌─────────────────────────┐
        │  Data saved!            │
        │  notifyListeners()      │
        │  UI updates with ❤️     │
        └─────────────────────────┘
```

## Authentication Flow

```
┌────────────────┐
│  App Starts    │
└───────┬────────┘
        │
        ↓
┌──────────────────────────────────────────┐
│  main() → FirebaseService.initialize()   │
└───────┬──────────────────────────────────┘
        │
        ↓
┌──────────────────────────────────────────┐
│  Firebase.initializeApp()                │
│  • Load configuration                    │
│  • Connect to Firebase services          │
└───────┬──────────────────────────────────┘
        │
        ↓
┌──────────────────────────────────────────┐
│  AuthService.signInAnonymously()         │
│  • Create anonymous user                 │
│  • Get user ID (UID)                     │
└───────┬──────────────────────────────────┘
        │
        ↓
┌──────────────────────────────────────────┐
│  User authenticated!                     │
│  • Can now use Firestore                │
│  • Data tied to user ID                 │
│  • No login UI required                  │
└───────┬──────────────────────────────────┘
        │
        ↓
┌──────────────────────────────────────────┐
│  Optional: Convert to permanent account  │
│  AuthService.linkAnonymousWithEmail()    │
│  • User provides email/password          │
│  • Anonymous account → permanent account │
│  • All data preserved                    │
└──────────────────────────────────────────┘
```

## Offline/Online Sync Flow

```
         ┌─────────────────────┐
         │   App State         │
         │   (User Action)     │
         └──────────┬──────────┘
                    │
                    ↓
         ┌─────────────────────┐
         │ Check: Is online?   │
         └──────┬──────┬───────┘
                │      │
        Online  │      │  Offline
                │      │
       ┌────────↓      ↓─────────┐
       │                          │
       ↓                          ↓
┌──────────────┐          ┌──────────────┐
│  Firebase    │          │   Local      │
│  Firestore   │          │   Storage    │
│              │          │              │
│ • Save data  │          │ • Save data  │
│ • Real-time  │          │ • Queue sync │
│   sync       │          │              │
└──────┬───────┘          └──────┬───────┘
       │                         │
       │  When back online       │
       │  ←────────────────────  │
       │                         │
       ↓                         ↓
┌──────────────────────────────────┐
│  Automatic Sync                  │
│  • Upload queued changes         │
│  • Download remote changes       │
│  • Merge if needed               │
│  • Update local cache            │
└──────┬───────────────────────────┘
       │
       ↓
┌──────────────────────────────────┐
│  Data consistent across devices  │
└──────────────────────────────────┘
```

## Firestore Data Structure

```
Cloud Firestore
│
├── users/                                  (Collection)
│   │
│   ├── {userId-1}/                        (Document)
│   │   │
│   │   ├── favorites/                     (Sub-collection)
│   │   │   │
│   │   │   ├── {favoriteId-1}/           (Document)
│   │   │   │   ├── name: "My Jazz Progression"
│   │   │   │   ├── progression: [
│   │   │   │   │     {root: "C", type: "maj7", ...},
│   │   │   │   │     {root: "A", type: "min7", ...},
│   │   │   │   │     ...
│   │   │   │   │   ]
│   │   │   │   ├── key: "C"
│   │   │   │   ├── genre: "jazzFusion"
│   │   │   │   ├── createdAt: Timestamp
│   │   │   │   └── updatedAt: Timestamp
│   │   │   │
│   │   │   └── {favoriteId-2}/           (Document)
│   │   │       └── ... (same structure)
│   │   │
│   │   └── settings/                     (Sub-collection)
│   │       │
│   │       └── preferences/              (Document)
│   │           ├── masterVolume: 0.7
│   │           ├── soundType: "piano"
│   │           ├── showNumerals: true
│   │           └── ... (other settings)
│   │
│   └── {userId-2}/                       (Document)
│       └── ... (same structure)
│
└── progressions/                         (Collection - Shared)
    │
    ├── {progressionId-1}/                (Document)
    │   ├── name: "Cool EDM Progression"
    │   ├── progression: [...]
    │   ├── key: "Am"
    │   ├── genre: "edm"
    │   ├── tempo: 128
    │   ├── userId: "user-xyz"
    │   ├── createdAt: Timestamp
    │   ├── likes: 42
    │   └── plays: 156
    │
    └── {progressionId-2}/                (Document)
        └── ... (same structure)
```

## Security Rules Flow

```
┌────────────────┐
│  User Request  │
│  (Read/Write)  │
└───────┬────────┘
        │
        ↓
┌────────────────────────────────────────┐
│  Firestore Security Rules              │
│                                        │
│  1. Check: Is user authenticated?      │
│     request.auth != null               │
│                                        │
│  2. Check: Is this user's data?        │
│     request.auth.uid == userId         │
│                                        │
│  3. Check: Is data valid?              │
│     request.resource.data.name is str  │
│     progression.size() <= 32           │
│                                        │
│  4. Decide: Allow or Deny              │
└────────┬───────────────────────────────┘
         │
         ↓
    ┌────┴────┐
    │         │
    ↓         ↓
┌───────┐ ┌───────┐
│ Allow │ │ Deny  │
└───────┘ └───────┘
```

## Multi-Platform Support

```
┌─────────────────────────────────────────────────────────┐
│              Groovy Chord Generator App                  │
│                  (Flutter Code)                          │
└───────┬──────────────────┬──────────────────┬───────────┘
        │                  │                  │
        ↓                  ↓                  ↓
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│   Android     │  │      iOS      │  │      Web      │
├───────────────┤  ├───────────────┤  ├───────────────┤
│ • APK/AAB     │  │ • IPA         │  │ • HTML/JS/CSS │
│ • Play Store  │  │ • App Store   │  │ • Firebase    │
│ • google-     │  │ • GoogleServ  │  │   Hosting     │
│   services    │  │   ice-Info    │  │ • Any web     │
│   .json       │  │   .plist      │  │   server      │
└───────┬───────┘  └───────┬───────┘  └───────┬───────┘
        │                  │                  │
        └──────────────────┴──────────────────┘
                          │
                          ↓
            ┌──────────────────────────┐
            │    Firebase Backend      │
            │  • Firestore Database    │
            │  • Authentication        │
            │  • Analytics             │
            │  • Storage (future)      │
            └──────────────────────────┘
```

## Development to Production Pipeline

```
┌──────────────┐
│  Development │
│  Environment │
└──────┬───────┘
       │
       ↓
┌─────────────────────────────────────┐
│  Local Testing                      │
│  • flutter run                      │
│  • Hot reload/restart               │
│  • Debug mode                       │
│  • Test Firebase (test mode rules) │
└──────┬──────────────────────────────┘
       │
       ↓
┌─────────────────────────────────────┐
│  Code Review & Testing              │
│  • Unit tests                       │
│  • Integration tests                │
│  • UI tests                         │
│  • Code quality checks              │
└──────┬──────────────────────────────┘
       │
       ↓
┌─────────────────────────────────────┐
│  Build for Production               │
│  • flutter build apk --release      │
│  • flutter build ios --release      │
│  • flutter build web --release      │
│  • Minification & obfuscation       │
└──────┬──────────────────────────────┘
       │
       ↓
┌─────────────────────────────────────┐
│  Production Firebase Setup          │
│  • Update security rules            │
│  • Configure indexes                │
│  • Set up monitoring                │
│  • Enable production auth           │
└──────┬──────────────────────────────┘
       │
       ↓
┌─────────────────────────────────────┐
│  Deploy to App Stores/Web           │
│  • Google Play Store                │
│  • Apple App Store                  │
│  • Firebase Hosting / Custom domain │
└──────┬──────────────────────────────┘
       │
       ↓
┌─────────────────────────────────────┐
│  Monitor & Maintain                 │
│  • Analytics dashboard              │
│  • Crash reporting                  │
│  • User feedback                    │
│  • Performance monitoring           │
└─────────────────────────────────────┘
```

## Architecture Principles

### 1. Separation of Concerns
- **UI Layer**: Screens and widgets (presentation)
- **Business Logic**: Providers and services
- **Data Layer**: Firebase and local storage

### 2. Offline-First
- Local storage as primary cache
- Firebase for synchronization
- Seamless online/offline transitions

### 3. Security
- User-specific data access
- Firestore security rules
- Authentication required for writes

### 4. Scalability
- Firebase handles infrastructure
- Automatic scaling with users
- Indexed queries for performance

### 5. Maintainability
- Clear file structure
- Comprehensive documentation
- Modular services
- Type-safe code

## Performance Considerations

```
┌─────────────────────────────────────────────────────────┐
│                   Performance Strategy                   │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. Data Loading                                         │
│     • Lazy load favorites                               │
│     • Pagination for large lists                        │
│     • Cache frequently accessed data                    │
│                                                          │
│  2. Firestore Optimization                              │
│     • Indexed queries                                   │
│     • Batch operations                                  │
│     • Limit query results                               │
│     • Use real-time updates selectively                 │
│                                                          │
│  3. UI Performance                                       │
│     • Efficient widget rebuilds                         │
│     • Const constructors where possible                 │
│     • ListView.builder for long lists                   │
│     • Optimized animations                              │
│                                                          │
│  4. Network Efficiency                                   │
│     • Compress data when possible                       │
│     • Minimize API calls                                │
│     • Cache responses                                   │
│     • Batch updates                                     │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

**These diagrams provide a complete visual understanding of the app's architecture, data flow, and Firebase integration.**
