#
# Third-party dependencies, built in-tree.
#
# Historically zlib, bzip2, libzip and maplibre-native-qt lived in a separate
# repository ("enrouteDependencies") and had to be built and installed against the
# Qt kit *before* enroute could be configured. They are now git submodules under
# 3rdParty/ and are compiled as part of the enroute build, so a fresh clone with
# `git submodule update --init --recursive` is self-contained.
#

#
# Save RPATH settings to restore them later: some of the dependencies below
# overwrite the RPATH / pkg-config settings of the main project.
#
set(_SAVED_CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_RPATH}")
set(_SAVED_CMAKE_INSTALL_RPATH_USE_LINK_PATH "${CMAKE_INSTALL_RPATH_USE_LINK_PATH}")
set(_SAVED_CMAKE_MACOSX_RPATH "${CMAKE_MACOSX_RPATH}")
set(_SAVED_PKG_CONFIG_RPATH "${PKG_CONFIG_RPATH}")

#
# Silence warnings coming from the vendored libraries while keeping enroute's own
# source tree warning-free. Applies to 3rdParty/ and everything below it.
#
if(MSVC)
    set_property(DIRECTORY PROPERTY COMPILE_OPTIONS "/W0")
else()
    set_property(DIRECTORY PROPERTY COMPILE_OPTIONS "-w")
endif()

# Static libraries below are linked into shared libraries (libzip on Android,
# everything into the iOS static build), so compile them position-independent.
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

#
# Helper: add a subdirectory but restore the RPATH / pkg-config settings afterwards.
#
function(add_subdirectory_with_rpath_isolation dir)
    set(SAVED_INSTALL_RPATH "${CMAKE_INSTALL_RPATH}")
    set(SAVED_INSTALL_RPATH_USE_LINK_PATH "${CMAKE_INSTALL_RPATH_USE_LINK_PATH}")
    set(SAVED_MACOSX_RPATH "${CMAKE_MACOSX_RPATH}")
    set(SAVED_PKG_CONFIG_RPATH "${PKG_CONFIG_RPATH}")

    add_subdirectory(${dir} ${ARGN})

    set(CMAKE_INSTALL_RPATH "${SAVED_INSTALL_RPATH}" PARENT_SCOPE)
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH "${SAVED_INSTALL_RPATH_USE_LINK_PATH}" PARENT_SCOPE)
    set(CMAKE_MACOSX_RPATH "${SAVED_MACOSX_RPATH}" PARENT_SCOPE)
    set(PKG_CONFIG_RPATH "${SAVED_PKG_CONFIG_RPATH}" PARENT_SCOPE)
endfunction()


#
# Google Material Icons
#

set(material-design-icons_SOURCE_DIR
    ${CMAKE_CURRENT_SOURCE_DIR}/material-design-icons
    CACHE INTERNAL "" FORCE)


#
# KDSingleApplication
#

# For simplicity, we do not build the KDSingleApplication library, but include the source files
# into the enroute target. This saves us the overhead of
# finding and loading the library at runtime.


#
# Sunset/sunrise computation
#

# For simplicity, we do not build the sunset library, but include the source files
# into the enroute target. This avoids problems on iOS and saves us the overhead of
# finding and loading the library at runtime.


#
# spriteGenerator
#

# Build the spriteGenerator tool only when the flightMapSprites target is invoked.
# It is a host-only developer tool and must not be included in mobile builds.
if(NOT ANDROID AND NOT IOS)
    add_subdirectory(spriteGenerator EXCLUDE_FROM_ALL)
endif()


#
# enrouteOGN library
#

# Build the enrouteOGN library as a static library
add_subdirectory(enrouteOGN)


#
# zlib (compression library, required by libzip)
#
# On the desktop we build the shared library; on Android / iOS everything ends up
# in the application binary, so we build the static one only.
if(ANDROID OR IOS)
    set(ZLIB_BUILD_SHARED OFF CACHE BOOL "Do not build the shared zlib on mobile" FORCE)
    set(ZLIB_BUILD_STATIC ON CACHE BOOL "Build the static zlib" FORCE)
endif()
set(ZLIB_BUILD_TESTING OFF CACHE BOOL "Do not build the zlib examples" FORCE)
set(ZLIB_INSTALL OFF CACHE BOOL "Do not install zlib into the enroute prefix" FORCE)
add_subdirectory(zlib)

# Make libzip's `find_package(ZLIB 1.1.2 REQUIRED)` resolve to the in-tree zlib
# instead of a system library. The zlib subdirectory already defines the
# ZLIB::ZLIB / ZLIB::ZLIBSTATIC aliases (with the correct include directories) when
# it built the shared library; FindZLIB skips its work when the target exists.
# On mobile (static only) we pre-seed the cache variables so FindZLIB creates an
# imported ZLIB::ZLIB pointing at the in-tree libz.a. Setting ZLIB_LIBRARY also
# prevents FindZLIB from ever locating a system zlib via find_library().
set(CMAKE_POLICY_DEFAULT_CMP0074 NEW)
set(ZLIB_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/zlib" CACHE PATH "Path to zlib sources" FORCE)
set(ZLIB_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/zlib" CACHE PATH "Path to zlib headers" FORCE)
if(ANDROID OR IOS)
    set(ZLIB_USE_STATIC_LIBS ON CACHE BOOL "Use the static zlib" FORCE)
    set(ZLIB_LIBRARY "${CMAKE_CURRENT_BINARY_DIR}/zlib/libz.a" CACHE FILEPATH "In-tree zlib" FORCE)
else()
    set(ZLIB_LIBRARY "${CMAKE_CURRENT_BINARY_DIR}/zlib/libz${CMAKE_SHARED_LIBRARY_SUFFIX}" CACHE FILEPATH "In-tree zlib" FORCE)
endif()


#
# bzip2 (compression backend for libzip)
#
# Only the library is needed; the command-line tools must not be built or
# installed. We always use the static variant and link it into libzip.
#
# bzip2's man/ subdirectory installs its manual pages to an absolute
# ${CMAKE_INSTALL_PREFIX}/man path, which would try to write into the system
# prefix. Nothing but Qt must end up in the system, so we redirect the install
# prefix of this subdirectory (and only this one) into the build tree - its
# install rules become harmless no-ops, and libzip consumes the static library
# directly from the build tree via the BZIP2_* variables set below.
set(ENABLE_LIB_ONLY ON CACHE BOOL "Only build the bzip2 library, not the applications" FORCE)
set(ENABLE_APP OFF CACHE BOOL "Do not build the bzip2 command-line tools" FORCE)
set(ENABLE_EXAMPLES OFF CACHE BOOL "Do not build the bzip2 examples" FORCE)
set(ENABLE_DOCS OFF CACHE BOOL "Do not build the bzip2 documentation" FORCE)
set(ENABLE_SHARED_LIB OFF CACHE BOOL "Do not build the shared bzip2 library" FORCE)
set(ENABLE_STATIC_LIB ON CACHE BOOL "Build the static bzip2 library" FORCE)
set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/.bzip2-install")
add_subdirectory(bzip2)
unset(CMAKE_INSTALL_PREFIX)

# Point libzip's `find_package(BZip2)` at the in-tree library. FindBZip2 creates
# the BZip2::BZip2 imported target from these variables. All three of
# BZIP2_LIBRARIES / BZIP2_LIBRARY / BZIP2_LIBRARY_RELEASE must be set: the module
# skips its find_library() calls when BZIP2_LIBRARIES is provided, and the
# imported target's location is taken from BZIP2_LIBRARY(_RELEASE).
set(BZIP2_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/bzip2" CACHE PATH "Path to bzip2 headers" FORCE)
set(BZIP2_LIBRARIES "${CMAKE_CURRENT_BINARY_DIR}/bzip2/libbz2_static.a" CACHE STRING "In-tree bzip2" FORCE)
set(BZIP2_LIBRARY "${CMAKE_CURRENT_BINARY_DIR}/bzip2/libbz2_static.a" CACHE FILEPATH "In-tree bzip2" FORCE)
set(BZIP2_LIBRARY_RELEASE "${CMAKE_CURRENT_BINARY_DIR}/bzip2/libbz2_static.a" CACHE FILEPATH "In-tree bzip2" FORCE)
set(BZIP2_FOUND TRUE CACHE BOOL "BZip2 found flag" FORCE)


#
# libzip (zip library for enroute)
#
# We build libzip from source on every platform for consistency. On Android / iOS
# it must be static (it is linked into the application binary); on the desktop the
# shared build is fine.
set(LIBZIP_DO_INSTALL OFF CACHE BOOL "Disable libzip installation" FORCE)
set(BUILD_DOC OFF CACHE BOOL "Disable libzip documentation" FORCE)
set(BUILD_EXAMPLES OFF CACHE BOOL "Disable libzip examples" FORCE)
set(BUILD_REGRESS OFF CACHE BOOL "Disable libzip regression tests" FORCE)
set(BUILD_TOOLS OFF CACHE BOOL "Disable libzip tools" FORCE)
set(ENABLE_LZMA OFF CACHE BOOL "Disable xz/lzma support" FORCE)
set(ENABLE_ZSTD OFF CACHE BOOL "Disable zstd support" FORCE)
if(ANDROID OR IOS)
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "Static libzip on mobile" FORCE)
endif()
add_subdirectory_with_rpath_isolation(libzip)
if(NOT ANDROID AND NOT IOS)
    set(BUILD_SHARED_LIBS ON CACHE BOOL "Restore shared default" FORCE)
endif()


#
# MapLibre Native Qt (map rendering)
#

set(MLN_QT_WITH_LOCATION ON CACHE BOOL "Build QMapLibreLocation" FORCE)
# enroute never uses the Qt Widgets bindings; skip them. They also require
# Qt6::OpenGLWidgets, which the Android / iOS kits do not ship.
set(MLN_QT_WITH_WIDGETS OFF CACHE BOOL "Do not build QMapLibreWidgets" FORCE)
# On mobile every library must end up inside the application binary; the static
# MapLibre build is the supported way to deploy the geoservices / QML plugins there.
if(ANDROID OR IOS)
    set(MLN_QT_STATIC ON CACHE BOOL "Build QMapLibre statically on mobile" FORCE)
else()
    set(MLN_QT_STATIC OFF CACHE BOOL "Build QMapLibre shared on the desktop" FORCE)
endif()
set(MLN_QT_WITH_COVERAGE OFF CACHE BOOL "No code coverage" FORCE)
set(MLN_QT_WITH_CLANG_TIDY OFF CACHE BOOL "No clang-tidy" FORCE)
set(MLN_QT_WITH_LTO OFF CACHE BOOL "No link-time optimization" FORCE)
set(MLN_QT_WITH_INTERNAL_ICU ON CACHE BOOL "Use the bundled ICU" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "Disable testing for dependencies" FORCE)
set(MBGL_WITH_QT_DECODERS ON CACHE BOOL "Use builtin decoders" FORCE)

# MapLibre Native (the vendored core) turns warnings into errors by default; that
# trips over unrelated warnings when compiled from within the enroute tree.
set(MLN_WITH_WERROR OFF CACHE BOOL "Do not treat MapLibre warnings as errors" FORCE)

# The MapLibre Native Qt tree unconditionally adds its `test/` directory. Those
# test targets are neither needed nor self-contained here. Skip them with an
# add_subdirectory() override; it must be defined right before adding maplibre,
# and since macros only propagate to *child* scopes, everything above this point
# is unaffected.
macro(add_subdirectory dir)
    if(NOT "${dir}" STREQUAL "test")
        _add_subdirectory(${dir} ${ARGN})
    else()
        message(STATUS "Skipping MapLibre test subdirectory: ${dir}")
    endif()
endmacro()

# MapLibre's core install rule references ${CMAKE_SOURCE_DIR}/vendor (the top of
# the enroute tree, not the maplibre submodule). Provide that path via a symlink
# while the install step runs, and remove it afterwards.
install(CODE "
    if(NOT EXISTS \"${CMAKE_SOURCE_DIR}/vendor\")
        execute_process(
            COMMAND \"${CMAKE_COMMAND}\" -E create_symlink
            3rdParty/maplibre-native-qt/vendor
            \"${CMAKE_SOURCE_DIR}/vendor\"
            RESULT_VARIABLE SYMLINK_RESULT)
        if(SYMLINK_RESULT EQUAL 0)
            message(STATUS \"Install: created vendor symlink for MapLibre Native Qt\")
        else()
            message(FATAL_ERROR \"Install: failed to create vendor symlink\")
        endif()
    endif()
")

_add_subdirectory(maplibre-native-qt)

# Clean up the temporary vendor symlink after all install operations.
install(CODE "
    if(EXISTS \"${CMAKE_SOURCE_DIR}/vendor\")
        execute_process(
            COMMAND \"${CMAKE_COMMAND}\" -E rm \"${CMAKE_SOURCE_DIR}/vendor\"
            RESULT_VARIABLE REMOVE_RESULT)
        if(REMOVE_RESULT EQUAL 0)
            message(STATUS \"Install: cleaned up vendor symlink\")
        else()
            message(WARNING \"Install: failed to remove vendor symlink\")
        endif()
    endif()
")

# When MapLibre is built in-tree the plugin targets exist as real (non-imported)
# targets, but the QMapLibre:: aliases that the install export would normally
# create are missing. Provide them so that `qmaplibre_location_setup_plugins()`
# and `qt_import_plugins(... geoservices ...)` keep working.
if(TARGET qtgeoservices_maplibre AND NOT TARGET QMapLibre::PluginGeoServices)
    add_library(QMapLibre::PluginGeoServices ALIAS qtgeoservices_maplibre)
endif()
if(TARGET declarative_locationplugin_maplibre AND NOT TARGET QMapLibre::PluginQml)
    add_library(QMapLibre::PluginQml ALIAS declarative_locationplugin_maplibre)
endif()

# Make the qmaplibre_location_setup_plugins() macro available to src/.
include(${CMAKE_CURRENT_SOURCE_DIR}/maplibre-native-qt/src/location/macros.cmake)

# Directory where the in-tree MapLibre QML module (URI "MapLibre") is generated.
# src/CMakeLists.txt passes this to qt_add_qml_module(... IMPORT_PATH ...) so that
# qmlcachegen, qmllint and androiddeployqt's qmlimportscanner can resolve
# "import MapLibre".
set(MLN_QT_PLUGIN_BUILD_DIR
    ${CMAKE_BINARY_DIR}/3rdParty/maplibre-native-qt/src/location/plugins
    CACHE INTERNAL "In-tree MapLibre QML module directory" FORCE)

# The MapLibre location / plugin targets build their include paths relative to
# ${CMAKE_SOURCE_DIR}/src/core, which resolves to the enroute tree when built
# in-tree. Add the correct directories explicitly.
foreach(_mln_tgt MLNQtCore MLNQtLocation MLNQtWidgets declarative_locationplugin_maplibre qtgeoservices_maplibre)
    if(TARGET ${_mln_tgt})
        target_include_directories(${_mln_tgt} PRIVATE
            ${CMAKE_CURRENT_SOURCE_DIR}/maplibre-native-qt/src/core
            ${CMAKE_CURRENT_SOURCE_DIR}/maplibre-native-qt/src/core/style)
    endif()
endforeach()

#
# Desktop development builds: copy the MapLibre geoservices + QML plugins next to
# the executable so the app runs without QML2_IMPORT_PATH / QT_PLUGIN_PATH.
#
function(copy_maplibre_plugins_to_target target_name)
    set(_plugin_build_dir ${MLN_QT_PLUGIN_BUILD_DIR})
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${_plugin_build_dir}/geoservices
            $<TARGET_FILE_DIR:${target_name}>/plugins/geoservices
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${_plugin_build_dir}/MapLibre
            $<TARGET_FILE_DIR:${target_name}>/MapLibre
        COMMENT "Copying MapLibre geoservices + QML plugins next to ${target_name}")
endfunction()

#
# One-stop plugin setup for an enroute executable, replacing upstream's
# qmaplibre_location_setup_plugins() where MapLibre is built in-tree.
#
# Upstream's macro inspects IMPORTED_LOCATION properties of the plugin targets,
# which only exist when QMapLibre was found via find_package() in a Qt
# installation. With the plugins built in this very tree we know the locations
# directly, so we replicate what the macro does:
#
#  * static MapLibre (Android / iOS): link the plugin targets into the
#    application; qt_import_plugins() takes care of the plugin initialisation.
#  * shared MapLibre (desktop): point QT_QML_IMPORT_PATH at the freshly built
#    MapLibre QML module (qmllint / qmlls) and copy the plugins next to the
#    executable (development runs) or into the bundle (macOS).
#
function(enroute_setup_maplibre_plugins target_name)
    set(_plugin_build_dir ${MLN_QT_PLUGIN_BUILD_DIR})

    # Make the MapLibre QML module visible to qmllint, qmlcachegen and the IDE.
    set_target_properties(${target_name} PROPERTIES QT_QML_IMPORT_PATH "${_plugin_build_dir}")
    list(APPEND QML_IMPORT_PATH "${_plugin_build_dir}")
    list(REMOVE_DUPLICATES QML_IMPORT_PATH)
    set(QML_IMPORT_PATH ${QML_IMPORT_PATH} CACHE STRING "QML import path for Qt Creator" FORCE)

    if(MLN_QT_STATIC)
        # Android / iOS: the plugins are linked into the application binary;
        # qt_import_plugins() takes care of the plugin initialisation.
        target_link_libraries(${target_name}
            PRIVATE
                QMapLibre::PluginGeoServices
                QMapLibre::PluginQml)
        return()
    endif()

    if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        # Mirror the upstream macro: the geoservices plugin goes into the app
        # bundle, the MapLibre QML module into the bundle's qml directory.
        add_custom_command(TARGET ${target_name} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy
                $<TARGET_FILE:qtgeoservices_maplibre>
                $<TARGET_BUNDLE_DIR:${target_name}>/Contents/PlugIns/geoservices/
            COMMAND ${CMAKE_COMMAND} -E copy_directory
                ${_plugin_build_dir}/MapLibre
                $<TARGET_BUNDLE_DIR:${target_name}>/Contents/Resources/qml/MapLibre
            COMMENT "Copying MapLibre plugins into ${target_name}.app")
        set_source_files_properties(${_plugin_build_dir}/MapLibre PROPERTIES
            MACOSX_PACKAGE_LOCATION "Resources/qml")
    else()
        copy_maplibre_plugins_to_target(${target_name})
    endif()
endfunction()


#
# Restore the RPATH / pkg-config settings that the dependencies above overwrote.
#
if(DEFINED _SAVED_CMAKE_INSTALL_RPATH)
    set(CMAKE_INSTALL_RPATH "${_SAVED_CMAKE_INSTALL_RPATH}")
endif()
if(DEFINED _SAVED_CMAKE_INSTALL_RPATH_USE_LINK_PATH)
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH "${_SAVED_CMAKE_INSTALL_RPATH_USE_LINK_PATH}")
endif()
if(DEFINED _SAVED_CMAKE_MACOSX_RPATH)
    set(CMAKE_MACOSX_RPATH "${_SAVED_CMAKE_MACOSX_RPATH}")
endif()
if(DEFINED _SAVED_PKG_CONFIG_RPATH)
    set(PKG_CONFIG_RPATH "${_SAVED_PKG_CONFIG_RPATH}")
endif()

