# Git History Cleanup Instructions
# =================================
# This guide helps you remove sensitive data from Git history

## ⚠️ WARNING: This will rewrite Git history!
## Make a backup before proceeding:
## git clone --mirror . ../learnease-backup

## Method 1: Using git filter-repo (Recommended)
## ----------------------------------------------

### Install git-filter-repo
# Windows (using pip):
pip install git-filter-repo

### Remove the .env file from all history
git filter-repo --path community_server/.env --invert-paths --force

### Remove specific test files with passwords
git filter-repo --path community_server/final_auth_test.dart --invert-paths --force
git filter-repo --path community_server/login_test_main.dart --invert-paths --force
git filter-repo --path community_server/test_complete_flow.dart --invert-paths --force
git filter-repo --path community_server/test_real_login.dart --invert-paths --force
git filter-repo --path community_server/test_send_email_otp.dart --invert-paths --force
git filter-repo --path community_server/create_correct_user.dart --invert-paths --force
git filter-repo --path community_server/insert_user_simple.dart --invert-paths --force
git filter-repo --path community_server/verify_credentials.dart --invert-paths --force
git filter-repo --path community_server/final_check.dart --invert-paths --force
git filter-repo --path FIX_COMPLETE.txt --invert-paths --force

### Force push to remote (⚠️ All collaborators must re-clone!)
git push origin --force --all
git push origin --force --tags


## Method 2: Using BFG Repo-Cleaner (Alternative)
## -----------------------------------------------

### Download BFG
# Go to: https://rtyley.github.io/bfg-repo-cleaner/
# Or use: https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar

### Remove .env file
java -jar bfg.jar --delete-files .env

### Remove files with secrets
java -jar bfg.jar --delete-files "{final_auth_test.dart,login_test_main.dart,test_complete_flow.dart}"

### Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive

### Force push
git push origin --force --all


## Method 3: Simple approach - Delete files and force commit
## ---------------------------------------------------------
# If you don't care about preserving history:

# 1. Delete sensitive files
rm community_server/.env
rm community_server/*_test.dart
rm community_server/test_*.dart
rm FIX_COMPLETE.txt

# 2. Create fresh .env from template
cp community_server/.env.example community_server/.env
# Edit and add your real credentials

# 3. Commit
git add .
git commit -m "chore: remove sensitive files and clean up test files"

# 4. Force push (if needed)
git push origin main --force


## After Cleanup
## -------------

### 1. Rotate ALL exposed credentials:
# - MongoDB password (create new user in MongoDB Atlas)
# - Google Gemini API Key (revoke and create new in Google Cloud Console)
# - Twilio credentials (regenerate in Twilio dashboard)
# - Gmail app password (revoke and create new)
# - JWT_SECRET (generate new: openssl rand -base64 32)

### 2. Update your local .env with new credentials

### 3. Notify collaborators to:
git fetch origin
git reset --hard origin/main
# Then create their own .env from .env.example

### 4. Set up pre-commit hook to prevent future leaks
# See: PRE_COMMIT_SETUP.md


## Verify Cleanup
## ---------------

# Check if secrets are still in history
git log --all --full-history --source --  community_server/.env

# Run ggshield scan again
ggshield secret scan repo .

# Should show significantly fewer or no secrets
