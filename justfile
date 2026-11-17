set shell := ["bash", "-eu", "-o", "pipefail", "-c"]
set positional-arguments

name := "slimr-yaml"
test_target := "yaml_test"
platforms := "macos linux"
required := "brew cmake gh git jq just ninja vcpkg"
llvm := env("LLVM_BIN", `brew --prefix llvm@23` + "/bin")
cxx := env("CXX", llvm + "/clang++")
triplet := replace(replace(arch(), "aarch64", "arm64"), "x86_64", "x64") + if os() == "macos" { "-osx" } else { "-linux" }
deps_env := "CC=\"" + llvm + "/clang\" CXX=\"" + cxx + "\" LIBCXX_DIR=\"$(dirname \"$(\"" + cxx + "\" -print-file-name=" + (if os() == "macos" { "c++/libc++.a" } else { "libc++.so" }) + ")\")\" "

_:
    @just --list

# Compile the Release library and test target (no tests)
build: (configure "Release")
    cmake --build build/cmake/Release --parallel 2

# Remove build output
clean:
    rm -rf build

# Configure CMake (Debug enables ASan + UBSan)
configure configuration="Debug": deps
    CC="{{ llvm }}/clang" CXX="{{ cxx }}" cmake -S . -B build/cmake/{{ configuration }} -G Ninja -DCMAKE_BUILD_TYPE={{ configuration }} -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" -DVCPKG_MANIFEST_MODE=OFF -DVCPKG_INSTALLED_DIR="{{ justfile_directory() }}/build/deps" -DVCPKG_TARGET_TRIPLET={{ triplet }} -DENABLE_SANITIZERS={{ if configuration == "Debug" { "ON" } else { "OFF" } }}

# Install vcpkg dependencies into build/deps
deps:
    {{ deps_env }}vcpkg install --x-wait-for-lock --x-feature=tests --overlay-triplets=triplets --triplet={{ triplet }} --x-install-root=build/deps

# Check required tools, C++26 support and env vars, printing fixes
doctor:
    LLVM_BIN="{{ llvm }}" bash scripts/doctor.sh {{ required }}

# Format C++ sources and this justfile
fmt:
    git ls-files -co --exclude-standard '*.cpp' '*.hpp' | xargs "{{ llvm }}/clang-format" -i
    just --fmt --unstable

# Check formatting, then lint with clang-tidy
lint: (configure "Debug")
    git ls-files -co --exclude-standard '*.cpp' '*.hpp' | xargs "{{ llvm }}/clang-format" --dry-run --Werror
    just --fmt --check --unstable
    "{{ llvm }}/clang-tidy" -p build/cmake/Debug --header-filter='[/\\](ports[/\\]{{ name }}|tests)[/\\][^/\\]+$' tests/*.cpp

# Release on GitHub (tests per platform, version bump, changelog, tag), then pull the release commit
release bump:
    gh workflow run release.yml -f bump="$1"
    sleep 5; id="$(gh run list --workflow release.yml --limit 1 --json databaseId -q '.[0].databaseId')"; if [ -t 1 ]; then gh run watch --interval 30 --compact --exit-status "$id"; else gh run watch --interval 30 --exit-status "$id" >/dev/null; fi || { gh run view "$id" --log-failed | tail -n 100; exit 1; }
    git pull --ff-only

# Debug build with ASan + UBSan, then run all tests, or only doctest cases matching filter
test filter="": (configure "Debug")
    if [ -z "$1" ]; then cmake --build build/cmake/Debug --parallel 2 && BUGSINK_DSN= ctest --test-dir build/cmake/Debug --output-on-failure --no-tests=error; else cmake --build build/cmake/Debug --target {{ test_target }} --parallel 2 && BUGSINK_DSN= build/cmake/Debug/{{ test_target }} -tc="$1"; fi

# Move vcpkg registry baselines to latest, then run tests (no commit)
upgrade-deps:
    git -C "$VCPKG_ROOT" pull --ff-only
    vcpkg x-update-baseline --x-install-root=build/deps
    just test
