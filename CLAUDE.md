# Project: enroute

## Build & lint
# All third-party libraries (zlib, bzip2, libzip, maplibre-native-qt) are git
# submodules under 3rdParty/ and are compiled as part of the enroute build — the
# separate "enrouteDependencies" repository is no longer required. After cloning:
#     git submodule update --init --recursive
# Build against the Qt online-installer kit; the path comes from the environment:
#     export Qt6_DIR_BASE=/opt/Qt/6.11.2/
#     export Qt6_DIR_LINUX=/opt/Qt/6.11.2/gcc_64/
# ./build-linux.sh configures + builds into build-linux/ (Debug, ccache, Ninja);
# pass -no-clean to keep the tree, -run to start the app afterwards. The build
# copies the MapLibre geoservices + QML plugins next to the executable, so
# build-linux/src/enroute runs without QML2_IMPORT_PATH / QT_PLUGIN_PATH.
cmake -B build/claude -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_PREFIX_PATH="$Qt6_DIR_LINUX"
cmake --build build/claude
cmake --build build/claude --target all_qmllint   # lint all QML (resolves project modules)
# NOTE: this project has no test target — `ctest` reports 0 tests. Verify via build +
# qmllint (and, if needed, by launching the app).
# The flight log (src/flightlog, FlightLogPage.qml) is work in progress and hidden in
# default builds. Add -DFLIGHTLOG=ON to the configure line to work on it. The option is
# cached in build/claude, so pass -DFLIGHTLOG=OFF/ON explicitly when the state matters.
# Android: ./build-android.sh builds the APK with the android_arm64_v8a kit; the
# dependencies are built in-tree (static) as well, nothing is installed into the kit.

## Conventions & rules
- Always build into build/claude (pass -B build/claude). Never configure into the repo
  root or into build/ directly, and do not create any other build directory.
- Don't hand-edit moc_*, qrc_*, or anything under build/ — they're generated.
- New C++ type exposed to QML: add QML_ELEMENT, ensure the file is in the module's
  SOURCES, then rebuild before assuming QML can see it.
- New .qml file: add it to QML_FILES in CMakeLists.txt, or it won't be in the module.
- After editing C++ headers, rebuild — moc-generated code won't update otherwise.
- A display is available (DISPLAY=:0 / Wayland). Launching the app puts a real window on
  the user's live desktop and may use real sensors/Bluetooth/position — don't launch it
  unprompted; ask first.
- Match existing qmlformat / clang-format style; don't reformat unrelated lines.
- Bindings must consume every dependency they rely on. Never "mention" a property
  (`Foo.bar; return f()`) to force re-evaluation: the QML-to-C++ compiler drops
  unused reads together with their change captures. Use the value in the
  expression, pass it to the C++ function as an argument (e.g.
  `metar.summary(Navigator.aircraft, Clock.time)`), or use a Connections handler
  with an imperative assignment.
- Lists over library data bind once to an item model: the library is a
  QAbstractListModel (WaypointLibrary, VACLibrary, Librarian.aircraftModel /
  routesModel); pages filter and sort through NameFilterProxyModel or
  DistanceSortProxyModel (src/ui/). No Q_INVOKABLE functions returning arrays as
  list models, no reload triggers. Delegates declare typed `required property`
  roles (`required property waypoint waypoint`), not `modelData`.
- Library-style data emits row-granular signals (begin/endInsertRows,
  begin/endRemoveRows, dataChanged); beginResetModel only for bulk replacement.
