# Flutter Build Script Usage Guide

## 📋 Overview

The `build_flutter.sh` script provides a complete Flutter build environment setup for platforms that don't have Flutter pre-installed (like some CI/CD systems or custom deployment environments).

## 📁 File Location
```
BstocK/
├── backend/
├── frontend/
└── build_flutter.sh  ← Created here (project root)
```

## 🔧 What the Script Does

### 1. **Install Flutter SDK**
```bash
git clone https://github.com/flutter/flutter.git --depth 1 --branch stable /tmp/flutter
export PATH="$PATH:/tmp/flutter/bin"
```
- Downloads the latest stable Flutter SDK to `/tmp/flutter`
- Adds Flutter to the system PATH

### 2. **Configure Flutter**
```bash
flutter config --no-analytics
flutter precache
```
- Disables analytics for CI environments
- Downloads necessary build artifacts

### 3. **Build the App**
```bash
cd frontend
flutter pub get
flutter build web --release
```
- Installs Flutter dependencies
- Builds the web app for production

## 🚀 Usage Scenarios

### **Scenario 1: Custom CI/CD Pipeline**
```yaml
# Example GitHub Actions workflow
- name: Build Flutter App
  run: |
    chmod +x build_flutter.sh
    ./build_flutter.sh
```

### **Scenario 2: Manual Server Deployment**
```bash
# On your server
git clone https://github.com/yourusername/BstocK.git
cd BstocK
chmod +x build_flutter.sh
./build_flutter.sh

# Built files will be in frontend/build/web/
```

### **Scenario 3: Docker Build**
```dockerfile
# In a Dockerfile
COPY build_flutter.sh .
RUN chmod +x build_flutter.sh && ./build_flutter.sh
```

### **Scenario 4: Alternative to Vercel**
If the Vercel Flutter runtime doesn't work, you can use this script with:
- **Netlify** (with custom build command)
- **Firebase Hosting**
- **GitHub Pages**
- **AWS S3 Static Hosting**
- **DigitalOcean App Platform**

## 📋 Prerequisites

The script requires:
- ✅ **Linux/macOS environment** (bash shell)
- ✅ **Git** installed
- ✅ **Internet connection** (to download Flutter SDK)
- ✅ **Sufficient disk space** (~1GB for Flutter SDK)

## ⚡ Performance Notes

### **Build Time:**
- **First run:** 5-10 minutes (downloads Flutter SDK)
- **Subsequent runs:** 2-3 minutes (if Flutter is cached)

### **Optimization Tips:**
```bash
# Cache Flutter SDK between builds
export FLUTTER_ROOT=/opt/flutter
git clone https://github.com/flutter/flutter.git --depth 1 --branch stable $FLUTTER_ROOT
export PATH="$PATH:$FLUTTER_ROOT/bin"
```

## 🔧 Customization Options

### **Different Flutter Channel:**
```bash
# For beta channel
git clone https://github.com/flutter/flutter.git --depth 1 --branch beta /tmp/flutter

# For master channel (latest)
git clone https://github.com/flutter/flutter.git --depth 1 --branch master /tmp/flutter
```

### **Additional Build Options:**
```bash
# Build with different renderer
flutter build web --release --web-renderer canvaskit

# Build with source maps for debugging
flutter build web --release --source-maps

# Build for specific target
flutter build web --release --target lib/main_prod.dart
```

### **Environment Variables:**
```bash
# Set before running script
export FLUTTER_WEB_USE_SKIA=true
export FLUTTER_WEB_AUTO_DETECT=true
./build_flutter.sh
```

## 🐛 Troubleshooting

### **Issue: "Permission denied"**
```bash
chmod +x build_flutter.sh
./build_flutter.sh
```

### **Issue: "Flutter command not found"**
- Ensure the PATH export worked:
```bash
export PATH="$PATH:/tmp/flutter/bin"
flutter --version
```

### **Issue: "Git not found"**
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install git

# CentOS/RHEL
sudo yum install git

# macOS
xcode-select --install
```

### **Issue: "No space left on device"**
- Flutter SDK needs ~1GB of space
- Clean up temporary files:
```bash
rm -rf /tmp/flutter
df -h  # Check available space
```

## 🎯 Integration Examples

### **With Netlify:**
```toml
# netlify.toml
[build]
  command = "./build_flutter.sh"
  publish = "frontend/build/web"
```

### **With Firebase Hosting:**
```json
{
  "hosting": {
    "public": "frontend/build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [{
      "source": "**",
      "destination": "/index.html"
    }]
  }
}
```

### **With GitHub Pages:**
```yaml
# .github/workflows/deploy.yml
name: Deploy to GitHub Pages
on:
  push:
    branches: [ main ]
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build Flutter
        run: |
          chmod +x build_flutter.sh
          ./build_flutter.sh
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: frontend/build/web
```

## ✅ Success Indicators

When the script completes successfully, you'll see:
```bash
Building Flutter App...
Running "flutter pub get" in frontend...
Flutter assets will be downloaded from https://storage.googleapis.com
Building application for the web...
✓ Built build/web
```

**Output location:** `frontend/build/web/`

## 🔄 Alternative: Vercel with Custom Build

If you prefer to use this script with Vercel:

```json
{
  "version": 2,
  "builds": [
    {
      "src": "build_flutter.sh",
      "use": "@vercel/static-build",
      "config": {
        "buildCommand": "chmod +x build_flutter.sh && ./build_flutter.sh",
        "outputDirectory": "frontend/build/web"
      }
    }
  ]
}
```

This build script gives you maximum control and compatibility across different hosting platforms! 🚀
