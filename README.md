# Groovy Chord Generator v2.4

🎵 A modern, mobile-optimized web app for creating amazing chord progressions for any genre.

## Quick Start

This repository includes a **self-contained HTML file** ready for Android APK conversion.

- **`android-apk/index.html`** - Single-file version with all CSS and JavaScript inlined, optimized for Android WebView

## Building an Android APK with Android Studio

Follow these steps to convert this web app into a native Android APK using Android Studio's WebView:

### Prerequisites

- [Android Studio](https://developer.android.com/studio) (latest version recommended)
- Android SDK (installed with Android Studio)
- A physical Android device or emulator for testing

### Step 1: Create a New Android Project

1. Open **Android Studio**
2. Click **File → New → New Project**
3. Select **Empty Activity** (or "Empty Views Activity" in newer versions)
4. Configure your project:
   - **Name**: `Groovy Chord Generator`
   - **Package name**: `com.yourname.chordgenerator`
   - **Language**: Kotlin (recommended) or Java
   - **Minimum SDK**: API 21 (Android 5.0) or higher
5. Click **Finish** and wait for the project to be created

### Step 2: Create the Assets Folder

1. In the **Project** view (left panel), navigate to `app/src/main/`
2. Right-click on `main` → **New → Directory**
3. Name it `assets`
4. The path should be: `app/src/main/assets/`

### Step 3: Copy index.html

1. Copy the `android-apk/index.html` file from this repository
2. Paste it into `app/src/main/assets/index.html` in your Android project

### Step 4: Modify activity_main.xml

Replace the contents of `app/src/main/res/layout/activity_main.xml` with:

```xml
<?xml version="1.0" encoding="utf-8"?>
<WebView xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/webView"
    android:layout_width="match_parent"
    android:layout_height="match_parent" />
```

### Step 5: Modify MainActivity

#### For Kotlin (`MainActivity.kt`):

Replace the contents of `app/src/main/java/[your.package.name]/MainActivity.kt` with:

```kotlin
package com.yourname.chordgenerator // Replace with your actual package name

import android.os.Bundle
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    private lateinit var webView: WebView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        webView = findViewById(R.id.webView)
        
        // Configure WebView settings
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            allowFileAccess = true
            loadWithOverviewMode = true
            useWideViewPort = true
            setSupportZoom(false)
            builtInZoomControls = false
            displayZoomControls = false
            mediaPlaybackRequiresUserGesture = false
        }
        
        // Set WebViewClient to handle navigation within the app
        webView.webViewClient = WebViewClient()
        
        // Load the local HTML file
        webView.loadUrl("file:///android_asset/index.html")
    }

    override fun onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack()
        } else {
            super.onBackPressed()
        }
    }
}
```

#### For Java (`MainActivity.java`):

```java
package com.yourname.chordgenerator; // Replace with your actual package name

import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    private WebView webView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        webView = findViewById(R.id.webView);
        
        // Configure WebView settings
        WebSettings webSettings = webView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
        webSettings.setAllowFileAccess(true);
        webSettings.setLoadWithOverviewMode(true);
        webSettings.setUseWideViewPort(true);
        webSettings.setSupportZoom(false);
        webSettings.setBuiltInZoomControls(false);
        webSettings.setDisplayZoomControls(false);
        webSettings.setMediaPlaybackRequiresUserGesture(false);
        
        // Set WebViewClient to handle navigation within the app
        webView.setWebViewClient(new WebViewClient());
        
        // Load the local HTML file
        webView.loadUrl("file:///android_asset/index.html");
    }

    @Override
    public void onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack();
        } else {
            super.onBackPressed();
        }
    }
}
```

### Step 6: Configure AndroidManifest.xml (Optional)

For a better full-screen experience, add these attributes to your `AndroidManifest.xml`:

```xml
<activity
    android:name=".MainActivity"
    android:configChanges="orientation|screenSize|keyboardHidden"
    android:theme="@style/Theme.AppCompat.NoActionBar"
    android:exported="true">
    ...
</activity>
```

### Step 7: Build the APK

1. Click **Build → Build Bundle(s) / APK(s) → Build APK(s)**
2. Wait for the build to complete
3. Click **locate** in the notification to find your APK
4. The APK will be at: `app/build/outputs/apk/debug/app-debug.apk`

### Step 8: Install on Device

1. Transfer the APK to your Android device
2. Enable "Install from unknown sources" in your device settings
3. Install and enjoy!

### Building a Signed Release APK

For publishing to the Google Play Store:

1. Click **Build → Generate Signed Bundle / APK**
2. Select **APK**
3. Create a new keystore or use an existing one
4. Complete the signing wizard
5. Choose **release** build variant

---

## Features

### ✨ Smart Presets (v2.4)
- **Visual Preset Cards**: 8 creative presets with instant one-tap application
- **Curated Moods**: Lo-Fi Chill Sunday, Cyberpunk Drive, Summer Pop Hit, Midnight Jazz, Epic Cinema, Soul Groove, Festival Drop, Indie Sunset
- **Auto-Configuration**: Presets automatically set genre, key, complexity, rhythm, and theory options

### 🌶️ "Spice It Up" (v2.4)
- **Chord Substitutions**: Auto-substitute chords for richer, jazzy variations
- **Tritone Substitutions**: Add sophisticated harmonic twists
- **Modal Interchange**: Borrow chords from parallel keys
- **Extension Upgrades**: Transform basic chords to 7ths, 9ths, sus chords

### 📜 Progression History (v2.4)
- **Auto-Save**: Automatically saves last 5 progressions
- **Instant Recall**: One-tap restore of any saved progression
- **Metadata Tracking**: Shows key, genre, and time for each saved progression

### 🎛️ Generator
- **Genre Selection**: Choose from multiple genres (Pop, Lo-Fi, EDM, R&B, Jazz, Trap, Cinematic, Indie Rock)
- **Key Selection**: Support for major and minor keys
- **Complexity Levels**: Simple, Medium, Complex, and Advanced progressions
- **Rhythm Options**: Soft, Moderate, Strong, and Intense patterns
- **Groove/Swing Slider**: Add humanization for a more natural feel
- **Modal Interchange Toggle**: Enable borrowed chords from parallel keys
- **Instant Generation**: One-tap chord progression creation
- **Animation & Sound Effects**: Visual light burst animations and fun sound effects

### 🎼 Visual Editor (Piano Roll)
- Touch-optimized grid interaction
- Pinch-to-zoom support on mobile
- Zoom in/out and reset controls
- Click/tap to add or remove notes
- Visual chord representation

### 💾 MIDI Export
- Export generated chord progressions as standard MIDI files
- Compatible with all major DAWs (Ableton, FL Studio, Logic Pro, etc.)
- One-click download from the floating action menu

### ⚙️ Settings
- Master volume control
- Sound type selection (Sine, Triangle, Square, Sawtooth)
- ADSR Envelope controls
- Toggle Roman numeral display
- Show/hide tips option

---

## Development

### Prerequisites
- Node.js 18+ and npm

### Getting Started

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production (creates single-file HTML in dist/)
npm run build

# Preview production build
npm run preview

# Run linting
npm run lint
```

### Building the Self-Contained HTML

The build process automatically creates a single self-contained HTML file:

```bash
npm run build
```

This generates `dist/index.html` with all CSS and JavaScript inlined. Copy this file to `android-apk/index.html` if you want to update the APK-ready version.

---

## Technologies

- **React 19** with TypeScript for component-based UI
- **Vite** for fast development and optimized production builds
- **vite-plugin-singlefile** for single-file HTML output
- Web Audio API for sound synthesis
- Canvas API for piano roll visualization
- CSS Grid and Flexbox for responsive layouts
- MIDI file generation (native TypeScript implementation)

---

## Version History

### v2.4 (Current)
- ✨ Smart Presets with visual preset cards
- 🌶️ "Spice It Up" button for chord substitutions
- 📜 History/Saved Progressions with auto-save
- 🎸 Modal Interchange for borrowed chords
- 🎹 Genre-Based Voicing
- 🎛️ Groove/Swing Slider
- 📱 **Android APK Ready**: Self-contained HTML build for WebView

---

## Credits

Created by **Edgar Valle** | © 2025