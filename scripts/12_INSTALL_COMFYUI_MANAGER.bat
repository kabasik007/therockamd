@echo off
setlocal EnableExtensions DisableDelayedExpansion

for %%I in ("%~dp0..") do set "REPO_ROOT=%%~fI"
set "LOG_DIR=%REPO_ROOT%\logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

if /I "%~1"=="worker" goto :worker
rem IMPORTANT: do NOT SHIFT here. SHIFT also shifts %%0 and would erase %%~f0.

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%I"
if not defined STAMP set "STAMP=unknown_time"
set "LOG_FILE=%LOG_DIR%\manager_%STAMP%.log"

echo [INFO] Logging to %LOG_FILE%
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_bat_logged.ps1" -BatPath "%~f0" -LogPath "%LOG_FILE%"
set "RC=%ERRORLEVEL%"

echo.
if not "%RC%"=="0" (
  echo [FAILED] ComfyUI-Manager install failed with code %RC%.
  echo ---------------- LAST 80 LOG LINES ----------------
  powershell -NoProfile -Command "if (Test-Path -LiteralPath $env:LOG_FILE) { Get-Content -LiteralPath $env:LOG_FILE -Tail 80 }"
  echo ---------------------------------------------------
) else (
  echo [SUCCESS] ComfyUI-Manager is ready.
)
echo Log: %LOG_FILE%
echo.
pause
exit /b %RC%

:worker
set "WORK_ROOT=%REPO_ROOT%\workspace\comfyui"
set "VENV_DIR=%WORK_ROOT%\.venv"
set "COMFYUI_DIR=%WORK_ROOT%\ComfyUI"
set "PYTHON_EXE=%VENV_DIR%\Scripts\python.exe"
set "NODE_DIR=%COMFYUI_DIR%\custom_nodes\ComfyUI-Manager"

where git >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Git is not installed or not in PATH.
  exit /b 10
)

if not exist "%PYTHON_EXE%" (
  echo [ERROR] Base environment not found. Run scripts\10_SETUP_COMFYUI_RX6900XT.bat first.
  exit /b 11
)

if not exist "%COMFYUI_DIR%\custom_nodes" mkdir "%COMFYUI_DIR%\custom_nodes"

if not exist "%NODE_DIR%\.git" (
  echo [STEP] Cloning ComfyUI-Manager...
  git clone https://github.com/ltdrdata/ComfyUI-Manager.git "%NODE_DIR%"
  if errorlevel 1 exit /b 20
) else (
  echo [STEP] Updating ComfyUI-Manager...
  git -C "%NODE_DIR%" pull --ff-only
  if errorlevel 1 exit /b 21
)

if exist "%NODE_DIR%\requirements.txt" (
  echo [STEP] Installing ComfyUI-Manager requirements...
  "%PYTHON_EXE%" "%REPO_ROOT%\scripts\install_requirements_filtered.py" "%NODE_DIR%\requirements.txt"
  if errorlevel 1 exit /b 30
)

exit /b 0
