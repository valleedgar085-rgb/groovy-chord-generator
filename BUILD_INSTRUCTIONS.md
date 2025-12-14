# Build Instructions - Groovy Chord Generator

Complete instructions for building the Groovy Chord Generator Android APK.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Detailed Build Steps](#detailed-build-steps)
4. [Build Variants](#build-variants)
5. [Troubleshooting](#troubleshooting)
6. [Distribution](#distribution)

---

## Prerequisites

### Required Software
- **Flutter SDK** (3.0.0 or later)
  - Download: https://flutter.dev/docs/get-started/install
  - Verify installation: `flutter doctor`
  
- **Android Studio** or **Android SDK Command-line Tools**
  - Download: https://developer.android.com/studio
  - Accept Android licenses: `flutter doctor --android-licenses`
  
- **Java JDK** (8 or later)
  - Required for Android builds
  - Verify: `java -version`

### Optional but Recommended
- **Android Device or Emulator** for testing
- **Git** for version control
- **Code Editor** (VS Code, Android Studio, or IntelliJ)

---

## Quick Start

For users who just want to build quickly:

### Linux/macOS
```bash
# Make the build script executable
chmod +x build_apk.sh

# Run the build script
./build_apk.sh
```

### Windows
```batch
# Run the build script
build_apk.bat
```

The APK will be created at: `build/app/outputs/flutter-apk/app-release.apk`

---

## Detailed Build Steps

### 1. Setup Environment

First, verify your Flutter installation:

```bash
flutter doctor
```

You should see checkmarks (✓) for:
- Flutter SDK
- Android toolchain
- Connected device (optional for building)

If you see any issues, follow the suggestions provided by `flutter doctor`.

### 2. Configure Release Signing (Production Builds)

**For production releases and Google Play Store uploads, you MUST set up release signing.**

See [KEYSTORE_SETUP.md](KEYSTORE_SETUP.md) for detailed instructions.

Quick summary:
```bash
# Generate keystore
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Configure key.properties
cd android
cp key.properties.template key.properties
# Edit key.properties with your keystore details
```

**Note:** If you skip this step, the APK will be signed with debug keys, which:
- Cannot be uploaded to Google Play Store
- Shows "For testing only" warning on some devices
- Is fine for development and testing

### 3. Install Dependencies

```bash
flutter pub get
```

This installs all packages defined in `pubspec.yaml`.

### 4. Generate App Icons (Optional)

If you've configured custom app icons:

```bash
flutter pub run flutter_launcher_icons:main
```

This generates Android launcher icons from `assets/icon/app_icon.png`.

### 5. Build the APK

#### Release APK (Recommended)
```bash
flutter build apk --release
```

This creates an optimized, production-ready APK.

#### Debug APK (Development)
```bash
flutter build apk --debug
```

Useful for debugging with better error messages and logs.

#### Profile APK (Performance Testing)
```bash
flutter build apk --profile
```

For performance profiling and optimization.

### 6. Locate the APK

After successful build, find your APK at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## Build Variants

### Release Build (Production)
```bash
flutter build apk --release
```
- **Size:** Smallest (code minification enabled)
- **Performance:** Optimized
- **Debugging:** No debug info
- **Use case:** Distribution, Play Store

### Debug Build
```bash
flutter build apk --debug
```
- **Size:** Larger
- **Performance:** Not optimized
- **Debugging:** Full debug info
- **Use case:** Development, debugging

### Split APKs per ABI (Advanced)
```bash
flutter build apk --release --split-per-abi
```
Creates separate APKs for different CPU architectures:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (Intel 64-bit)

**Benefits:**
- Smaller download size (users get only the APK for their device)
- Google Play automatically serves the right APK

**Note:** Google Play requires 64-bit (arm64-v8a) support.

### Android App Bundle (Play Store)
```bash
flutter build appbundle --release
```
Creates an `.aab` file required for Google Play Store uploads.

**Output:** `build/app/outputs/bundle/release/app-release.aab`

**Benefits:**
- Google Play generates optimized APKs for each device
- Smaller download sizes
- Required for new apps on Play Store

---

## Troubleshooting

### Issue: "Flutter not found"
**Solution:** Add Flutter to your PATH
```bash
# Linux/macOS - Add to ~/.bashrc or ~/.zshrc
export PATH="$PATH:/path/to/flutter/bin"

# Windows - Add to System Environment Variables
C:\path\to\flutter\bin
```

### Issue: "Android licenses not accepted"
**Solution:**
```bash
flutter doctor --android-licenses
```
Press 'y' to accept all licenses.

### Issue: "Gradle build failed"
**Solutions:**
1. Clean the project:
   ```bash
   flutter clean
   cd android
   ./gradlew clean
   cd ..
   ```

2. Verify Android SDK is installed:
   ```bash
   flutter doctor -v
   ```

3. Check `android/app/build.gradle.kts` for correct SDK versions

### Issue: "Keystore file not found"
**Solution:** Verify `android/key.properties` has correct path:
```properties
storeFile=/absolute/path/to/upload-keystore.jks
```
Use absolute paths, not relative paths.

### Issue: "Out of memory" during build
**Solution:** Increase Gradle memory in `android/gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=512m
```

### Issue: "APK size too large"
**Solutions:**
1. Use split APKs:
   ```bash
   flutter build apk --release --split-per-abi
   ```

2. Check for unused assets in `pubspec.yaml`

3. Use App Bundle instead:
   ```bash
   flutter build appbundle --release
   ```

### Issue: Build succeeds but app crashes
**Solutions:**
1. Check ProGuard rules in `android/app/proguard-rules.pro`
2. Build a debug APK to see error logs:
   ```bash
   flutter build apk --debug
   adb install build/app/outputs/flutter-apk/app-debug.apk
   adb logcat
   ```

---

## Distribution

### Installing on Device

#### Via Flutter
```bash
# Connect device via USB with USB debugging enabled
flutter install
```

#### Via ADB
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

#### Manual Installation
1. Copy APK to device
2. Open file manager on device
3. Tap the APK file
4. Allow installation from unknown sources if prompted
5. Install

### Sharing APK

The APK file can be shared directly:
- Email attachment
- Cloud storage (Google Drive, Dropbox)
- File transfer apps
- USB transfer

**Warning:** APKs from unknown sources may show security warnings on Android.

### Google Play Store

For Play Store distribution:

1. Build App Bundle:
   ```bash
   flutter build appbundle --release
   ```

2. Create a Google Play Console account
   - https://play.google.com/console

3. Upload `app-release.aab` to Play Console

4. Complete store listing:
   - App description
   - Screenshots
   - Icon
   - Privacy policy
   - Content rating

5. Submit for review

**Cost:** $25 one-time developer registration fee

---

## Build Configuration

### Minimum SDK Versions
- **minSdk:** 21 (Android 5.0 Lollipop)
- **targetSdk:** 34 (Android 14)
- **compileSdk:** 34

### App Identifiers
- **Package Name:** com.edgarvalle.chordgenerator
- **App Name:** Groovy Chord Generator

### Build Optimizations
- **Code Shrinking:** Enabled (R8/ProGuard)
- **Resource Shrinking:** Enabled
- **Minification:** Enabled in release builds
- **MultiDex:** Enabled (for large app)

---

## Additional Resources

- [Flutter Deployment Documentation](https://docs.flutter.dev/deployment/android)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [Google Play Console](https://play.google.com/console)
- [KEYSTORE_SETUP.md](KEYSTORE_SETUP.md) - Detailed keystore instructions
- [Android ProGuard](https://developer.android.com/studio/build/shrink-code)

---

## Quick Reference Commands

```bash
# Clean project
flutter clean

# Get dependencies
flutter pub get

# Generate icons
flutter pub run flutter_launcher_icons

# Build release APK
flutter build apk --release

# Build release App Bundle
flutter build appbundle --release

# Install on device
flutter install

# Check APK size
du -h build/app/outputs/flutter-apk/app-release.apk

# View detailed build info
flutter build apk --release --verbose
```

---

## Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Run `flutter doctor -v` for diagnostics
3. Review build logs for specific errors
4. Check Flutter documentation: https://flutter.dev

---

**Last Updated:** December 2024
**Version:** 2.5.0
