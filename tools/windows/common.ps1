function Stop-ToolScript([string]$Message) {
    if (Test-Path -LiteralPath "Function:Fail") {
        Fail $Message
        return
    }

    throw $Message
}

function Resolve-RepoRoot([string]$WindowsToolsRoot) {
    return (Resolve-Path -LiteralPath (Join-Path $WindowsToolsRoot "../..")).Path
}

function Get-GeneratedOutputRoot([string]$RepoRoot) {
    return Join-Path $RepoRoot "out"
}

function Get-WindowsBuildDir([string]$RepoRoot) {
    return Get-ConfiguredBuildDirectory -RepoRoot $RepoRoot -ConfigurePresetName "windows-vcpkg"
}

function Get-WindowsAnalyzeBuildDir([string]$RepoRoot) {
    return Get-ConfiguredBuildDirectory -RepoRoot $RepoRoot -ConfigurePresetName "windows-vcpkg-analyze"
}

function Save-CallerState {
    return [pscustomobject]@{
        PreviousLocation = (Get-Location).ProviderPath
        HadVcpkgRoot = Test-Path -LiteralPath "Env:VCPKG_ROOT"
        PreviousVcpkgRoot = $env:VCPKG_ROOT
    }
}

function Restore-CallerState([object]$State) {
    if ($null -eq $State) {
        return
    }

    Set-Location -LiteralPath $State.PreviousLocation

    if ($State.HadVcpkgRoot) {
        $env:VCPKG_ROOT = $State.PreviousVcpkgRoot
    } else {
        Remove-Item -LiteralPath "Env:VCPKG_ROOT" -ErrorAction SilentlyContinue
    }
}

function Get-DotNetProcessEnvironmentEntries {
    $entries = New-Object System.Collections.Generic.List[object]
    foreach ($entry in [Environment]::GetEnvironmentVariables("Process").GetEnumerator()) {
        $entries.Add([pscustomobject]@{
            Name = [string]$entry.Key
            Value = [string]$entry.Value
        })
    }

    return $entries.ToArray()
}

function Get-NativeWindowsProcessEnvironmentEntries {
    if (-not ([System.Management.Automation.PSTypeName]"Sdl3BoilerplateTools.NativeEnvironment").Type) {
        Add-Type -Language CSharp -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace Sdl3BoilerplateTools
{
    public static class NativeEnvironment
    {
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        private static extern IntPtr GetEnvironmentStringsW();

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        private static extern bool FreeEnvironmentStringsW(IntPtr environment);

        public static string[] GetEntries()
        {
            IntPtr environment = GetEnvironmentStringsW();
            if (environment == IntPtr.Zero)
            {
                throw new InvalidOperationException("GetEnvironmentStringsW failed with error " + Marshal.GetLastWin32Error().ToString());
            }

            try
            {
                List<string> entries = new List<string>();
                IntPtr cursor = environment;
                while (true)
                {
                    string entry = Marshal.PtrToStringUni(cursor);
                    if (entry == null || entry.Length == 0)
                    {
                        break;
                    }

                    entries.Add(entry);
                    cursor = IntPtr.Add(cursor, (entry.Length + 1) * 2);
                }

                return entries.ToArray();
            }
            finally
            {
                FreeEnvironmentStringsW(environment);
            }
        }
    }
}
"@
    }

    $entries = New-Object System.Collections.Generic.List[object]
    foreach ($entry in [Sdl3BoilerplateTools.NativeEnvironment]::GetEntries()) {
        $separatorIndex = $entry.IndexOf("=")
        if ($entry.StartsWith("=")) {
            $separatorIndex = $entry.IndexOf("=", 1)
        }
        if ($separatorIndex -lt 0) {
            continue
        }

        $name = $entry.Substring(0, $separatorIndex)
        if ([string]::IsNullOrEmpty($name)) {
            continue
        }

        $entries.Add([pscustomobject]@{
            Name = $name
            Value = $entry.Substring($separatorIndex + 1)
        })
    }

    return $entries.ToArray()
}

function Get-ProcessEnvironmentEntries {
    if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
        return Get-NativeWindowsProcessEnvironmentEntries
    }

    return Get-DotNetProcessEnvironmentEntries
}

function Get-OrdinalSortedStrings([object[]]$Values) {
    $sorted = [string[]]@($Values | ForEach-Object { [string]$_ })
    [Array]::Sort($sorted, [System.StringComparer]::Ordinal)
    return $sorted
}

function Get-CaseVariantEnvironmentDuplicateGroups([object[]]$Entries) {
    $groups = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[object]]' ([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($entry in $Entries) {
        if (-not $groups.ContainsKey($entry.Name)) {
            $groups.Add($entry.Name, (New-Object System.Collections.Generic.List[object]))
        }

        $groups[$entry.Name].Add($entry)
    }

    $duplicates = New-Object System.Collections.Generic.List[object]
    foreach ($groupName in $groups.Keys) {
        $groupEntries = @($groups[$groupName])
        if ($groupEntries.Count -lt 2) {
            continue
        }

        $variants = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
        foreach ($entry in $groupEntries) {
            [void]$variants.Add($entry.Name)
        }

        if ($variants.Count -gt 1) {
            $variantValues = @()
            foreach ($variant in $variants) {
                $variantValues += [string]$variant
            }

            $duplicates.Add([pscustomobject]@{
                LogicalName = $groupName
                Entries = $groupEntries
                Variants = @(Get-OrdinalSortedStrings -Values $variantValues)
            })
        }
    }

    return $duplicates.ToArray()
}

function Get-EffectiveEnvironmentValue([object[]]$Entries, [string]$CanonicalName) {
    foreach ($entry in $Entries) {
        if ($entry.Name.Equals($CanonicalName, [System.StringComparison]::Ordinal)) {
            return $entry.Value
        }
    }

    foreach ($entry in $Entries) {
        if (-not [string]::IsNullOrEmpty($entry.Value)) {
            return $entry.Value
        }
    }

    return $Entries[0].Value
}

function Normalize-ProcessEnvironmentVariableCase([string]$CanonicalName) {
    $entries = @(Get-ProcessEnvironmentEntries | Where-Object {
        $_.Name.Equals($CanonicalName, [System.StringComparison]::OrdinalIgnoreCase)
    })

    if ($entries.Count -eq 0) {
        return
    }

    $hasCanonicalName = $false
    $hasNonCanonicalName = $false
    foreach ($entry in $entries) {
        if ($entry.Name.Equals($CanonicalName, [System.StringComparison]::Ordinal)) {
            $hasCanonicalName = $true
        } else {
            $hasNonCanonicalName = $true
        }
    }

    if ($entries.Count -eq 1 -and $hasCanonicalName -and -not $hasNonCanonicalName) {
        return
    }

    $effectiveValue = Get-EffectiveEnvironmentValue -Entries $entries -CanonicalName $CanonicalName
    $namesToClear = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    [void]$namesToClear.Add($CanonicalName)
    foreach ($entry in $entries) {
        [void]$namesToClear.Add($entry.Name)
    }

    $clearNames = @()
    foreach ($name in $namesToClear) {
        $clearNames += [string]$name
    }

    for ($pass = 0; $pass -lt ($clearNames.Count + $entries.Count + 2); $pass++) {
        foreach ($name in $clearNames) {
            [Environment]::SetEnvironmentVariable($name, $null, "Process")
        }
    }

    [Environment]::SetEnvironmentVariable($CanonicalName, $effectiveValue, "Process")

    $remainingEntries = @(Get-ProcessEnvironmentEntries | Where-Object {
        $_.Name.Equals($CanonicalName, [System.StringComparison]::OrdinalIgnoreCase)
    })
    if ($remainingEntries.Count -ne 1 -or
        -not $remainingEntries[0].Name.Equals($CanonicalName, [System.StringComparison]::Ordinal)) {
        Stop-ToolScript "Could not safely normalize process environment variable '$CanonicalName'."
    }
}

function Normalize-WindowsProcessEnvironment {
    if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
        return
    }

    $canonicalNames = @(
        "ALLUSERSPROFILE",
        "APPDATA",
        "CommonProgramFiles",
        "CommonProgramFiles(x86)",
        "CommonProgramW6432",
        "ComSpec",
        "DriverData",
        "HOMEDRIVE",
        "HOMEPATH",
        "LOCALAPPDATA",
        "NUMBER_OF_PROCESSORS",
        "OS",
        "Path",
        "PATHEXT",
        "PROCESSOR_ARCHITECTURE",
        "PROCESSOR_IDENTIFIER",
        "PROCESSOR_LEVEL",
        "PROCESSOR_REVISION",
        "ProgramData",
        "ProgramFiles",
        "ProgramFiles(x86)",
        "ProgramW6432",
        "PUBLIC",
        "SystemDrive",
        "SystemRoot",
        "TEMP",
        "TMP",
        "USERDOMAIN",
        "USERNAME",
        "USERPROFILE",
        "VCPKG_ROOT",
        "WINDIR"
    )

    foreach ($canonicalName in $canonicalNames) {
        Normalize-ProcessEnvironmentVariableCase -CanonicalName $canonicalName
    }

    $duplicates = @(Get-CaseVariantEnvironmentDuplicateGroups -Entries (Get-ProcessEnvironmentEntries))
    if ($duplicates.Count -eq 0) {
        return
    }

    $descriptions = @($duplicates | ForEach-Object {
        "{0} (variants: {1})" -f $_.LogicalName, ($_.Variants -join ", ")
    })
    Stop-ToolScript ("Process environment contains case-variant duplicate variables that can break MSBuild/.NET when launching CL.exe: {0}. Fix the inherited shell, user, or machine environment and rerun the script." -f ($descriptions -join "; "))
}

function Get-FullPath([string]$Path) {
    return [System.IO.Path]::GetFullPath($Path)
}

function Remove-TrailingPathSeparators([string]$Path) {
    return $Path.TrimEnd([char[]]@('\', '/'))
}

function Test-PathEquals([string]$Left, [string]$Right) {
    $leftFull = Remove-TrailingPathSeparators -Path (Get-FullPath $Left)
    $rightFull = Remove-TrailingPathSeparators -Path (Get-FullPath $Right)
    return $leftFull.Equals($rightFull, [System.StringComparison]::OrdinalIgnoreCase)
}

function Assert-PathUnderRoot([string]$Path, [string]$Root, [switch]$AllowRoot) {
    $rootFull = Remove-TrailingPathSeparators -Path (Get-FullPath $Root)
    $pathFull = Remove-TrailingPathSeparators -Path (Get-FullPath $Path)

    if ($pathFull.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        if ($AllowRoot) {
            return
        }

        Stop-ToolScript "Refusing to operate on root directory itself: $Path"
    }

    $rootPrefix = $rootFull + [System.IO.Path]::DirectorySeparatorChar
    if (-not $pathFull.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        Stop-ToolScript "Refusing to operate outside expected root: $Path"
    }
}

function Remove-KnownDirectory([string]$Path, [string]$AllowedRoot, [string]$Label) {
    Assert-PathUnderRoot -Path $Path -Root $AllowedRoot
    if (Test-Path -LiteralPath $Path -PathType Container) {
        Write-Host "Removing $Label directory: $Path"
        Remove-Item -LiteralPath $Path -Recurse -Force
    } else {
        Write-Host "$Label directory does not exist: $Path"
    }
}

function Resolve-VcpkgRoot(
    [string]$RequestedRoot,
    [switch]$WriteStatus,
    [switch]$PassThru
) {
    if ($RequestedRoot) {
        if (-not (Test-Path -LiteralPath $RequestedRoot -PathType Container)) {
            Stop-ToolScript "Invalid VCPKG_ROOT: directory not found: $RequestedRoot"
        }

        $resolvedRoot = (Resolve-Path -LiteralPath $RequestedRoot).Path
        $toolchainFile = Join-Path $resolvedRoot "scripts/buildsystems/vcpkg.cmake"
        if (-not (Test-Path -LiteralPath $toolchainFile -PathType Leaf)) {
            Stop-ToolScript "Invalid VCPKG_ROOT: vcpkg toolchain file not found: $toolchainFile"
        }

        $env:VCPKG_ROOT = $resolvedRoot
        if ($WriteStatus) {
            Write-Host "VCPKG_ROOT set to: $resolvedRoot"
        }
        if ($PassThru) {
            return $resolvedRoot
        }

        return
    }

    if (-not $env:VCPKG_ROOT) {
        Stop-ToolScript "VCPKG_ROOT is not set. Pass -VcpkgRoot or set the VCPKG_ROOT environment variable."
    }

    if (-not (Test-Path -LiteralPath $env:VCPKG_ROOT -PathType Container)) {
        Stop-ToolScript "Invalid VCPKG_ROOT: directory not found: $env:VCPKG_ROOT"
    }

    $resolvedExistingRoot = (Resolve-Path -LiteralPath $env:VCPKG_ROOT).Path
    $existingToolchainFile = Join-Path $resolvedExistingRoot "scripts/buildsystems/vcpkg.cmake"
    if (-not (Test-Path -LiteralPath $existingToolchainFile -PathType Leaf)) {
        Stop-ToolScript "Invalid VCPKG_ROOT: vcpkg toolchain file not found: $existingToolchainFile"
    }

    $env:VCPKG_ROOT = $resolvedExistingRoot
    if ($WriteStatus) {
        Write-Host "Using VCPKG_ROOT: $resolvedExistingRoot"
    }
    if ($PassThru) {
        return $resolvedExistingRoot
    }
}

function Get-VcpkgToolchainFile([string]$VcpkgRoot) {
    return Join-Path $VcpkgRoot "scripts/buildsystems/vcpkg.cmake"
}

function Require-Command([string]$Name, [string]$CommandType = "") {
    if ($CommandType) {
        $command = Get-Command $Name -CommandType $CommandType -ErrorAction SilentlyContinue |
            Select-Object -First 1
    } else {
        $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    }

    if (-not $command) {
        Stop-ToolScript "$Name was not found on PATH."
    }

    return $command
}

function Invoke-NativeCommand([string]$Command, [string[]]$Arguments = @()) {
    Write-Host "> $Command $($Arguments -join ' ')"
    & $Command @Arguments
    $exitCode = $LASTEXITCODE
    if ($null -eq $exitCode) {
        $exitCode = 0
    }
    if ($exitCode -ne 0) {
        Stop-ToolScript "$Command failed with exit code $exitCode."
    }
}

function Invoke-CapturedNativeCommand([string]$Command, [string[]]$Arguments = @()) {
    $outputLines = New-Object System.Collections.Generic.List[string]
    $commandInfo = Get-Command $Command -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $commandInfo) {
        $line = "$Command was not found on PATH."
        [Console]::Error.WriteLine($line)
        $outputLines.Add($line)

        return [pscustomobject]@{
            ExitCode = 1
            Lines = @($outputLines)
        }
    }

    $exitCode = 1
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    try {
        Write-Host "> $($commandInfo.Source) $($Arguments -join ' ')"
        & $commandInfo.Source @Arguments 2>&1 | ForEach-Object {
            if ($_ -is [System.Management.Automation.ErrorRecord]) {
                $line = $_.Exception.Message
                [Console]::Error.WriteLine($line)
            } else {
                $line = $_.ToString()
                Write-Host $line
            }

            $outputLines.Add($line)
        }

        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) {
            $exitCode = 1
        }
    } catch {
        $line = $_.Exception.Message
        [Console]::Error.WriteLine($line)
        $outputLines.Add($line)
        $exitCode = 1
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Lines = @($outputLines)
    }
}

function Get-ObjectPropertyValue([object]$Object, [string]$Name) {
    if ($null -eq $Object) {
        return $null
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function Get-JsonArrayProperty([object]$Object, [string]$Name) {
    $value = Get-ObjectPropertyValue -Object $Object -Name $Name
    if ($null -eq $value) {
        return @()
    }

    return @($value)
}

function Read-CMakePresets([string]$RepoRoot) {
    $presetPath = Join-Path $RepoRoot "CMakePresets.json"
    if (-not (Test-Path -LiteralPath $presetPath -PathType Leaf)) {
        Stop-ToolScript "CMakePresets.json was not found: $presetPath"
    }

    return Get-Content -Raw -LiteralPath $presetPath | ConvertFrom-Json
}

function Get-ConfigurePreset([object]$Presets, [string]$Name) {
    $configurePresets = Get-JsonArrayProperty -Object $Presets -Name "configurePresets"
    return @($configurePresets | Where-Object { $_.name -eq $Name }) | Select-Object -First 1
}

function Get-BuildPreset([object]$Presets, [string]$Name) {
    $buildPresets = Get-JsonArrayProperty -Object $Presets -Name "buildPresets"
    return @($buildPresets | Where-Object { $_.name -eq $Name }) | Select-Object -First 1
}

function Get-TestPreset([object]$Presets, [string]$Name) {
    $testPresets = Get-JsonArrayProperty -Object $Presets -Name "testPresets"
    return @($testPresets | Where-Object { $_.name -eq $Name }) | Select-Object -First 1
}

function Get-InheritedPresetProperty([object]$Presets, [object]$Preset, [string]$Name) {
    $value = Get-ObjectPropertyValue -Object $Preset -Name $Name
    if ($null -ne $value) {
        return $value
    }

    $inherits = Get-ObjectPropertyValue -Object $Preset -Name "inherits"
    foreach ($parentName in @($inherits)) {
        if (-not $parentName) {
            continue
        }

        $parentPreset = Get-ConfigurePreset -Presets $Presets -Name $parentName
        if ($parentPreset) {
            $parentValue = Get-InheritedPresetProperty -Presets $Presets -Preset $parentPreset -Name $Name
            if ($null -ne $parentValue) {
                return $parentValue
            }
        }
    }

    return $null
}

function Resolve-PresetBinaryDirectory([string]$RepoRoot, [object]$Presets, [string]$ConfigurePresetName) {
    $preset = Get-ConfigurePreset -Presets $Presets -Name $ConfigurePresetName
    if (-not $preset) {
        Stop-ToolScript "CMake configure preset '$ConfigurePresetName' was not found."
    }

    $binaryDir = Get-InheritedPresetProperty -Presets $Presets -Preset $preset -Name "binaryDir"
    if (-not $binaryDir) {
        Stop-ToolScript "CMake configure preset '$ConfigurePresetName' does not define binaryDir."
    }

    $expanded = $binaryDir.Replace('${sourceDir}', $RepoRoot)
    return Get-FullPath $expanded
}

function Assert-BuildPresetContract(
    [object]$Presets,
    [string]$Name,
    [string]$ConfigurePreset,
    [string]$Configuration
) {
    $preset = Get-BuildPreset -Presets $Presets -Name $Name
    if (-not $preset) {
        Stop-ToolScript "CMake build preset '$Name' was not found."
    }
    if ($preset.configurePreset -ne $ConfigurePreset -or $preset.configuration -ne $Configuration) {
        Stop-ToolScript "CMake build preset '$Name' must build $Configuration from $ConfigurePreset."
    }
}

function Assert-TestPresetContract(
    [object]$Presets,
    [string]$Name,
    [string]$ConfigurePreset,
    [string]$Configuration
) {
    $preset = Get-TestPreset -Presets $Presets -Name $Name
    if (-not $preset) {
        Stop-ToolScript "CMake test preset '$Name' was not found."
    }
    if ($preset.configurePreset -ne $ConfigurePreset -or $preset.configuration -ne $Configuration) {
        Stop-ToolScript "CMake test preset '$Name' must test $Configuration from $ConfigurePreset."
    }

    $output = Get-ObjectPropertyValue -Object $preset -Name "output"
    if ((Get-ObjectPropertyValue -Object $output -Name "outputOnFailure") -ne $true) {
        Stop-ToolScript "CMake test preset '$Name' must enable outputOnFailure."
    }

    $execution = Get-ObjectPropertyValue -Object $preset -Name "execution"
    if ((Get-ObjectPropertyValue -Object $execution -Name "noTestsAction") -ne "error") {
        Stop-ToolScript "CMake test preset '$Name' must fail when no tests are discovered."
    }
}

function Assert-BoilerplatePresetContract([string]$RepoRoot, [string]$VcpkgRoot) {
    $presets = Read-CMakePresets -RepoRoot $RepoRoot

    if ($presets.version -ne 6) {
        Stop-ToolScript "CMakePresets.json must use schema version 6."
    }

    $minimum = Get-ObjectPropertyValue -Object $presets -Name "cmakeMinimumRequired"
    if ((Get-ObjectPropertyValue -Object $minimum -Name "major") -ne 4 -or
        (Get-ObjectPropertyValue -Object $minimum -Name "minor") -ne 2 -or
        (Get-ObjectPropertyValue -Object $minimum -Name "patch") -ne 0) {
        Stop-ToolScript "CMakePresets.json must require CMake 4.2.0."
    }

    $windowsPreset = Get-ConfigurePreset -Presets $presets -Name "windows-vcpkg"
    if (-not $windowsPreset) {
        Stop-ToolScript "CMake configure preset 'windows-vcpkg' was not found."
    }
    if ($windowsPreset.generator -ne "Visual Studio 18 2026") {
        Stop-ToolScript "CMake preset 'windows-vcpkg' must use generator 'Visual Studio 18 2026'."
    }
    if ($windowsPreset.architecture -ne "x64") {
        Stop-ToolScript "CMake preset 'windows-vcpkg' must set architecture to x64."
    }

    $windowsCondition = Get-ObjectPropertyValue -Object $windowsPreset -Name "condition"
    if ((Get-ObjectPropertyValue -Object $windowsCondition -Name "type") -ne "equals" -or
        (Get-ObjectPropertyValue -Object $windowsCondition -Name "lhs") -ne '${hostSystemName}' -or
        (Get-ObjectPropertyValue -Object $windowsCondition -Name "rhs") -ne "Windows") {
        Stop-ToolScript "CMake preset 'windows-vcpkg' must be gated to Windows hosts."
    }

    $windowsBuildDir = Resolve-PresetBinaryDirectory -RepoRoot $RepoRoot -Presets $presets -ConfigurePresetName "windows-vcpkg"
    $expectedWindowsBuildDir = Join-Path (Get-GeneratedOutputRoot -RepoRoot $RepoRoot) "build-win-vcpkg"
    if (-not (Test-PathEquals -Left $windowsBuildDir -Right $expectedWindowsBuildDir)) {
        Stop-ToolScript "CMake preset 'windows-vcpkg' must use build directory '$expectedWindowsBuildDir'."
    }

    $toolchainFile = Get-ObjectPropertyValue -Object $windowsPreset -Name "toolchainFile"
    if ($toolchainFile -ne '$env{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake') {
        Stop-ToolScript "CMake preset 'windows-vcpkg' must use top-level toolchainFile from VCPKG_ROOT."
    }

    $cacheVariables = Get-ObjectPropertyValue -Object $windowsPreset -Name "cacheVariables"
    if ($null -ne (Get-ObjectPropertyValue -Object $cacheVariables -Name "CMAKE_TOOLCHAIN_FILE")) {
        Stop-ToolScript "CMake preset 'windows-vcpkg' must not set CMAKE_TOOLCHAIN_FILE in cacheVariables."
    }
    if ((Get-ObjectPropertyValue -Object $cacheVariables -Name "VCPKG_TARGET_TRIPLET") -ne "x64-windows") {
        Stop-ToolScript "CMake preset 'windows-vcpkg' must use VCPKG_TARGET_TRIPLET=x64-windows."
    }
    if ((Get-ObjectPropertyValue -Object $cacheVariables -Name "VCPKG_MANIFEST_MODE") -ne "ON") {
        Stop-ToolScript "CMake preset 'windows-vcpkg' must use VCPKG_MANIFEST_MODE=ON."
    }

    $analyzePreset = Get-ConfigurePreset -Presets $presets -Name "windows-vcpkg-analyze"
    if (-not $analyzePreset) {
        Stop-ToolScript "CMake configure preset 'windows-vcpkg-analyze' was not found."
    }
    if ($analyzePreset.inherits -ne "windows-vcpkg") {
        Stop-ToolScript "CMake configure preset 'windows-vcpkg-analyze' must inherit windows-vcpkg."
    }

    $analyzeBuildDir = Resolve-PresetBinaryDirectory -RepoRoot $RepoRoot -Presets $presets -ConfigurePresetName "windows-vcpkg-analyze"
    $expectedAnalyzeBuildDir = Join-Path (Get-GeneratedOutputRoot -RepoRoot $RepoRoot) "build-win-vcpkg-analyze"
    if (-not (Test-PathEquals -Left $analyzeBuildDir -Right $expectedAnalyzeBuildDir)) {
        Stop-ToolScript "CMake preset 'windows-vcpkg-analyze' must use build directory '$expectedAnalyzeBuildDir'."
    }

    $analyzeCacheVariables = Get-ObjectPropertyValue -Object $analyzePreset -Name "cacheVariables"
    if ((Get-ObjectPropertyValue -Object $analyzeCacheVariables -Name "SDL3BOILERPLATE_ENABLE_MSVC_ANALYZE") -ne "ON") {
        Stop-ToolScript "CMake preset 'windows-vcpkg-analyze' must enable SDL3BOILERPLATE_ENABLE_MSVC_ANALYZE."
    }

    Assert-BuildPresetContract -Presets $presets -Name "windows-debug" -ConfigurePreset "windows-vcpkg" -Configuration "Debug"
    Assert-BuildPresetContract -Presets $presets -Name "windows-release" -ConfigurePreset "windows-vcpkg" -Configuration "Release"
    Assert-BuildPresetContract -Presets $presets -Name "windows-debug-analyze" -ConfigurePreset "windows-vcpkg-analyze" -Configuration "Debug"

    Assert-TestPresetContract -Presets $presets -Name "windows-debug-tests" -ConfigurePreset "windows-vcpkg" -Configuration "Debug"
    Assert-TestPresetContract -Presets $presets -Name "windows-release-tests" -ConfigurePreset "windows-vcpkg" -Configuration "Release"

    $expectedToolchain = Get-VcpkgToolchainFile -VcpkgRoot $VcpkgRoot
    if (-not (Test-Path -LiteralPath $expectedToolchain -PathType Leaf)) {
        Stop-ToolScript "Expected vcpkg toolchain file was not found: $expectedToolchain"
    }

    return $presets
}

function Get-ConfiguredBuildDirectory([string]$RepoRoot, [string]$ConfigurePresetName) {
    $presets = Read-CMakePresets -RepoRoot $RepoRoot
    return Resolve-PresetBinaryDirectory -RepoRoot $RepoRoot -Presets $presets -ConfigurePresetName $ConfigurePresetName
}

function Assert-CleanSkipConfigureCompatible([switch]$Clean, [switch]$SkipConfigure, [string]$Label = "build directory") {
    if ($Clean -and $SkipConfigure) {
        Stop-ToolScript "-Clean cannot be combined with -SkipConfigure because the $Label is removed before configure."
    }
}

function Clear-KnownBuildDirectory([string]$BuildDir, [string]$RepoRoot, [string]$Label = "build") {
    $outputRoot = Get-GeneratedOutputRoot -RepoRoot $RepoRoot
    Remove-KnownDirectory -Path $BuildDir -AllowedRoot $outputRoot -Label $Label
}

function Get-CMakeCacheEntry([string]$CachePath, [string]$Name) {
    if (-not (Test-Path -LiteralPath $CachePath -PathType Leaf)) {
        return $null
    }

    $escapedName = [System.Text.RegularExpressions.Regex]::Escape($Name)
    foreach ($line in Get-Content -LiteralPath $CachePath) {
        if ($line -match "^$escapedName(:[^=]*)?=(.*)$") {
            return $Matches[2]
        }
    }

    return $null
}

function Get-FullPathForComparison([string]$Path, [string]$BaseDirectory) {
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return Get-FullPath $Path
    }

    return Get-FullPath (Join-Path $BaseDirectory $Path)
}

function Assert-CachedBuildDirectoryMatches(
    [string]$BuildDir,
    [string]$ToolchainFile,
    [string]$ExpectedGenerator = "Visual Studio 18 2026",
    [string]$ExpectedPlatform = "x64",
    [string]$ExpectedTriplet = "x64-windows"
) {
    $cachePath = Join-Path $BuildDir "CMakeCache.txt"
    if (-not (Test-Path -LiteralPath $cachePath -PathType Leaf)) {
        return
    }

    $cacheDir = Split-Path -Parent $cachePath
    $cachedToolchainFile = Get-CMakeCacheEntry -CachePath $cachePath -Name "CMAKE_TOOLCHAIN_FILE"
    if ([string]::IsNullOrWhiteSpace($cachedToolchainFile)) {
        Stop-ToolScript "Existing build directory is not a valid vcpkg-configured build directory: $BuildDir. Run the script again with -Clean."
    }

    $cachedToolchainFullPath = Get-FullPathForComparison -Path $cachedToolchainFile -BaseDirectory $cacheDir
    $expectedToolchainFullPath = Get-FullPathForComparison -Path $ToolchainFile -BaseDirectory (Get-Location).ProviderPath
    if (-not $cachedToolchainFullPath.Equals($expectedToolchainFullPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        Stop-ToolScript "Existing build directory was configured with a different toolchain: $BuildDir. Run the script again with -Clean."
    }

    $cachedGenerator = Get-CMakeCacheEntry -CachePath $cachePath -Name "CMAKE_GENERATOR"
    if ($cachedGenerator -ne $ExpectedGenerator) {
        Stop-ToolScript "Existing build directory was configured with generator '$cachedGenerator', expected '$ExpectedGenerator'. Run the script again with -Clean."
    }

    $cachedPlatform = Get-CMakeCacheEntry -CachePath $cachePath -Name "CMAKE_GENERATOR_PLATFORM"
    if ($cachedPlatform -ne $ExpectedPlatform) {
        Stop-ToolScript "Existing build directory was configured with platform '$cachedPlatform', expected '$ExpectedPlatform'. Run the script again with -Clean."
    }

    $cachedTriplet = Get-CMakeCacheEntry -CachePath $cachePath -Name "VCPKG_TARGET_TRIPLET"
    if ($cachedTriplet -ne $ExpectedTriplet) {
        Stop-ToolScript "Existing build directory was configured with triplet '$cachedTriplet', expected '$ExpectedTriplet'. Run the script again with -Clean."
    }
}

function Assert-SkipConfigureCacheExists(
    [switch]$SkipConfigure,
    [string]$BuildDir,
    [string]$PresetName,
    [string]$ScriptName = "script"
) {
    if (-not $SkipConfigure) {
        return
    }

    $cachePath = Join-Path $BuildDir "CMakeCache.txt"
    if (-not (Test-Path -LiteralPath $cachePath -PathType Leaf)) {
        Stop-ToolScript "$ScriptName was run with -SkipConfigure, but no CMake cache exists at '$cachePath'. Run without -SkipConfigure first to configure preset '$PresetName'."
    }
}

function Invoke-CMakeConfigureUnlessSkipped(
    [switch]$SkipConfigure,
    [string]$Preset,
    [switch]$CaptureOutput
) {
    if ($SkipConfigure) {
        Write-Host "Skipping configure because -SkipConfigure was specified."
        return $null
    }

    $arguments = @("--preset", $Preset)
    if ($CaptureOutput) {
        return Invoke-CapturedNativeCommand -Command "cmake" -Arguments $arguments
    }

    Invoke-NativeCommand -Command "cmake" -Arguments $arguments
}

function Invoke-CMakeBuildPreset(
    [string]$Preset,
    [string]$Target,
    [switch]$CaptureOutput,
    [switch]$Parallel
) {
    $arguments = @("--build", "--preset", $Preset)
    if ($Target) {
        $arguments += @("--target", $Target)
    }
    if ($Parallel) {
        $arguments += "--parallel"
    }

    if ($CaptureOutput) {
        return Invoke-CapturedNativeCommand -Command "cmake" -Arguments $arguments
    }

    Invoke-NativeCommand -Command "cmake" -Arguments $arguments
}

function Assert-RequiredRepoFiles([string]$RepoRoot, [string[]]$RelativePaths) {
    foreach ($relativePath in $RelativePaths) {
        $fullPath = Join-Path $RepoRoot $relativePath
        if (-not (Test-Path -LiteralPath $fullPath)) {
            Stop-ToolScript "Required repo path not found: $fullPath"
        }
    }
}
