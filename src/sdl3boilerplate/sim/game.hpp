#ifndef SDL3BOILERPLATE_SIM_GAME_HPP
#define SDL3BOILERPLATE_SIM_GAME_HPP

#include "sdl3boilerplate/foundation/time.hpp"
#include "sdl3boilerplate/sim/game_input.hpp"
#include "sdl3boilerplate/sim/game_state.hpp"
#include "sdl3boilerplate/sim/player.hpp"

namespace sdl3boilerplate::sim {

class Game {
  public:
    Game();

    Game(const Game&) = delete;
    Game& operator=(const Game&) = delete;
    Game(Game&&) = delete;
    Game& operator=(Game&&) = delete;

    void Update(const GameInput& input, foundation::SecondsF delta_time);

    [[nodiscard]] const GameState& state() const;

  private:
    void SyncState();

    Player player_;
    GameState state_;
};

} // namespace sdl3boilerplate::sim

#endif // SDL3BOILERPLATE_SIM_GAME_HPP
