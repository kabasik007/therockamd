param(
    [Parameter(Mandatory=$true)][string]$RepoRoot,
    [int]$Port = 8188
)

$ErrorActionPreference = 'SilentlyContinue'

$repoRootNorm = [IO.Path]::GetFullPath($RepoRoot).TrimEnd('\').ToLowerInvariant()
$expectedPython = Join-Path $RepoRoot 'workspace\comfyui\.venv\Scripts\python.exe'
$expectedMain = Join-Path $RepoRoot 'workspace\comfyui\ComfyUI\main.py'
$expectedPythonNorm = [IO.Path]::GetFullPath($expectedPython).ToLowerInvariant()
$expectedMainNorm = [IO.Path]::GetFullPath($expectedMain).ToLowerInvariant()

function Get-Proc([int]$PidValue) {
    return Get-CimInstance Win32_Process -Filter "ProcessId=$PidValue"
}

function Is-OurComfy($proc) {
    if ($null -eq $proc) { return $false }
    $cmd = [string]$proc.CommandLine
    $exe = [string]$proc.ExecutablePath
    if ([string]::IsNullOrWhiteSpace($cmd)) { return $false }

    $cmdNorm = $cmd.ToLowerInvariant()
    $exeNorm = $exe.ToLowerInvariant()
    $hasMain = $cmdNorm.Contains('main.py')

    return (
        $cmdNorm.Contains($expectedMainNorm) -or
        ($hasMain -and $exeNorm -eq $expectedPythonNorm) -or
        ($hasMain -and $cmdNorm.Contains($repoRootNorm))
    )
}

$candidates = New-Object System.Collections.Generic.HashSet[int]

try {
    foreach ($listener in @(Get-NetTCPConnection -State Listen -LocalPort $Port)) {
        if ($listener.OwningProcess -gt 0) { [void]$candidates.Add([int]$listener.OwningProcess) }
    }
} catch {}

try {
    foreach ($proc in Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^(python|pythonw)\.exe$' }) {
        if (Is-OurComfy $proc) { [void]$candidates.Add([int]$proc.ProcessId) }
    }
} catch {
    Write-Host "[WARN] Could not enumerate all Python processes: $($_.Exception.Message)" -ForegroundColor Yellow
}

if ($candidates.Count -eq 0) {
    Write-Host "[INFO] No running ComfyUI process from this Bootstrap was found."
    exit 0
}

$killed = 0
foreach ($pidValue in @($candidates)) {
    $proc = Get-Proc $pidValue
    if (-not (Is-OurComfy $proc)) {
        Write-Host "[REFUSE] PID $pidValue is not our ComfyUI process." -ForegroundColor Yellow
        if ($null -ne $proc) { Write-Host "         Cmd: $($proc.CommandLine)" }
        continue
    }

    Write-Host "[STOP] PID $pidValue"
    Write-Host "       $($proc.CommandLine)"
    & "$env:SystemRoot\System32\taskkill.exe" /PID $pidValue /T /F
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    $killed++
}

Start-Sleep -Milliseconds 500
$left = @(Get-NetTCPConnection -State Listen -LocalPort $Port)
if ($left.Count -gt 0) {
    Write-Host "[WARN] Port $Port is still in use. It may belong to another application." -ForegroundColor Yellow
    exit 3
}

if ($killed -gt 0) {
    Write-Host "[SUCCESS] ComfyUI is stopped and port $Port is free." -ForegroundColor Green
} else {
    Write-Host "[INFO] Nothing belonging to this Bootstrap was killed."
}
exit 0
