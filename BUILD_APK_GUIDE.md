# Building Signed APK for Groovy Chord Generator

## Prerequisites Setup

### 1. Install Node.js (if not already installed)
Download and install Node.js from: https://nodejs.org/
- Recommended: LTS version (v20 or higher)
- After installation, restart your terminal/PowerShell

### 2. Verify Installation
```powershell
node --version
npm --version
```

### 3. Install Dependencies
```powershell
cd "C:\Users\Edgar Valle\AndroidStudioProjects\groovy-chord-generator"
npm install
```

### 4. Install Capacitor
```powershell
npm install @capacitor/core @capacitor/cli @capacitor/android
```

### 5. Initialize Capacitor (if not already done)
```powershell
npx cap init
```
- App name: Groovy Chord Generator
- App ID: com.edgarvalle.groovychordgenerator
- Web directory: dist

## Building the Web App

### 1. Build the Vite app
```powershell
npm run build
```

This creates the `dist` folder with your web app.

### 2. Add Android Platform
```powershell
npx cap add android
```

This creates the `android` folder with all Android project files.

### 3. Sync Web Assets to Android
```powershell
npx cap sync android
```

## Creating a Keystore for Signing

### Option A: Using PowerShell (Requires Java JDK)

```powershell
# Navigate to android/app directory
cd android/app

# Generate keystore
keytool -genkey -v -keystore release-key.keystore -alias groovy-key -keyalg RSA -keysize 2048 -validity 10000

# You'll be prompted for:
# - Keystore password (remember this!)
# - Personal information
# - Key password (can be same as keystore password)
```

### Option B: Using Android Studio

1. Open Android Studio
2. File → Open → Select the `android` folder in your project
3. Build → Generate Signed Bundle/APK
4. Follow the wizard to create a new keystore

## Configure Gradle for Signing

### 1. Create `android/key.properties` file:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=groovy-key
storeFile=release-key.keystore
```

**IMPORTANT:** Add `key.properties` to `.gitignore` to keep passwords secure!

### 2. Update `android/app/build.gradle`

Add before the `android` block:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Inside the `android` block, add:
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile file(keystoreProperties['storeFile'])
        storePassword keystoreProperties['storePassword']
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled false
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

## Building the Signed APK

### Method 1: Using Gradle Command (Recommended)
```powershell
cd android
.\gradlew assembleRelease
```

The signed APK will be at: `android/app/build/outputs/apk/release/app-release.apk`

### Method 2: Using Android Studio
1. Open the `android` folder in Android Studio
2. Build → Generate Signed Bundle/APK
3. Choose APK
4. Select your keystore
5. Choose "release" build variant
6. Click Finish

### Method 3: Using Capacitor CLI
```powershell
npx cap build android --release
```

## Quick Build Script

Save this as `build-apk.ps1`:
```powershell
# Build web app
Write-Host "Building web app..." -ForegroundColor Green
npm run build

# Sync to Android
Write-Host "Syncing to Android..." -ForegroundColor Green
npx cap sync android

# Build APK
Write-Host "Building signed APK..." -ForegroundColor Green
cd android
.\gradlew assembleRelease

# Copy APK to root
Write-Host "Copying APK..." -ForegroundColor Green
Copy-Item "app\build\outputs\apk\release\app-release.apk" "..\groovy-chord-generator.apk"
cd ..

Write-Host "Done! APK is at: groovy-chord-generator.apk" -ForegroundColor Green
```

Run it with:
```powershell
.\build-apk.ps1
```

## Troubleshooting

### "npm not found"
- Node.js not installed or not in PATH
- Solution: Install Node.js and restart terminal

### "ANDROID_HOME not set"
- Android SDK not configured
- Solution: Install Android Studio and set ANDROID_HOME environment variable:
  ```powershell
  [System.Environment]::SetEnvironmentVariable('ANDROID_HOME', 'C:\Users\YOUR_USERNAME\AppData\Local\Android\Sdk', 'User')
  ```

### "Java not found"
- JDK not installed
- Solution: Android Studio includes JDK, or download from https://adoptium.net/

### "Gradle build failed"
- Check `android/app/build.gradle` for proper configuration
- Ensure keystore file exists and paths are correct
- Try: `cd android ; .\gradlew clean`

### App Crashes on Launch
- Clear app data on device
- Check `capacitor.config.ts` has correct `webDir: 'dist'`
- Ensure `dist` folder was built before syncing

## Testing the APK

### Install on Device via ADB
```powershell
adb install groovy-chord-generator.apk
```

### Or Copy to Device
- Copy the APK to your phone
- Open it with a file manager
- Allow installation from unknown sources if prompted

## Version Updates

When updating the app:

1. Update version in `package.json`
2. Update version in `android/app/build.gradle` (versionCode and versionName)
3. Rebuild:
   ```powershell
   npm run build
   npx cap sync android
   cd android ; .\gradlew assembleRelease
   ```

## Publishing to Google Play Store

1. Build an AAB (Android App Bundle) instead of APK:
   ```powershell
   cd android
   .\gradlew bundleRelease
   ```
   
2. Upload the AAB from `android/app/build/outputs/bundle/release/app-release.aab`

3. You'll need:
   - Google Play Developer account ($25 one-time fee)
   - Privacy policy URL
   - App screenshots and description
   - Content rating questionnaire

