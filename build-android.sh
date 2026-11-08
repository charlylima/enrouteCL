#!/bin/bash
# Android build script for enroute
# Requires: Qt for Android, Android SDK, Android NDK

set -e
source ./set_qt_env.sh

# Check if paths exist
if [ ! -d "$ANDROID_SDK_ROOT" ]; then
    echo "ERROR: Android SDK not found at $ANDROID_SDK_ROOT"
    exit 1
fi

if [ ! -d "$ANDROID_NDK_ROOT" ]; then
    echo "ERROR: Android NDK not found at $ANDROID_NDK_ROOT"
    exit 1
fi

if [ ! -d "$Qt6_DIR_ANDROID" ]; then
    echo "ERROR: Qt for Android not found at $Qt6_DIR_ANDROID"
    echo "Please install Qt $QT_VERSION for android_arm64_v8a"
    exit 1
fi

if [ ! -d "$QT_HOST_PATH" ]; then
    echo "ERROR: Qt host tools not found at $QT_HOST_PATH"
    exit 1
fi

echo "=========================================="
echo "Android Build Configuration"
echo "=========================================="
echo "Android SDK: $ANDROID_SDK_ROOT"
echo "Android NDK: $ANDROID_NDK_ROOT"
echo "Qt Android:  $Qt6_DIR_ANDROID"
echo "Qt Host:     $QT_HOST_PATH"
echo "=========================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check for dependencies directory
if [ ! -d "3rdParty" ]; then
    echo "ERROR: 3rdParty directory not found. Run: git submodule update --init --recursive"
    exit 1
fi

echo ""
echo "=========================================="
echo "Building enroute for Android..."
echo "=========================================="
rm -rf build-android-debug
$Qt6_DIR_ANDROID/bin/qt-cmake \
    -S . \
    -B build-android-debug \
    -G Ninja \
    -DCMAKE_BUILD_TYPE:STRING=Debug \
    -DFLIGHTLOG=ON

cmake --build build-android-debug
cmake --build build-android-debug --target apk
cp build-android-debug/src/android-build/build/outputs/apk/debug/android-build-debug.apk .

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo "APK location:"
ls -lh android-build-debug.apk 2>/dev/null || echo "APK not found - check build log"
echo "=========================================="

# Copy APK to Windows share
WIN_SHARE="/mnt/c/Users/user/win-share"
if [ -d "$WIN_SHARE" ]; then
    cp android-build-debug.apk "$WIN_SHARE/"
    echo "APK copied to $WIN_SHARE/android-build-debug.apk"
else
    echo "WARNING: Windows share not found at $WIN_SHARE — skipping copy"
fi
