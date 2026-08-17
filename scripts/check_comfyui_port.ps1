param(
    [int]$Port = 8188,
    [string]$RepoRoot = ""
)

$ErrorActionPreference = 'SilentlyContinue'

$listeners = @(Get-NetTCPConnection -State Listen -LocalPort $Port)
if ($listeners.Count -eq 0) {
    Write-Host "[CHECK] Port $Port is free."
    exit 0
}

Write-Host "[ERROR] Port $Port is already in use." -ForegroundColor Red
foreach ($listener in $listeners) {
    $pidValue = [int]$listener.OwningProcess
    $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$pidValue"
    if ($null -ne $proc) {
        Write-Host "        PID : $pidValue"
        Write-Host "        Name: $($proc.Name)"
        Write-Host "        Cmd : $($proc.CommandLine)"
    }
    else {
        Write-Host "        PID : $pidValue"
    }
}

Write-Host ""
Write-Host "Do not start a second ComfyUI instance." -ForegroundColor Yellow
Write-Host "If this is the Bootstrap ComfyUI, run STOP_COMFYUI.bat first." -ForegroundColor Yellow
exit 1
