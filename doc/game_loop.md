# Game Loop

Uses `std::chrono::steady_clock` and a fixed-step accumulator.

Each outer frame:

1. Poll SDL events and update input state.
2. Measure elapsed time with `steady_clock`.
3. Clamp large deltas to avoid runaway simulation after stalls or debugger breaks.
4. Run zero or more fixed simulation updates at 60 Hz.
5. Render once using the latest simulation state.

Raw frame delta is not the authoritative simulation timestep. This keeps gameplay behavior stable across different frame rates and transient stalls.
