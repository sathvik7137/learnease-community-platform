# PowerShell script to automatically update ngrok URL
# Usage: .\scripts\update_ngrok_url.ps1

Write-Host "Fetching current ngrok URL..." -ForegroundColor Cyan

try {
    # Get ngrok API status
    $response = Invoke-WebRequest -Uri "http://127.0.0.1:4040/api/tunnels" -UseBasicParsing
    $json = $response.Content | ConvertFrom-Json
    
    if (-not $json.tunnels -or $json.tunnels.Count -eq 0) {
        Write-Host "No active ngrok tunnels found!" -ForegroundColor Red
        exit 1
    }
    
    $ngrokUrl = $json.tunnels[0].public_url
    Write-Host "Found ngrok URL: $ngrokUrl" -ForegroundColor Green
    
    # Update api_config.dart
    $configFile = "lib/config/api_config.dart"
    $content = Get-Content $configFile -Raw
    
    # Replace the production URL
    $content = $content -replace "static const String _productionBaseUrl = '[^']*';", "static const String _productionBaseUrl = '$ngrokUrl';"
    
    Set-Content -Path $configFile -Value $content
    Write-Host "Updated api_config.dart with new ngrok URL!" -ForegroundColor Green
    Write-Host "" 
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. flutter build web --release" -ForegroundColor Gray
    Write-Host "  2. firebase deploy --only hosting" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Done!" -ForegroundColor Green
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Make sure ngrok is running on http://127.0.0.1:4040" -ForegroundColor Yellow
    exit 1
}
