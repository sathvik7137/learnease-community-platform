# Pre-commit Hook Setup for GitGuardian
# =======================================
# This prevents committing secrets to your repository

## Option 1: Using ggshield pre-commit hook (Recommended)
## -------------------------------------------------------

### Install ggshield globally (if not already installed)
pip install ggshield

### Install pre-commit hook
ggshield install -m local

# This creates a .git/hooks/pre-commit file that will:
# - Scan staged files before each commit
# - Block the commit if secrets are found
# - Show you exactly what was detected


## Option 2: Manual pre-commit hook
## ---------------------------------

### Create .git/hooks/pre-commit file:

#!/bin/sh
# GitGuardian pre-commit hook

echo "🔍 Scanning for secrets..."

# Run ggshield scan
ggshield secret scan pre-commit

# Check exit code
if [ $? -ne 0 ]; then
    echo "❌ Secrets detected! Commit blocked."
    echo "Please remove secrets or use 'git commit --no-verify' to skip (NOT recommended)"
    exit 1
fi

echo "✅ No secrets detected. Proceeding with commit."
exit 0

### Make it executable (Git Bash or WSL):
chmod +x .git/hooks/pre-commit


## Option 3: Using pre-commit framework
## -------------------------------------

### Install pre-commit
pip install pre-commit

### Create .pre-commit-config.yaml in project root:

repos:
  - repo: https://github.com/GitGuardian/ggshield
    rev: v1.21.0
    hooks:
      - id: ggshield
        language_version: python3
        stages: [commit]

### Install the hook:
pre-commit install

### Test it:
pre-commit run --all-files


## Testing Your Setup
## -------------------

### Test by trying to commit a fake secret:

# Create a test file
echo "API_KEY=sk-test123456789" > test_secret.txt

# Try to commit
git add test_secret.txt
git commit -m "test secret detection"

# Should be blocked!

# Clean up
git reset HEAD test_secret.txt
rm test_secret.txt


## Bypass Hook (Emergency Only)
## -----------------------------

# If you really need to commit (NOT RECOMMENDED for secrets):
git commit --no-verify -m "your message"


## Troubleshooting
## ---------------

### Hook not running?
# Check if hook exists:
ls -la .git/hooks/pre-commit

# Reinstall:
ggshield install -m local --force

### Too many false positives?
# Update your .ggignore file
# See .ggignore in project root


## For Team Setup
## ---------------

# Each team member should run:
ggshield install -m local

# Or add to your README/onboarding docs:
"""
After cloning, run:
pip install ggshield
ggshield install -m local
"""
