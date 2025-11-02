# Testing Backend Persistence Fixes

## Quick Test Checklist ✅

### Step 1: Start Fresh
```bash
# Delete old database to test from scratch
rm users.db

# Start the backend server
dart run bin/server.dart
```

**Expected Output:**
```
📂 Database path: C:\...\users.db
✅ Database tables: users, otps, sessions, email_otps
📊 Existing users in database: 0
🚀 Community Server running on http://localhost:8080
```

---

### Step 2: Register New User

1. Open the Flutter app (http://localhost:7777)
2. Go to Sign-Up screen
3. Enter email: `test@example.com`
4. Set password: `password123`
5. Click "Continue with OTP Verification"

**Server Should Log:**
```
[SIGNUP OTP] Email OTP saved for test@example.com: 123456 (expires ...)
✅ Email sent successfully to test@example.com
```

**Database Change:**
- `email_otps` table now contains the OTP
- Check: `SELECT * FROM email_otps;` returns one row

---

### Step 3: Verify OTP

1. Enter OTP from server console (e.g., `123456`)
2. Click "Verify OTP"

**Server Should Log:**
```
[EMAIL OTP] 👤 New user created: [uuid] with username: test
💾 Email OTP saved to database: test@example.com
✅ Email OTP verified successfully
```

**Database Changes:**
- `users` table now has the new user
- `email_otps` table has deleted the OTP

---

### Step 4: **CRITICAL TEST** - Restart Server (This is where it was failing!)

1. Stop the backend server (Ctrl+C in terminal)
2. Wait 2 seconds
3. Start server again: `dart run bin/server.dart`

**Expected Output:**
```
📂 Database path: C:\...\users.db
✅ Database tables: users, otps, sessions, email_otps
📊 Existing users in database: 1  ← THIS SHOULD NOT BE 0!
🚀 Community Server running on http://localhost:8080
```

✅ **SUCCESS**: User data persisted! (Previously would show 0 users)

---

### Step 5: Login with Persisted User

1. Go back to Sign-In screen
2. Enter email: `test@example.com`
3. Enter password: `password123`
4. Click "Continue with OTP Verification"

**Server Should Log:**
```
[LOGIN OTP] 🔍 Looking up user with email: "test@example.com"
[LOGIN OTP] ✅ User found: email=test@example.com, hasPassword=true
[LOGIN OTP] ✅ Email OTP saved for test@example.com: 654321 (expires ...)
✅ Email sent successfully to test@example.com
```

✅ **SUCCESS**: User was found in database! (Previously would say "Email not registered")

---

### Step 6: Verify OTP After Restart

1. Enter OTP from server console
2. Click "Verify OTP"
3. Should log in successfully

**Server Should Log:**
```
[EMAIL OTP] ✅ OTP verified successfully
✅ User found: email=test@example.com
✅ Tokens issued for test@example.com
```

✅ **SUCCESS**: Full login flow works after restart!

---

## Debugging Commands

### Check Current Users
```bash
# Using the debug endpoint (if DEV_ALLOW_DEBUG=1 is set)
curl http://localhost:8080/internal/debug/users

# Or check SQLite directly
sqlite3 users.db
sqlite> SELECT email, username, created_at FROM users;
sqlite> SELECT email, code, expires_at FROM email_otps;
```

### Reset Database (Start Fresh)
```bash
rm users.db
# Server will recreate on next start
```

### Check Database Location
Look for this line in server startup logs:
```
📂 Database path: C:\full\path\to\users.db
```

This tells you exactly where data is being stored.

---

## Expected Behavior After Fixes

| Scenario | Before Fix | After Fix |
|----------|------------|-----------|
| Register user | ✅ Works | ✅ Works |
| Close VSCode | ❌ User lost | ✅ User persisted |
| Restart backend | ❌ "Email not registered" | ✅ User found |
| Try OTP after restart | ❌ Always fails | ✅ Works (if within 5 min) |
| Multiple register/login cycles | ❌ Fails after restart | ✅ Consistent |

---

## If Tests Still Fail

### Problem: "Email not registered" after restart

**Check:**
1. Server startup logs show `📊 Existing users: 0`?
   - Database is not persisting
   - Make sure `users.db` exists in server directory

2. Server logs show wrong path?
   - `📂 Database path: ...` shows unexpected location
   - Make sure you're running from `community_server` directory

3. `email_otps` table missing?
   - Server logs don't show it in table list
   - Delete `users.db` and restart to rebuild schema

### Problem: "Invalid OTP" on correct code

**Check:**
1. OTP expired? (5-minute limit)
   - Generate new OTP and verify you're entering within 5 minutes

2. Database issue?
   - Check: `sqlite3 users.db "SELECT * FROM email_otps;"`
   - Should show your email with the code

3. Case sensitivity?
   - Email stored as lowercase
   - Try entering email in lowercase

---

## Performance Notes

✅ Database operations are fast (SQLite in-process)
✅ No network calls for OTP verification (local database)
✅ Scales to thousands of users without issue

---

## That's it! 🎉

You've successfully tested the persistence fixes.

Users and OTPs now survive server restarts!
