param(
    [Parameter(Mandatory = $true)]
    [string]$BatPath,

    [Parameter(Mandatory = $true)]
    [string]$LogPath
)

$ErrorActionPreference = "Stop"

$logDir = Split-Path -Parent $LogPath
if ($logDir -and -not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$writer = New-Object System.IO.StreamWriter($LogPath, $true, $utf8NoBom)
$writer.AutoFlush = $true

try {
    $header = @(
        "============================================================",
        "TheRock AMD Bootstrap logger",
        "Started : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')",
        "BAT     : $BatPath",
        "LOG     : $LogPath",
        "============================================================"
    )

    foreach ($line in $header) {
        Write-Host $line
        $writer.WriteLine($line)
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $env:ComSpec

    # Worker mode uses a plain token. The BAT detects it but must not SHIFT
    # before reading %~f0: Windows SHIFT also shifts %0.
    $psi.Arguments = '/d /s /c ""' + $BatPath + '" worker 2>&1"'
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    if (-not $process.Start()) {
        throw "Failed to start cmd.exe worker process."
    }

    while (($line = $process.StandardOutput.ReadLine()) -ne $null) {
        Write-Host $line
        $writer.WriteLine($line)
    }

    $stderr = $process.StandardError.ReadToEnd()
    if ($stderr) {
        Write-Host $stderr -ForegroundColor Red
        $writer.Write($stderr)
    }

    $process.WaitForExit()
    $exitCode = $process.ExitCode

    $footer = @(
        "============================================================",
        "Finished: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')",
        "ExitCode: $exitCode",
        "============================================================"
    )

    foreach ($line in $footer) {
        Write-Host $line
        $writer.WriteLine($line)
    }

    exit $exitCode
}
catch {
    $message = "LOGGER ERROR: $($_.Exception.Message)"
    Write-Host $message -ForegroundColor Red
    try { $writer.WriteLine($message) } catch {}
    exit 250
}
finally {
    if ($writer) { $writer.Dispose() }
}
