# LearnEase - Build Release APK/Bundle Script
# Run this script to build production-ready Android app

Write-Host "================================" -ForegroundColor Cyan
Write-Host "LearnEase Production Build Script" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is installed
Write-Host "1. Checking Flutter installation..." -ForegroundColor Yellow
$flutterCheck = flutter --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter not found! Please install Flutter first." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Flutter found" -ForegroundColor Green
Write-Host ""

# Clean previous builds
Write-Host "2. Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
Write-Host "✅ Clean complete" -ForegroundColor Green
Write-Host ""

# Get dependencies
Write-Host "3. Getting dependencies..." -ForegroundColor Yellow
flutter pub get
Write-Host "✅ Dependencies installed" -ForegroundColor Green
Write-Host ""

# Check for keystore
Write-Host "4. Checking for release keystore..." -ForegroundColor Yellow
$keystorePath = "C:\Users\CyberBot\learnease-release-key.jks"
if (-Not (Test-Path $keystorePath)) {
    Write-Host "⚠️  Keystore not found! Creating one now..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please answer the following questions to create your signing key:" -ForegroundColor Cyan
    Write-Host ""
    
    $command = "keytool -genkey -v -keystore `"$keystorePath`" -keyalg RSA -keysize 2048 -validity 10000 -alias learnease"
    
    Invoke-Expression $command
    
    if (-Not (Test-Path $keystorePath)) {
        Write-Host "❌ Failed to create keystore. Build aborted." -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Keystore created successfully" -ForegroundColor Green
} else {
    Write-Host "✅ Keystore found" -ForegroundColor Green
}
Write-Host ""

# Build APK
Write-Host "5. Building Release APK..." -ForegroundColor Yellow
Write-Host "This may take several minutes..." -ForegroundColor Gray
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ APK build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ APK built successfully" -ForegroundColor Green
Write-Host ""

# Build App Bundle (for Play Store)
Write-Host "6. Building App Bundle (AAB for Play Store)..." -ForegroundColor Yellow
Write-Host "This may take several minutes..." -ForegroundColor Gray
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ App Bundle build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ App Bundle built successfully" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "================================" -ForegroundColor Cyan
Write-Host "✅ BUILD COMPLETE!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📦 APK Location:" -ForegroundColor Yellow
Write-Host "   build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor White
Write-Host ""
Write-Host "📦 App Bundle Location (Upload this to Play Store):" -ForegroundColor Yellow
Write-Host "   build\app\outputs\bundle\release\app-release.aab" -ForegroundColor White
Write-Host ""
Write-Host "📊 APK Size:" -ForegroundColor Yellow
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    $apkSize = (Get-Item $apkPath).Length / 1MB
    Write-Host "   $([math]::Round($apkSize, 2)) MB" -ForegroundColor White
}
Write-Host ""
Write-Host "📊 App Bundle Size:" -ForegroundColor Yellow
$aabPath = "build\app\outputs\bundle\release\app-release.aab"
if (Test-Path $aabPath) {
    $aabSize = (Get-Item $aabPath).Length / 1MB
    Write-Host "   $([math]::Round($aabSize, 2)) MB" -ForegroundColor White
}
Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Test the APK on a real device" -ForegroundColor White
Write-Host "   2. Upload app-release.aab to Google Play Console" -ForegroundColor White
Write-Host "   3. Configure store listing and screenshots" -ForegroundColor White
Write-Host ""
