#ifndef SDL3BOILERPLATE_FOUNDATION_TIME_HPP
#define SDL3BOILERPLATE_FOUNDATION_TIME_HPP

#include <chrono>

namespace sdl3boilerplate::foundation {

using Clock = std::chrono::steady_clock;
using SecondsF = std::chrono::duration<float>;

inline constexpr int kFixedUpdatesPerSecond = 60;
inline constexpr SecondsF kFixedTimeStep{1.0F / static_cast<float>(kFixedUpdatesPerSecond)};
inline constexpr SecondsF kMaxFrameDelta{0.25F};

} // namespace sdl3boilerplate::foundation

#endif // SDL3BOILERPLATE_FOUNDATION_TIME_HPP
