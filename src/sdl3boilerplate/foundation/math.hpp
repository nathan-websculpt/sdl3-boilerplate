#ifndef SDL3BOILERPLATE_FOUNDATION_MATH_HPP
#define SDL3BOILERPLATE_FOUNDATION_MATH_HPP

#include <algorithm>
#include <cmath>

namespace sdl3boilerplate::foundation {

struct Vec2 {
    float x;
    float y;
};

inline Vec2 operator+(Vec2 lhs, Vec2 rhs) {
    return Vec2{lhs.x + rhs.x, lhs.y + rhs.y};
}

inline Vec2 operator*(Vec2 vector, float scalar) {
    return Vec2{vector.x * scalar, vector.y * scalar};
}

inline bool IsFinite(float value) {
    return std::isfinite(value);
}

inline bool IsFinite(Vec2 value) {
    return IsFinite(value.x) && IsFinite(value.y);
}

inline float Length(Vec2 value) {
    return std::sqrt((value.x * value.x) + (value.y * value.y));
}

inline Vec2 NormalizeOrZero(Vec2 value) {
    const float length = Length(value);
    if (length <= 0.0F || !IsFinite(length)) {
        return Vec2{0.0F, 0.0F};
    }

    return Vec2{value.x / length, value.y / length};
}

inline Vec2 Clamp(Vec2 value, Vec2 minimum, Vec2 maximum) {
    return Vec2{
        std::clamp(value.x, minimum.x, maximum.x),
        std::clamp(value.y, minimum.y, maximum.y),
    };
}

} // namespace sdl3boilerplate::foundation

#endif // SDL3BOILERPLATE_FOUNDATION_MATH_HPP
