#ifndef SDL3BOILERPLATE_INPUT_INPUT_TRANSLATOR_HPP
#define SDL3BOILERPLATE_INPUT_INPUT_TRANSLATOR_HPP

#include <SDL3/SDL_events.h>
#include <SDL3/SDL_scancode.h>

#include "sdl3boilerplate/input/input_state.hpp"

namespace sdl3boilerplate::input {

class InputTranslator {
  public:
    void HandleEvent(const SDL_Event& event);

    [[nodiscard]] const InputState& state() const;

  private:
    void SetKey(SDL_Scancode scancode, bool pressed);
    void RefreshMovementState();

    bool w_pressed_ = false;
    bool a_pressed_ = false;
    bool s_pressed_ = false;
    bool d_pressed_ = false;
    bool up_pressed_ = false;
    bool down_pressed_ = false;
    bool left_pressed_ = false;
    bool right_pressed_ = false;

    InputState state_;
};

} // namespace sdl3boilerplate::input

#endif // SDL3BOILERPLATE_INPUT_INPUT_TRANSLATOR_HPP
