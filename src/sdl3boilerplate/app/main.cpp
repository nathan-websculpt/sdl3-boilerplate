#include <SDL3/SDL_main.h>

#include "sdl3boilerplate/app/platform.hpp"

int main(int argc, char* argv[]) {
    (void)argc;
    (void)argv;

    return sdl3boilerplate::app::RunApplication();
}
