param(
    [ValidateSet("Debug", "Release")]
    [string]$Config = "Debug",

    [switch]$Clean,

    [switch]$SkipConfigure,

    [switch]$NoRun,

    [string]$VcpkgRoot
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Fail([string]$Message) {
    throw $Message
}

. "$PSScriptRoot/common.ps1"

$repoRoot = Resolve-RepoRoot -WindowsToolsRoot $PSScriptRoot
$callerState = Save-CallerState
$exitCode = 0

function Find-BoilerplateExecutable([string]$BuildDir, [string]$Configuration) {
    $expectedPath = Join-Path (Join-Path $BuildDir $Configuration) "sdl3boilerplate.exe"
    if (Test-Path -LiteralPath $expectedPath -PathType Leaf) {
        return (Resolve-Path -LiteralPath $expectedPath).Path
    }

    $candidate = Get-ChildItem -LiteralPath $BuildDir -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq "sdl3boilerplate.exe" } |
        Where-Object { $_.FullName -like "*\$Configuration\*" } |
        Sort-Object -Property LastWriteTime -Descending |
        Select-Object -First 1
    if ($candidate) {
        return $candidate.FullName
    }

    Fail "Could not locate $Configuration build output for sdl3boilerplate.exe under '$BuildDir'."
}

try {
    Normalize-WindowsProcessEnvironment

    $resolvedVcpkgRoot = Resolve-VcpkgRoot -RequestedRoot $VcpkgRoot -WriteStatus -PassThru
    $toolchainFile = Get-VcpkgToolchainFile -VcpkgRoot $resolvedVcpkgRoot

    Require-Command -Name "cmake" -CommandType Application | Out-Null
    Assert-RequiredRepoFiles -RepoRoot $repoRoot -RelativePaths @(
        "CMakeLists.txt",
        "CMakePresets.json",
        "vcpkg.json",
        "src/sdl3boilerplate/app/main.cpp"
    )
    Assert-BoilerplatePresetContract -RepoRoot $repoRoot -VcpkgRoot $resolvedVcpkgRoot | Out-Null

    Assert-CleanSkipConfigureCompatible -Clean:$Clean -SkipConfigure:$SkipConfigure

    Set-Location -LiteralPath $repoRoot

    $buildDir = Get-WindowsBuildDir -RepoRoot $repoRoot
    if ($Clean) {
        Clear-KnownBuildDirectory -BuildDir $buildDir -RepoRoot $repoRoot -Label "build"
    } else {
        Assert-CachedBuildDirectoryMatches -BuildDir $buildDir -ToolchainFile $toolchainFile
    }

    Assert-SkipConfigureCacheExists -SkipConfigure:$SkipConfigure -BuildDir $buildDir -PresetName "windows-vcpkg" -ScriptName "build.ps1"
    Invoke-CMakeConfigureUnlessSkipped -SkipConfigure:$SkipConfigure -Preset "windows-vcpkg"

    $buildPreset = if ($Config -eq "Release") { "windows-release" } else { "windows-debug" }
    Invoke-CMakeBuildPreset -Preset $buildPreset -Target "sdl3boilerplate"

    $exePath = Find-BoilerplateExecutable -BuildDir $buildDir -Configuration $Config
    if ($NoRun) {
        Write-Host "Run disabled; skipping game launch."
    } elseif ($Config -eq "Debug") {
        Write-Host "Launching game: $exePath"
        & $exePath
        $gameExitCode = $LASTEXITCODE
        if ($null -eq $gameExitCode) {
            $gameExitCode = 0
        }
        if ($gameExitCode -ne 0) {
            $exitCode = $gameExitCode
        }
    } else {
        Write-Host "Release build completed; skipping auto-launch."
    }
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    $exitCode = 1
} finally {
    Restore-CallerState -State $callerState
}

exit $exitCode
