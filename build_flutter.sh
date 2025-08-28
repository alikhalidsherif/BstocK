#!/bin/bash

# Exit on error
set -e

# 1. Install Flutter
echo "Cloning Flutter SDK..."
git clone https://github.com/flutter/flutter.git --depth 1 --branch stable /tmp/flutter
export PATH="$PATH:/tmp/flutter/bin"

# 2. Configure Flutter
echo "Configuring Flutter..."
flutter config --no-analytics
flutter precache

# 3. Build the App
echo "Building Flutter App..."
cd frontend
flutter pub get
flutter build web --release
