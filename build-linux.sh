#!/bin/bash
# Build script for Enroute using Qt with qt-cmake and ninja

set -e  # Exit on error

source ./set_qt_env.sh
QT_CMAKE="${Qt6_DIR_LINUX}/bin/qt-cmake"
BUILD_DIR="build-linux"

mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

echo "Configuring project with qt-cmake..."
"${QT_CMAKE}" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DFLIGHTLOG=ON \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DCMAKE_PREFIX_PATH="${Qt6_DIR_LINUX}" \
    ..

echo "Building project with ninja..."
cmake --build .

echo "Build completed successfully!"
src/enroute 
