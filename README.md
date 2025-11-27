# Groovy Chord Generator v2.0

🎵 A modern, mobile-optimized web app for creating amazing chord progressions for any genre.

## Features

### 🎛️ Generator
- **Genre Selection**: Choose from 8 different genres (Happy Pop, Chill Lo-Fi, EDM, R&B, Jazz, Trap, Cinematic, Indie Rock)
- **Key Selection**: Support for major and minor keys
- **Complexity Levels**: Simple, Medium, Complex, and Advanced progressions
- **Rhythm Options**: Soft, Moderate, Strong, and Intense patterns
- **Instant Generation**: One-tap chord progression creation
- **✨ Animation & Sound Effects**: Visual light burst animations and fun sound effects during chord generation

### 🎼 Visual Editor (Piano Roll)
- Touch-optimized grid interaction
- Pinch-to-zoom support on mobile
- Zoom in/out and reset controls
- Click/tap to add or remove notes
- Visual chord representation

### 💾 MIDI Export
- Export generated chord progressions as standard MIDI files
- Compatible with all major DAWs (Ableton, FL Studio, Logic Pro, etc.)
- Includes tempo and time signature information
- One-click download from the floating action menu

### ⚙️ Settings
- Master volume control
- Sound type selection (Sine, Triangle, Square, Sawtooth)
- Toggle Roman numeral display
- Show/hide tips option

### 📱 Mobile-First Design
- Responsive layout for all screen sizes
- Bottom navigation bar (Generator, Editor, Settings)
- Floating action button for quick access
- Collapsible sections for compact layouts
- Touch-friendly controls and buttons

### 🚀 Progressive Web App (PWA)
- Install on mobile devices
- Offline capability with service worker
- App-like experience
- Fast loading and caching

## Getting Started

1. Open `index.html` in a modern web browser
2. Complete the onboarding tutorial (or skip it)
3. Select your preferred genre and key
4. Tap the Generate button (🎲) to create a chord progression
5. Use the Editor tab to view and modify notes
6. Hit Play to hear your creation!
7. Export to MIDI using the floating action button (💾)

## Building an Android APK

You can convert this PWA into a native Android APK using one of the following methods:

### Option 1: PWA Builder (Recommended - Easiest)

1. Visit [PWABuilder.com](https://www.pwabuilder.com)
2. Enter your hosted app URL (or deploy to GitHub Pages first)
3. Click "Package for stores" → "Android"
4. Download the generated APK or Android App Bundle

### Option 2: Capacitor (For Development)

1. Install Node.js if not already installed
2. Initialize a Capacitor project:
   ```bash
   npm init -y
   npm install @capacitor/core @capacitor/cli @capacitor/android
   npx cap init "Groovy Chord Generator" "com.edgarvalle.chordgenerator"
   ```
3. Copy your web app to the `www` folder
4. Add Android platform:
   ```bash
   npx cap add android
   npx cap copy android
   npx cap open android
   ```
5. Build APK from Android Studio (Build → Build Bundle(s) / APK(s) → Build APK(s))

### Option 3: TWA (Trusted Web Activity)

1. Deploy your PWA to a secure (HTTPS) hosting service
2. Use [Bubblewrap](https://github.com/AyushAgnihotri2025/AayushAg/AyushAg.github.io) CLI:
   ```bash
   npm install -g @AyushAgnihotri2025/AayushAg-cli
   AyushAg init --manifest https://your-domain.com/manifest.json
   AyushAg build
   ```
3. The APK will be generated in the output folder

### Deployment Tips
- Host your PWA on GitHub Pages, Netlify, or Vercel for free HTTPS hosting
- Ensure `manifest.json` includes all required icons
- Test on a real Android device before publishing

## Technologies

- Pure HTML5, CSS3, and JavaScript (no frameworks)
- Web Audio API for sound synthesis
- Canvas API for piano roll visualization
- Service Worker for offline support
- CSS Grid and Flexbox for responsive layouts
- MIDI file generation (native JavaScript implementation)

## Browser Support

Works in all modern browsers including:
- Chrome/Edge (recommended)
- Firefox
- Safari
- Mobile browsers (iOS Safari, Chrome for Android)

## Version History

### v2.1 (Current)
- ✨ Added animated light effects during chord generation
- 🔊 Added fun sound effects when generating chords
- 💾 MIDI export functionality for DAW integration
- 📱 APK packaging documentation for Android deployment

### v2.0
- Complete mobile-first redesign
- Added tabbed navigation (Generator, Editor, Settings)
- Implemented collapsible sections
- Added floating action button with quick actions
- Touch-optimized piano roll with zoom/scroll
- PWA support with offline capability
- Onboarding tutorial for new users
- Audio settings (volume, sound type)
- Display preferences (Roman numerals, tips)

### v1.0
- Initial release
- Basic chord generation
- Piano roll editor
- Audio playback

## Credits

Created by **Edgar Valle** | © 2024