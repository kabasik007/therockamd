@echo off
setlocal EnableExtensions DisableDelayedExpansion

for %%I in ("%~dp0..") do set "REPO_ROOT=%%~fI"
set "LOG_DIR=%REPO_ROOT%\logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

if /I "%~1"=="worker" goto :worker
rem IMPORTANT: do NOT SHIFT here. SHIFT also shifts %%0 and would erase %%~f0.

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%I"
if not defined STAMP set "STAMP=unknown_time"
set "LOG_FILE=%LOG_DIR%\comfyui_%STAMP%.log"

echo ============================================================
echo TheRock AMD Bootstrap - ComfyUI LAUNCH
echo Log: %LOG_FILE%
echo ============================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_bat_logged.ps1" -BatPath "%~f0" -LogPath "%LOG_FILE%"
set "RC=%ERRORLEVEL%"

echo.
if not "%RC%"=="0" (
    echo [FAILED] ComfyUI exited with code %RC%.
    echo Full log: %LOG_FILE%
    echo.
    echo ---------------- LAST 80 LOG LINES ----------------
    powershell -NoProfile -Command "if (Test-Path -LiteralPath $env:LOG_FILE) { Get-Content -LiteralPath $env:LOG_FILE -Tail 80 }"
    echo ---------------------------------------------------
) else (
    echo [INFO] ComfyUI exited normally.
)

echo.
echo CMD WILL NOT CLOSE AUTOMATICALLY.
pause
exit /b %RC%

:worker
set "WORK_ROOT=%REPO_ROOT%\workspace\comfyui"
set "VENV_DIR=%WORK_ROOT%\.venv"
set "COMFYUI_DIR=%WORK_ROOT%\ComfyUI"
set "PYTHON_EXE=%VENV_DIR%\Scripts\python.exe"
set "HOST=127.0.0.1"
set "PORT=8188"

if not exist "%PYTHON_EXE%" (
  echo [ERROR] Venv not found. Run scripts\10_SETUP_COMFYUI_RX6900XT.bat first.
  exit /b 10
)

if not exist "%COMFYUI_DIR%\main.py" (
  echo [ERROR] ComfyUI is not installed. Run scripts\10_SETUP_COMFYUI_RX6900XT.bat first.
  exit /b 11
)

echo [CHECK] Port %PORT% preflight...
powershell -NoProfile -ExecutionPolicy Bypass -File "%REPO_ROOT%\scripts\check_comfyui_port.ps1" -Port %PORT% -RepoRoot "%REPO_ROOT%"
if errorlevel 1 (
  echo [ERROR] Refusing to start a second ComfyUI instance.
  echo [INFO] Run STOP_COMFYUI.bat from the Bootstrap root, then launch again.
  exit /b 14
)

echo [CHECK] torchaudio...
"%PYTHON_EXE%" -c "import torchaudio; print('torchaudio:', torchaudio.__version__)"
if errorlevel 1 (
  echo [WARN] torchaudio is missing or broken. Repairing from TheRock multi-arch index...
  "%PYTHON_EXE%" -m pip install --upgrade --index-url https://rocm.nightlies.amd.com/whl-multi-arch/ "torch[device-gfx1030]" "torchvision[device-gfx1030]" torchaudio
  if errorlevel 1 (
    echo [ERROR] torchaudio repair failed.
    exit /b 12
  )
  echo [CHECK] torchaudio after repair...
  "%PYTHON_EXE%" -c "import torchaudio; print('torchaudio:', torchaudio.__version__)"
  if errorlevel 1 (
    echo [ERROR] torchaudio still cannot be imported after repair.
    exit /b 13
  )
)

echo.
echo [STEP] Running AMD doctor before launch...
"%PYTHON_EXE%" "%REPO_ROOT%\scripts\doctor.py"
if errorlevel 1 (
  echo [ERROR] doctor.py failed. Refusing to launch ComfyUI.
  exit /b 20
)

echo.
echo [INFO] Launching ComfyUI on http://%HOST%:%PORT%/
echo [INFO] To stop ComfyUI reliably, run STOP_COMFYUI.bat from the Bootstrap root.
echo.
cd /d "%COMFYUI_DIR%"
"%PYTHON_EXE%" main.py --listen %HOST% --port %PORT%
set "RC=%ERRORLEVEL%"
echo.
echo [INFO] ComfyUI process returned exit code %RC%.
exit /b %RC%
