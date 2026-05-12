# Development And Validation

The canonical Windows workflow is preset-first through vcpkg manifest mode. Use the PowerShell helpers in `tools/windows/` for day-to-day work; they validate the preset/vcpkg contract, run from the repo root, keep generated output under `out/`, and restore the caller's working directory and previous `VCPKG_ROOT` when they exit.

## Requirements

- Windows PowerShell
- Visual Studio with MSVC; presets use generator `Visual Studio 18 2026`
- CMake 4.2 or newer for the documented preset workflow
- vcpkg, set with `VCPKG_ROOT` or passed as `-VcpkgRoot "C:\path\to\vcpkg"`

If PowerShell blocks scripts in a local shell:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

## Presets And Output

The main configure preset is `windows-vcpkg`. It writes to `out/build-win-vcpkg`, uses x64 architecture, `VCPKG_TARGET_TRIPLET=x64-windows`, `VCPKG_MANIFEST_MODE=ON`, and the preset-level toolchain file `$env{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake`.

The analyze configure preset is `windows-vcpkg-analyze`. It inherits the main preset, writes to `out/build-win-vcpkg-analyze`, and enables `SDL3BOILERPLATE_ENABLE_MSVC_ANALYZE=ON`.

Build presets:

- `windows-debug`
- `windows-release`
- `windows-debug-analyze`

CTest presets:

- `windows-debug-tests`
- `windows-release-tests`

The CTest presets enable output on failure and fail when no tests are discovered.

## Windows Scripts

Common commands:

```powershell
.\tools\windows\build.ps1 -Config Debug -NoRun
.\tools\windows\build.ps1
.\tools\windows\test.ps1 -Config Debug
.\tools\windows\analyze.ps1
.\tools\windows\format.ps1
```

`build.ps1` supports `-Config Debug|Release`, `-Clean`, `-SkipConfigure`, `-NoRun`, and `-VcpkgRoot <path>`. Debug builds auto-launch `sdl3boilerplate.exe` unless `-NoRun` is supplied and propagate a nonzero app exit code. Release builds use `windows-release` and never auto-launch.

`test.ps1` supports `-Config Debug|Release`, `-Clean`, `-SkipConfigure`, `-TestFilter <regex>`, and `-VcpkgRoot <path>`. It builds the aggregate `sdl3boilerplate_tests` target with the matching build preset, then runs the matching CTest preset with `--output-on-failure` and `--no-tests=error`. `-TestFilter` maps to CTest `-R`.

`analyze.ps1` supports `-Clean`, `-SkipConfigure`, and `-VcpkgRoot <path>`. It is Debug-only, uses `windows-vcpkg-analyze`, builds only `sdl3boilerplate`, does not run CTest, and prints an `Analyze summary`. Compiler and static-analysis diagnostics are informational unless configure or build fails.

`format.ps1` has no parameters. It runs `clang-format -i` on project-owned C/C++ source, header, and module-like files while excluding generated output, build trees, third-party, and external directories.

`-Clean` removes only the known lane build directory after repo-root and output-root safety validation. `-SkipConfigure` reuses an existing configured tree and requires the expected `CMakeCache.txt`. `-Clean` and `-SkipConfigure` fail when combined. Existing cached trees are checked against the active vcpkg toolchain path, generator, platform, and triplet.

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

## Visual Studio

1. Install Visual Studio with the Desktop development with C++ workload.
2. Ensure `VCPKG_ROOT` is set.
3. Open the repository root folder.
4. Select configure preset `windows-vcpkg`.
5. Build `sdl3boilerplate` or `sdl3boilerplate_tests` with `windows-debug` or `windows-release`.
6. If prompted about a toolchain/cache/platform mismatch, delete/regenerate cache or rerun the relevant script with `-Clean`.

## Source Rules

Headers use `.hpp` and traditional include guards. In `.hpp` files, includes are grouped as standard library, third-party, then project headers. In `.cpp` files, include the matching project header first when one exists, then group the remaining includes as standard library, third-party, then project headers.

Production and test sources are listed explicitly in `CMakeLists.txt`; do not add source globbing. `src/sdl3boilerplate/sim/` stays SDL-free. Runtime dependency is SDL3 only, and GoogleTest is for tests.

This foundation intentionally has no release gate and no release, packaging, install, dist, asset, audio, texture, or font tooling.
