# Groovy Chord Generator - Android

This directory contains the Android-specific configuration for the Flutter app.

## Building

The Flutter app is built using standard Flutter commands from the project root:

```bash
# Get dependencies
flutter pub get

# Run on connected device
flutter run

# Build release APK
flutter build apk --release

# Build app bundle for Play Store
flutter build appbundle --release
```

## Project Structure

```
android/
├── app/
│   ├── build.gradle.kts       # App-level Gradle build config
│   ├── proguard-rules.pro     # ProGuard rules for release builds
│   └── src/main/
│       ├── AndroidManifest.xml
│       ├── kotlin/.../
│       │   └── MainActivity.kt  # Flutter activity
│       └── res/
│           ├── drawable/       # Splash screen & drawables
│           ├── mipmap-*/       # App icons
│           └── values/         # Themes, colors, strings
├── build.gradle.kts            # Project-level Gradle config
├── settings.gradle.kts         # Gradle settings
├── gradle.properties           # Gradle properties
└── gradle/wrapper/             # Gradle wrapper
```

## Requirements

- Flutter SDK 3.0+
- Android SDK
- Android Studio (for development)

## Customization

### Change App Name
Edit `app/src/main/AndroidManifest.xml`:
```xml
android:label="Your App Name"
```

### Change Package Name
Update in these files:
- `app/build.gradle.kts` → `namespace` and `applicationId`
- Rename the kotlin package folder accordingly
- `MainActivity.kt` → update package declaration

### Change App Icon
Use Flutter's flutter_launcher_icons package or Android Studio's Image Asset Studio.
