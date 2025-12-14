# App Icon Setup Guide

This guide explains how to customize and generate app launcher icons for the Groovy Chord Generator.

## Current Icon

The app currently includes a default icon at `assets/icon/app_icon.png` featuring:
- Purple to pink gradient background (matching the app's color scheme)
- Music note symbol
- "C7" chord notation
- Clean, modern design

## Customizing the Icon

### Option 1: Replace Existing Icon

1. Create or obtain a new icon image (PNG format)
2. Image should be **512x512 pixels** minimum
3. Use square format with transparent or solid background
4. Replace `assets/icon/app_icon.png` with your new icon

### Option 2: Edit SVG Source

1. Edit `assets/icon/app_icon.svg` in any vector graphics editor:
   - Adobe Illustrator
   - Inkscape (free)
   - Figma
   - Sketch

2. Export as PNG at 512x512 pixels
3. Save to `assets/icon/app_icon.png`

### Design Guidelines

For best results, follow Android's icon design guidelines:

**Recommended:**
- Simple, recognizable design
- High contrast
- Avoid fine details (may not render well at small sizes)
- Test at various sizes (48x48, 72x72, 96x96, 144x144)
- Use solid shapes rather than thin lines

**Colors:**
- App theme colors: Purple (#8B5CF6), Pink (#F472B6), Cyan (#22D3EE)
- Background: Dark (#14142B) or gradient
- Foreground: White/light colors for contrast

**Themes:**
- Music notes
- Chord symbols (like C, Am, G7)
- Piano keys
- Guitar pick
- Treble/bass clef
- Waveforms

## Generating Launcher Icons

Once you have your icon at `assets/icon/app_icon.png`, generate the launcher icons:

### Method 1: Using flutter_launcher_icons Package

```bash
# Install dependencies
flutter pub get

# Generate icons
flutter pub run flutter_launcher_icons
```

This will automatically create:
- Multiple resolution icons for Android
- Adaptive icons (with separate foreground/background)
- Icons placed in correct resource directories

### Method 2: Using Build Script

The build scripts (`build_apk.sh` and `build_apk.bat`) automatically generate icons during the build process.

```bash
# Linux/macOS
./build_apk.sh

# Windows
build_apk.bat
```

## Configuration

Icon generation is configured in `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon/app_icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#14142B"
  adaptive_icon_foreground: "assets/icon/app_icon.png"
```

### Configuration Options

- **android**: Generate Android icons (true/false)
- **ios**: Generate iOS icons (true/false)
- **image_path**: Path to source icon
- **min_sdk_android**: Minimum Android SDK version
- **adaptive_icon_background**: Background color for Android adaptive icons
- **adaptive_icon_foreground**: Foreground image for Android adaptive icons

## Android Adaptive Icons

Android 8.0+ uses adaptive icons that can be shaped differently on different devices:
- Circle
- Square
- Rounded square
- Squircle

The configuration uses:
- **Foreground**: Your icon image
- **Background**: Solid dark color (#14142B) matching the app theme

This ensures the icon looks good regardless of device shape mask.

## Manual Icon Creation

If you prefer to create icons manually:

### Required Sizes for Android

Place icons in `android/app/src/main/res/`:

- `mipmap-mdpi/ic_launcher.png` - 48x48
- `mipmap-hdpi/ic_launcher.png` - 72x72
- `mipmap-xhdpi/ic_launcher.png` - 96x96
- `mipmap-xxhdpi/ic_launcher.png` - 144x144
- `mipmap-xxxhdpi/ic_launcher.png` - 192x192

### Adaptive Icons

For adaptive icons (Android 8.0+), also create:

- `mipmap-anydpi-v26/ic_launcher.xml`
- Foreground and background PNGs in each density folder

## Testing Icons

After generating icons:

1. Build and install the app:
   ```bash
   flutter build apk --release
   flutter install
   ```

2. Check the app icon on your device:
   - Home screen
   - App drawer
   - Recent apps
   - Settings > Apps

3. Test on different Android versions if possible

## Troubleshooting

### Icons not updating
1. Uninstall the app completely
2. Run `flutter clean`
3. Rebuild and reinstall

### Icons look blurry
- Ensure source icon is at least 512x512
- Check that high-resolution icons are being generated
- Avoid upscaling small images

### Adaptive icon background shows
- This is normal on Android 8.0+
- Ensure `adaptive_icon_background` color matches your icon
- Or use transparent background in foreground image

## Resources

- [Flutter Launcher Icons Package](https://pub.dev/packages/flutter_launcher_icons)
- [Android Icon Design Guidelines](https://developer.android.com/guide/practices/ui_guidelines/icon_design_launcher)
- [Material Design Icons](https://material.io/design/iconography/)
- [Android Adaptive Icons](https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive)

## Free Icon Tools

- **Inkscape** - Free vector graphics editor
- **GIMP** - Free raster graphics editor
- **Figma** - Free web-based design tool
- **Canva** - Free online design tool (with templates)

---

**Note:** Remember to regenerate icons after any changes to `assets/icon/app_icon.png`!
