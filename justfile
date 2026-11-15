set shell := ["bash", "-eu", "-o", "pipefail", "-c"]
set positional-arguments

architecture := replace(replace(arch(), "aarch64", "arm64"), "x86_64", "x64")
system := if os() == "macos" { "osx" } else { os() }
triplet := f'{{architecture}}-{{system}}'
cxx := env("CXX", if os() == "macos" { "/usr/bin/clang++" } else { "clang++" })

_:
    @just --list

# Install vcpkg dependencies into build/deps
deps:
    : "${VCPKG_ROOT:?Set VCPKG_ROOT to a bootstrapped checkout}"
    vcpkg install --x-wait-for-lock --x-feature=tests --triplet={{triplet}} --x-install-root=build/deps

# Configure CMake (Debug enables ASan + UBSan)
configure configuration="Debug": deps
    CXX="{{cxx}}" cmake -S . -B "build/cmake/$1" -G Ninja -DCMAKE_BUILD_TYPE="$1" -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" -DVCPKG_MANIFEST_MODE=OFF -DVCPKG_MANIFEST_INSTALL=OFF -DVCPKG_INSTALLED_DIR="{{justfile_directory()}}/build/deps" -DVCPKG_TARGET_TRIPLET={{triplet}} -DENABLE_SANITIZERS={{if configuration == "Debug" { "ON" } else { "OFF" }}}

# Debug build with ASan + UBSan, then run all tests
test: (configure "Debug")
    cmake --build build/cmake/Debug --parallel 2
    BUGSINK_DSN= ctest --test-dir build/cmake/Debug --output-on-failure --no-tests=error

# Compile the Release binary
build: (configure "Release")
    cmake --build build/cmake/Release --parallel 2

# Remove build output
clean:
    rm -rf build
