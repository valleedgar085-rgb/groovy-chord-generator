#!/bin/bash

# Groovy Chord Generator - APK Build Script
# This script builds a release APK for the Groovy Chord Generator app

set -e  # Exit on error

echo "================================================"
echo "Groovy Chord Generator - APK Build Script"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: Flutter is not installed or not in PATH${NC}"
    echo "Please install Flutter from https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo -e "${GREEN}✓${NC} Flutter detected: $(flutter --version | head -1)"
echo ""

# Check if keystore is configured
if [ -f "android/key.properties" ]; then
    echo -e "${GREEN}✓${NC} Keystore configuration found"
    echo -e "${YELLOW}ℹ${NC} Building with release signing"
else
    echo -e "${YELLOW}⚠${NC} No keystore configuration found"
    echo -e "${YELLOW}ℹ${NC} Building with debug signing (not suitable for production)"
    echo ""
    echo "To create a release keystore, see KEYSTORE_SETUP.md"
    echo ""
    read -p "Continue with debug signing? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo ""

# Step 1: Clean previous builds
echo "Step 1/5: Cleaning previous builds..."
flutter clean
echo -e "${GREEN}✓${NC} Clean complete"
echo ""

# Step 2: Get dependencies
echo "Step 2/5: Getting dependencies..."
flutter pub get
echo -e "${GREEN}✓${NC} Dependencies installed"
echo ""

# Step 3: Generate launcher icons (if configured)
if grep -q "flutter_launcher_icons" pubspec.yaml; then
    echo "Step 3/5: Generating launcher icons..."
    flutter pub run flutter_launcher_icons:main || echo -e "${YELLOW}⚠${NC} Icon generation skipped (optional)"
    echo ""
else
    echo "Step 3/5: Skipping launcher icons (not configured)"
    echo ""
fi

# Step 4: Build APK
echo "Step 4/5: Building release APK..."
echo "This may take several minutes..."
echo ""
flutter build apk --release
echo ""
echo -e "${GREEN}✓${NC} APK build complete"
echo ""

# Step 5: Show build info
echo "Step 5/5: Build information"
echo "================================================"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo -e "${GREEN}✓${NC} APK created successfully!"
    echo ""
    echo "Location: $APK_PATH"
    echo "Size: $APK_SIZE"
    echo ""
    echo "To install on a connected device:"
    echo "  flutter install"
    echo ""
    echo "To install manually:"
    echo "  adb install $APK_PATH"
    echo ""
else
    echo -e "${RED}✗${NC} APK file not found at expected location"
    exit 1
fi

echo "================================================"
echo -e "${GREEN}Build Complete!${NC}"
echo "================================================"
