#ifndef SDL3BOILERPLATE_SIM_GAME_STATE_HPP
#define SDL3BOILERPLATE_SIM_GAME_STATE_HPP

#include "sdl3boilerplate/foundation/math.hpp"

namespace sdl3boilerplate::sim {

struct GameState {
    foundation::Vec2 player_position{0.0F, 0.0F};
};

} // namespace sdl3boilerplate::sim

#endif // SDL3BOILERPLATE_SIM_GAME_STATE_HPP
