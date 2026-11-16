cmake_minimum_required(VERSION 3.31)
set(CMAKE_OSX_DEPLOYMENT_TARGET "15.0" CACHE STRING "Minimum macOS version")
if(CMAKE_HOST_APPLE AND NOT CMAKE_OSX_SYSROOT)
    execute_process(COMMAND xcrun --show-sdk-path
        OUTPUT_VARIABLE CMAKE_OSX_SYSROOT OUTPUT_STRIP_TRAILING_WHITESPACE
        COMMAND_ERROR_IS_FATAL ANY)
endif()
project(slimr-yaml VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 26)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
include(CTest)
include(CheckIPOSupported)
include(CheckCXXSourceCompiles)
option(ENABLE_SANITIZERS "Enable address and undefined behavior sanitizers" OFF)

add_library(app_options INTERFACE)
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    execute_process(COMMAND "${CMAKE_CXX_COMPILER}" -print-file-name=libc++.so
        OUTPUT_VARIABLE libcxx_so OUTPUT_STRIP_TRAILING_WHITESPACE COMMAND_ERROR_IS_FATAL ANY)
    cmake_path(GET libcxx_so PARENT_PATH libcxx_dir)
    cmake_path(NORMAL_PATH libcxx_dir)
    string(APPEND CMAKE_REQUIRED_FLAGS " -stdlib=libc++")
    list(APPEND CMAKE_REQUIRED_LINK_OPTIONS -L${libcxx_dir})
    target_compile_options(app_options INTERFACE -stdlib=libc++)
    target_link_options(app_options INTERFACE -stdlib=libc++ -L${libcxx_dir}
        $<$<CONFIG:Release>:-static-libstdc++> $<$<NOT:$<CONFIG:Release>>:-Wl$<COMMA>-rpath$<COMMA>${libcxx_dir}>)
endif()
target_compile_options(app_options INTERFACE -ftrivial-auto-var-init=zero)
check_cxx_source_compiles("
#include <version>
#ifndef _LIBCPP_VERSION
#error libc++ is required for the selected hardening mode
#endif
#ifndef _LIBCPP_HARDENING_MODE_FAST
#error libc++ FAST hardening is unavailable
#endif
int main() { return 0; }" HAVE_LIBCPP_HARDENING)
if(NOT HAVE_LIBCPP_HARDENING)
    message(FATAL_ERROR "Use a Clang/libc++ toolchain supporting FAST hardening (the check also fails on link errors; see CMakeFiles/CMakeConfigureLog.yaml)")
endif()
target_compile_definitions(app_options INTERFACE
    _LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_FAST)
if(ENABLE_SANITIZERS)
    target_compile_options(app_options INTERFACE
        -g -fsanitize=address,undefined -fno-sanitize-recover=undefined)
    target_link_options(app_options INTERFACE -fsanitize=address,undefined)
endif()
check_ipo_supported(RESULT HAVE_IPO OUTPUT IPO_ERROR)
if(NOT HAVE_IPO)
    message(FATAL_ERROR "Release IPO is required: ${IPO_ERROR}")
endif()

find_package(slimr-json CONFIG REQUIRED)
add_library(slimr_yaml INTERFACE)
add_library(slimr::yaml ALIAS slimr_yaml)
target_compile_features(slimr_yaml INTERFACE cxx_std_26)
target_include_directories(slimr_yaml INTERFACE
    "${CMAKE_CURRENT_SOURCE_DIR}/ports/slimr-yaml"
    "${CMAKE_CURRENT_SOURCE_DIR}/ports/slimr-yaml/vendor")
target_sources(slimr_yaml INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/ports/slimr-yaml/yaml_impl.cpp")
target_link_libraries(slimr_yaml INTERFACE slimr::json)

if(BUILD_TESTING)
    find_package(slimr-test CONFIG REQUIRED)
    add_executable(yaml_test tests/test_main.cpp)
    target_link_libraries(yaml_test PRIVATE slimr::yaml slimr::test app_options)
    set_target_properties(yaml_test PROPERTIES INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
    add_test(NAME yaml COMMAND yaml_test)
    set_tests_properties(yaml PROPERTIES TIMEOUT 120
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        ENVIRONMENT "BUGSINK_DSN=;TMPDIR=${CMAKE_BINARY_DIR}")

    add_executable(yaml_multi_tu_test tests/test_multi_tu_a.cpp tests/test_multi_tu_b.cpp)
    target_link_libraries(yaml_multi_tu_test PRIVATE slimr::yaml app_options)
    set_target_properties(yaml_multi_tu_test PROPERTIES INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
    add_test(NAME yaml_multi_tu COMMAND yaml_multi_tu_test)
    set_tests_properties(yaml_multi_tu PROPERTIES TIMEOUT 120
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        ENVIRONMENT "BUGSINK_DSN=;TMPDIR=${CMAKE_BINARY_DIR}")
endif()
