#include <cstddef>
#include <gtest/gtest.h>
#include <limits>

#include "sdl3boilerplate/foundation/fixed_step_scheduler.hpp"
#include "sdl3boilerplate/foundation/time.hpp"

namespace {

constexpr float kTolerance = 0.000001F;

using sdl3boilerplate::foundation::FixedStepScheduler;
using sdl3boilerplate::foundation::kFixedTimeStep;
using sdl3boilerplate::foundation::kFixedUpdatesPerSecond;
using sdl3boilerplate::foundation::kMaxFrameDelta;
using sdl3boilerplate::foundation::SecondsF;

void ExpectSecondsNear(SecondsF actual, SecondsF expected) {
    EXPECT_NEAR(expected.count(), actual.count(), kTolerance);
}

TEST(FixedStepScheduler, ClampsLargeFrameDeltas) {
    ExpectSecondsNear(FixedStepScheduler::ClampFrameDelta(kMaxFrameDelta + SecondsF{10.0F}),
                      kMaxFrameDelta);

    FixedStepScheduler large_delta_scheduler;
    FixedStepScheduler clamped_delta_scheduler;
    const std::size_t expected_clamped_steps = static_cast<std::size_t>(
        kMaxFrameDelta.count() * static_cast<float>(kFixedUpdatesPerSecond));

    const std::size_t large_delta_steps = large_delta_scheduler.Advance(SecondsF{10.0F});
    const std::size_t clamped_delta_steps = clamped_delta_scheduler.Advance(kMaxFrameDelta);

    EXPECT_EQ(expected_clamped_steps, large_delta_steps);
    EXPECT_EQ(clamped_delta_steps, large_delta_steps);
    ExpectSecondsNear(large_delta_scheduler.accumulator(), clamped_delta_scheduler.accumulator());
}

TEST(FixedStepScheduler, IgnoresZeroNegativeAndNonFiniteFrameDeltas) {
    FixedStepScheduler scheduler;

    EXPECT_EQ(std::size_t{0}, scheduler.Advance(SecondsF{0.0F}));
    EXPECT_EQ(std::size_t{0}, scheduler.Advance(SecondsF{-1.0F}));
    EXPECT_EQ(std::size_t{0}, scheduler.Advance(SecondsF{std::numeric_limits<float>::infinity()}));
    EXPECT_EQ(std::size_t{0}, scheduler.Advance(SecondsF{-std::numeric_limits<float>::infinity()}));
    EXPECT_EQ(std::size_t{0}, scheduler.Advance(SecondsF{std::numeric_limits<float>::quiet_NaN()}));

    ExpectSecondsNear(scheduler.accumulator(), SecondsF::zero());
}

TEST(FixedStepScheduler, SchedulesOneFixedStepAfterOneFixedDelta) {
    FixedStepScheduler scheduler;

    EXPECT_EQ(std::size_t{1}, scheduler.Advance(kFixedTimeStep));
    ExpectSecondsNear(scheduler.accumulator(), SecondsF::zero());
}

TEST(FixedStepScheduler, SchedulesMultipleFixedStepsAfterAccumulatedTime) {
    FixedStepScheduler scheduler;

    EXPECT_EQ(std::size_t{0}, scheduler.Advance(kFixedTimeStep * 0.5F));
    EXPECT_EQ(std::size_t{2}, scheduler.Advance(kFixedTimeStep * 1.5F));
    ExpectSecondsNear(scheduler.accumulator(), SecondsF::zero());
}

TEST(FixedStepScheduler, PreservesLeftoverAccumulatorTime) {
    FixedStepScheduler scheduler;
    const SecondsF leftover = kFixedTimeStep * 0.25F;

    EXPECT_EQ(std::size_t{1}, scheduler.Advance(kFixedTimeStep + leftover));
    ExpectSecondsNear(scheduler.accumulator(), leftover);

    EXPECT_EQ(std::size_t{0}, scheduler.Advance(SecondsF::zero()));
    ExpectSecondsNear(scheduler.accumulator(), leftover);

    EXPECT_EQ(std::size_t{1}, scheduler.Advance(kFixedTimeStep - leftover));
    ExpectSecondsNear(scheduler.accumulator(), SecondsF::zero());
}

} // namespace
