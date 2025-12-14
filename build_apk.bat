@echo off
REM Groovy Chord Generator - APK Build Script (Windows)
REM This script builds a release APK for the Groovy Chord Generator app

setlocal enabledelayedexpansion

echo ================================================
echo Groovy Chord Generator - APK Build Script
echo ================================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: Flutter is not installed or not in PATH
    echo Please install Flutter from https://flutter.dev/docs/get-started/install
    exit /b 1
)

for /f "delims=" %%i in ('flutter --version ^| findstr /C:"Flutter"') do set FLUTTER_VERSION=%%i
echo [OK] Flutter detected: %FLUTTER_VERSION%
echo.

REM Check if keystore is configured
if exist "android\key.properties" (
    echo [OK] Keystore configuration found
    echo [INFO] Building with release signing
) else (
    echo [WARNING] No keystore configuration found
    echo [INFO] Building with debug signing (not suitable for production)
    echo.
    echo To create a release keystore, see KEYSTORE_SETUP.md
    echo.
    set /p CONTINUE="Continue with debug signing? (y/n): "
    if /i not "!CONTINUE!"=="y" exit /b 1
)
echo.

REM Step 1: Clean previous builds
echo Step 1/5: Cleaning previous builds...
call flutter clean
if %errorlevel% neq 0 exit /b %errorlevel%
echo [OK] Clean complete
echo.

REM Step 2: Get dependencies
echo Step 2/5: Getting dependencies...
call flutter pub get
if %errorlevel% neq 0 exit /b %errorlevel%
echo [OK] Dependencies installed
echo.

REM Step 3: Generate launcher icons (if configured)
findstr /C:"flutter_launcher_icons" pubspec.yaml >nul 2>nul
if %errorlevel% equ 0 (
    echo Step 3/5: Generating launcher icons...
    call flutter pub run flutter_launcher_icons:main
    echo.
) else (
    echo Step 3/5: Skipping launcher icons (not configured)
    echo.
)

REM Step 4: Build APK
echo Step 4/5: Building release APK...
echo This may take several minutes...
echo.
call flutter build apk --release
if %errorlevel% neq 0 (
    echo [ERROR] APK build failed
    exit /b %errorlevel%
)
echo.
echo [OK] APK build complete
echo.

REM Step 5: Show build info
echo Step 5/5: Build information
echo ================================================
set APK_PATH=build\app\outputs\flutter-apk\app-release.apk
if exist "%APK_PATH%" (
    echo [OK] APK created successfully!
    echo.
    echo Location: %APK_PATH%
    for %%A in ("%APK_PATH%") do echo Size: %%~zA bytes
    echo.
    echo To install on a connected device:
    echo   flutter install
    echo.
    echo To install manually:
    echo   adb install %APK_PATH%
    echo.
) else (
    echo [ERROR] APK file not found at expected location
    exit /b 1
)

echo ================================================
echo Build Complete!
echo ================================================

endlocal
