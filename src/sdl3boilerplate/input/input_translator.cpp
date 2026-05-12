#include "sdl3boilerplate/input/input_translator.hpp"

#include <SDL3/SDL_events.h>
#include <SDL3/SDL_scancode.h>

namespace sdl3boilerplate::input {

void InputTranslator::HandleEvent(const SDL_Event& event) {
    switch (event.type) {
    case SDL_EVENT_QUIT:
        state_.quit_requested = true;
        break;
    case SDL_EVENT_KEY_DOWN:
        SetKey(event.key.scancode, true);
        break;
    case SDL_EVENT_KEY_UP:
        SetKey(event.key.scancode, false);
        break;
    default:
        break;
    }
}

const InputState& InputTranslator::state() const {
    return state_;
}

void InputTranslator::SetKey(SDL_Scancode scancode, bool pressed) {
    switch (scancode) {
    case SDL_SCANCODE_W:
        w_pressed_ = pressed;
        break;
    case SDL_SCANCODE_A:
        a_pressed_ = pressed;
        break;
    case SDL_SCANCODE_S:
        s_pressed_ = pressed;
        break;
    case SDL_SCANCODE_D:
        d_pressed_ = pressed;
        break;
    case SDL_SCANCODE_UP:
        up_pressed_ = pressed;
        break;
    case SDL_SCANCODE_DOWN:
        down_pressed_ = pressed;
        break;
    case SDL_SCANCODE_LEFT:
        left_pressed_ = pressed;
        break;
    case SDL_SCANCODE_RIGHT:
        right_pressed_ = pressed;
        break;
    case SDL_SCANCODE_ESCAPE:
        if (pressed) {
            state_.quit_requested = true;
        }
        break;
    default:
        break;
    }

    RefreshMovementState();
}

void InputTranslator::RefreshMovementState() {
    state_.move_up = w_pressed_ || up_pressed_;
    state_.move_down = s_pressed_ || down_pressed_;
    state_.move_left = a_pressed_ || left_pressed_;
    state_.move_right = d_pressed_ || right_pressed_;
}

} // namespace sdl3boilerplate::input
