# Changelog

## Unreleased

- Internal: switch macOS builds to `llvm@23` with static `libc++` and `-Wl,-exported_symbols_list,/dev/null`.
- Internal: align tooling with the cpp-templates library template.
- Split `slimr-yaml` from `slimr-cpp` into its own vcpkg registry repository.
- Internal: move the repository to `slimr-down-now/yaml`
