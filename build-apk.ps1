# Groovy Chord Generator - Build Signed APK Script
# This script builds the web app and creates a signed Android APK

param(
    [switch]$SkipBuild = $false,
    [switch]$Clean = $false
)

$ErrorActionPreference = "Stop"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Groovy Chord Generator APK Build" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check if node is available
try {
    $nodeVersion = node --version
    Write-Host "✓ Node.js $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Node.js not found!" -ForegroundColor Red
    Write-Host "Please install Node.js from https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

# Check if npm is available
try {
    $npmVersion = npm --version
    Write-Host "✓ npm $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ npm not found!" -ForegroundColor Red
    exit 1
}

# Check if dependencies are installed
if (!(Test-Path "node_modules")) {
    Write-Host ""
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    npm install
}

# Clean if requested
if ($Clean) {
    Write-Host ""
    Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
    if (Test-Path "dist") { Remove-Item -Recurse -Force "dist" }
    if (Test-Path "android\app\build") { Remove-Item -Recurse -Force "android\app\build" }
}

# Build web app
if (!$SkipBuild) {
    Write-Host ""
    Write-Host "Building web app..." -ForegroundColor Yellow
    npm run build

    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Web build failed!" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Web build complete" -ForegroundColor Green
}

# Check if android folder exists
if (!(Test-Path "android")) {
    Write-Host ""
    Write-Host "Android platform not found. Adding it..." -ForegroundColor Yellow
    npx cap add android

    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Failed to add Android platform!" -ForegroundColor Red
        exit 1
    }
}

# Sync to Android
Write-Host ""
Write-Host "Syncing to Android..." -ForegroundColor Yellow
npx cap sync android

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Sync failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Sync complete" -ForegroundColor Green

# Check if keystore exists
$keystorePath = "android\app\release-key.keystore"
if (!(Test-Path $keystorePath)) {
    Write-Host ""
    Write-Host "⚠ Keystore not found at: $keystorePath" -ForegroundColor Yellow
    Write-Host "Please create a keystore first. See BUILD_APK_GUIDE.md for instructions." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Quick command:" -ForegroundColor Cyan
    Write-Host "cd android\app" -ForegroundColor White
    Write-Host "keytool -genkey -v -keystore release-key.keystore -alias groovy-key -keyalg RSA -keysize 2048 -validity 10000" -ForegroundColor White
    Write-Host ""
    $continue = Read-Host "Continue without signed APK? (y/n)"
    if ($continue -ne "y") {
        exit 0
    }
}

# Check if key.properties exists
$keyPropsPath = "android\key.properties"
if (!(Test-Path $keyPropsPath)) {
    Write-Host ""
    Write-Host "⚠ key.properties not found" -ForegroundColor Yellow
    Write-Host "Creating template key.properties file..." -ForegroundColor Yellow

    $keyPropsContent = @"
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=groovy-key
storeFile=release-key.keystore
"@

    Set-Content -Path $keyPropsPath -Value $keyPropsContent
    Write-Host "✓ Created $keyPropsPath" -ForegroundColor Green
    Write-Host "Please edit this file with your actual keystore passwords!" -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Have you updated key.properties with correct passwords? (y/n)"
    if ($continue -ne "y") {
        Write-Host "Please update key.properties and run this script again." -ForegroundColor Yellow
        exit 0
    }
}

# Build APK
Write-Host ""
Write-Host "Building signed APK..." -ForegroundColor Yellow
Write-Host "This may take several minutes..." -ForegroundColor Gray

Push-Location android

try {
    .\gradlew assembleRelease

    if ($LASTEXITCODE -ne 0) {
        throw "Gradle build failed"
    }

    Write-Host "✓ APK build complete" -ForegroundColor Green

    # Find the APK
    $apkPath = "app\build\outputs\apk\release\app-release.apk"

    if (Test-Path $apkPath) {
        $apkSize = (Get-Item $apkPath).Length / 1MB
        Write-Host ""
        Write-Host "✓ APK created successfully!" -ForegroundColor Green
        Write-Host "  Size: $([math]::Round($apkSize, 2)) MB" -ForegroundColor Cyan
        Write-Host "  Location: android\$apkPath" -ForegroundColor Cyan

        # Copy to root with version
        $packageJson = Get-Content "..\package.json" | ConvertFrom-Json
        $version = $packageJson.version
        $outputName = "groovy-chord-generator-v$version.apk"

        Copy-Item $apkPath "..\$outputName" -Force
        Write-Host ""
        Write-Host "✓ Copied to: $outputName" -ForegroundColor Green

        # Show file info
        Write-Host ""
        Write-Host "================================" -ForegroundColor Cyan
        Write-Host "Build Summary" -ForegroundColor Cyan
        Write-Host "================================" -ForegroundColor Cyan
        Write-Host "App: Groovy Chord Generator v$version" -ForegroundColor White
        Write-Host "Package: com.edgarvalle.groovychordgenerator" -ForegroundColor White
        Write-Host "APK: $outputName" -ForegroundColor White
        Write-Host ""
        Write-Host "To install on device via ADB:" -ForegroundColor Yellow
        Write-Host "  adb install $outputName" -ForegroundColor White
        Write-Host ""
        Write-Host "Or copy the APK to your phone and install it." -ForegroundColor Yellow

    } else {
        Write-Host "✗ APK not found at expected location!" -ForegroundColor Red
    }

} catch {
    Write-Host "✗ Build failed: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location

Write-Host ""
Write-Host "Done! ✨" -ForegroundColor Green

