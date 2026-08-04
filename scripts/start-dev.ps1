param(
    [string]$AvdName,
    [switch]$RunFlutter,
    [switch]$NoDocker,
    [switch]$NoEmulator,
    [switch]$NoBuild
)

$ErrorActionPreference = 'Stop'

function Resolve-SdkTool {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    $candidates = @()

    if ($env:ANDROID_SDK_ROOT) {
        $candidates += (Join-Path $env:ANDROID_SDK_ROOT $RelativePath)
    }

    if ($env:ANDROID_HOME) {
        $candidates += (Join-Path $env:ANDROID_HOME $RelativePath)
    }

    $candidates += (Join-Path $env:LOCALAPPDATA ("Android\\sdk\\" + $RelativePath))

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    throw "Could not find Android SDK tool: $RelativePath"
}

function Get-RunningEmulatorSerial {
    param(
        [Parameter(Mandatory = $true)][string]$AdbPath
    )

    $lines = & $AdbPath devices
    foreach ($line in $lines) {
        if ($line -match '^(emulator-\d+)\s+device$') {
            return $Matches[1]
        }
    }

    return $null
}

function Wait-ForEmulatorBoot {
    param(
        [Parameter(Mandatory = $true)][string]$AdbPath,
        [Parameter(Mandatory = $true)][string]$Serial,
        [int]$TimeoutSeconds = 180
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        try {
            $boot = (& $AdbPath -s $Serial shell getprop sys.boot_completed 2>$null).Trim()
            if ($boot -eq '1') {
                & $AdbPath -s $Serial shell input keyevent 82 | Out-Null
                return
            }
        } catch {
            # Keep polling while emulator is booting.
        }

        Start-Sleep -Seconds 2
    }

    throw "Timed out waiting for emulator $Serial to boot."
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$frontendDir = Join-Path $repoRoot 'frontend'

$adb = Resolve-SdkTool -RelativePath 'platform-tools\\adb.exe'
$emulator = Resolve-SdkTool -RelativePath 'emulator\\emulator.exe'

$serial = $null

if (-not $NoEmulator) {
    $serial = Get-RunningEmulatorSerial -AdbPath $adb

    if (-not $serial) {
        if (-not $AvdName) {
            $available = & $emulator -list-avds
            if (-not $available -or $available.Count -eq 0) {
                throw 'No Android Virtual Devices found. Create an AVD in Android Studio first.'
            }

            $AvdName = $available[0]
        }

        Write-Host "Starting emulator: $AvdName"
        Start-Process -FilePath $emulator -ArgumentList @('-avd', $AvdName)

        $maxDetectSeconds = 60
        $detectedStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        while ($detectedStopwatch.Elapsed.TotalSeconds -lt $maxDetectSeconds) {
            $serial = Get-RunningEmulatorSerial -AdbPath $adb
            if ($serial) {
                break
            }

            Start-Sleep -Seconds 2
        }

        if (-not $serial) {
            throw 'Emulator process started but no adb emulator device was detected.'
        }
    }

    Write-Host "Waiting for emulator boot: $serial"
    Wait-ForEmulatorBoot -AdbPath $adb -Serial $serial
    Write-Host 'Emulator is ready.'
}

if (-not $NoDocker) {
    Set-Location $repoRoot

    $composeArgs = @('compose', 'up', '-d')
    if (-not $NoBuild) {
        $composeArgs += '--build'
    }

    Write-Host 'Starting Docker stack...'
    & docker @composeArgs
    Write-Host 'Docker stack started.'
}

if ($RunFlutter) {
    if (-not $serial) {
        throw 'RunFlutter requires an emulator device. Remove -NoEmulator or start an emulator first.'
    }

    $flutterCommand = "Set-Location '$frontendDir'; flutter run -d $serial"
    Write-Host "Starting flutter run on $serial in a new terminal window..."
    Start-Process -FilePath 'powershell' -ArgumentList @('-NoExit', '-ExecutionPolicy', 'Bypass', '-Command', $flutterCommand)
}

Write-Host ''
Write-Host 'Done.'
if (-not $NoDocker) {
    Write-Host 'Frontend web: http://localhost:8080'
    Write-Host 'Backend API:  http://localhost:8000'
}
if ($serial) {
    Write-Host "Emulator:     $serial"
}
