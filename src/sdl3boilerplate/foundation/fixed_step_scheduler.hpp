#ifndef SDL3BOILERPLATE_FOUNDATION_FIXED_STEP_SCHEDULER_HPP
#define SDL3BOILERPLATE_FOUNDATION_FIXED_STEP_SCHEDULER_HPP

#include <cstddef>

#include "sdl3boilerplate/foundation/time.hpp"

namespace sdl3boilerplate::foundation {

class FixedStepScheduler {
public:
    [[nodiscard]] static SecondsF ClampFrameDelta(SecondsF frame_delta);

    [[nodiscard]] std::size_t Advance(SecondsF frame_delta);
    [[nodiscard]] SecondsF accumulator() const;

private:
    SecondsF accumulator_{SecondsF::zero()};
};

} // namespace sdl3boilerplate::foundation

#endif // SDL3BOILERPLATE_FOUNDATION_FIXED_STEP_SCHEDULER_HPP
