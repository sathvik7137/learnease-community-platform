# 🚀 Deploy LearnEase Backend to Production

## ⚠️ CRITICAL: You CANNOT use ngrok in production!

Ngrok URLs expire after a few hours and are not suitable for a production app on Play Store.

---

## 🎯 Recommended Option: Railway (Easiest)

### Why Railway?
- ✅ FREE tier (500 hours/month)
- ✅ Automatic deployments from GitHub
- ✅ Built-in SSL/HTTPS
- ✅ Simple setup (5 minutes)
- ✅ Supports Dart natively

### Setup Steps:

#### 1. Sign Up
```
1. Go to: https://railway.app
2. Sign in with GitHub
3. Connect your repository: sathvik7137/learnease-community-platform
```

#### 2. Create New Project
```
1. Click "New Project"
2. Select "Deploy from GitHub repo"
3. Choose: learnease-community-platform
4. Railway will auto-detect the project
```

#### 3. Configure Build Settings
```
Root Directory: community_server
Build Command: dart pub get
Start Command: dart run bin/server.dart
```

#### 4. Add Environment Variables
```
In Railway Dashboard > Variables:

MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/learnease
PORT=8080
JWT_SECRET=your-super-secret-jwt-key-here
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

#### 5. Get Your Production URL
```
After deployment completes:
1. Go to Settings > Domains
2. Click "Generate Domain"
3. You'll get: https://yourapp.railway.app
4. Copy this URL!
```

#### 6. Update Flutter App
```dart
// In lib/config/api_config.dart
static const String _productionBaseUrl = 'https://yourapp.railway.app';
```

---

## 🎯 Alternative Option 1: Render

### Why Render?
- ✅ FREE tier (750 hours/month)
- ✅ Auto-deploy from GitHub
- ✅ Built-in SSL
- ✅ Good for small apps

### Setup Steps:

#### 1. Sign Up
```
1. Go to: https://render.com
2. Sign in with GitHub
```

#### 2. Create Web Service
```
1. Click "New +" > "Web Service"
2. Connect GitHub: learnease-community-platform
3. Configure:
   - Name: learnease-backend
   - Root Directory: community_server
   - Environment: Docker
   - Build Command: dart pub get
   - Start Command: dart run bin/server.dart
```

#### 3. Add Environment Variables
```
Same as Railway (see above)
```

#### 4. Get URL
```
Your service URL: https://learnease-backend.onrender.com
```

---

## 🎯 Alternative Option 2: DigitalOcean App Platform

### Why DigitalOcean?
- ✅ $5/month (more reliable than free tiers)
- ✅ Better performance
- ✅ Professional hosting
- ✅ Good for scaling

### Setup Steps:

#### 1. Sign Up
```
1. Go to: https://www.digitalocean.com
2. Create account (gets $200 free credit)
```

#### 2. Create App
```
1. Go to Apps > Create App
2. Connect GitHub
3. Select: community_server folder
4. Choose: Dart/Flutter
```

#### 3. Configure
```
Build Command: dart pub get
Run Command: dart run bin/server.dart
Port: 8080
```

---

## 🗄️ Database: MongoDB Atlas

### Setup MongoDB (Required for all options):

#### 1. Create Free Cluster
```
1. Go to: https://www.mongodb.com/cloud/atlas
2. Sign up free
3. Create cluster (M0 Free tier)
4. Select AWS / Region nearest to you
```

#### 2. Configure Access
```
1. Database Access > Add User:
   - Username: learnease_user
   - Password: Generate strong password
   - Privileges: Read and write to any database

2. Network Access > Add IP:
   - Click "Allow Access from Anywhere"
   - IP: 0.0.0.0/0 (for Railway/Render to connect)
```

#### 3. Get Connection String
```
1. Click "Connect"
2. Choose "Connect your application"
3. Copy connection string:
   mongodb+srv://learnease_user:<password>@cluster0.xxxxx.mongodb.net/
   
4. Replace <password> with your actual password
5. Add database name at end: /learnease
```

#### 4. Add to Environment Variables
```
MONGODB_URI=mongodb+srv://learnease_user:yourpassword@cluster0.xxxxx.mongodb.net/learnease
```

---

## 📧 Email Setup (Gmail SMTP)

### Enable App Password:

```
1. Go to Google Account > Security
2. Enable 2-Step Verification
3. Go to App Passwords
4. Generate password for "Mail"
5. Copy the 16-character password
```

### Add to Environment Variables:
```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=xxxx xxxx xxxx xxxx (16-char app password)
```

---

## ✅ Testing Your Production Backend

### 1. Health Check
```bash
curl https://yourapp.railway.app/health
```

Expected response:
```json
{"status": "OK", "timestamp": "..."}
```

### 2. Test Authentication
```bash
curl -X POST https://yourapp.railway.app/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123456",
    "username": "testuser"
  }'
```

### 3. Test from Flutter App
```
1. Update api_config.dart with new URL
2. Run: flutter run --release
3. Try login/signup
4. Check if data saves to MongoDB
```

---

## 🔒 Security Checklist

Before going live:

- [ ] Change all default passwords
- [ ] Use strong JWT_SECRET (min 32 characters)
- [ ] Enable MongoDB authentication
- [ ] Restrict MongoDB IP access (after testing)
- [ ] Enable rate limiting on backend
- [ ] Add CORS restrictions (only your domains)
- [ ] Use environment variables (never hardcode secrets)
- [ ] Enable HTTPS only (no HTTP)

---

## 📊 Monitoring & Logs

### Railway:
```
- Go to Deployments > View Logs
- See real-time server logs
- Monitor CPU/Memory usage
```

### Render:
```
- Go to Logs tab
- Real-time log streaming
- Set up alerts
```

### MongoDB Atlas:
```
- Go to Metrics tab
- Monitor connections, operations
- Set up alerts for errors
```

---

## 🆘 Troubleshooting

### Backend won't start:
```bash
# Check logs for errors
# Common issues:
1. Missing environment variables
2. MongoDB connection failed
3. Port already in use
4. Dart version mismatch
```

### Can't connect from app:
```bash
# Check:
1. Backend is running (check Railway/Render dashboard)
2. URL is correct in api_config.dart
3. HTTPS (not HTTP)
4. No firewall blocking
5. MongoDB connection string is correct
```

### Database connection failed:
```bash
# Fix:
1. Check MongoDB Atlas > Network Access
2. Ensure 0.0.0.0/0 is allowed
3. Verify connection string
4. Check username/password
5. Ensure database name is correct
```

---

## 🚀 Quick Start (Railway - Recommended)

```bash
# 1. Deploy to Railway (5 minutes)
1. Go to railway.app
2. Sign in with GitHub
3. New Project > Deploy from repo
4. Select: learnease-community-platform
5. Set root: community_server
6. Add environment variables
7. Deploy!

# 2. Setup MongoDB (5 minutes)
1. Go to mongodb.com/atlas
2. Create free cluster
3. Add user and allow IP access
4. Copy connection string
5. Add to Railway env vars

# 3. Update Flutter app (2 minutes)
# Edit lib/config/api_config.dart:
static const String _productionBaseUrl = 'https://yourapp.railway.app';

# 4. Test!
flutter run --release
```

---

## 💰 Cost Comparison

| Service | Free Tier | Paid | Best For |
|---------|-----------|------|----------|
| **Railway** | 500 hrs/mo | $5/mo | Easiest setup |
| **Render** | 750 hrs/mo | $7/mo | Good free tier |
| **DigitalOcean** | $200 credit | $5/mo | Best reliability |
| **MongoDB Atlas** | 512MB FREE | $9/mo | Required |
| **Gmail SMTP** | FREE | FREE | Email sending |

**Recommended for Launch:** Railway Free + MongoDB Free = $0/month

---

## 📞 Support

**Railway:** https://railway.app/help
**Render:** https://render.com/docs
**MongoDB:** https://www.mongodb.com/docs

---

**Next Step:** After deploying backend, update `PLAY_STORE_CHECKLIST.md` and continue with app build!
