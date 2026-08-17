@echo off
setlocal EnableExtensions DisableDelayedExpansion

for %%I in ("%~dp0..") do set "REPO_ROOT=%%~fI"

echo ============================================================
echo TheRock AMD Bootstrap - STOP ComfyUI
echo This will stop only ComfyUI started from this Bootstrap.
echo ============================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0stop_comfyui.ps1" -RepoRoot "%REPO_ROOT%" -Port 8188
set "RC=%ERRORLEVEL%"

echo.
if "%RC%"=="0" (
    echo [DONE] Stop command completed successfully.
) else (
    echo [WARN] Stop command finished with exit code %RC%.
)

echo.
echo CMD WILL NOT CLOSE AUTOMATICALLY.
pause
exit /b %RC%
