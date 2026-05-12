#ifndef SDL3BOILERPLATE_FOUNDATION_CONFIG_HPP
#define SDL3BOILERPLATE_FOUNDATION_CONFIG_HPP

#include <cstdint>

namespace sdl3boilerplate::foundation {

struct Color {
    std::uint8_t r;
    std::uint8_t g;
    std::uint8_t b;
    std::uint8_t a;
};

inline constexpr const char* kApplicationTitle = "SDL3 Boilerplate";

inline constexpr int kWindowWidth = 960;
inline constexpr int kWindowHeight = 720;

inline constexpr float kPlayerSize = 24.0F;
inline constexpr float kPlayerSpeedPixelsPerSecond = 240.0F;

inline constexpr Color kBackgroundColor{10, 14, 22, 255};
inline constexpr Color kPlayerColor{245, 247, 250, 255};

} // namespace sdl3boilerplate::foundation

#endif // SDL3BOILERPLATE_FOUNDATION_CONFIG_HPP
