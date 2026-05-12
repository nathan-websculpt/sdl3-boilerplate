#include <gtest/gtest.h>

#include "sdl3boilerplate/foundation/time.hpp"

namespace {

TEST(TimeConstants, FixedStepRunsAtSixtyHertz) {
    EXPECT_EQ(60, sdl3boilerplate::foundation::kFixedUpdatesPerSecond);
    EXPECT_NEAR(1.0F / 60.0F, sdl3boilerplate::foundation::kFixedTimeStep.count(), 0.000001F);
}

TEST(TimeConstants, MaxFrameDeltaClampsLargeStalls) {
    EXPECT_NEAR(0.25F, sdl3boilerplate::foundation::kMaxFrameDelta.count(), 0.000001F);
}

} // namespace
