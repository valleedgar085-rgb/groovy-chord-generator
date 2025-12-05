# 🎵 Groovy Chord Generator

<div align="center">

![Version](https://img.shields.io/badge/version-2.5-purple)
![Platform](https://img.shields.io/badge/platform-Android-green)
![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)

**Create amazing chord progressions for any genre** — A mobile-optimized music creation tool built with Flutter.

</div>

## ✨ Features

- 🎹 **Generate chord progressions** for 12+ genres (Pop, Lo-Fi, EDM, R&B, Jazz, Trap, and more)
- 🎯 **Smart Presets** — One-tap genre configurations with optimized settings
- 🎸 **Bass Line Generator** — Multiple bass styles including walking bass, syncopated, and more
- 🎵 **Advanced Music Theory** — Voice leading, modal interchange, secondary dominants
- 🌶️ **Spice It Up!** — Add variations and extensions to your progressions
- 📊 **Functional Harmony** — Generate progressions based on harmonic functions
- 🎛️ **Groove Engine** — Apply rhythmic templates like Neo-Soul Swing, Funk Syncopation
- 📜 **History** — Access your previous progressions
- 🔒 **Chord Locking** — Lock specific chords while regenerating others

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.0 or higher
- Android Studio / VS Code with Flutter extensions
- Android SDK

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/valleedgar085-rgb/groovy-chord-generator.git
   cd groovy-chord-generator
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Build APK

```bash
flutter build apk --release
```

## 📱 App Structure

```
lib/
├── main.dart              # App entry point
├── models/
│   ├── types.dart         # Type definitions
│   └── constants.dart     # Music theory constants
├── providers/
│   └── app_state.dart     # State management
├── screens/
│   ├── home_screen.dart   # Main screen
│   ├── generator_tab.dart # Chord generator
│   ├── editor_tab.dart    # Piano roll editor
│   ├── bass_tab.dart      # Bass line generator
│   └── settings_tab.dart  # Settings
├── widgets/
│   ├── header.dart        # App header
│   ├── bottom_navigation.dart
│   ├── fab_menu.dart      # Floating action button
│   ├── chord_card.dart    # Chord display card
│   ├── preset_card.dart   # Preset selection card
│   ├── control_dropdown.dart
│   └── collapsible_section.dart
└── utils/
    ├── theme.dart         # App theming
    └── music_theory.dart  # Music theory functions
```

## 🎨 Theme

The app features a beautiful dark theme with purple accent colors, optimized for music creation at any time of day.

## 🎹 Supported Genres

| Genre | Style | Tempo |
|-------|-------|-------|
| Happy Pop | Major, uplifting | 120 BPM |
| Chill Lo-Fi | Minor 7ths, jazzy | 85 BPM |
| Energetic EDM | Anthemic | 128 BPM |
| Soulful R&B | Smooth, 9th chords | 90 BPM |
| Jazz Fusion | Complex harmony | 110 BPM |
| Dark Trap | Harmonic minor | 140 BPM |
| Cinematic | Epic, dramatic | 100 BPM |
| Indie Rock | Dreamy | 115 BPM |
| Reggae | Laid-back | 80 BPM |
| Blues | 12-bar variations | 90 BPM |
| Country | Nashville style | 110 BPM |
| Funk | Syncopated | 105 BPM |

## 👨‍�� Author

**Edgar Valle**

## 📄 License

© 2024 All rights reserved.
