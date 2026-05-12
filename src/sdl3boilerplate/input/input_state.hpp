#ifndef SDL3BOILERPLATE_INPUT_INPUT_STATE_HPP
#define SDL3BOILERPLATE_INPUT_INPUT_STATE_HPP

namespace sdl3boilerplate::input {

struct InputState {
    bool move_up = false;
    bool move_down = false;
    bool move_left = false;
    bool move_right = false;
    bool quit_requested = false;
};

} // namespace sdl3boilerplate::input

#endif // SDL3BOILERPLATE_INPUT_INPUT_STATE_HPP
