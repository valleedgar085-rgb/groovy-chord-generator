# Pre-Flight Checker for APK Build
# Run this script to check if your environment is ready to build an APK

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Environment Pre-Flight Checker" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$allGood = $true

# Check Node.js
Write-Host "Checking Node.js..." -NoNewline
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host " OK Found $nodeVersion" -ForegroundColor Green
    }
    else {
        throw "Not found"
    }
}
catch {
    Write-Host " X Not found" -ForegroundColor Red
    Write-Host "  -> Install from: https://nodejs.org/" -ForegroundColor Yellow
    $allGood = $false
}

# Check npm
Write-Host "Checking npm..." -NoNewline
try {
    $npmVersion = npm --version 2>$null
    if ($npmVersion) {
        Write-Host " OK Found v$npmVersion" -ForegroundColor Green
    }
    else {
        throw "Not found"
    }
}
catch {
    Write-Host " X Not found" -ForegroundColor Red
    $allGood = $false
}

# Check node_modules
Write-Host "Checking dependencies..." -NoNewline
if (Test-Path "node_modules") {
    Write-Host " OK Installed" -ForegroundColor Green
}
else {
    Write-Host " X Missing" -ForegroundColor Red
    Write-Host "  -> Run: npm install" -ForegroundColor Yellow
    $allGood = $false
}

# Check for Capacitor packages
Write-Host "Checking Capacitor..." -NoNewline
if (Test-Path "node_modules/@capacitor/core") {
    Write-Host " OK Installed" -ForegroundColor Green
}
else {
    Write-Host " X Missing" -ForegroundColor Red
    Write-Host "  -> Run: npm install" -ForegroundColor Yellow
    $allGood = $false
}

# Check dist folder
Write-Host "Checking web build..." -NoNewline
if (Test-Path "dist") {
    Write-Host " OK Built" -ForegroundColor Green
}
else {
    Write-Host " ! Not built yet" -ForegroundColor Yellow
    Write-Host "  -> Run: npm run build" -ForegroundColor Yellow
}

# Check android folder
Write-Host "Checking Android platform..." -NoNewline
if (Test-Path "android") {
    Write-Host " OK Added" -ForegroundColor Green
}
else {
    Write-Host " ! Not added yet" -ForegroundColor Yellow
    Write-Host "  -> Run: npx cap add android" -ForegroundColor Yellow
}

# Check ANDROID_HOME
Write-Host "Checking ANDROID_HOME..." -NoNewline
$androidHome = [System.Environment]::GetEnvironmentVariable('ANDROID_HOME', 'User')
if (!$androidHome) {
    $androidHome = [System.Environment]::GetEnvironmentVariable('ANDROID_HOME', 'Machine')
}
if ($androidHome) {
    Write-Host " OK Set to $androidHome" -ForegroundColor Green
    if (!(Test-Path $androidHome)) {
        Write-Host "  ! Warning: Path doesn't exist!" -ForegroundColor Yellow
    }
}
else {
    Write-Host " ! Not set" -ForegroundColor Yellow
    Write-Host "  -> Usually: C:\Users\$env:USERNAME\AppData\Local\Android\Sdk" -ForegroundColor Gray
}

# Check Java/JDK
Write-Host "Checking Java..." -NoNewline
try {
    $javaVersion = java -version 2>&1 | Select-Object -First 1
    if ($javaVersion) {
        Write-Host " OK Found" -ForegroundColor Green
    }
    else {
        throw "Not found"
    }
}
catch {
    Write-Host " ! Not in PATH" -ForegroundColor Yellow
    Write-Host "  -> Android Studio includes JDK" -ForegroundColor Gray
}

# Check keytool
Write-Host "Checking keytool..." -NoNewline
try {
    $keytoolVersion = keytool 2>&1 | Select-Object -First 1
    if ($keytoolVersion) {
        Write-Host " OK Found" -ForegroundColor Green
    }
    else {
        throw "Not found"
    }
}
catch {
    Write-Host " ! Not in PATH" -ForegroundColor Yellow
    Write-Host "  -> Needed for creating keystore" -ForegroundColor Gray
}

# Check keystore
if (Test-Path "android") {
    Write-Host "Checking keystore..." -NoNewline
    if (Test-Path "android\app\release-key.keystore") {
        Write-Host " OK Exists" -ForegroundColor Green
    }
    else {
        Write-Host " ! Not created yet" -ForegroundColor Yellow
        Write-Host "  -> See QUICKSTART.md" -ForegroundColor Yellow
    }

    # Check key.properties
    Write-Host "Checking key.properties..." -NoNewline
    if (Test-Path "android\key.properties") {
        Write-Host " OK Exists" -ForegroundColor Green
        $keyProps = Get-Content "android\key.properties" -Raw
        if ($keyProps -match "YOUR_KEYSTORE_PASSWORD") {
            Write-Host "  ! Warning: Still has placeholder passwords!" -ForegroundColor Yellow
            Write-Host "  -> Edit android\key.properties with actual passwords" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host " ! Not created yet" -ForegroundColor Yellow
        Write-Host "  -> See QUICKSTART.md for template" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan

if ($allGood) {
    Write-Host "OK Ready to build!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. npm run build" -ForegroundColor White
    Write-Host "2. npx cap add android (if not done)" -ForegroundColor White
    Write-Host "3. Create keystore (if not done)" -ForegroundColor White
    Write-Host "4. Configure signing (if not done)" -ForegroundColor White
    Write-Host "5. .\build-apk.ps1" -ForegroundColor White
}
else {
    Write-Host "! Please fix the issues above" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Quick fix commands:" -ForegroundColor Cyan
    Write-Host "npm install" -ForegroundColor White
}

Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

