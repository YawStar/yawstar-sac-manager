@echo off
title YawStar SAC Manager Launcher
:: color 0A

cd /d "%~dp0"

echo ========================================
echo         YawStar SAC Manager Launcher
echo             version 1.0.0.10
echo ========================================
echo.

:: Check if venv exists
if not exist ".\venv\Scripts\Activate.ps1" (
    color 04
	echo [ERROR] Virtual environment not found!
    echo Please create venv first: python -m venv venv
    pause
    exit /b 1
)

:: Check if Python script exists
if not exist "YS_SAC_Manager.py" (
    color 04
	echo [ERROR] "YS_SAC_Manager.py" not found!
    pause
    exit /b 1
)

:: Activate and run
color 0A
echo [OK] Virtual environment found.
echo [OK] Starting SAC Manager...
echo.

:: venv ထဲက pythonw.exe ကို သုံးပြီး Background မှာ Run
start "" ".\venv\Scripts\pythonw.exe" "YS_SAC_Manager.py"

exit /b 0