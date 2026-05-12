#include <gtest/gtest.h>
#include <stdexcept>

#include "sdl3boilerplate/render/renderer.hpp"

TEST(Renderer, NullRendererPointerThrowsInvalidArgument) {
    EXPECT_THROW((void)sdl3boilerplate::render::Renderer(nullptr), std::invalid_argument);
}
