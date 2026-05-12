#include "sdl3boilerplate/sim/game.hpp"

#include "sdl3boilerplate/foundation/config.hpp"
#include "sdl3boilerplate/foundation/math.hpp"

namespace sdl3boilerplate::sim {

namespace {

foundation::Vec2 InitialPlayerPosition() {
    return foundation::Vec2{
        static_cast<float>(foundation::kWindowWidth) * 0.5F,
        static_cast<float>(foundation::kWindowHeight) * 0.5F,
    };
}

} // namespace

Game::Game() : player_(InitialPlayerPosition()) {
    SyncState();
}

void Game::Update(const GameInput& input, foundation::SecondsF delta_time) {
    player_.Update(input, delta_time.count());
    SyncState();
}

const GameState& Game::state() const {
    return state_;
}

void Game::SyncState() {
    state_.player_position = player_.position();
}

} // namespace sdl3boilerplate::sim
