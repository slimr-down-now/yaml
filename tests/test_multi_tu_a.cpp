#include "yaml.hpp"

bool multi_tu_yaml_roundtrip_b();

int main() {
    auto split = slimr::parse_frontmatter("---\nkey: value\n---\nbody\n");
    if (!split || !split->frontmatter) {
        return 1;
    }
    if ((*split->frontmatter)["key"].get<std::string>() != "value") {
        return 1;
    }
    return multi_tu_yaml_roundtrip_b() ? 0 : 1;
}
