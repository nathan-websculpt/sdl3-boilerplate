# Using this as a Boilerplate

This repository is meant to be cloned, renamed, and then shaped into a new SDL3/C++ game.

## Rename Surface

Start by searching for every boilerplate identifier and deciding which ones belong to the new game:

```powershell
rg -n "sdl3boilerplate|sdl3_boilerplate|sdl3-boilerplate|SDL3BOILERPLATE|SDL3 Boilerplate|Sdl3Boilerplate|Boilerplate" .
```

The usual rename targets are:

- `SDL3 Boilerplate`: user-facing application name, README title, and `kApplicationTitle`.
- `sdl3_boilerplate`: CMake project name.
- `sdl3-boilerplate`: vcpkg manifest package name.
- `sdl3boilerplate`: CMake target stem, `sdl3boilerplate.exe`, namespace stem, source tree name, and include prefix.
- `SDL3BOILERPLATE`: header include guard prefix and MSVC analyze option prefix.
- `Sdl3Boilerplate`: PowerShell helper/C# type stem in Windows tooling.

Concrete CMake names to update together:

- Executable target: `sdl3boilerplate`.
- Internal library targets: `sdl3boilerplate_foundation`, `sdl3boilerplate_sim`, `sdl3boilerplate_input`, and `sdl3boilerplate_sdl`.
- Test targets: `sdl3boilerplate_foundation_tests`, `sdl3boilerplate_sim_tests`, `sdl3boilerplate_input_tests`, `sdl3boilerplate_render_tests`, and aggregate target `sdl3boilerplate_tests`.
- Helper functions/options: `sdl3boilerplate_apply_diagnostics`, `sdl3boilerplate_apply_analysis`, and `SDL3BOILERPLATE_ENABLE_MSVC_ANALYZE`.

Likely files and paths to update:

- `CMakeLists.txt`: project name, target names, helper function names, explicit source paths, and analyze option.
- `CMakePresets.json`: analyze option cache variable. The `windows-vcpkg` preset names and `out/build-win-vcpkg*` directories can usually stay because they describe the workflow, not the game.
- `tools/windows/build.ps1`: executable name, target name, required source path, and helper names.
- `tools/windows/analyze.ps1`: app target name and helper names.
- `tools/windows/common.ps1`: preset-contract helper names, C# namespace/type stem, and project-specific diagnostics.
- `tools/windows/test.ps1`: aggregate test target name and helper names.
- `src/**` and `tests/**`: namespace, include prefix, source root path, include guards, and demo type names.

Keep production and test source lists explicit in `CMakeLists.txt`; update paths manually after moving files.

## Replace the Demo

The boilerplate app is a moving-square demo. These areas are expected to be replaced or heavily edited:

- `src/sdl3boilerplate/sim/player.*`: square/player movement rules, bounds, speed, and size.
- `src/sdl3boilerplate/sim/game.*`, `game_input.hpp`, and `game_state.hpp`: demo state model, commands, and update rules.
- `src/sdl3boilerplate/input/input_state.hpp` and `input_translator.*`: WASD/arrow command mapping and quit behavior once the new game needs different controls.
- `src/sdl3boilerplate/render/renderer.*`: dark background and white-square drawing.
- `src/sdl3boilerplate/foundation/config.hpp`: app title, window size, demo colors, player size, and speed constants.
- Demo-specific tests under `tests/sim/`, movement-specific parts of `tests/input/`, and renderer tests that describe the old visual surface.

Keep tests for any behavior that remains.

## Architecture Contract

Preserve these boundaries while customizing:

- `sim` owns authoritative gameplay state and update rules. It must not include SDL headers, use SDL types, or depend on SDL event names.
- `input` is the SDL boundary for controls. It translates platform events into plain command/state types.
- `app` owns SDL lifetime, platform resources, the main loop, and the fixed-step scheduler.
- `render` observes simulation state. It should not mutate gameplay state or become the source of truth.
- The outer frame can render at variable cadence, but simulation advances through fixed 60 Hz steps from `kFixedTimeStep`.
- State ownership should stay explicit: avoid global mutable renderer/game state and raw owning pointers.

This separation lets the new game grow without turning rendering, input, and simulation into one coupled loop.

## Post-Rename Validation

After renaming and replacing the demo, run the standard Windows workflow from the repo root:

```powershell
.\tools\windows\build.ps1 -Config Debug -Clean -NoRun
.\tools\windows\test.ps1 -Config Debug
.\tools\windows\analyze.ps1 -Clean
.\tools\windows\format.ps1
```

If `VCPKG_ROOT` is not set, pass `-VcpkgRoot "C:\path\to\vcpkg"` to the build, test, and analyze scripts.

