#include "sdl3boilerplate/sim/player.hpp"

#include "sdl3boilerplate/foundation/config.hpp"

namespace sdl3boilerplate::sim {

namespace {

foundation::Vec2 MovementDirection(const GameInput& input) {
    foundation::Vec2 direction{0.0F, 0.0F};

    if (input.move_left) {
        direction.x -= 1.0F;
    }
    if (input.move_right) {
        direction.x += 1.0F;
    }
    if (input.move_up) {
        direction.y -= 1.0F;
    }
    if (input.move_down) {
        direction.y += 1.0F;
    }

    return foundation::NormalizeOrZero(direction);
}

foundation::Vec2 ClampToWindow(foundation::Vec2 position) {
    const float half_player_size = foundation::kPlayerSize * 0.5F;

    return foundation::Clamp(
        position, foundation::Vec2{half_player_size, half_player_size},
        foundation::Vec2{static_cast<float>(foundation::kWindowWidth) - half_player_size,
                         static_cast<float>(foundation::kWindowHeight) - half_player_size});
}

} // namespace

Player::Player(foundation::Vec2 initial_position) : position_(ClampToWindow(initial_position)) {}

void Player::Update(const GameInput& input, float delta_seconds) {
    if (delta_seconds <= 0.0F || !foundation::IsFinite(delta_seconds)) {
        return;
    }

    const foundation::Vec2 movement =
        MovementDirection(input) * (foundation::kPlayerSpeedPixelsPerSecond * delta_seconds);

    position_ = ClampToWindow(position_ + movement);
}

foundation::Vec2 Player::position() const {
    return position_;
}

} // namespace sdl3boilerplate::sim
