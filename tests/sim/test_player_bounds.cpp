#include <gtest/gtest.h>

#include "sdl3boilerplate/foundation/config.hpp"
#include "sdl3boilerplate/foundation/time.hpp"
#include "sdl3boilerplate/sim/game.hpp"
#include "sdl3boilerplate/sim/game_input.hpp"

namespace {

constexpr float kTolerance = 0.001F;

void ExpectPositionNear(sdl3boilerplate::foundation::Vec2 actual, float expected_x,
                        float expected_y) {
    EXPECT_NEAR(expected_x, actual.x, kTolerance);
    EXPECT_NEAR(expected_y, actual.y, kTolerance);
}

TEST(PlayerBounds, ClampsToTopLeftVisibleBounds) {
    sdl3boilerplate::sim::Game game;
    const float half_player_size = sdl3boilerplate::foundation::kPlayerSize * 0.5F;

    game.Update(sdl3boilerplate::sim::GameInput{.move_up = true, .move_left = true},
                sdl3boilerplate::foundation::SecondsF{10.0F});

    ExpectPositionNear(game.state().player_position, half_player_size, half_player_size);
}

TEST(PlayerBounds, ClampsToBottomRightVisibleBounds) {
    sdl3boilerplate::sim::Game game;
    const float half_player_size = sdl3boilerplate::foundation::kPlayerSize * 0.5F;

    game.Update(sdl3boilerplate::sim::GameInput{.move_down = true, .move_right = true},
                sdl3boilerplate::foundation::SecondsF{10.0F});

    ExpectPositionNear(
        game.state().player_position,
        static_cast<float>(sdl3boilerplate::foundation::kWindowWidth) - half_player_size,
        static_cast<float>(sdl3boilerplate::foundation::kWindowHeight) - half_player_size);
}

} // namespace
