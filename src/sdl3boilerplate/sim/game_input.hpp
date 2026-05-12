#ifndef SDL3BOILERPLATE_SIM_GAME_INPUT_HPP
#define SDL3BOILERPLATE_SIM_GAME_INPUT_HPP

namespace sdl3boilerplate::sim {

struct GameInput {
    bool move_up = false;
    bool move_down = false;
    bool move_left = false;
    bool move_right = false;
};

} // namespace sdl3boilerplate::sim

#endif // SDL3BOILERPLATE_SIM_GAME_INPUT_HPP
