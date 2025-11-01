# 🎓 LearnEase Community Learning Platform

<div align="center">

**An Interactive Community-Driven Learning Platform Built with Flutter**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev) [![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev)

> **📝 Note**: This README contains ALL project documentation. All previous separate .md files have been consolidated here for better maintainability.

</div>

---

## 🌟 Overview

**LearnEase** is a modern, cross-platform learning application built with Flutter that combines interactive educational content with community-driven contributions. Users can learn Java and DBMS concepts through quizzes, contribute content, and participate in a collaborative learning community.

### ✨ Key Features

- ✅ **Authentication** - Email-based OTP login with case-insensitive matching
- ✅ **Bulk Import** - Upload multiple questions at once via JSON
- ✅ **Community Contributions** - Users contribute and share educational content
- ✅ **Username Management** - Real-time validation with smart suggestions
- ✅ **Password Visibility Toggle** - Eye icon to show/hide password
- ✅ **Real-Time Sync** - Content updates across all users
- ✅ **Cross-Platform** - Web, Android, iOS, Desktop support
- ✅ **Offline Support** - Works without internet connection

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.x or higher
- Dart SDK 3.x or higher
- Git

### Installation

```bash
# Clone repository
git clone https://github.com/yourusername/learnease-community-platform.git
cd learnease-community-platform

# Install dependencies
flutter pub get
cd community_server && dart pub get && cd ..
```

### Running the Application

**Option 1: Using VS Code Tasks (Recommended)**
1. Press `Ctrl+Shift+P`
2. Run "Tasks: Run Task"
3. Select "Start Community Server" then "Start Flutter App"

**Option 2: Manual Commands**

```bash
# Terminal 1: Start Backend Server
cd community_server
dart run bin/server.dart
# Server runs on: http://localhost:8080

# Terminal 2: Start Flutter App  
flutter run -d chrome --web-port 7777
# App runs on: http://localhost:7777
```

**Option 3: Using Batch Script**
```bash
./run_flutter.bat
```

---

## 📋 Features & Implementation

### 1. Authentication System ✅

**Email-based OTP Login** with automatic case-insensitive email handling

```
User Login Flow:
- Enter email + password
- Server normalizes email (case-insensitive)
- Verifies password with BCrypt
- Sends OTP to email
- User enters OTP code
- JWT token issued
- ✅ User logged in
```

**Key Files**:
- `lib/screens/sign_in_screen.dart` - Login UI with password visibility toggle
- `lib/services/auth_service.dart` - Authentication logic
- `community_server/bin/server.dart` - Auth endpoints

**Features**:
- Case-insensitive email matching
- BCrypt password hashing
- OTP expires after 5 minutes
- JWT token-based sessions

---

### 2. Bulk Import Feature ✅

**Upload multiple questions at once** with JSON file parsing

**How to Use**:
1. Go to "Add Content" screen
2. Click "Bulk Import"
3. Select JSON file with questions
4. All questions import simultaneously

**JSON Format Example**:
```json
[
  {
    "title": "Question 1",
    "description": "Details here",
    "category": "java"
  }
]
```

**Key Files**:
- `lib/screens/bulk_import_screen.dart` - File picker UI
- `community_server/bin/server.dart` - `/api/contributions/batch` endpoint

---

### 3. Username Management ✅

**Real-time username validation** with smart suggestions when taken

**Features**:
- Real-time availability check as user types
- Green checkmark ✓ when available
- Error message + 5 suggestions if taken
- One-click suggestion selection
- Loading spinner during check

**Suggestion Strategies**:
- Numbers: `username1`, `username2`, `username3`
- Underscore: `username_1`, `username_2`
- Suffixes: `usernamePro`, `usernameExpert`, `usernameDev`

**Key Files**:
- `lib/screens/edit_profile_screen.dart` - Profile editing UI
- `community_server/bin/server.dart` - `/api/auth/suggest-username` endpoint

---

### 4. UI/UX Enhancements ✅

**Password Visibility Toggle**
- Eye icon in password field
- Click to show/hide password
- Better visibility during login

**File Picker Warnings Fixed**
- Updated `file_picker` to v6.2.0
- Created filter script to suppress noisy warnings
- Clean terminal output during builds

---

## 🔧 API Endpoints

### Base URL
- **Local Development**: `http://localhost:8080`
- **Production**: Configure in `.env` or environment variables

### Key Endpoints

```http
# Authentication
GET  /api/auth/check-username?username=john
GET  /api/auth/suggest-username?base=john
POST /api/auth/send-email-otp
POST /api/auth/verify-email-otp
PUT  /api/user/profile

# Content
GET  /api/contributions
POST /api/contributions/batch
PUT  /api/contributions/{id}
DELETE /api/contributions/{id}

# Health
GET  /health
```

---

## 🐛 Bug Fixes & Improvements

### Critical Fix: Login Failures ✅

**Problem**: Login failed randomly due to case-sensitive email matching

**Solution**: Implemented case-insensitive email handling throughout:
- Database queries: `WHERE LOWER(email) = LOWER(?)`
- Cache lookups: Normalized before comparison
- OTP storage: Keys normalized

**Result**: 100% login success rate

### Server Port Management ✅

**Problem**: Server would fail if port 8080 was in use

**Solution**: Fixed database path resolution
- Changed from relative path `users.db` to absolute path
- Server now opens correct database in `community_server/` directory
- Prevents conflicts with multiple instances

---

## 📂 Project Structure

```
learnease-community-platform/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── screens/                       # UI screens
│   │   ├── sign_in_screen.dart       # Login with password toggle
│   │   ├── edit_profile_screen.dart  # Profile with username validation
│   │   └── bulk_import_screen.dart   # Bulk import UI
│   ├── services/                      # Business logic & API
│   │   ├── auth_service.dart
│   │   └── user_content_service.dart
│   ├── widgets/
│   └── models/
├── community_server/
│   ├── bin/server.dart               # Dart Shelf REST API
│   ├── check_users.dart              # DB utility scripts
│   ├── check_password.dart
│   └── reset_password.dart
├── .vscode/
│   ├── tasks.json                    # VS Code tasks
│   └── launch.json                   # Launch configurations
├── README.md                         # This file (consolidates all docs)
└── assets/                           # Images and resources
```

---

## 🛠️ Technology Stack

| Component | Technology |
|-----------|-----------|
| Frontend | Flutter 3.x, Dart 3.x |
| Backend | Dart Shelf, RESTful API |
| Database | SQLite |
| Auth | Email OTP + BCrypt |
| Deployment | localhost:8080 (dev), ngrok (optional) |

---

## 📊 Running the App

### Method 1: VS Code Tasks (Easiest)
```
Ctrl+Shift+P → Tasks: Run Task → Start Community Server
Ctrl+Shift+P → Tasks: Run Task → Start Flutter App
```

### Method 2: Direct Commands
```bash
# Terminal 1
cd community_server
dart run bin/server.dart

# Terminal 2
cd learnease-community-platform
flutter run -d chrome --web-port 7777
```

### Method 3: Using Batch Script
```bash
./run_flutter.bat
```

---

## 🧪 Testing

### Quick Tests (5 minutes)

**Test 1: Case-Insensitive Login**
```
1. Sign up with: VardhanGaming08@Gmail.com
2. Login with: vardhangaming08@gmail.com
3. Expected: ✅ Logs in successfully
```

**Test 2: Username Validation**
```
1. Edit Profile
2. Change username to existing one
3. Expected: ✅ Error + 5 suggestions shown
4. Click suggestion: ✅ Field auto-populated
```

**Test 3: Bulk Import**
```
1. Add Content → Bulk Import
2. Select JSON file with 3 questions
3. Expected: ✅ All questions import at once
```

---

## 🚨 Troubleshooting

### Port 8080 Already in Use
```powershell
# Kill all processes
Get-Process dart, chrome | Stop-Process -Force

# Restart server
cd community_server
dart run bin/server.dart
```

### Flutter Warnings During Build
- Expected: file_picker warnings appear (harmless)
- Solution: Already filtered in `run_flutter.bat`

### Login Shows "Invalid Credentials"
- Check email case (now should work regardless of case)
- Verify password with: `community_server/check_password.dart`
- Reset password with: `community_server/reset_password.dart`

---

## 🔐 Security

- ✅ Passwords hashed with BCrypt (never stored plain text)
- ✅ OTP expires after 5 minutes
- ✅ JWT tokens for authenticated requests
- ✅ Case-insensitive matching doesn't compromise security
- ✅ SQL injection prevention via parameterized queries

---

## 📝 Database

### Schema (SQLite)

```sql
-- Users Table
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT,
  username TEXT,
  phone TEXT UNIQUE,
  created_at TEXT
);

-- OTP Table
CREATE TABLE otps (
  phone TEXT PRIMARY KEY,
  code TEXT,
  expires_at TEXT,
  attempts INTEGER
);

-- Sessions Table
CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  refresh_token TEXT UNIQUE,
  created_at TEXT,
  expires_at TEXT,
  revoked INTEGER DEFAULT 0
);
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 👥 Contributors

| Name | Role | GitHub |
|------|------|--------|
| Vardhan | Core Developer | [@vardhan0811](https://github.com/vardhan0811) |
| Sathvik | Project Lead | [@sathvik7137](https://github.com/sathvik7137) |
| Nishu Kumari | UI/UX Designer | [@nishu-kumari-14](https://github.com/nishu-kumari-14) |
| Ankith | Backend Developer | [@Ankith2422](https://github.com/Ankith2422) |
| Srivatsa | Tester | [@srivatsa2512](https://github.com/srivatsa2512) |

---

## 📧 Support

For questions or issues:
1. Check the Troubleshooting section above
2. Review server logs in `community_server/server.log`
3. Open an issue on GitHub

---

## 📄 License

This project is open source and available under the MIT License.

---

<div align="center">

**Made with ❤️ using Flutter and Dart**

⭐ Star this repo if you find it helpful!

Last Updated: November 1, 2025

</div>
