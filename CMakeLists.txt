cmake_minimum_required(VERSION 3.25)

project(
    sdl3_boilerplate
    VERSION 0.1.0
    DESCRIPTION "Reusable SDL3 C++20 game foundation"
    LANGUAGES CXX)

option(SDL3BOILERPLATE_ENABLE_MSVC_ANALYZE "Enable MSVC static analysis." OFF)

find_package(SDL3 CONFIG REQUIRED)

add_library(sdl3boilerplate_foundation STATIC
    src/sdl3boilerplate/foundation/fixed_step_scheduler.cpp)

target_include_directories(sdl3boilerplate_foundation
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_compile_features(sdl3boilerplate_foundation PUBLIC cxx_std_20)

add_library(sdl3boilerplate_sim STATIC
    src/sdl3boilerplate/sim/game.cpp
    src/sdl3boilerplate/sim/player.cpp)

target_include_directories(sdl3boilerplate_sim
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_compile_features(sdl3boilerplate_sim PUBLIC cxx_std_20)

target_link_libraries(sdl3boilerplate_sim
    PUBLIC
        sdl3boilerplate_foundation)

add_library(sdl3boilerplate_input STATIC
    src/sdl3boilerplate/input/input_translator.cpp)

target_include_directories(sdl3boilerplate_input
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_compile_features(sdl3boilerplate_input PUBLIC cxx_std_20)

target_link_libraries(sdl3boilerplate_input
    PUBLIC
        SDL3::SDL3)

add_library(sdl3boilerplate_sdl STATIC
    src/sdl3boilerplate/app/platform.cpp
    src/sdl3boilerplate/render/renderer.cpp)

target_include_directories(sdl3boilerplate_sdl
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_compile_features(sdl3boilerplate_sdl PUBLIC cxx_std_20)

target_link_libraries(sdl3boilerplate_sdl
    PUBLIC
        sdl3boilerplate_input
        sdl3boilerplate_sim
        SDL3::SDL3)

add_executable(sdl3boilerplate
    src/sdl3boilerplate/app/main.cpp)

target_compile_features(sdl3boilerplate PRIVATE cxx_std_20)

target_link_libraries(sdl3boilerplate
    PRIVATE
        sdl3boilerplate_sdl)

function(sdl3boilerplate_apply_diagnostics target_name)
    if(MSVC)
        target_compile_options(${target_name}
            PRIVATE
                /W4
                /permissive-
                /Zc:__cplusplus)
    else()
        target_compile_options(${target_name}
            PRIVATE
                -Wall
                -Wextra
                -Wpedantic)
    endif()
endfunction()

function(sdl3boilerplate_apply_analysis target_name)
    if(MSVC AND SDL3BOILERPLATE_ENABLE_MSVC_ANALYZE)
        target_compile_options(${target_name}
            PRIVATE
                /analyze)
    endif()
endfunction()

sdl3boilerplate_apply_diagnostics(sdl3boilerplate_sim)
sdl3boilerplate_apply_diagnostics(sdl3boilerplate_foundation)
sdl3boilerplate_apply_diagnostics(sdl3boilerplate_input)
sdl3boilerplate_apply_diagnostics(sdl3boilerplate_sdl)
sdl3boilerplate_apply_diagnostics(sdl3boilerplate)
sdl3boilerplate_apply_analysis(sdl3boilerplate_foundation)
sdl3boilerplate_apply_analysis(sdl3boilerplate_sim)
sdl3boilerplate_apply_analysis(sdl3boilerplate_input)
sdl3boilerplate_apply_analysis(sdl3boilerplate_sdl)
sdl3boilerplate_apply_analysis(sdl3boilerplate)

include(CTest)

if(BUILD_TESTING)
    find_package(GTest CONFIG REQUIRED)
    include(GoogleTest)

    add_executable(sdl3boilerplate_foundation_tests
        tests/foundation/test_fixed_step_scheduler.cpp
        tests/foundation/test_time_constants.cpp)

    target_link_libraries(sdl3boilerplate_foundation_tests
        PRIVATE
            sdl3boilerplate_foundation
            GTest::gtest_main)

    sdl3boilerplate_apply_diagnostics(sdl3boilerplate_foundation_tests)
    gtest_discover_tests(sdl3boilerplate_foundation_tests)

    add_executable(sdl3boilerplate_sim_tests
        tests/sim/test_game_movement.cpp
        tests/sim/test_player_bounds.cpp)

    target_link_libraries(sdl3boilerplate_sim_tests
        PRIVATE
            sdl3boilerplate_sim
            GTest::gtest_main)

    sdl3boilerplate_apply_diagnostics(sdl3boilerplate_sim_tests)
    gtest_discover_tests(sdl3boilerplate_sim_tests)

    add_executable(sdl3boilerplate_input_tests
        tests/input/test_input_translator.cpp)

    target_link_libraries(sdl3boilerplate_input_tests
        PRIVATE
            sdl3boilerplate_input
            SDL3::SDL3
            GTest::gtest_main)

    sdl3boilerplate_apply_diagnostics(sdl3boilerplate_input_tests)
    gtest_discover_tests(sdl3boilerplate_input_tests)

    add_executable(sdl3boilerplate_render_tests
        tests/render/test_renderer.cpp)

    target_link_libraries(sdl3boilerplate_render_tests
        PRIVATE
            sdl3boilerplate_sdl
            GTest::gtest_main)

    sdl3boilerplate_apply_diagnostics(sdl3boilerplate_render_tests)
    gtest_discover_tests(sdl3boilerplate_render_tests)

    add_custom_target(sdl3boilerplate_tests
        DEPENDS
            sdl3boilerplate_foundation_tests
            sdl3boilerplate_sim_tests
            sdl3boilerplate_input_tests
            sdl3boilerplate_render_tests)
endif()
