# Quick Start Guide - Groovy Chord Generator with Firebase

This guide will get you up and running with the Groovy Chord Generator app in minutes.

## Prerequisites

✅ Flutter SDK 3.0+ installed  
✅ Android Studio or VS Code with Flutter extensions  
✅ Google account (for Firebase)  
✅ 15-20 minutes of your time

## Step 1: Clone and Setup (2 minutes)

```bash
# Clone the repository
git clone https://github.com/valleedgar085-rgb/groovy-chord-generator.git
cd groovy-chord-generator

# Get Flutter dependencies
flutter pub get
```

## Step 2: Firebase Setup (10 minutes)

### Option A: Use FlutterFire CLI (Recommended)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Configure Firebase for your project
flutterfire configure
```

This will:
- Create a Firebase project (or use existing)
- Register your app
- Download configuration files
- Set up everything automatically

### Option B: Manual Setup

See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for detailed manual setup instructions.

## Step 3: Enable Firebase Services (5 minutes)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Enable these services:

### Firestore Database
- Click "Firestore Database" > "Create database"
- Choose "Start in test mode"
- Select your region
- Click "Enable"

### Authentication
- Click "Authentication" > "Get started"
- Click "Sign-in method"
- Enable "Anonymous" (for immediate user access)
- Optionally enable "Email/Password"

## Step 4: Update Configuration (2 minutes)

If you used FlutterFire CLI, skip this step. Otherwise:

1. Open `lib/services/firebase_service.dart`
2. Replace placeholder values in `_getFirebaseOptions()` with your Firebase config

## Step 5: Run the App (1 minute)

```bash
# Run on Android device/emulator
flutter run -d android

# Run on iOS device/simulator
flutter run -d ios

# Run on Web
flutter run -d chrome
```

## Verify Everything Works

1. **App Launches**: Check that the app opens without errors
2. **Firebase Connected**: Look for console message: "Firebase initialized successfully"
3. **Authentication**: Check for: "Signed in anonymously: [user-id]"
4. **Generate Chords**: Tap "Generate" to create a chord progression
5. **Save Favorite**: Tap the heart icon to save to favorites
6. **Check Firestore**: Go to Firebase Console > Firestore Database
   - You should see: `users/{userId}/favorites/`

## Common Issues

### "Firebase not initialized"
**Solution**: Run `flutterfire configure` or check your configuration files

### "google-services.json not found"
**Solution**: Ensure `google-services.json` is in `android/app/` directory

### "Pod install failed" (iOS)
**Solution**: 
```bash
cd ios
pod install --repo-update
cd ..
```

### "Permission denied" in Firestore
**Solution**: Ensure Firestore is in "test mode" or update security rules

## What's Next?

### For Development
- Explore the chord generator features
- Try different genres and keys
- Generate bass lines
- Use the piano roll editor

### For Production
1. Update Firestore security rules (see FIREBASE_SETUP.md)
2. Configure proper authentication
3. Set up app icons and splash screens
4. Build release versions
5. Deploy to app stores

## App Features Overview

### Core Features
- 🎹 Generate chord progressions for 12+ genres
- 🎯 Smart presets with genre-specific settings
- 🎸 Bass line generator with multiple styles
- ✏️ Piano roll editor for fine-tuning
- ❤️ Save favorites (synced to Firebase)
- 🔒 Lock specific chords while regenerating
- 🔗 Share progressions via URL

### Firebase Features
- ☁️ Cloud storage for favorites
- 👤 Anonymous authentication (instant access)
- 📱 Cross-device synchronization
- 💾 Offline support with local backup
- 🔄 Automatic sync when online

## Project Structure

```
lib/
├── main.dart                          # Entry point + Firebase init
├── models/                            # Data models
├── providers/                         # State management
├── screens/                           # UI screens
├── widgets/                           # Reusable components
├── services/                          # Business logic
│   ├── firebase_service.dart         # Firebase initialization
│   ├── auth_service.dart             # Authentication
│   ├── firestore_service.dart        # Cloud Firestore
│   └── firebase_favorites_service.dart # Cloud favorites
└── utils/                             # Music theory & theme
```

## Documentation

- **[FIREBASE_SETUP.md](FIREBASE_SETUP.md)** - Detailed Firebase setup
- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Complete project structure
- **[README.md](README.md)** - App overview and features

## Architecture Highlights

### State Management
- Uses **Provider** for state management
- Centralized app state in `AppState`
- Reactive UI updates

### Data Persistence
- **Primary**: Cloud Firestore (online)
- **Backup**: SharedPreferences (offline)
- Automatic synchronization

### Authentication
- **Anonymous auth**: Users start immediately
- **Optional upgrade**: To email/password later
- **Seamless UX**: No login required to start

### Offline Support
- App works offline
- Favorites saved locally
- Syncs to cloud when online

## Building for Production

### Android
```bash
flutter build apk --release          # APK file
flutter build appbundle --release    # App Bundle (recommended)
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Security Best Practices

1. **Never commit** Firebase config files to public repos
2. **Use Firestore security rules** in production
3. **Enable App Check** for production apps
4. **Monitor usage** in Firebase Console
5. **Set data limits** (e.g., max favorites per user)

## Support & Resources

- **Issues**: [GitHub Issues](https://github.com/valleedgar085-rgb/groovy-chord-generator/issues)
- **Flutter Docs**: [flutter.dev](https://flutter.dev/docs)
- **Firebase Docs**: [firebase.google.com](https://firebase.google.com/docs)
- **FlutterFire**: [firebase.flutter.dev](https://firebase.flutter.dev/)

## Tips for Success

✨ **Start Simple**: Use anonymous auth initially  
✨ **Test Offline**: Verify app works without internet  
✨ **Monitor Costs**: Check Firebase usage regularly  
✨ **Use Indexes**: Add Firestore indexes as needed  
✨ **Plan Security**: Update rules before production  

## Next Steps

1. ✅ Complete this Quick Start
2. 📖 Read the detailed [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
3. 🏗️ Review [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)
4. 🎵 Start creating amazing chord progressions!
5. 🚀 Build and deploy your app

---

**Need Help?** Check the documentation or open an issue on GitHub!

**Happy Coding! 🎵🚀**
