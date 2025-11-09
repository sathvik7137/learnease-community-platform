# Credential Rotation Helper Script
# ==================================
# This script helps you rotate exposed credentials

Write-Host "🔐 CREDENTIAL ROTATION HELPER" -ForegroundColor Red
Write-Host "============================" -ForegroundColor Red
Write-Host ""

Write-Host "⚠️  YOUR CREDENTIALS WERE EXPOSED ON GITHUB!" -ForegroundColor Yellow
Write-Host "You MUST rotate them NOW to secure your application." -ForegroundColor Yellow
Write-Host ""

# Generate new JWT Secret
Write-Host "1. GENERATING NEW JWT SECRET..." -ForegroundColor Cyan
$jwtSecret = [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
Write-Host "   New JWT Secret: $jwtSecret" -ForegroundColor Green
Write-Host ""

# Instructions for MongoDB
Write-Host "2. MONGODB PASSWORD - ACTION REQUIRED:" -ForegroundColor Cyan
Write-Host "   ❌ Your current MongoDB password was EXPOSED" -ForegroundColor Red
Write-Host "   📝 Steps:" -ForegroundColor Yellow
Write-Host "      a. Go to: https://cloud.mongodb.com/" -ForegroundColor White
Write-Host "      b. Click 'Database Access' in left sidebar" -ForegroundColor White
Write-Host "      c. Find your user (probably 'rayapureddyvardhan2004')" -ForegroundColor White
Write-Host "      d. Click 'Edit' → 'Edit Password'" -ForegroundColor White
Write-Host "      e. Click 'Autogenerate Secure Password' (RECOMMENDED)" -ForegroundColor White
Write-Host "      f. COPY the new password (you'll need it below)" -ForegroundColor White
Write-Host "      g. Click 'Update User'" -ForegroundColor White
Write-Host ""
$mongoPassword = Read-Host "   Enter your NEW MongoDB password"
Write-Host ""

# Instructions for Gmail SMTP
Write-Host "3. GMAIL APP PASSWORD - ACTION REQUIRED:" -ForegroundColor Cyan
Write-Host "   ❌ Your Gmail app password was EXPOSED" -ForegroundColor Red
Write-Host "   📝 Steps:" -ForegroundColor Yellow
Write-Host "      a. Go to: https://myaccount.google.com/apppasswords" -ForegroundColor White
Write-Host "      b. Find the old app password and DELETE it" -ForegroundColor White
Write-Host "      c. Click 'Create' → Select 'Other' → Type 'LearnEase Server'" -ForegroundColor White
Write-Host "      d. Click 'Generate'" -ForegroundColor White
Write-Host "      e. COPY the 16-character password" -ForegroundColor White
Write-Host ""
$smtpPassword = Read-Host "   Enter your NEW Gmail app password (16 chars)"
Write-Host ""

# Get Gmail address
$smtpUser = Read-Host "   Enter your Gmail address (e.g., your-email@gmail.com)"
Write-Host ""

# Get MongoDB username
$mongoUser = Read-Host "   Enter your MongoDB username (usually same as email prefix)"
Write-Host ""

# Get MongoDB cluster URL
Write-Host "   MongoDB cluster URL (e.g., cluster0.sufzx.mongodb.net):" -ForegroundColor Yellow
$mongoCluster = Read-Host "   "
Write-Host ""

# Build MongoDB URI
$mongoUri = "mongodb://${mongoUser}:${mongoPassword}@${mongoCluster}:27017/learnease?ssl=true&replicaSet=Cluster0-shard-0&authSource=admin"

Write-Host "4. UPDATING .ENV FILE..." -ForegroundColor Cyan

# Check if .env exists
$envPath = "community_server\.env"
if (Test-Path $envPath) {
    Write-Host "   Found existing .env file" -ForegroundColor Green
    
    # Backup old .env
    $backupPath = "community_server\.env.backup." + (Get-Date -Format "yyyyMMdd_HHmmss")
    Copy-Item $envPath $backupPath
    Write-Host "   Backed up to: $backupPath" -ForegroundColor Yellow
    
    # Read current .env
    $envContent = Get-Content $envPath -Raw
    
    # Update values
    $envContent = $envContent -replace 'JWT_SECRET=.*', "JWT_SECRET=$jwtSecret"
    $envContent = $envContent -replace 'MONGODB_URI=.*', "MONGODB_URI=$mongoUri"
    $envContent = $envContent -replace 'SMTP_USER=.*', "SMTP_USER=$smtpUser"
    $envContent = $envContent -replace 'SMTP_PASSWORD=.*', "SMTP_PASSWORD=$smtpPassword"
    
    # Write updated .env
    Set-Content -Path $envPath -Value $envContent
    Write-Host "   ✅ .env file updated!" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  .env file not found. Creating from template..." -ForegroundColor Yellow
    
    # Create new .env from template
    $newEnv = @"
# Updated credentials - $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
AI_MODEL=models/text-bison-001
GEMINI_API_KEY=your_gemini_api_key_here

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=$smtpUser
SMTP_PASSWORD=$smtpPassword

# JWT Secret
JWT_SECRET=$jwtSecret

# MongoDB Connection
MONGODB_URI=$mongoUri
"@
    
    Set-Content -Path $envPath -Value $newEnv
    Write-Host "   ✅ Created new .env file!" -ForegroundColor Green
}

Write-Host ""
Write-Host "5. RENDER ENVIRONMENT VARIABLES - ACTION REQUIRED:" -ForegroundColor Cyan
Write-Host "   📝 Update these in Render dashboard:" -ForegroundColor Yellow
Write-Host "      a. Go to: https://dashboard.render.com" -ForegroundColor White
Write-Host "      b. Select your service" -ForegroundColor White
Write-Host "      c. Click 'Environment' tab" -ForegroundColor White
Write-Host "      d. Update these variables:" -ForegroundColor White
Write-Host ""
Write-Host "   JWT_SECRET=$jwtSecret" -ForegroundColor Cyan
Write-Host "   MONGODB_URI=$mongoUri" -ForegroundColor Cyan
Write-Host "   SMTP_USER=$smtpUser" -ForegroundColor Cyan
Write-Host "   SMTP_PASSWORD=$smtpPassword" -ForegroundColor Cyan
Write-Host ""
Write-Host "      e. Click 'Save Changes'" -ForegroundColor White
Write-Host "      f. Render will auto-redeploy with new credentials" -ForegroundColor White
Write-Host ""

Write-Host "6. MAKE REPOSITORY PRIVATE:" -ForegroundColor Cyan
Write-Host "   📝 Immediately hide the exposed secrets:" -ForegroundColor Yellow
Write-Host "      Go to: https://github.com/sathvik7137/learnease-community-platform/settings" -ForegroundColor White
Write-Host "      Scroll to 'Danger Zone' → Click 'Change visibility' → Make Private" -ForegroundColor White
Write-Host ""

Write-Host "✅ LOCAL CREDENTIALS ROTATED!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 NEXT STEPS:" -ForegroundColor Yellow
Write-Host "   1. Update Render environment variables (see above)" -ForegroundColor White
Write-Host "   2. Make repository private (see above)" -ForegroundColor White
Write-Host "   3. Test your local server: cd community_server; dart run bin/server.dart" -ForegroundColor White
Write-Host "   4. Verify old credentials don't work anymore" -ForegroundColor White
Write-Host ""
Write-Host "🔒 Your application is now secure with NEW credentials!" -ForegroundColor Green
Write-Host ""

# Ask if user wants to test local server
$testServer = Read-Host "Do you want to test the local server now? (y/n)"
if ($testServer -eq 'y' -or $testServer -eq 'Y') {
    Write-Host ""
    Write-Host "Starting local server..." -ForegroundColor Cyan
    Set-Location community_server
    dart pub get
    dart run bin/server.dart
}
