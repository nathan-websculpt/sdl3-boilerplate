param(
    [ValidateSet("Debug", "Release")]
    [string]$Config = "Debug",

    [switch]$Clean,

    [switch]$SkipConfigure,

    [string]$TestFilter,

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

try {
    Normalize-WindowsProcessEnvironment

    $resolvedVcpkgRoot = Resolve-VcpkgRoot -RequestedRoot $VcpkgRoot -WriteStatus -PassThru
    $toolchainFile = Get-VcpkgToolchainFile -VcpkgRoot $resolvedVcpkgRoot

    Require-Command -Name "cmake" -CommandType Application | Out-Null
    Require-Command -Name "ctest" -CommandType Application | Out-Null
    Assert-RequiredRepoFiles -RepoRoot $repoRoot -RelativePaths @(
        "CMakeLists.txt",
        "CMakePresets.json",
        "vcpkg.json",
        "tests"
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

    Assert-SkipConfigureCacheExists -SkipConfigure:$SkipConfigure -BuildDir $buildDir -PresetName "windows-vcpkg" -ScriptName "test.ps1"
    Invoke-CMakeConfigureUnlessSkipped -SkipConfigure:$SkipConfigure -Preset "windows-vcpkg"

    $buildPreset = if ($Config -eq "Release") { "windows-release" } else { "windows-debug" }
    Invoke-CMakeBuildPreset -Preset $buildPreset -Target "sdl3boilerplate_tests"

    $testPreset = if ($Config -eq "Release") { "windows-release-tests" } else { "windows-debug-tests" }
    $ctestArguments = @(
        "--preset", $testPreset,
        "--output-on-failure",
        "--no-tests=error"
    )
    if ($TestFilter) {
        $ctestArguments += @("-R", $TestFilter)
    }

    Invoke-NativeCommand -Command "ctest" -Arguments $ctestArguments
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    $exitCode = 1
} finally {
    Restore-CallerState -State $callerState
}

exit $exitCode
