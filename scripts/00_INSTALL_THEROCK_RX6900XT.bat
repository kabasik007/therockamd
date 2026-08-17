@echo off
setlocal

set "VENV=.venv_therock"
set "PY=%VENV%\Scripts\python.exe"

echo ============================================================
echo TheRock AMD Bootstrap - RX 6900 XT / gfx1030 / Windows
echo ============================================================
echo.

where py >nul 2>nul || (
  echo [FAIL] Python launcher ^(py.exe^) not found.
  exit /b 10
)

py -3.12 -c "import sys; print(sys.version)" || (
  echo [FAIL] Python 3.12 x64 is required for this baseline.
  exit /b 11
)

if not exist "%PY%" (
  echo [1/4] Creating %VENV% ...
  py -3.12 -m venv "%VENV%" || exit /b 20
) else (
  echo [1/4] Existing %VENV% found; preserving it.
)

echo [2/4] Updating pip...
"%PY%" -m pip install --upgrade pip || exit /b 30

echo [3/4] Installing AMD TheRock PyTorch for gfx1030...
"%PY%" -m pip install --upgrade --index-url https://rocm.nightlies.amd.com/whl-multi-arch/ "torch[device-gfx1030]" "torchvision[device-gfx1030]" || exit /b 40

echo [4/4] Running doctor...
"%PY%" scripts\doctor.py || exit /b 50

echo.
echo [PASS] TheRock AMD environment is ready.
echo Freeze it before application installs:
echo   "%PY%" -m pip freeze ^> requirements-known-good.txt
exit /b 0
