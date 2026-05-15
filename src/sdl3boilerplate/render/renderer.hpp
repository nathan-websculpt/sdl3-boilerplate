#ifndef SDL3BOILERPLATE_RENDER_RENDERER_HPP
#define SDL3BOILERPLATE_RENDER_RENDERER_HPP

#include <SDL3/SDL_render.h>

#include "sdl3boilerplate/foundation/config.hpp"
#include "sdl3boilerplate/sim/game_state.hpp"

namespace sdl3boilerplate::render {

class Renderer {
public:
    explicit Renderer(SDL_Renderer* renderer);

    Renderer(const Renderer&) = delete;
    Renderer& operator=(const Renderer&) = delete;
    Renderer(Renderer&&) = delete;
    Renderer& operator=(Renderer&&) = delete;

    [[nodiscard]] bool Render(const sim::GameState& state) const;

private:
    [[nodiscard]] bool SetDrawColor(foundation::Color color) const;

    SDL_Renderer* renderer_;
};

} // namespace sdl3boilerplate::render

#endif // SDL3BOILERPLATE_RENDER_RENDERER_HPP
