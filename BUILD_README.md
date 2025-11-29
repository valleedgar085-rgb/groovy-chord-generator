# 🚀 APK Build Instructions - Start Here!

Welcome! This guide will help you build a signed APK of **Groovy Chord Generator v2.4**.

## 📋 What You Have

I've set up the following files for you:

- ✅ `capacitor.config.ts` - Capacitor configuration
- ✅ `package.json` - Updated with Capacitor dependencies
- ✅ `build-apk.ps1` - Automated build script
- ✅ `check-environment.ps1` - Environment checker
- ✅ `QUICKSTART.md` - Quick reference guide
- ✅ `BUILD_APK_GUIDE.md` - Detailed documentation
- ✅ `gradle-signing-config.txt` - Gradle signing configuration reference

## 🎯 Choose Your Path

### Path A: Automated Script (Recommended)
1. Run environment checker: `.\check-environment.ps1`
2. Fix any issues it finds
3. Run the build script: `.\build-apk.ps1`

### Path B: Manual Steps
Follow the steps in `QUICKSTART.md`

### Path C: Using Android Studio
Follow the steps in `BUILD_APK_GUIDE.md`

## ⚡ Fastest Start (If Everything Is Installed)

Open PowerShell in this directory and run:

```powershell
# 1. Check environment
.\check-environment.ps1

# 2. Install dependencies (first time only)
npm install

# 3. Build and create APK
.\build-apk.ps1
```

The APK will be created as `groovy-chord-generator-v2.4.0.apk`

## 🔧 Prerequisites Checklist

Before building, you need:

- [ ] **Node.js** installed (https://nodejs.org/)
- [ ] **Android Studio** installed (for Android SDK)
- [ ] **ANDROID_HOME** environment variable set
- [ ] **npm dependencies** installed (`npm install`)
- [ ] **Keystore created** for signing
- [ ] **key.properties** configured with passwords

## 🆘 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| `npm not found` | Install Node.js from nodejs.org |
| `ANDROID_HOME not set` | Run the command in QUICKSTART.md |
| `keytool not found` | Add Android Studio's JDK to PATH |
| `gradlew fails` | Check you're in the `android` directory |
| Keystore missing | Follow Step 5 in QUICKSTART.md |

## 📁 File Structure After Setup

```
groovy-chord-generator/
├── dist/                          # Built web app
├── android/                       # Android project
│   ├── app/
│   │   ├── release-key.keystore  # Your signing key
│   │   └── build/
│   │       └── outputs/
│   │           └── apk/
│   │               └── release/
│   │                   └── app-release.apk  # 🎉 Your APK!
│   └── key.properties             # Signing passwords
└── groovy-chord-generator-v2.4.0.apk  # Copied to root
```

## 📚 Documentation

- **QUICKSTART.md** - Quick step-by-step guide
- **BUILD_APK_GUIDE.md** - Comprehensive documentation
- **gradle-signing-config.txt** - Gradle configuration reference

## 🎉 After Building

Your signed APK will be at:
- `android\app\build\outputs\apk\release\app-release.apk`
- Also copied to: `groovy-chord-generator-v2.4.0.apk`

### Install on Device

**Option 1 - ADB:**
```powershell
adb install groovy-chord-generator-v2.4.0.apk
```

**Option 2 - Manual:**
1. Copy APK to your phone
2. Open with file manager
3. Allow installation from unknown sources
4. Install!

## 🔄 For Future Updates

1. Make your code changes
2. Update version in `package.json`
3. Update version in `android/app/build.gradle`
4. Run: `.\build-apk.ps1`

## 📱 Publishing to Google Play

Want to publish on Google Play Store?

1. Build AAB instead:
   ```powershell
   cd android
   .\gradlew bundleRelease
   ```

2. Find AAB at: `android\app\build\outputs\bundle\release\app-release.aab`

3. Upload to Google Play Console

See `BUILD_APK_GUIDE.md` for more details.

## 💡 Tips

- Keep your keystore and passwords safe! You need them to update the app
- Backup your `release-key.keystore` and `key.properties` 
- Never commit `key.properties` to git (already in .gitignore)
- Test the APK on multiple devices before publishing

## ❓ Need Help?

1. Run `.\check-environment.ps1` to diagnose issues
2. Check `QUICKSTART.md` for common problems
3. See `BUILD_APK_GUIDE.md` for detailed troubleshooting
4. Make sure Android Studio is installed with SDK tools

---

**Ready to build?** Start with: `.\check-environment.ps1`

Good luck! 🎵✨

