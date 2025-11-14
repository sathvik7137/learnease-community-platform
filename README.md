# 🎓 LearnEase Community Platform
**A modern, cross-platform learning application built with Flutter and Dart**
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev)
[![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-green.svg)](https://www.mongodb.com)
> An interactive community-driven platform for learning Java and DBMS through quizzes, challenges, and collaborative content creation.
---
## 🚀 Quick Start
### Prerequisites
- Flutter SDK 3.x+
- Dart SDK 3.x+
- MongoDB Atlas account (production) or MongoDB local (development)
### Installation & Run
```bash
# Clone repository
git clone https://github.com/sathvik7137/learnease-community-platform.git
cd learnease-community-platform
# Install dependencies
flutter pub get
cd community_server && dart pub get && cd ..
# Start backend server (Terminal 1)
cd community_server
dart run bin/server.dart
# Server runs on http://localhost:8080
# Start Flutter app (Terminal 2)
flutter run -d chrome --web-port 7777
# App runs on http://localhost:7777
```
**VS Code Users:** Press F5 to auto-launch both server and app with fixed ports.
---
## ✨ Key Features
- ✅ **Multi-Auth System** - Email OTP, Google OAuth (phone OTP disabled to avoid SMS charges)
- ✅ **Community Contributions** - Users create and share educational content
- ✅ **Admin Dashboard** - Content moderation, user management, platform stats
- ✅ **MongoDB Integration** - Full migration from SQLite complete
- ✅ **Real-time Sync** - Content updates across all connected users
- ✅ **Cross-Platform** - Web, Android, iOS support
- ✅ **Bulk Import** - Upload multiple questions via JSON
- ✅ **Username Validation** - Real-time availability check with smart suggestions
- ✅ **Performance Optimized** - Fast animations (150ms), smooth scrolling, hardware acceleration
---
## 📂 Project Structure
```
learnease-community-platform/
├── lib/                           # Flutter app source
│   ├── main.dart                  # App entry point
│   ├── screens/                   # UI screens
│   ├── services/                  # API & business logic
│   ├── widgets/                   # Reusable components
│   └── models/                    # Data models
├── community_server/              # Dart backend
│   ├── bin/server.dart            # Main server (Shelf REST API)
│   └── *.dart                     # Utility scripts
├── assets/                        # Images & resources
├── .vscode/                       # VS Code configuration
│   ├── launch.json                # Debug configurations
│   └── tasks.json                 # Build tasks
└── README.md                      # This file
```
---
## 🛠️ Technology Stack
| Component | Technology |
|-----------|-----------|
| **Frontend** | Flutter 3.x, Dart 3.x |
| **Backend** | Dart Shelf (REST API) |
| **Database** | MongoDB Atlas (production), SQLite (cache/sessions) |
| **Authentication** | Email OTP + BCrypt, Google OAuth, JWT |
| **Deployment** | Render (backend), Web hosting (frontend) |
| **Email** | Gmail API via OAuth2 |
---
## 🔐 Authentication Flow
### Email OTP Login
1. User enters email + password
2. Server validates credentials with BCrypt
3. Sends OTP to email (expires in 5 minutes)
4. User enters OTP code
5. JWT token issued → User logged in
### Google OAuth
1. User clicks "Sign in with Google"
2. Google auth redirects with ID token
3. Server verifies token with Google API
4. User created/logged in → JWT token issued
### Phone OTP (Disabled)
- **Reason:** SMS services (Twilio, MSG91) charge per message
- **Alternative:** Email OTP provides free, reliable authentication
---
## 🔧 API Endpoints
**Base URLs:**
- Local: http://localhost:8080
- Production: https://learnease-community-platform.onrender.com
### Authentication
```http
POST /api/auth/send-email-otp        # Send OTP to email
POST /api/auth/verify-email-otp      # Verify OTP & login
POST /api/auth/google                # Google OAuth login
POST /api/auth/admin-login           # Admin authentication
GET  /api/auth/suggest-username      # Get username suggestions
```
### Content Management
```http
GET    /api/contributions            # Get all approved contributions
POST   /api/contributions            # Create new contribution
POST   /api/contributions/batch      # Bulk import contributions
PUT    /api/contributions/:id        # Update contribution
DELETE /api/contributions/:id        # Delete contribution
```
### Admin
```http
GET    /api/admin/users              # List all users
DELETE /api/admin/users/:id          # Delete user (cascades to all data)
GET    /api/admin/contributions      # All contributions with moderation
PUT    /api/admin/contributions/:id  # Approve/reject content
GET    /api/stats/public             # Platform statistics
```
---
## 🐛 Recent Critical Fixes
### ✅ MongoDB Migration Complete (Nov 14, 2025)
**Issue:** New users weren't appearing in User Management  
**Root Cause:** _dbInsertUser() only wrote to SQLite, never MongoDB  
**Fix:** Rewrote as async function to insert to MongoDB first, SQLite as fallback  
**Commit:** 2a2d796
### ✅ Email Privacy Protection (Nov 14, 2025)
**Issue:** User emails exposed in community contributions  
**Root Cause:** API returned all fields including authorEmail  
**Fix:** Sanitize responses to remove email, show only username  
**Commit:** 2a2d796
### ✅ User Count Consistency (Nov 13, 2025)
**Issue:** Admin Dashboard showed 7 users, User Management showed 8  
**Root Cause:** Query used excludeFields() which hides but doesn't filter  
**Fix:** Changed to where.eq('admin_passkey', null) for proper filtering  
**Commit:** f089f8f
### ✅ Cascade User Deletion (Nov 13, 2025)
**Issue:** Deleting users left orphaned data  
**Fix:** Delete across all collections: contributions, quiz_results, challenge_results, sessions, email_otps  
**Commit:** 7a2fd2f
---
## 📊 Database Schema
### MongoDB Collections
**users** - User accounts
```javascript
{
  id: String,
  email: String,
  password_hash: String,
  username: String,
  google_id: String,
  admin_passkey: String (only for admin),
  created_at: String
}
```
**contributions** - User-submitted content
```javascript
{
  title: String,
  description: String,
  category: String (java|dbms),
  authorId: String,
  authorName: String,
  status: String (pending|approved|rejected),
  serverCreatedAt: String
}
```
**quiz_results** - Quiz attempt records  
**challenge_results** - Challenge attempt records  
**sessions** - Active JWT sessions  
**email_otps** - OTP codes (expire in 5 min)
### SQLite (Fallback/Cache)
- Used for temporary data (sessions, OTPs)
- MongoDB is primary database for all persistent data
---
## 🚨 Troubleshooting
### Port 8080 Already in Use
```powershell
# Kill processes
Get-Process dart, chrome | Stop-Process -Force
# Restart server
cd community_server
dart run bin/server.dart
```
### New Users Not Appearing
- ✅ **Fixed:** MongoDB migration complete (commit 2a2d796)
- All user creation paths now write to MongoDB
- Check server logs for "✅ User inserted to MongoDB"
### Email Not Sending
- Ensure Gmail API credentials configured in Render environment
- Check GMAIL_REFRESH_TOKEN, GMAIL_CLIENT_ID, GMAIL_CLIENT_SECRET
- OTP codes printed to console for development
### MongoDB Connection Failed
- Verify MONGODB_URI environment variable set
- Check MongoDB Atlas whitelist includes server IP
- Connection string format: mongodb+srv://user:pass@cluster.mongodb.net/db?retryWrites=true
---
## 🔐 Security Notes
- ✅ Passwords hashed with BCrypt (never stored plain text)
- ✅ JWT tokens with 7-day expiration
- ✅ Email addresses hidden in public API responses
- ✅ Admin passkey required for admin operations
- ✅ SQL injection prevention via parameterized queries
**⚠️ Important:** Never commit .env files or hardcoded credentials. Use environment variables.
---
## 🚀 Deployment
### Backend (Render)
1. Push to GitHub (auto-deploys from main branch)
2. Set environment variables:
   - MONGODB_URI - MongoDB Atlas connection string
   - GMAIL_REFRESH_TOKEN - OAuth2 refresh token
   - GMAIL_CLIENT_ID - Google API client ID
   - GMAIL_CLIENT_SECRET - Google API client secret
   - JWT_SECRET - Secret for signing JWT tokens
3. Build command: dart pub get
4. Start command: dart run bin/server.dart
### Frontend
```bash
# Build for web
flutter build web --release
# Deploy to hosting (Firebase, Vercel, etc.)
firebase deploy
```
---
## 👥 Contributors
| Name | Role | GitHub |
|------|------|--------|
| Sathvik | Project Lead | [@sathvik7137](https://github.com/sathvik7137) |
| Vardhan | Core Developer | [@vardhan0811](https://github.com/vardhan0811) |
| Nishu Kumari | UI/UX Designer | [@nishu-kumari-14](https://github.com/nishu-kumari-14) |
| Ankith | Backend Developer | [@Ankith2422](https://github.com/Ankith2422) |
| Srivatsa | Tester | [@srivatsa2512](https://github.com/srivatsa2512) |
---
## 📄 License
This project is open source and available under the MIT License.
---
## 📧 Support
For issues or questions:
1. Check Troubleshooting section
2. Review server logs: community_server/server.log
3. Open an issue on GitHub
---
<div align="center">
**Made with ❤️ using Flutter & Dart**
⭐ Star this repo if you find it helpful!
**Last Updated:** November 14, 2025
</div>
