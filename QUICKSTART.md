# QUICK START - Build Your APK NOW!

## 🚨 Prerequisites Check

Before starting, you need:
1. **Node.js** installed (https://nodejs.org/)
2. **Android Studio** installed (for Android SDK and build tools)
3. **Java JDK** (comes with Android Studio)

## ⚡ Fastest Path to APK

### Step 1: Open PowerShell in Your Project
```powershell
cd "C:\Users\Edgar Valle\AndroidStudioProjects\groovy-chord-generator"
```

### Step 2: Install Dependencies (First Time Only)
```powershell
npm install
```

This installs all packages including Capacitor (already added to package.json).

### Step 3: Build the Web App
```powershell
npm run build
```

This creates the `dist` folder with your compiled web app.

### Step 4: Add Android Platform (First Time Only)
```powershell
npx cap add android
```

This creates the `android` folder with the Android project.

### Step 5: Create Signing Key (First Time Only)
```powershell
cd android\app
keytool -genkey -v -keystore release-key.keystore -alias groovy-key -keyalg RSA -keysize 2048 -validity 10000
```

You'll be asked for:
- Keystore password: **Choose a strong password and REMEMBER IT!**
- Your name and organization details
- Key password: **Use the same password as keystore**

**IMPORTANT:** Write down your password! You'll need it to update the app.

### Step 6: Configure Signing (First Time Only)

Create file `android/key.properties` with this content (replace YOUR_PASSWORD):
```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=groovy-key
storeFile=release-key.keystore
```

### Step 7: Update build.gradle (First Time Only)

Open `android/app/build.gradle` and find the `android {` section.

Add this BEFORE the `android {` block:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Inside the `android {` block, add:
```gradle
signingConfigs {
    release {
        if (keystorePropertiesFile.exists()) {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled false
        proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
    }
}
```

### Step 8: Build the APK!
```powershell
cd "C:\Users\Edgar Valle\AndroidStudioProjects\groovy-chord-generator"
npx cap sync android
cd android
.\gradlew assembleRelease
```

### Step 9: Find Your APK
Your signed APK is at:
```
android\app\build\outputs\apk\release\app-release.apk
```

## 🎉 Install on Your Phone

### Option 1: Using ADB
```powershell
adb install android\app\build\outputs\apk\release\app-release.apk
```

### Option 2: Manual Install
1. Copy `app-release.apk` to your phone
2. Open it with your file manager
3. Allow installation from unknown sources if prompted
4. Install!

---

## 🔄 For Future Builds

After the first-time setup, to rebuild just run:
```powershell
npm run build
npx cap sync android
cd android
.\gradlew assembleRelease
```

Or use the automated script:
```powershell
.\build-apk.ps1
```

---

## 🆘 Troubleshooting

### "npm not found"
→ Install Node.js from https://nodejs.org/ and restart PowerShell

### "ANDROID_HOME not set"
→ Set it in PowerShell (replace YOUR_USERNAME):
```powershell
[System.Environment]::SetEnvironmentVariable('ANDROID_HOME', 'C:\Users\YOUR_USERNAME\AppData\Local\Android\Sdk', 'User')
```
Then restart PowerShell.

### "keytool not found"
→ Add Java to PATH. Find the JDK in Android Studio:
```
C:\Program Files\Android\Android Studio\jbr\bin
```
Add this to your PATH environment variable.

### "gradlew not found" or permission denied
→ You're not in the android directory:
```powershell
cd android
```

### Build fails with signing errors
→ Check your `key.properties` file has correct passwords and keystore exists

### App won't install
→ If you previously installed a debug version:
```powershell
adb uninstall com.edgarvalle.groovychordgenerator
```
Then try installing again.

---

## 📱 Testing Before Publishing

1. Install the APK on multiple devices
2. Test all features:
   - Chord generation
   - Piano roll editor
   - MIDI export
   - Sound playback
   - Settings
3. Check app doesn't crash
4. Verify offline functionality works

---

## 🚀 Publishing to Google Play Store

When ready to publish:

1. Build AAB instead of APK:
   ```powershell
   cd android
   .\gradlew bundleRelease
   ```
   
2. Find AAB at: `android\app\build\outputs\bundle\release\app-release.aab`

3. Create Google Play Console account ($25 one-time)

4. Upload the AAB and fill out store listing

5. Submit for review!

---

## ❓ Still Having Issues?

Check `BUILD_APK_GUIDE.md` for detailed instructions and troubleshooting.

