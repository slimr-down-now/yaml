# slimr::yaml

Fast, robust C++26 YAML parsing and serialization library built on top of [RapidYAML (ryml)](https://github.com/biojppm/rapidyaml) and `slimr::json`, featuring `std::expected` error handling and Markdown frontmatter extraction.

Borrowed directly from the design of [`@slimr/yaml`](https://www.npmjs.com/package/@slimr/yaml).

## Why `slimr::yaml`?

- **RapidYAML Core:** Powered by high-performance zero-copy RapidYAML underneath for fast in-arena parsing.
- **Seamless `slimr::Json` & Struct Integration:** Parses YAML directly into `slimr::Json` trees or arbitrary C++ structs via Glaze.
- **Markdown Frontmatter Support:** Built-in `parse_frontmatter()` helper for extracting and parsing YAML frontmatter blocks (`--- ... ---`) from Markdown documents.
- **Clean `std::expected` Errors:** Catches exceptions and reports descriptive error messages without crashing.

## Install

Add `slimr-down-now/yaml` to `vcpkg-configuration.json`:

```json
{
  "kind": "git",
  "repository": "https://github.com/slimr-down-now/yaml",
  "baseline": "<commit-sha>",
  "packages": [
    "slimr-yaml"
  ]
}
```

Declare `slimr-yaml` in `vcpkg.json` and link `slimr::yaml` in `CMakeLists.txt`:

```cmake
find_package(slimr-yaml CONFIG REQUIRED)
target_link_libraries(my_target PRIVATE slimr::yaml)
```

## Quick Start

```cpp
#include <yaml.hpp>
#include <iostream>

using namespace slimr;

int main() {
    // Parse YAML string into slimr::Json with std::expected
    auto yaml_str = R"(
        title: Hello Slimr
        version: 1.0
        features:
          - fast
          - robust
    )";

    auto doc = parse_yaml(yaml_str);
    if (!doc) {
        std::cerr << "YAML parse error: " << doc.error() << "\n";
        return 1;
    }

    std::string title = (*doc)["title"].get<std::string>();

    // Serialize back to YAML
    std::string serialized = to_yaml(*doc);

    // Parse Markdown frontmatter
    std::string markdown = R"(---
author: Alice
tags: [cpp, yaml]
---
# Document Body
Hello world!
)";

    auto parsed_fm = parse_frontmatter(markdown);
    if (parsed_fm && parsed_fm->frontmatter) {
        std::string author = (*parsed_fm->frontmatter)["author"].get<std::string>();
        std::cout << "Author: " << author << "\nBody: " << parsed_fm->body << "\n";
    }

    return 0;
}
```

---

## API Cheat Sheet

| Function / Type | Signature | Description |
| --- | --- | --- |
| `parse_yaml` | `template <typename T = Json> inline std::expected<T, std::string> parse_yaml(std::string_view yaml_str)` | Parses YAML string into `slimr::Json` or typed C++ struct `T` inside `std::expected`. |
| `to_yaml` | `template <typename T> inline std::string to_yaml(const T& val)` | Serializes a `slimr::Json` value or C++ struct `T` to a YAML string. |
| `FrontmatterSplit` | `struct FrontmatterSplit { std::optional<Json> frontmatter; std::string raw_frontmatter; std::string body; };` | Result structure containing parsed frontmatter and markdown body. |
| `parse_frontmatter` | `inline std::expected<FrontmatterSplit, std::string> parse_frontmatter(std::string_view markdown)` | Splits Markdown with `---` YAML frontmatter into `{ frontmatter, body }`. |

## Develop against an unreleased lib

vcpkg reads extra port dirs from `VCPKG_OVERLAY_PORTS`, and an overlay wins over the registry. Point it at a dir of symlinks, one per unreleased lib; manifests never change:

```sh
mkdir -p ~/.vcpkg/overlays/dev
ln -s ~/dev/slimr/<name>/ports/slimr-<name> ~/.vcpkg/overlays/dev/slimr-<name>
export VCPKG_OVERLAY_PORTS=~/.vcpkg/overlays/dev
just test
```

Remove the symlink (or `unset VCPKG_OVERLAY_PORTS`) to build against the released lib again. Keep the export out of shell startup files. `just release` refuses to run while `VCPKG_OVERLAY_PORTS` is set.

## Environment Variables

| Name | Required | Purpose |
| --- | --- | --- |
| *(none)* | — | — |

## Development

See [docs/development.md](docs/development.md) for building, testing, linting, and releasing.
