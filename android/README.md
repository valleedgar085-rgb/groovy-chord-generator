# Groovy Chord Generator - Android Project

This directory contains a complete Android Studio project with Kotlin that wraps the web app in a WebView for building native APKs.

## Quick Start

1. **Build the web app first:**
   ```bash
   cd ..
   npm install
   npm run build
   ```

2. **Copy the built HTML to assets:**
   ```bash
   npm run build:android
   ```
   This copies `dist/index.html` to `android/app/src/main/assets/index.html`

3. **Open in Android Studio:**
   - Open Android Studio
   - Select **File → Open**
   - Navigate to this `android` folder and open it
   - Wait for Gradle sync to complete

4. **Build the APK:**
   - Click **Build → Build Bundle(s) / APK(s) → Build APK(s)**
   - Find your APK at: `app/build/outputs/apk/debug/app-debug.apk`

## Project Structure

```
android/
├── app/
│   ├── build.gradle.kts       # App-level Gradle build config (Kotlin DSL)
│   ├── proguard-rules.pro     # ProGuard rules for release builds
│   └── src/main/
│       ├── AndroidManifest.xml
│       ├── assets/
│       │   └── index.html     # Built web app (copy from dist/)
│       ├── java/.../
│       │   └── MainActivity.kt  # Main activity with WebView
│       └── res/
│           ├── drawable/      # Vector drawables
│           ├── layout/        # Activity layouts
│           ├── mipmap-*/      # App icons
│           └── values/        # Strings, colors, themes
├── build.gradle.kts           # Project-level Gradle config
├── settings.gradle.kts        # Gradle settings
├── gradle.properties          # Gradle properties
└── gradle/wrapper/            # Gradle wrapper
```

## Requirements

- Android Studio Hedgehog (2023.1.1) or newer
- Android SDK 34 (Android 14)
- Kotlin 1.9.21+
- Gradle 8.2+

## Building a Signed Release APK

For publishing to the Google Play Store:

1. Click **Build → Generate Signed Bundle / APK**
2. Select **APK**
3. Create a new keystore or use an existing one
4. Complete the signing wizard
5. Choose **release** build variant

## Customization

### Change App Name
Edit `app/src/main/res/values/strings.xml`:
```xml
<string name="app_name">Your App Name</string>
```

### Change Package Name
Update in these files:
- `app/build.gradle.kts` → `namespace` and `applicationId`
- `app/src/main/AndroidManifest.xml` → rename package folder
- `MainActivity.kt` → update package declaration

### Change App Icon
Replace the vector drawables in:
- `app/src/main/res/drawable/ic_launcher_foreground.xml`
- `app/src/main/res/drawable/ic_launcher_background.xml`

Or use Android Studio's **Image Asset Studio**:
1. Right-click `res` folder
2. Select **New → Image Asset**
3. Configure your launcher icon
