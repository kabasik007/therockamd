@echo off
setlocal EnableExtensions DisableDelayedExpansion

for %%I in ("%~dp0..") do set "REPO_ROOT=%%~fI"
set "LOG_DIR=%REPO_ROOT%\logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

if /I "%~1"=="worker" goto :worker
rem IMPORTANT: do NOT SHIFT here. SHIFT also shifts %%0 and would erase %%~f0.

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%I"
if not defined STAMP set "STAMP=unknown_time"
set "LOG_FILE=%LOG_DIR%\setup_%STAMP%.log"

cls
echo ============================================================
echo TheRock AMD Bootstrap - ComfyUI SETUP
echo RX 6900 XT / gfx1030 / TheRock
echo ============================================================
echo.
echo Log file:
echo   %LOG_FILE%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_bat_logged.ps1" -BatPath "%~f0" -LogPath "%LOG_FILE%"
set "RC=%ERRORLEVEL%"

echo.
if "%RC%"=="0" (
    echo ============================================================
    echo [SUCCESS] Setup finished successfully.
    echo ============================================================
) else (
    echo ============================================================
    echo [FAILED] Setup stopped with exit code %RC%.
    echo ============================================================
    echo.
    echo Full log:
    echo   %LOG_FILE%
    echo.
    echo ---------------- LAST 80 LOG LINES ----------------
    powershell -NoProfile -Command "if (Test-Path -LiteralPath $env:LOG_FILE) { Get-Content -LiteralPath $env:LOG_FILE -Tail 80 } else { Write-Host 'Log file was not created.' }"
    echo ---------------------------------------------------
)

echo.
echo CMD WILL NOT CLOSE AUTOMATICALLY.
echo Copy the error above or send the log file if something failed.
echo.
pause
exit /b %RC%

:worker
set "WORK_ROOT=%REPO_ROOT%\workspace\comfyui"
set "VENV_DIR=%WORK_ROOT%\.venv"
set "COMFYUI_DIR=%WORK_ROOT%\ComfyUI"
set "PYTHON_EXE=%VENV_DIR%\Scripts\python.exe"

echo.
echo ============================================================
echo TheRock AMD Bootstrap - ComfyUI setup worker
echo REPO_ROOT   = %REPO_ROOT%
echo WORK_ROOT   = %WORK_ROOT%
echo VENV_DIR    = %VENV_DIR%
echo COMFYUI_DIR = %COMFYUI_DIR%
echo ============================================================
echo.

where git >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Git is not installed or not in PATH.
  exit /b 10
)

echo [CHECK] Git:
where git

echo.
echo [CHECK] Python 3.12:
py -3.12 -V
if errorlevel 1 (
  echo [ERROR] Python 3.12 launcher target not found.
  echo Install Python 3.12 x64 and ensure the Windows launcher ^(py.exe^) works.
  exit /b 11
)

if not exist "%WORK_ROOT%" mkdir "%WORK_ROOT%"
if errorlevel 1 exit /b 12
if not exist "%WORK_ROOT%\downloads" mkdir "%WORK_ROOT%\downloads"
if errorlevel 1 exit /b 13

if not exist "%PYTHON_EXE%" (
  echo.
  echo [STEP] Creating Python 3.12 venv...
  py -3.12 -m venv "%VENV_DIR%"
  if errorlevel 1 (
    echo [ERROR] Failed to create venv.
    exit /b 20
  )
) else (
  echo [INFO] Existing venv found: %VENV_DIR%
)

echo.
echo [CHECK] Venv Python:
"%PYTHON_EXE%" -V
if errorlevel 1 exit /b 21

echo.
echo [STEP] Upgrading pip/setuptools/wheel...
"%PYTHON_EXE%" -m pip install --upgrade pip setuptools wheel
if errorlevel 1 (
  echo [ERROR] pip bootstrap failed.
  exit /b 30
)

echo.
echo [STEP] Installing TheRock PyTorch + torchvision + torchaudio for gfx1030...
echo [INFO] Index: https://rocm.nightlies.amd.com/whl-multi-arch/
"%PYTHON_EXE%" -m pip install --upgrade --index-url https://rocm.nightlies.amd.com/whl-multi-arch/ "torch[device-gfx1030]" "torchvision[device-gfx1030]" torchaudio
if errorlevel 1 (
  echo [ERROR] TheRock PyTorch installation failed.
  exit /b 40
)

if not exist "%COMFYUI_DIR%\.git" (
  echo.
  echo [STEP] Cloning ComfyUI...
  git clone https://github.com/Comfy-Org/ComfyUI.git "%COMFYUI_DIR%"
  if errorlevel 1 (
    echo [ERROR] ComfyUI clone failed.
    exit /b 50
  )
) else (
  echo.
  echo [STEP] Updating existing ComfyUI checkout...
  git -C "%COMFYUI_DIR%" pull --ff-only
  if errorlevel 1 (
    echo [ERROR] ComfyUI git pull failed.
    exit /b 51
  )
)

echo.
echo [STEP] Installing ComfyUI requirements without overriding TheRock torch...
"%PYTHON_EXE%" "%REPO_ROOT%\scripts\install_requirements_filtered.py" "%COMFYUI_DIR%\requirements.txt"
if errorlevel 1 (
  echo [ERROR] ComfyUI requirements installation failed.
  exit /b 60
)

echo.
echo [STEP] Running AMD doctor...
"%PYTHON_EXE%" "%REPO_ROOT%\scripts\doctor.py"
if errorlevel 1 (
  echo [ERROR] doctor.py failed. Stop here and investigate before using ComfyUI.
  exit /b 70
)

echo.
echo [STEP] Creating common model directories...
if not exist "%COMFYUI_DIR%\models\checkpoints" mkdir "%COMFYUI_DIR%\models\checkpoints"
if not exist "%COMFYUI_DIR%\models\loras" mkdir "%COMFYUI_DIR%\models\loras"
if not exist "%COMFYUI_DIR%\models\controlnet" mkdir "%COMFYUI_DIR%\models\controlnet"
if not exist "%COMFYUI_DIR%\models\text_encoders" mkdir "%COMFYUI_DIR%\models\text_encoders"
if not exist "%COMFYUI_DIR%\models\diffusion_models" mkdir "%COMFYUI_DIR%\models\diffusion_models"
if not exist "%COMFYUI_DIR%\models\vae" mkdir "%COMFYUI_DIR%\models\vae"
if not exist "%COMFYUI_DIR%\models\clip_vision" mkdir "%COMFYUI_DIR%\models\clip_vision"
if not exist "%COMFYUI_DIR%\models\ipadapter" mkdir "%COMFYUI_DIR%\models\ipadapter"
if not exist "%COMFYUI_DIR%\models\upscale_models" mkdir "%COMFYUI_DIR%\models\upscale_models"
if not exist "%COMFYUI_DIR%\input" mkdir "%COMFYUI_DIR%\input"
if not exist "%COMFYUI_DIR%\output" mkdir "%COMFYUI_DIR%\output"

echo.
echo [SUCCESS] Base ComfyUI setup worker finished.
echo.
echo Next:
echo   1. Optional: run scripts\12_INSTALL_COMFYUI_MANAGER.bat
echo   2. Optional: run scripts\13_INSTALL_BASIC_CUSTOM_NODES.bat
echo   3. Optional Z-Image-Turbo: run scripts\14_INSTALL_Z_IMAGE_TURBO_MODELS.bat
echo   4. Launch with scripts\11_LAUNCH_COMFYUI_RX6900XT.bat
exit /b 0
