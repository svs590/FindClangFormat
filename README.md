# FindClangFormat

This repo provides FindClangFormat.cmake module, which can be used to configure a CMake project that needs clang-format. 
The module supports selection by version and REQUIRED/QUIET flags.

## Usage

1. Download FindClangFormat.cmake and place it wherever is needed in your project.
2. [*Configure*](https://cmake.org/cmake/help/latest/variable/CMAKE_MODULE_PATH.html) your CMakeLists.txt for search FindClangFormat.cmake module (add FindClangFormat.cmake directory to `CMAKE_MODULE_PATH` variable).
3. Use `find_package(ClangFormat [version] [QUIET] [REQUIRED])` in CMakeLists.txt.

There are two optional variables `CLANGFORMAT_EXECUTABLE` and `CLANGFORMAT_ROOT` that can help find appropriate clang-format executable. If an exact executable `CLANGFORMAT_EXECUTABLE` presented, then `find_package` tries to use only that executable. Otherwise, `find_package` search appropriate clang-format on your system, including additional search directory `CLANGFORMAT_ROOT` (can be empty/not defined).

If version is specified, `find_package` finds the first clang-format executable that satisfies this version. Otherwise, if both version and `CLANGFORMAT_EXECUTABLE` are not specified, find_package finds the highest version.

The following are set after `find_package` is done:
- `CLANGFORMAT_FOUND`       -  true if clang-format found, else otherwise;
- `CLANGFORMAT_ROOT_DIR`    -  path to the clang-format base directory;
- `CLANGFORMAT_EXECUTABLE`  -  path to the clang-format executable;
- `CLANGFORMAT_VERSION`     -  version string of the clang-format.

For example, this code finds the highest version of clang-format in REQUIRED mode:
```
find_package(ClangFormat REQUIRED)
add_custom_target(
    clangformat ALL COMMAND ${CLANGFORMAT_EXECUTABLE}
    -style=<style | file:filename.clang-format>
    -i ${ALL_FILES}
)
```

In this example `find_package` tries to find clang-format 14 or higher in REQUIRED mode:
```
find_package(ClangFormat 14 REQUIRED)
...
```

Usage with exact executable path:
```cmake . -DCLANGFORMAT_EXECUTABLE="/usr/bin/clang-format-14.0"```

## Licensed under the MIT License