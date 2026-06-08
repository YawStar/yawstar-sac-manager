@echo off
cls
title YawStar SAC Manager Launcher
:: color 0A
cd /d "%~dp0"

echo ========================================
echo         YawStar SAC Manager Launcher
echo             version 1.0.0.11
echo ========================================
echo.

:: Check if Powershell installed
where powershell

if %errorlevel% equ 1 (
    color 04
	echo [ERROR] 'Powershell' not found!
    echo Please download Powershell first.
    pause
    exit /b 1
)

:: Check if Main_Icon.ico exists
if not exist "Assets\Main_Icon.ico" (
    color 04
	echo [ERROR] 'Assets\Main_Icon.ico' file not found!
    echo Please download and execute setup.bat first
    timeout /t 1 /nobreak >nul
    call :DownloadSetup
    exit /b 1
)

:: Check if PyidaungSu.ttf exists
if not exist "Assets\PyidaungSu.ttf" (
    color 04
	echo [ERROR] 'Assets\PyidaungSu.ttf' file not found!
    echo Please download and execute setup.bat first
    timeout /t 3 /nobreak >nul
    exit /b 1
)

:: Check if venv exists
if not exist "venv\Scripts\Activate.bat" (
    color 04
    echo [ERROR] Virtual environment not found!
    echo Please download and execute setup.bat first
    timeout /t 3 /nobreak >nul
    exit /b 1
)

:: Check if Python script exists
if not exist "YS_SAC_Manager.py" (
    ::color 04
	echo [ERROR] "YS_SAC_Manager.py" not found!
)

:: Activate and run
color 0A
echo [OK] Assets found.
echo [OK] Powershell.exe found.
echo [OK] Virtual environment found.
echo [OK] Main Script found.
echo [OK] Starting YawStar SAC Manager...
echo.

:: venv ထဲက pythonw.exe ကို သုံးပြီး Background မှာ Run
start "" "venv\Scripts\pythonw.exe" "YS_SAC_Manager.py"
exit /b 0

:DownloadSetup
echo [INFO] Downloading Setup.bat.. Please wait...
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/YawStar/yawstar-sac-manager/refs/heads/main/Setup.bat' -OutFile '%~dp0Setup.bat'" -ErrorAction Stop
if %errorlevel% neq 0 (
    echo [ERROR] Download failed.
    exit /b 1
) else (
    Setup.bat
    exit /b 1
)
