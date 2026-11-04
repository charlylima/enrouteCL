#!/bin/bash
set -e

# Android build script for enroute.
#
# Requires: Qt 6 for Android (android_arm64_v8a) plus the matching host kit, the
# Android SDK and the Android NDK. All third-party libraries (zlib, bzip2,
# libzip, maplibre-native-qt) are submodules under 3rdParty/ and are compiled
# as part of the enroute build - nothing is installed into the Qt kit or the
# system.
#
# Make sure the submodules are present:
#     git submodule update --init --recursive

# Configuration - override by exporting the variables before calling the script.
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/opt/android/sdk}"
ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT:-/opt/android/android-ndk-r27c}"
QT_ROOT_DIR="${QT_ROOT_DIR:-/opt/Qt/6.11.2/android_arm64_v8a}"
QT_HOST_PATH="${QT_HOST_PATH:-/opt/Qt/6.11.2/gcc_64}"
JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk-amd64}"

# Check if paths exist
if [ ! -d "$ANDROID_SDK_ROOT" ]; then
    echo "ERROR: Android SDK not found at $ANDROID_SDK_ROOT"
    exit 1
fi

if [ ! -d "$ANDROID_NDK_ROOT" ]; then
    echo "ERROR: Android NDK not found at $ANDROID_NDK_ROOT"
    exit 1
fi

if [ ! -d "$QT_ROOT_DIR" ]; then
    echo "ERROR: Qt for Android not found at $QT_ROOT_DIR"
    echo "Please install Qt for android_arm64_v8a"
    exit 1
fi

if [ ! -d "$QT_HOST_PATH" ]; then
    echo "ERROR: Qt host tools not found at $QT_HOST_PATH"
    exit 1
fi

# Export environment variables
export ANDROID_SDK_ROOT
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export ANDROID_NDK_ROOT
export QT_HOST_PATH
export JAVA_HOME

echo "=========================================="
echo "Android Build Configuration"
echo "=========================================="
echo "Android SDK: $ANDROID_SDK_ROOT"
echo "Android NDK: $ANDROID_NDK_ROOT"
echo "Qt Android:  $QT_ROOT_DIR"
echo "Qt Host:     $QT_HOST_PATH"
echo "Java:        $JAVA_HOME"
echo "=========================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check that the 3rdParty submodules are checked out
for _sub in 3rdParty/zlib 3rdParty/bzip2 3rdParty/libzip 3rdParty/maplibre-native-qt/vendor/maplibre-native; do
    if [ ! -e "$_sub" ] || [ -z "$(ls -A "$_sub" 2>/dev/null)" ]; then
        echo "ERROR: $_sub is missing or empty."
        echo "Run: git submodule update --init --recursive"
        exit 1
    fi
done

echo ""
echo "=========================================="
echo "Building enroute for Android..."
echo "=========================================="
if [ "$1" != "-no-clean" ]; then
    rm -rf build-android
fi
$QT_ROOT_DIR/bin/qt-cmake \
    -S . \
    -B build-android \
    -G Ninja \
    -DCMAKE_BUILD_TYPE:STRING=Debug \
    -DCMAKE_C_COMPILER_LAUNCHER="ccache" \
    -DCMAKE_CXX_COMPILER_LAUNCHER="ccache"

cmake --build build-android
cmake --build build-android --target apk
cp build-android/src/android-build/build/outputs/apk/debug/android-build-debug.apk enroute.apk

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo "APK location:"
ls -lh enroute.apk 2>/dev/null || echo "APK not found - check build log"
echo "=========================================="

# Copy APK to Windows share
WIN_SHARE="/mnt/c/Users/user/win-share"
if [ -d "$WIN_SHARE" ]; then
    cp enroute.apk "$WIN_SHARE/"
    echo "APK copied to $WIN_SHARE/enroute.apk"
else
    echo "WARNING: Windows share not found at $WIN_SHARE — skipping copy"
fi
