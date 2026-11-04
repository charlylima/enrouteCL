#!/bin/bash
#
# Build script for Enroute Flight Navigation on Linux (desktop).
#
# All third-party dependencies (zlib, bzip2, libzip, maplibre-native-qt) are
# git submodules under 3rdParty/ and are compiled as part of this build, so no
# separate "enrouteDependencies" repository is needed anymore.
#
# Make sure the submodules are present:
#     git submodule update --init --recursive
#
# The Qt 6 installation is taken from the environment:
#     export Qt6_DIR_LINUX=/opt/Qt/6.11.2/gcc_64     # the desktop kit
#     export Qt6_DIR_BASE=/opt/Qt/6.11.2/            # optional, parent of the kits
#
# Usage:
#     ./build-linux.sh              # clean debug build
#     ./build-linux.sh -no-clean    # keep the build directory
#     ./build-linux.sh -run         # build, then start from the build tree
#     ./build-linux.sh -install     # build, install into ./enrouteInstallation, run

set -e  # Exit on error

if [ -z "$Qt6_DIR_LINUX" ]; then
    if [ -n "$Qt6_DIR_BASE" ]; then
        Qt6_DIR_LINUX="${Qt6_DIR_BASE}gcc_64"
    else
        echo "Error: Qt6_DIR_LINUX is not set. Please export it to your Qt6 desktop kit."
        echo "Example: export Qt6_DIR_LINUX=/opt/Qt/6.11.2/gcc_64"
        echo "If you have not installed Qt6, download it from https://www.qt.io/download."
        exit 1
    fi
fi

QT_CMAKE="${Qt6_DIR_LINUX}/bin/qt-cmake"
BUILD_DIR="build-linux"
INSTALL_DIR="enrouteInstallation"

# Clean unless "-no-clean" is given.
if [ "$1" != "-no-clean" ] && [ "$2" != "-no-clean" ]; then
    rm -rf "${BUILD_DIR}"
    rm -rf "${INSTALL_DIR}"
fi

echo "Configuring project with qt-cmake..."
"${QT_CMAKE}" \
    -S . \
    -B "${BUILD_DIR}" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_C_COMPILER_LAUNCHER="ccache" \
    -DCMAKE_CXX_COMPILER_LAUNCHER="ccache" \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DCMAKE_PREFIX_PATH="${Qt6_DIR_LINUX}" \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"

echo "Building project with ninja..."
cmake --build "${BUILD_DIR}"

# Call with "-run" parameter to run the executable from the build tree.
# The MapLibre plugins are copied next to the binary by the build itself, so no
# QML2_IMPORT_PATH / QT_PLUGIN_PATH environment is required.
if [ "$1" = "-run" ] || [ "$2" = "-run" ]; then
    "${BUILD_DIR}/src/enroute"
fi

# Call with "-install" parameter to install and run from the installation directory.
if [ "$1" = "-install" ] || [ "$2" = "-install" ]; then
    cmake --install "${BUILD_DIR}"
    cd "${INSTALL_DIR}" && ./bin/enroute
fi

echo "Build completed successfully!" 
