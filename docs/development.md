# Development

## Prerequisites

Run `just doctor` to verify required tools (`brew`, `cmake`, `gh`, `git`, `jq`, `just`, `ninja`, `vcpkg`), `VCPKG_ROOT`, C++26 compilation, and `LLVM_BIN` (`llvm@23` `clang-format` / `clang-tidy`).

## Build, Test, and Lint

```bash
just test              # Debug build (ASan + UBSan) and run all tests
just test "<case>"     # Run only doctest cases matching filter
just build             # Release build (no tests run)
just fmt               # Format C++ sources and justfile
just lint              # Check formatting and run clang-tidy
just upgrade-deps      # Update vcpkg baselines and run tests
```

## Release

```bash
just release patch     # Trigger release.yml (patch|minor|major) and pull tag commit
```
