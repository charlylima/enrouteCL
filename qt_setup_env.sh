# Environment for building Enroute on this machine.
#
# All third-party dependencies (zlib, bzip2, libzip, maplibre-native-qt) are
# submodules under 3rdParty/ and are built as part of the enroute build, so
# QML2_IMPORT_PATH / QT_PLUGIN_PATH / QMapLibre_DIR no longer need to point at a
# separately installed dependency tree. The build copies the MapLibre plugins
# next to the executable, so ./build-linux/src/enroute runs out of the box.

export Qt6_DIR_BASE=/opt/Qt/6.11.2/
export Qt6_DIR_LINUX=/opt/Qt/6.11.2/gcc_64/
