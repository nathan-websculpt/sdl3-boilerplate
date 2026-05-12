#include "sdl3boilerplate/render/renderer.hpp"

#include <SDL3/SDL_rect.h>
#include <SDL3/SDL_render.h>
#include <stdexcept>

#include "sdl3boilerplate/foundation/config.hpp"

namespace sdl3boilerplate::render {

Renderer::Renderer(SDL_Renderer* renderer) : renderer_(renderer) {
    if (renderer_ == nullptr) {
        throw std::invalid_argument("render::Renderer requires a non-null SDL_Renderer");
    }
}

bool Renderer::Render(const sim::GameState& state) const {
    if (!SetDrawColor(foundation::kBackgroundColor)) {
        return false;
    }

    if (!SDL_RenderClear(renderer_)) {
        return false;
    }

    if (!SetDrawColor(foundation::kPlayerColor)) {
        return false;
    }

    const float half_player_size = foundation::kPlayerSize * 0.5F;
    const SDL_FRect player_rect{
        state.player_position.x - half_player_size,
        state.player_position.y - half_player_size,
        foundation::kPlayerSize,
        foundation::kPlayerSize,
    };

    if (!SDL_RenderFillRect(renderer_, &player_rect)) {
        return false;
    }

    return SDL_RenderPresent(renderer_);
}

bool Renderer::SetDrawColor(foundation::Color color) const {
    return SDL_SetRenderDrawColor(renderer_, color.r, color.g, color.b, color.a);
}

} // namespace sdl3boilerplate::render
