# 🚀 Deploy LearnEase Backend to Production

## ⚠️ CRITICAL: You CANNOT use ngrok in production!

Ngrok URLs expire after a few hours and are not suitable for a production app on Play Store.

---

## � FREE HOSTING COMPARISON

| Service | Free Tier | Always Free? | Best For |
|---------|-----------|--------------|----------|
| **Render** | 750 hrs/month | ✅ YES | **RECOMMENDED - Most generous free tier** |
| **Railway** | $5 credit/month | ⚠️ Need credit card | Easiest setup but requires card |
| **Fly.io** | 3 shared VMs | ✅ YES | Good for Dart apps |
| **Glitch** | Always on | ✅ YES | Simple projects |

**BEST CHOICE:** Render.com - No credit card required, 750 hours = always free!

---

## 🎯 Recommended Option #1: Render (100% FREE - No Credit Card!)

### Why Render?
- ✅ **750 hours/month FREE** (= always running!)
- ✅ **NO CREDIT CARD REQUIRED**
- ✅ Automatic deployments from GitHub
- ✅ Built-in SSL/HTTPS
- ✅ Simple setup (5 minutes)
- ✅ Supports Dart natively
- ✅ Auto-deploy on git push

### Setup Steps (5 Minutes - 100% Free):

#### 1. Sign Up (NO CREDIT CARD!)
```
1. Go to: https://render.com
2. Click "Get Started for Free"
3. Sign in with GitHub
4. Authorize Render to access your repos
```

#### 2. Create Web Service
```
1. Click "New +" button (top right)
2. Select "Web Service"
3. Connect your GitHub repo: sathvik7137/learnease-community-platform
4. Click "Connect" next to your repo
```

#### 3. Configure Service
```
Fill in these fields:

Name: learnease-backend
Region: Singapore (or closest to you)
Branch: main
Root Directory: community_server
Runtime: Docker
Build Command: (leave empty - Docker handles it)
Start Command: (leave empty - Docker handles it)
Instance Type: Free
```

#### 4. Create Dockerfile in community_server folder
You need to add this file first! (I'll help you create it below)

#### 5. Add Environment Variables
```
Click "Advanced" > "Add Environment Variable"

Add these one by one:
MONGODB_URI = mongodb+srv://username:password@cluster.mongodb.net/learnease
PORT = 8080
JWT_SECRET = your-super-secret-jwt-key-min-32-chars
SMTP_HOST = smtp.gmail.com
SMTP_PORT = 587
SMTP_USER = your-email@gmail.com
SMTP_PASS = your-gmail-app-password
```

#### 6. Deploy!
```
1. Click "Create Web Service"
2. Wait 5-10 minutes for first deployment
3. You'll get a URL like: https://learnease-backend.onrender.com
4. COPY THIS URL!
```

#### 7. Update Flutter App
```dart
// In lib/config/api_config.dart
static const String _productionBaseUrl = 'https://learnease-backend.onrender.com';
```

---

## 🎯 Recommended Option #2: Fly.io (100% FREE - 3 VMs)

### Why Fly.io?
- ✅ **ALWAYS FREE** - 3 shared VMs
- ✅ NO CREDIT CARD for free tier
- ✅ Global CDN
- ✅ Fast deployments
- ✅ Great for Dart

### Setup Steps:

#### 1. Install Fly CLI
```powershell
# Install Fly CLI
powershell -Command "iwr https://fly.io/install.ps1 -useb | iex"
```

#### 2. Sign Up & Login
```powershell
# Sign up (no credit card!)
fly auth signup

# Or login if you have account
fly auth login
```

#### 3. Deploy Your App
```powershell
# Go to your community_server folder
cd "C:\Users\CyberBot\Desktop\Projects\Intermediate -Flutter\community_server"

# Initialize Fly app
fly launch --name learnease-backend

# Follow prompts:
# - Choose region: Singapore/India
# - Database? No (we use MongoDB Atlas)
# - Deploy now? Yes
```

#### 4. Set Environment Variables
```powershell
# Set secrets (environment variables)
fly secrets set MONGODB_URI="mongodb+srv://user:pass@cluster.mongodb.net/learnease"
fly secrets set PORT="8080"
fly secrets set JWT_SECRET="your-secret-key-here"
fly secrets set SMTP_HOST="smtp.gmail.com"
fly secrets set SMTP_PORT="587"
fly secrets set SMTP_USER="your-email@gmail.com"
fly secrets set SMTP_PASS="your-app-password"
```

#### 5. Get Your URL
```
After deployment:
Your app is available at: https://learnease-backend.fly.dev
```

---

## 🎯 Alternative Option 3: Railway (Requires Credit Card)

### Why Railway?
- ⚠️ **$5 FREE CREDIT/month** (requires credit card verification)
- ✅ Easiest setup
- ✅ Auto-deploy from GitHub
- ✅ Built-in SSL/HTTPS

**Note:** Railway requires a credit card on file but gives you $5 credit every month which is enough for a small app. You won't be charged unless you exceed the credit.

### Setup Steps:

#### 1. Sign Up
```
1. Go to: https://railway.app
2. Sign in with GitHub
3. Add credit card (won't be charged, just verification)
```

#### 2. Deploy
```
1. Click "New Project"
2. Select "Deploy from GitHub repo"
3. Choose: learnease-community-platform
4. Set root: community_server
5. Add environment variables (same as above)
6. Deploy!
```

#### 3. Get URL
```
Settings > Domains > Generate Domain
You'll get: https://yourapp.railway.app
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
SMTP_PASS=YOUR_16CHAR_APP_PASSWORD
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
    "password": "YourTestPassword123",
    "username": "yourtestuser"
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

## 🚀 Quick Start (Render - 100% FREE, No Credit Card!)

```bash
# 1. Deploy to Render (10 minutes) - NO CREDIT CARD NEEDED!
1. Go to render.com
2. Sign in with GitHub
3. New + > Web Service
4. Connect: learnease-community-platform
5. Configure:
   - Name: learnease-backend
   - Root: community_server
   - Runtime: Docker
   - Instance: Free
6. Add environment variables (see below)
7. Create Web Service!

# 2. Setup MongoDB (5 minutes) - FREE FOREVER
1. Go to mongodb.com/atlas
2. Create free cluster (M0 tier)
3. Add user and allow IP: 0.0.0.0/0
4. Copy connection string
5. Add to Render env vars

# 3. Update Flutter app (2 minutes)
# Edit lib/config/api_config.dart:
static const String _productionBaseUrl = 'https://learnease-backend.onrender.com';

# 4. Test!
flutter run --release
```

---

## 🚀 Alternative Quick Start (Fly.io - FREE with CLI)

```powershell
# 1. Install Fly CLI
iwr https://fly.io/install.ps1 -useb | iex

# 2. Sign up (NO CREDIT CARD!)
fly auth signup

# 3. Deploy
cd community_server
fly launch --name learnease-backend

# 4. Set environment variables
fly secrets set MONGODB_URI="your-connection-string"
fly secrets set JWT_SECRET="your-secret"
# ... set other variables

# 5. Your app is live at:
# https://learnease-backend.fly.dev
```

---

## 💰 Cost Comparison (Updated)

| Service | Free Tier | Credit Card? | Limits | Best For |
|---------|-----------|--------------|--------|----------|
| **Render** ⭐ | 750 hrs/mo | ❌ NO | Always free! | **BEST - No card needed** |
| **Fly.io** ⭐ | 3 VMs free | ❌ NO | Always free! | **BEST - CLI deploy** |
| **Railway** | $5 credit/mo | ✅ YES | Need card | Easy but needs card |
| **Glitch** | Always on | ❌ NO | 4000 req/hr | Simple projects |
| **MongoDB Atlas** | 512MB | ❌ NO | Always free! | Database (Required) |
| **Gmail SMTP** | FREE | ❌ NO | 500 emails/day | Email sending |

**🎯 Recommended for Launch (100% FREE, No Credit Card):**
- **Backend:** Render.com or Fly.io = **$0/month**
- **Database:** MongoDB Atlas Free = **$0/month**
- **Email:** Gmail SMTP = **$0/month**
- **TOTAL:** **$0/month** 🎉

**Railway Alternative:** If you have a credit card, Railway is easiest but requires card verification (gives $5 free credit monthly)

---

## 📞 Support

**Railway:** https://railway.app/help
**Render:** https://render.com/docs
**MongoDB:** https://www.mongodb.com/docs

---

**Next Step:** After deploying backend, update `PLAY_STORE_CHECKLIST.md` and continue with app build!
