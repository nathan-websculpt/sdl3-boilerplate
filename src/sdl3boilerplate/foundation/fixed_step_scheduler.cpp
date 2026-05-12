#include "sdl3boilerplate/foundation/fixed_step_scheduler.hpp"

#include <algorithm>
#include <cmath>

namespace sdl3boilerplate::foundation {

SecondsF FixedStepScheduler::ClampFrameDelta(SecondsF frame_delta) {
    const float delta_seconds = frame_delta.count();
    if (delta_seconds <= 0.0F || !std::isfinite(delta_seconds)) {
        return SecondsF::zero();
    }

    return std::min(frame_delta, kMaxFrameDelta);
}

std::size_t FixedStepScheduler::Advance(SecondsF frame_delta) {
    accumulator_ += ClampFrameDelta(frame_delta);

    std::size_t step_count = 0;
    while (accumulator_ >= kFixedTimeStep) {
        accumulator_ -= kFixedTimeStep;
        ++step_count;
    }

    return step_count;
}

SecondsF FixedStepScheduler::accumulator() const {
    return accumulator_;
}

} // namespace sdl3boilerplate::foundation
