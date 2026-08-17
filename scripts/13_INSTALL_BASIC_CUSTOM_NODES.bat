@echo off
setlocal EnableExtensions DisableDelayedExpansion

for %%I in ("%~dp0..") do set "REPO_ROOT=%%~fI"
set "LOG_DIR=%REPO_ROOT%\logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

if /I "%~1"=="worker" goto :worker
rem IMPORTANT: do NOT SHIFT here. SHIFT also shifts %%0 and would erase %%~f0.

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%I"
if not defined STAMP set "STAMP=unknown_time"
set "LOG_FILE=%LOG_DIR%\custom_nodes_%STAMP%.log"

echo [INFO] Logging to %LOG_FILE%
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_bat_logged.ps1" -BatPath "%~f0" -LogPath "%LOG_FILE%"
set "RC=%ERRORLEVEL%"

echo.
if not "%RC%"=="0" (
  echo [FAILED] Custom node install failed with code %RC%.
  echo ---------------- LAST 80 LOG LINES ----------------
  powershell -NoProfile -Command "if (Test-Path -LiteralPath $env:LOG_FILE) { Get-Content -LiteralPath $env:LOG_FILE -Tail 80 }"
  echo ---------------------------------------------------
) else (
  echo [SUCCESS] Basic custom nodes installed.
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
set "CUSTOM_NODES_DIR=%COMFYUI_DIR%\custom_nodes"

if not exist "%PYTHON_EXE%" (
  echo [ERROR] Base environment not found. Run scripts\10_SETUP_COMFYUI_RX6900XT.bat first.
  exit /b 10
)

where git >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Git is not installed or not in PATH.
  exit /b 11
)

if not exist "%CUSTOM_NODES_DIR%" mkdir "%CUSTOM_NODES_DIR%"

call :install_node "https://github.com/Fannovel16/comfyui_controlnet_aux.git" "comfyui_controlnet_aux"
if errorlevel 1 exit /b 20

call :install_node "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git" "ComfyUI_IPAdapter_plus"
if errorlevel 1 exit /b 21

exit /b 0

:install_node
set "NODE_URL=%~1"
set "NODE_NAME=%~2"
set "NODE_PATH=%CUSTOM_NODES_DIR%\%NODE_NAME%"

echo.
echo [STEP] %NODE_NAME%
if not exist "%NODE_PATH%\.git" (
  git clone "%NODE_URL%" "%NODE_PATH%"
  if errorlevel 1 exit /b 1
) else (
  git -C "%NODE_PATH%" pull --ff-only
  if errorlevel 1 exit /b 1
)

if exist "%NODE_PATH%\requirements.txt" (
  "%PYTHON_EXE%" "%REPO_ROOT%\scripts\install_requirements_filtered.py" "%NODE_PATH%\requirements.txt"
  if errorlevel 1 exit /b 1
)
exit /b 0
