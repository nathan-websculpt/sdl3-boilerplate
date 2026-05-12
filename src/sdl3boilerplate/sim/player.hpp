#ifndef SDL3BOILERPLATE_SIM_PLAYER_HPP
#define SDL3BOILERPLATE_SIM_PLAYER_HPP

#include "sdl3boilerplate/foundation/math.hpp"
#include "sdl3boilerplate/sim/game_input.hpp"

namespace sdl3boilerplate::sim {

class Player {
  public:
    explicit Player(foundation::Vec2 initial_position);

    void Update(const GameInput& input, float delta_seconds);

    [[nodiscard]] foundation::Vec2 position() const;

  private:
    foundation::Vec2 position_;
};

} // namespace sdl3boilerplate::sim

#endif // SDL3BOILERPLATE_SIM_PLAYER_HPP
