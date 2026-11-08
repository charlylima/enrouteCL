#!/bin/bash

export QT_VERSION=6.11.3
export JAVA_VERSION=21

# Environment setup for Qt6 development
export Qt6_DIR_LINUX="/opt/Qt/${QT_VERSION}/gcc_64"
export Qt6_DIR_ANDROID="/opt/Qt/${QT_VERSION}/android_arm64_v8a"
export Qt6_DIR_ANDROID_x86_64="/opt/Qt/${QT_VERSION}/android_x86_64"
export QT_HOST_PATH="$Qt6_DIR_LINUX"

# Set JAVA_HOME for Android builds
export JAVA_HOME="/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64"

# Android SDK and NDK paths
export ANDROID_HOME="/opt/android/sdk"
export ANDROID_SDK_ROOT="/opt/android/sdk"
export ANDROID_NDK_ROOT="/opt/android/android-ndk-r27c"

# Add tools to PATH
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

echo "Qt6 environment configured:"
echo "  Qt6_DIR_LINUX: $Qt6_DIR_LINUX"
echo "  Qt6_DIR_ANDROID: $Qt6_DIR_ANDROID"
echo "  Qt6_DIR_ANDROID_x86_64: $Qt6_DIR_ANDROID_x86_64"
echo "  JAVA_HOME: $JAVA_HOME"
echo "  ANDROID_HOME: $ANDROID_HOME"
echo "  ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"
echo "  ANDROID_NDK_ROOT: $ANDROID_NDK_ROOT"
