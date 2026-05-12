#include <cmath>
#include <gtest/gtest.h>
#include <limits>

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

sdl3boilerplate::foundation::Vec2 CenterPosition() {
    return sdl3boilerplate::foundation::Vec2{
        static_cast<float>(sdl3boilerplate::foundation::kWindowWidth) * 0.5F,
        static_cast<float>(sdl3boilerplate::foundation::kWindowHeight) * 0.5F,
    };
}

TEST(GameMovement, PlayerStartsCentered) {
    const sdl3boilerplate::sim::Game game;
    const sdl3boilerplate::foundation::Vec2 center = CenterPosition();

    ExpectPositionNear(game.state().player_position, center.x, center.y);
}

TEST(GameMovement, NoInputPreservesPosition) {
    sdl3boilerplate::sim::Game game;
    const sdl3boilerplate::foundation::Vec2 center = CenterPosition();

    game.Update(sdl3boilerplate::sim::GameInput{}, sdl3boilerplate::foundation::SecondsF{1.0F});

    ExpectPositionNear(game.state().player_position, center.x, center.y);
}

TEST(GameMovement, WasdLikeCommandsMoveExpectedAxes) {
    sdl3boilerplate::sim::Game game;
    const sdl3boilerplate::foundation::Vec2 center = CenterPosition();

    game.Update(sdl3boilerplate::sim::GameInput{.move_up = true, .move_left = true},
                sdl3boilerplate::foundation::SecondsF{0.0F});
    ExpectPositionNear(game.state().player_position, center.x, center.y);

    game.Update(sdl3boilerplate::sim::GameInput{.move_right = true},
                sdl3boilerplate::foundation::SecondsF{1.0F});
    ExpectPositionNear(game.state().player_position,
                       center.x + sdl3boilerplate::foundation::kPlayerSpeedPixelsPerSecond,
                       center.y);

    game.Update(sdl3boilerplate::sim::GameInput{.move_up = true},
                sdl3boilerplate::foundation::SecondsF{1.0F});
    ExpectPositionNear(game.state().player_position,
                       center.x + sdl3boilerplate::foundation::kPlayerSpeedPixelsPerSecond,
                       center.y - sdl3boilerplate::foundation::kPlayerSpeedPixelsPerSecond);
}

TEST(GameMovement, DiagonalMovementIsNormalized) {
    sdl3boilerplate::sim::Game game;
    const sdl3boilerplate::foundation::Vec2 center = CenterPosition();
    const float expected_delta =
        sdl3boilerplate::foundation::kPlayerSpeedPixelsPerSecond / std::sqrt(2.0F);

    game.Update(sdl3boilerplate::sim::GameInput{.move_down = true, .move_right = true},
                sdl3boilerplate::foundation::SecondsF{1.0F});

    ExpectPositionNear(game.state().player_position, center.x + expected_delta,
                       center.y + expected_delta);
}

TEST(GameMovement, InvalidDeltaDoesNotMovePlayer) {
    sdl3boilerplate::sim::Game game;
    const sdl3boilerplate::foundation::Vec2 center = CenterPosition();
    const sdl3boilerplate::sim::GameInput input{.move_right = true};

    game.Update(input, sdl3boilerplate::foundation::SecondsF{-1.0F});
    game.Update(input, sdl3boilerplate::foundation::SecondsF{0.0F});
    game.Update(input,
                sdl3boilerplate::foundation::SecondsF{std::numeric_limits<float>::infinity()});
    game.Update(input,
                sdl3boilerplate::foundation::SecondsF{std::numeric_limits<float>::quiet_NaN()});

    ExpectPositionNear(game.state().player_position, center.x, center.y);
}

} // namespace
