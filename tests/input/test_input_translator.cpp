#include <SDL3/SDL_events.h>
#include <SDL3/SDL_scancode.h>
#include <gtest/gtest.h>

#include "sdl3boilerplate/input/input_translator.hpp"

namespace {

SDL_Event KeyEvent(SDL_EventType type, SDL_Scancode scancode) {
    SDL_Event event{};
    event.type = type;
    event.key.scancode = scancode;
    return event;
}

TEST(InputTranslator, QuitEventRequestsQuit) {
    sdl3boilerplate::input::InputTranslator translator;

    SDL_Event event{};
    event.type = SDL_EVENT_QUIT;
    translator.HandleEvent(event);

    EXPECT_TRUE(translator.state().quit_requested);
}

TEST(InputTranslator, EscapeKeyDownRequestsQuit) {
    sdl3boilerplate::input::InputTranslator translator;

    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_DOWN, SDL_SCANCODE_ESCAPE));

    EXPECT_TRUE(translator.state().quit_requested);
}

TEST(InputTranslator, WasdMovementTracksKeyDownAndUp) {
    sdl3boilerplate::input::InputTranslator translator;

    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_DOWN, SDL_SCANCODE_W));
    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_DOWN, SDL_SCANCODE_A));
    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_DOWN, SDL_SCANCODE_S));
    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_DOWN, SDL_SCANCODE_D));

    EXPECT_TRUE(translator.state().move_up);
    EXPECT_TRUE(translator.state().move_left);
    EXPECT_TRUE(translator.state().move_down);
    EXPECT_TRUE(translator.state().move_right);

    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_UP, SDL_SCANCODE_W));
    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_UP, SDL_SCANCODE_A));
    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_UP, SDL_SCANCODE_S));
    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_UP, SDL_SCANCODE_D));

    EXPECT_FALSE(translator.state().move_up);
    EXPECT_FALSE(translator.state().move_left);
    EXPECT_FALSE(translator.state().move_down);
    EXPECT_FALSE(translator.state().move_right);
}

TEST(InputTranslator, ArrowMovementTracksKeyDownAndUp) {
    sdl3boilerplate::input::InputTranslator translator;

    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_DOWN, SDL_SCANCODE_UP));
    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_DOWN, SDL_SCANCODE_LEFT));
    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_DOWN, SDL_SCANCODE_DOWN));
    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_DOWN, SDL_SCANCODE_RIGHT));

    EXPECT_TRUE(translator.state().move_up);
    EXPECT_TRUE(translator.state().move_left);
    EXPECT_TRUE(translator.state().move_down);
    EXPECT_TRUE(translator.state().move_right);

    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_UP, SDL_SCANCODE_UP));
    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_UP, SDL_SCANCODE_LEFT));
    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_UP, SDL_SCANCODE_DOWN));
    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_UP, SDL_SCANCODE_RIGHT));

    EXPECT_FALSE(translator.state().move_up);
    EXPECT_FALSE(translator.state().move_left);
    EXPECT_FALSE(translator.state().move_down);
    EXPECT_FALSE(translator.state().move_right);
}

TEST(InputTranslator, OverlappingBindingsStayActiveUntilAllBindingsRelease) {
    sdl3boilerplate::input::InputTranslator translator;

    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_DOWN, SDL_SCANCODE_W));
    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_DOWN, SDL_SCANCODE_UP));
    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_UP, SDL_SCANCODE_W));

    EXPECT_TRUE(translator.state().move_up);

    translator.HandleEvent(KeyEvent(SDL_EVENT_KEY_UP, SDL_SCANCODE_UP));

    EXPECT_FALSE(translator.state().move_up);
}

} // namespace
