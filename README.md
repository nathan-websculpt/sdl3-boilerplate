# SDL3 Boilerplate

Reusable SDL3 C++20 game foundation code for Windows-first development. The first visible app is intentionally small: it opens a 960x720 window, clears to a dark background, draws a centered white square, moves with WASD or arrow keys, and exits with Escape or the window close button.

The small app sits on production-oriented structure: SDL resources are RAII-owned, simulation is SDL-free, rendering observes simulation state, and timing uses a fixed-step `std::chrono::steady_clock` loop.

## Requirements

- CMake 4.2 or newer for the documented Windows preset workflow. The project CMake floor is 3.25 for manual configurations with a generator supported by that CMake version.
- Visual Studio with the C++ workload. The Windows presets use generator `Visual Studio 18 2026`.
- vcpkg with `VCPKG_ROOT` set, or pass `-VcpkgRoot "C:\path\to\vcpkg"` to the Windows scripts.

Runtime dependency:

- SDL3 only.

Development/test dependency:

- GoogleTest.

## Workflow

The Windows helpers are the normal day-to-day entry points. They run from the repo root, use vcpkg manifest mode, keep generated output under `out/`, and restore the caller's working directory and previous `VCPKG_ROOT` when they exit.

Standard quick workflow:

```powershell
$env:VCPKG_ROOT = "C:\path\to\vcpkg"
.\tools\windows\build.ps1 -Config Debug -NoRun
.\tools\windows\test.ps1 -Config Debug
.\tools\windows\analyze.ps1
.\tools\windows\format.ps1
```

Build Debug without running:

```powershell
.\tools\windows\build.ps1 -Config Debug -NoRun
```

Build and run Debug:

```powershell
.\tools\windows\build.ps1
```

Build Release. Release builds never auto-launch:

```powershell
.\tools\windows\build.ps1 -Config Release
```

Run tests:

```powershell
.\tools\windows\test.ps1 -Config Debug
.\tools\windows\test.ps1 -Config Release
.\tools\windows\test.ps1 -Config Debug -TestFilter FixedStep
```

Run MSVC analysis:

```powershell
.\tools\windows\analyze.ps1
```

Format project-owned C/C++ files:

```powershell
.\tools\windows\format.ps1
```

The normal Windows build tree is `out/build-win-vcpkg`; the analyze lane uses `out/build-win-vcpkg-analyze`. Build, test, and analyze scripts support `-Clean` and `-SkipConfigure`, and those flags cannot be combined. `-Clean` removes only the known lane build directory after safety checks. `-SkipConfigure` reuses an existing configured tree and requires the expected `CMakeCache.txt`.

`build.ps1` builds target `sdl3boilerplate`, defaults to Debug, launches Debug unless `-NoRun` is supplied, and propagates a nonzero app exit code. `test.ps1` builds target `sdl3boilerplate_tests`, runs the matching CTest preset with output on failure and no-tests-as-error behavior, and maps `-TestFilter` to CTest `-R`. `analyze.ps1` builds only `sdl3boilerplate` in the Debug analyze lane, does not run tests, and reports compiler/static-analysis diagnostics as informational unless configure or build fails.

This foundation intentionally has no release gate, packaging, install, dist, asset, audio, texture, or font tooling.

## Starting A New Game From This Boilerplate

Use [Using This As A Boilerplate](doc/using_as_boilerplate.md) after cloning to rename the project, replace the moving-square demo, and preserve the SDL boundary, fixed-step simulation, explicit state ownership, and render-observes-simulation design.

## Manual Preset Use

Manual build:

```powershell
$env:VCPKG_ROOT = "C:\path\to\vcpkg"
cmake --preset windows-vcpkg
cmake --build --preset windows-debug --target sdl3boilerplate
.\out\build-win-vcpkg\Debug\sdl3boilerplate.exe
```

Manual tests:

```powershell
cmake --build --preset windows-debug --target sdl3boilerplate_tests
ctest --preset windows-debug-tests --output-on-failure --no-tests=error
```

Manual analyze:

```powershell
cmake --preset windows-vcpkg-analyze
cmake --build --preset windows-debug-analyze --target sdl3boilerplate
```

## Structure

- `app`: SDL lifetime, platform loop, window and renderer ownership.
- `foundation`: shared config, math, and time constants.
- `input`: SDL event translation into SDL-free command state.
- `sim`: authoritative game state and movement rules. This layer has no SDL dependency.
- `render`: SDL renderer drawing code that observes simulation state.
- `tests`: GoogleTest coverage for foundation, input translation, simulation, and rendering boundaries.
- `tools/windows`: Windows build, test, analyze, and format entry points.
- `doc`: architecture, development, game loop, and boilerplate customization notes.
