# Deployment Guide - Groovy Chord Generator

This guide covers deploying the Groovy Chord Generator app to production environments.

## Table of Contents
1. [Pre-deployment Checklist](#pre-deployment-checklist)
2. [Firebase Production Setup](#firebase-production-setup)
3. [Android Deployment](#android-deployment)
4. [iOS Deployment](#ios-deployment)
5. [Web Deployment](#web-deployment)
6. [Post-deployment](#post-deployment)

## Pre-deployment Checklist

Before deploying to production, ensure:

- [ ] All features tested on target platforms
- [ ] Firebase configuration completed
- [ ] Firestore security rules updated for production
- [ ] App icons and splash screens configured
- [ ] Privacy policy and terms of service created
- [ ] App version numbers updated
- [ ] Debug code and console logs removed or disabled
- [ ] Analytics and crash reporting configured
- [ ] Performance optimizations applied

## Firebase Production Setup

### 1. Update Firestore Security Rules

Replace test mode rules with production rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the document
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // User data - only owner can access
    match /users/{userId} {
      allow read, write: if isOwner(userId);
      
      // Favorites subcollection
      match /favorites/{favoriteId} {
        allow read, write: if isOwner(userId);
        
        // Validate favorite data structure
        allow create: if isOwner(userId) 
          && request.resource.data.keys().hasAll(['name', 'progression', 'key', 'genre', 'createdAt'])
          && request.resource.data.name is string
          && request.resource.data.name.size() > 0
          && request.resource.data.name.size() <= 100
          && request.resource.data.progression is list
          && request.resource.data.progression.size() > 0
          && request.resource.data.progression.size() <= 32;
      }
      
      // Settings subcollection
      match /settings/{document=**} {
        allow read, write: if isOwner(userId);
      }
    }
    
    // Shared progressions - public read, authenticated write
    match /progressions/{progressionId} {
      allow read: if true;
      allow create: if isAuthenticated()
        && request.resource.data.userId == request.auth.uid;
      allow update, delete: if isAuthenticated() 
        && resource.data.userId == request.auth.uid;
    }
  }
}
```

### 2. Set Up Firestore Indexes

Create composite indexes for efficient queries:

1. Go to Firebase Console > Firestore > Indexes
2. Add indexes for:
   - Collection: `users/{userId}/favorites`
     - Fields: `createdAt` (Descending)
   - Collection: `progressions`
     - Fields: `createdAt` (Descending), `userId` (Ascending)

### 3. Configure Firebase Authentication

1. Go to Firebase Console > Authentication > Settings
2. Configure authorized domains for your app
3. Set up email verification templates
4. Configure password reset templates
5. Enable account protection features

### 4. Set Up Firebase App Check

Protect your Firebase resources from abuse:

```bash
# Enable App Check in Firebase Console
# Then add to your app:
```

In `lib/main.dart`:
```dart
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await FirebaseService.initialize();
  
  // Enable App Check
  await FirebaseAppCheck.instance.activate(
    webRecaptchaSiteKey: 'YOUR_RECAPTCHA_SITE_KEY',
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );
  
  await AuthService.signInAnonymously();
  runApp(const GroovyChordGeneratorApp());
}
```

### 5. Enable Analytics

Firebase Analytics is already included. Verify it's tracking:

1. Go to Firebase Console > Analytics
2. Check real-time events
3. Configure custom events if needed

## Android Deployment

### 1. Configure App Signing

Create a keystore for release signing:

```bash
keytool -genkey -v -keystore ~/groovy-chord-generator.keystore \
  -alias groovy-chord-generator -keyalg RSA -keysize 2048 -validity 10000
```

Create `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=groovy-chord-generator
storeFile=/path/to/groovy-chord-generator.keystore
```

Update `android/app/build.gradle`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 2. Update App Information

In `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.edgarvalle.groovy_chord_generator">
    
    <application
        android:label="Groovy Chord Generator"
        android:icon="@mipmap/ic_launcher">
        <!-- ... -->
    </application>
</manifest>
```

In `pubspec.yaml`:

```yaml
version: 2.5.0+1  # Increment version number
```

### 3. Build Release APK/AAB

```bash
# Build APK (for direct distribution)
flutter build apk --release --split-per-abi

# Build App Bundle (for Google Play)
flutter build appbundle --release
```

Output files:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### 4. Test Release Build

```bash
# Install and test on device
flutter install --release
```

### 5. Deploy to Google Play Store

1. Create a developer account: [Google Play Console](https://play.google.com/console)
2. Create a new app
3. Fill in store listing information
4. Upload screenshots and promotional graphics
5. Upload the AAB file
6. Configure pricing and distribution
7. Submit for review

## iOS Deployment

### 1. Configure App Signing

1. Enroll in Apple Developer Program: [developer.apple.com](https://developer.apple.com)
2. Create App ID in Apple Developer Console
3. Create provisioning profiles
4. Configure signing in Xcode:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner > Signing & Capabilities
   - Select your team
   - Configure bundle identifier

### 2. Update App Information

In `ios/Runner/Info.plist`:

```xml
<key>CFBundleDisplayName</key>
<string>Groovy Chord Generator</string>
<key>CFBundleShortVersionString</key>
<string>2.5.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

### 3. Build Release IPA

```bash
# Build for release
flutter build ios --release

# Archive in Xcode
# Open ios/Runner.xcworkspace in Xcode
# Product > Archive
# Distribute App > App Store Connect
```

### 4. Deploy to App Store

1. Create app in App Store Connect
2. Fill in app information
3. Upload screenshots and promotional materials
4. Upload build using Xcode or Transporter
5. Submit for review

## Web Deployment

### 1. Build for Web

```bash
# Build optimized web version
flutter build web --release --web-renderer canvaskit

# Or use HTML renderer for better compatibility
flutter build web --release --web-renderer html
```

### 2. Deploy to Firebase Hosting

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize Firebase Hosting
firebase init hosting

# Configure firebase.json:
```

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

```bash
# Deploy to Firebase
firebase deploy --only hosting
```

### 3. Configure Custom Domain (Optional)

1. Go to Firebase Console > Hosting
2. Click "Add custom domain"
3. Follow DNS configuration instructions
4. Wait for SSL certificate provisioning

### 4. Alternative: Deploy to Other Platforms

**Netlify:**
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
netlify deploy --prod --dir=build/web
```

**Vercel:**
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod
```

**GitHub Pages:**
```bash
# Build
flutter build web --release --base-href /groovy-chord-generator/

# Deploy to gh-pages branch
# Use GitHub Actions or manual push to gh-pages
```

## Post-deployment

### 1. Monitor App Performance

- Check Firebase Console > Analytics for user engagement
- Monitor Crashlytics for crash reports
- Review Firestore usage and costs
- Check authentication metrics

### 2. Set Up Alerts

Configure Firebase alerts for:
- Unusual spike in authentication
- Firestore read/write quota approaching limit
- Crash rate increases
- Error rate spikes

### 3. Optimize Costs

- Review Firestore usage in Console
- Implement data retention policies
- Optimize queries to reduce reads
- Consider caching strategies
- Set up billing alerts

### 4. Update Documentation

- Keep README.md updated
- Update version numbers
- Document any breaking changes
- Update screenshots if UI changed

### 5. User Feedback

- Monitor app store reviews
- Set up in-app feedback mechanism
- Track feature requests
- Address bugs promptly

## Continuous Integration/Deployment

### GitHub Actions Example

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      - run: flutter pub get
      - run: flutter test
      - run: flutter build web --release
      
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: your-project-id
```

## Troubleshooting

### Build Fails
- Clean build: `flutter clean && flutter pub get`
- Update Flutter: `flutter upgrade`
- Check dependency conflicts

### Firebase Quota Exceeded
- Optimize queries
- Implement caching
- Upgrade Firebase plan
- Review security rules

### App Rejected from Store
- Review app store guidelines
- Address reviewer feedback
- Update metadata if needed
- Resubmit with changes

## Resources

- [Flutter Deployment Guide](https://flutter.dev/docs/deployment)
- [Firebase Console](https://console.firebase.google.com)
- [Google Play Console](https://play.google.com/console)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Firebase Hosting Docs](https://firebase.google.com/docs/hosting)

---

**Good luck with your deployment! 🚀**
