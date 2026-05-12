#include "sdl3boilerplate/app/platform.hpp"

#include <SDL3/SDL.h>
#include <cstddef>
#include <stdexcept>
#include <string>

#include "sdl3boilerplate/foundation/config.hpp"
#include "sdl3boilerplate/foundation/fixed_step_scheduler.hpp"
#include "sdl3boilerplate/foundation/time.hpp"
#include "sdl3boilerplate/input/input_translator.hpp"
#include "sdl3boilerplate/render/renderer.hpp"
#include "sdl3boilerplate/sim/game.hpp"
#include "sdl3boilerplate/sim/game_input.hpp"

namespace sdl3boilerplate::app {
namespace {

std::string MakeSdlErrorMessage(const char* operation) {
    return std::string(operation) + " failed: " + SDL_GetError();
}

class SdlRuntime {
  public:
    SdlRuntime() {
        if (!SDL_Init(SDL_INIT_VIDEO)) {
            const std::string error_message = MakeSdlErrorMessage("SDL_Init");
            SDL_Quit();
            throw std::runtime_error(error_message);
        }
    }

    ~SdlRuntime() {
        SDL_Quit();
    }

    SdlRuntime(const SdlRuntime&) = delete;
    SdlRuntime& operator=(const SdlRuntime&) = delete;
};

class Window {
  public:
    Window()
        : window_(SDL_CreateWindow(foundation::kApplicationTitle, foundation::kWindowWidth,
                                   foundation::kWindowHeight, 0)) {
        if (window_ == nullptr) {
            throw std::runtime_error(MakeSdlErrorMessage("SDL_CreateWindow"));
        }
    }

    ~Window() {
        if (window_ != nullptr) {
            SDL_DestroyWindow(window_);
        }
    }

    Window(const Window&) = delete;
    Window& operator=(const Window&) = delete;

    SDL_Window* get() const {
        return window_;
    }

  private:
    SDL_Window* window_;
};

class RendererHandle {
  public:
    explicit RendererHandle(SDL_Window* window) : renderer_(SDL_CreateRenderer(window, nullptr)) {
        if (renderer_ == nullptr) {
            throw std::runtime_error(MakeSdlErrorMessage("SDL_CreateRenderer"));
        }

        if (!SDL_SetRenderVSync(renderer_, 1)) {
            const std::string error_message = MakeSdlErrorMessage("SDL_SetRenderVSync");
            SDL_DestroyRenderer(renderer_);
            renderer_ = nullptr;
            throw std::runtime_error(error_message);
        }
    }

    ~RendererHandle() {
        if (renderer_ != nullptr) {
            SDL_DestroyRenderer(renderer_);
        }
    }

    RendererHandle(const RendererHandle&) = delete;
    RendererHandle& operator=(const RendererHandle&) = delete;

    SDL_Renderer* get() const {
        return renderer_;
    }

  private:
    SDL_Renderer* renderer_;
};

sim::GameInput ToGameInput(const input::InputState& state) {
    return sim::GameInput{
        .move_up = state.move_up,
        .move_down = state.move_down,
        .move_left = state.move_left,
        .move_right = state.move_right,
    };
}

} // namespace

int RunApplication() {
    try {
        const SdlRuntime sdl_runtime;
        const Window window;
        const RendererHandle renderer_handle(window.get());
        const render::Renderer renderer(renderer_handle.get());

        sim::Game game;
        input::InputTranslator input_translator;

        auto previous_time = foundation::Clock::now();
        foundation::FixedStepScheduler fixed_step_scheduler;

        bool running = true;
        while (running) {
            SDL_Event event;
            while (SDL_PollEvent(&event)) {
                input_translator.HandleEvent(event);
            }

            const input::InputState& input_state = input_translator.state();
            if (input_state.quit_requested) {
                running = false;
                continue;
            }

            const auto current_time = foundation::Clock::now();
            const foundation::SecondsF frame_delta = current_time - previous_time;
            previous_time = current_time;

            const sim::GameInput game_input = ToGameInput(input_state);
            const std::size_t fixed_step_count = fixed_step_scheduler.Advance(frame_delta);
            for (std::size_t step_index = 0; step_index < fixed_step_count; ++step_index) {
                game.Update(game_input, foundation::kFixedTimeStep);
            }

            if (!renderer.Render(game.state())) {
                SDL_LogError(SDL_LOG_CATEGORY_RENDER, "Render failed: %s", SDL_GetError());
                return 1;
            }
        }

        return 0;
    } catch (const std::exception& exception) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s", exception.what());
        return 1;
    }
}

} // namespace sdl3boilerplate::app
