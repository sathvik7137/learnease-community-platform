# Production Utilities

This directory contains **production-critical utilities** for server administration.

## Essential Files

### 🚀 Main Server
- **`bin/server.dart`** - Main backend server (DO NOT DELETE)
- **`lib/`** - Server libraries and modules

### 🔧 Admin Utilities

#### `setup_admin_user.dart`
**Purpose:** Initial setup of admin account in MongoDB  
**When to use:** First-time deployment or when admin account is missing  
**Usage:**
```bash
dart run community_server/setup_admin_user.dart
```

#### `check_admin_credentials.dart`
**Purpose:** Verify admin credentials are properly set in MongoDB  
**Security:** Prompts for password/passkey (no hardcoded values)  
**Usage:**
```bash
dart run community_server/check_admin_credentials.dart
# Then enter password and passkey when prompted
```

#### `verify_admin_passkey.dart`
**Purpose:** Test if a specific passkey matches the stored hash  
**Security:** Prompts for passkey input  
**Usage:**
```bash
dart run community_server/verify_admin_passkey.dart
# Enter passkey when prompted
```

#### `set_admin_passkey.dart`
**Purpose:** Update admin passkey in production MongoDB  
**Security:** Prompts for new passkey (min 6 characters)  
**Usage:**
```bash
dart run community_server/set_admin_passkey.dart
# Follow the prompts to set new passkey
```

## Security Notes

⚠️ **All utilities require `MONGODB_URI` environment variable**
- No hardcoded credentials in source code
- Credentials are prompted at runtime
- Production-ready security standards

## What Was Removed

The following file categories were removed for production readiness:

### ❌ Test Files (~30 files)
- `*_test*.dart` - Unit/integration tests
- `test_*.dart` - Development test scripts
- `diagnose_*.dart` - Debugging utilities

### ❌ Debug/Check Files (~20 files)
- `check_*.dart` (except check_admin_credentials.dart)
- `debug_*.dart` - Debug utilities
- `list_*.dart` - Data listing scripts
- `find_*.dart` - User lookup scripts

### ❌ Migration Scripts (~15 files)
- `create_*.dart` - One-time user creation
- `delete_all_*.dart` - Bulk deletion scripts
- `export_*.dart` / `import_*.dart` - Data migration
- `insert_*.dart` - Sample data insertion
- `reset_*.dart` - Database reset scripts

### ❌ Temporary Data Files
- `*.db` - SQLite databases (MongoDB is primary)
- `*.json` - Export files
- `*.log` - Debug logs
- `*.txt` - Temporary output files

## Environment Setup

Required environment variables:
```bash
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/dbname
JWT_SECRET=your_secret_key
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your_app_password
```

Set these in:
- **Local:** `.env` file in community_server directory
- **Render:** Dashboard → Environment tab

## Why This Cleanup Matters

1. **Security:** No hardcoded credentials exposed in source code
2. **Clarity:** Only essential files, no clutter
3. **Professionalism:** Production-ready codebase
4. **Maintainability:** Easy to understand what each file does
5. **Safety:** Test files can't accidentally run in production

---

**Last Updated:** Nov 14, 2025  
**Production-Ready:** ✅  
**Commit:** 155e718
