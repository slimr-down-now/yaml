#include "yaml.hpp"

bool multi_tu_yaml_roundtrip_b() {
    auto parsed = slimr::parse_yaml("count: 7\nname: multi\n");
    if (!parsed) {
        return false;
    }
    if ((*parsed)["count"].get<int64_t>() != 7 || (*parsed)["name"].get<std::string>() != "multi") {
        return false;
    }
    auto emitted = slimr::to_yaml(*parsed);
    return emitted.find("name: multi") != std::string::npos;
}
