# 🚀 LearnEase Deployment Guide

## Quick Start

### Local Development
```bash
# Terminal 1: Start backend server
cd community_server
dart run bin/server.dart

# Terminal 2: Start Flutter app
flutter run -d chrome
```
✅ App automatically uses `http://localhost:8080`

---

### Production Deployment

#### Step 1: Start Backend & Ngrok
```bash
# Terminal 1: Backend server
cd community_server
dart run bin/server.dart

# Terminal 2: Start ngrok tunnel
ngrok http 8080
```

#### Step 2: Update ngrok URL (When it changes)
```bash
# PowerShell - Run from project root
.\scripts\update_ngrok_url.ps1
```

This script will:
- ✅ Fetch the current ngrok URL automatically
- ✅ Update `lib/config/api_config.dart`
- ✅ All files automatically use the new URL

#### Step 3: Build & Deploy to Firebase
```bash
# Build
flutter build web --release

# Deploy
firebase deploy --only hosting
```

#### Step 4: Share with your friend
```
Frontend: https://learnease-app-temp.web.app
```

---

## How It Works

### Automatic URL Detection
The `ApiConfig` class in `lib/config/api_config.dart` automatically detects the environment:

```dart
class ApiConfig {
  static String get webBaseUrl {
    if (kDebugMode) {
      return 'http://localhost:8080';  // Local development
    }
    return _productionBaseUrl;  // Production (ngrok/deployed)
  }
}
```

### All API Calls Use One Config
Every service imports and uses `ApiConfig`:
- ✅ `auth_service.dart`
- ✅ `user_content_service.dart`
- ✅ `ai_service.dart`
- ✅ `admin_dashboard_screen.dart`
- ✅ `admin_contributions_screen.dart`
- ✅ `admin_user_management_screen.dart`

### Single Source of Truth
Update ngrok URL in **ONE place**:
```dart
// lib/config/api_config.dart
static const String _productionBaseUrl = 'https://YOUR-NEW-NGROK-URL.ngrok-free.app';
```

---

## Troubleshooting

### App shows "Network error" on mobile
1. Clear browser cache completely
2. Hard refresh (long-press refresh button)
3. Check if ngrok tunnel is still running
4. Update ngrok URL if it changed

### "No active ngrok tunnels found"
- Make sure ngrok is running: `ngrok http 8080`
- Ngrok API runs on `http://127.0.0.1:4040` by default

### Backend connection fails locally
- Ensure backend is running on `http://localhost:8080`
- Check: `netstat -ano | findstr "8080"`

---

## Keeping Ngrok Running

To keep the tunnel persistent:
```bash
# Option 1: Keep terminal open (simple)
ngrok http 8080

# Option 2: Use a process manager
# pm2 install pm2-windows-startup
# pm2 start "ngrok http 8080"
# pm2 save
```

---

## Timeline of Changes

✅ **V1.0** - Hardcoded URLs (problematic)
✅ **V2.0** - Centralized API config (better)
✅ **V3.0** - Automatic URL updater script (best!)

---

## Scripts Available

### `update_ngrok_url.ps1` (Recommended for Windows)
- Automatically fetches current ngrok URL
- Updates config file
- Shows next steps

### `update_ngrok_url.dart`
- Dart version of the updater
- Run with: `dart scripts/update_ngrok_url.dart`

---

## Summary

| Task | Command |
|------|---------|
| **Local Dev** | `flutter run -d chrome` |
| **Start Backend** | `cd community_server && dart run bin/server.dart` |
| **Start Ngrok** | `ngrok http 8080` |
| **Update URL** | `.\scripts\update_ngrok_url.ps1` |
| **Build Web** | `flutter build web --release` |
| **Deploy** | `firebase deploy --only hosting` |

🎉 **Done! Your app is live!**
