@echo off
setlocal EnableExtensions DisableDelayedExpansion

for %%I in ("%~dp0..") do set "REPO_ROOT=%%~fI"
set "LOG_DIR=%REPO_ROOT%\logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

if /I "%~1"=="worker" goto :worker
rem IMPORTANT: do NOT SHIFT here. SHIFT also shifts %%0 and would erase %%~f0.

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%I"
if not defined STAMP set "STAMP=unknown_time"
set "LOG_FILE=%LOG_DIR%\z_image_turbo_models_%STAMP%.log"

cls
echo ============================================================
echo TheRock AMD Bootstrap - Z-Image-Turbo MODEL INSTALLER
echo RX 6900 XT / ComfyUI
echo ============================================================
echo.
echo Downloads the OFFICIAL Comfy-Org Z-Image-Turbo model files.
echo Total full package: about 20.7 GB ^(19.27 GiB^).
echo Existing complete files are reused.
echo Interrupted .part files are resumed automatically.
echo.
echo Log file:
echo   %LOG_FILE%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_bat_logged.ps1" -BatPath "%~f0" -LogPath "%LOG_FILE%"
set "RC=%ERRORLEVEL%"

echo.
if "%RC%"=="0" (
    echo ============================================================
    echo [SUCCESS] Z-Image-Turbo model package is ready.
    echo ============================================================
    echo.
    echo Restart ComfyUI, reopen the Z-Image-Turbo template, and refresh models.
) else (
    echo ============================================================
    echo [FAILED] Model installer stopped with exit code %RC%.
    echo ============================================================
    echo.
    echo Partial downloads were NOT deleted; rerun this BAT to resume.
    echo Full log:
    echo   %LOG_FILE%
)

echo.
echo CMD WILL NOT CLOSE AUTOMATICALLY.
echo.
pause
exit /b %RC%

:worker
set "WORK_ROOT=%REPO_ROOT%\workspace\comfyui"
set "COMFYUI_DIR=%WORK_ROOT%\ComfyUI"
set "MODELS_DIR=%COMFYUI_DIR%\models"

if not exist "%COMFYUI_DIR%\main.py" (
  echo [ERROR] ComfyUI is not installed at:
  echo   %COMFYUI_DIR%
  echo Run scripts\10_SETUP_COMFYUI_RX6900XT.bat first.
  exit /b 10
)

where curl.exe >nul 2>nul
if errorlevel 1 (
  echo [ERROR] curl.exe was not found. Windows 11 normally includes it.
  exit /b 11
)

if not exist "%MODELS_DIR%\text_encoders" mkdir "%MODELS_DIR%\text_encoders"
if not exist "%MODELS_DIR%\diffusion_models" mkdir "%MODELS_DIR%\diffusion_models"
if not exist "%MODELS_DIR%\vae" mkdir "%MODELS_DIR%\vae"

echo [INFO] Source : https://huggingface.co/Comfy-Org/z_image_turbo
echo [INFO] Required files:
echo   text_encoders\qwen_3_4b.safetensors              8,044,982,048 bytes
echo   diffusion_models\z_image_turbo_bf16.safetensors 12,309,866,400 bytes
echo   vae\ae.safetensors                               335,304,388 bytes

call :download_model "Qwen 3 4B text encoder" "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors" "%MODELS_DIR%\text_encoders\qwen_3_4b.safetensors" "8044982048" "6c671498573ac2f7a5501502ccce8d2b08ea6ca2f661c458e708f36b36edfc5a"
if errorlevel 1 exit /b 30

call :download_model "Z-Image-Turbo BF16 diffusion model" "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors" "%MODELS_DIR%\diffusion_models\z_image_turbo_bf16.safetensors" "12309866400" "2407613050b809ffdff18a4ac99af83ea6b95443ecebdf80e064a79c825574a6"
if errorlevel 1 exit /b 31

call :download_model "Z-Image VAE" "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors" "%MODELS_DIR%\vae\ae.safetensors" "335304388" "afc8e28272cd15db3919bacdb6918ce9c1ed22e96cb12c4d5ed0fba823529e38"
if errorlevel 1 exit /b 32

echo [SUCCESS] All official Z-Image-Turbo files are installed.
exit /b 0

:download_model
set "MODEL_LABEL=%~1"
set "MODEL_URL=%~2"
set "MODEL_DEST=%~3"
set "MODEL_BYTES=%~4"
set "MODEL_SHA256=%~5"
set "MODEL_PART=%MODEL_DEST%.part"

echo.
echo [MODEL] %MODEL_LABEL%

if exist "%MODEL_DEST%" (
  call :check_size "%MODEL_DEST%" "%MODEL_BYTES%"
  if not errorlevel 1 (
    echo [OK] Complete file already exists. Skipping download.
    if /I "%THEROCKAMD_FULL_VERIFY%"=="1" call :verify_hash "%MODEL_DEST%" "%MODEL_SHA256%"
    if errorlevel 1 exit /b 1
    exit /b 0
  )
  echo [WARN] Existing final file has the wrong size. Preserving it as .bad_TIMESTAMP.
  call :quarantine_file "%MODEL_DEST%" "bad"
  if errorlevel 1 exit /b 1
)

if exist "%MODEL_PART%" (
  for %%F in ("%MODEL_PART%") do echo [INFO] Resuming partial file at %%~zF bytes.
) else (
  echo [INFO] Starting new download.
)

curl.exe --fail --location --retry 8 --retry-delay 5 --retry-all-errors --continue-at - --output "%MODEL_PART%" "%MODEL_URL%"
if errorlevel 1 (
  echo [ERROR] curl failed. Partial file preserved for resume.
  exit /b 1
)

call :check_size "%MODEL_PART%" "%MODEL_BYTES%"
if errorlevel 1 exit /b 1

call :verify_hash "%MODEL_PART%" "%MODEL_SHA256%"
if errorlevel 1 (
  echo [ERROR] SHA-256 mismatch. Download is not trusted.
  call :quarantine_file "%MODEL_PART%" "corrupt"
  exit /b 1
)

move /y "%MODEL_PART%" "%MODEL_DEST%" >nul
if errorlevel 1 exit /b 1
echo [OK] Installed and verified.
exit /b 0

:check_size
set "SIZE_FILE=%~1"
set "SIZE_EXPECTED=%~2"
if not exist "%SIZE_FILE%" exit /b 1
for %%F in ("%SIZE_FILE%") do set "SIZE_ACTUAL=%%~zF"
if "%SIZE_ACTUAL%"=="%SIZE_EXPECTED%" (
  echo [CHECK] Size PASS: %SIZE_ACTUAL% bytes
  exit /b 0
)
echo [CHECK] Size FAIL: got %SIZE_ACTUAL%, expected %SIZE_EXPECTED% bytes
exit /b 1

:verify_hash
set "HASH_FILE=%~1"
set "HASH_EXPECTED=%~2"
for /f "usebackq delims=" %%H in (`powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 -LiteralPath $env:HASH_FILE).Hash.ToLowerInvariant()"`) do set "HASH_ACTUAL=%%H"
if /I "%HASH_ACTUAL%"=="%HASH_EXPECTED%" (
  echo [CHECK] SHA-256 PASS
  exit /b 0
)
echo [CHECK] SHA-256 FAIL
echo [CHECK] Expected: %HASH_EXPECTED%
echo [CHECK] Actual  : %HASH_ACTUAL%
exit /b 1

:quarantine_file
set "QUARANTINE_SOURCE=%~1"
set "QUARANTINE_TAG=%~2"
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "QUARANTINE_STAMP=%%I"
if not defined QUARANTINE_STAMP set "QUARANTINE_STAMP=unknown"
set "QUARANTINE_DEST=%QUARANTINE_SOURCE%.%QUARANTINE_TAG%_%QUARANTINE_STAMP%"
move /y "%QUARANTINE_SOURCE%" "%QUARANTINE_DEST%" >nul
if errorlevel 1 exit /b 1
echo [INFO] Preserved as: %QUARANTINE_DEST%
exit /b 0
