# Architecture

This project is a reusable SDL3 game foundation. The first app renders a single moving square, but the code is split around boundaries that can survive larger games.

## Layers

- `foundation` contains shared constants, math helpers, and chrono types.
- `input` translates SDL events into command-style input state.
- `sim` owns authoritative gameplay state and update rules.
- `render` observes simulation state and draws it through SDL.
- `app` owns SDL lifetime, platform resources, and the main loop.

## Simulation Boundary

Simulation must stay SDL-free. No SDL includes, SDL types, SDL constants, or SDL event names belong under `src/sdl3boilerplate/sim/`.

Input is translated before simulation consumes it. Rendering receives const simulation state and does not own or mutate gameplay state.

## Ownership

SDL lifetime, windows, and renderers are wrapped in non-copyable RAII objects. The code does not use raw owning pointers, `new`, `delete`, or global mutable renderer state.
