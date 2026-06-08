@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
color 07
SET PYTHON_PATH = ""
Title "Setup for YawStar SAC Manager"
cls

echo ========================================
echo      Setup for YawStar SAC Manager
echo            version 1.0.0.11
echo ========================================
echo.

:: Check Python installed
where python >nul 2>&1
if %errorlevel% equ 0 (
    python --version | find "3.11" >nul
    if !errorlevel! equ 0 (
        SET "PYTHON_PATH=python"
        echo [INFO] Python 3.11 is already installed.
        goto :check_venv
    )
) else if exist "%localappdata%\Programs\Python\Python311\python.exe" (
    echo [INFO] Python 3.11 is already installed.
    echo Task [1] --- Done.
    echo Task [2] --- Done.
    echo.
    goto :add_Python_PATH
) else (
    echo [WARNING] Python not found!
    goto :downloadPY
)


:: မရှိရင် Download လုပ်
:downloadPY
cls
echo [1] Downloading Python 3.11.9. Please wait...
powershell -Command "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe' -OutFile '%temp%\python-3.11.9-amd64.exe' -ErrorAction Stop
if %errorlevel% neq 0 (
    echo [ERROR] Download failed.
    echo.
    pause
    exit /b 1
) else (
    echo [INFO] Download successful
    echo Task [1] --- Done.
    echo.
    goto :installPY
)


:installPY
:: Python ကို စတင် Install လုပ်
echo [2] Installing Python 3.11.9. Please wait...
"%temp%\python-3.11.9-amd64.exe" /passive
if %errorlevel% neq 0 (
    echo [ERROR] Installation failed.
    echo.
    pause
    exit /b 1
) else (
    echo [INFO] Python install successful
    echo Task [2] --- Done.
    echo.
)
:: Download လုပ်ထားတဲ့ ဖိုင်ကို ဖျက်
del "%temp%\python-3.11.9-amd64.exe" 2>nul


:: Python PATH ကို Add
:add_Python_PATH
REM ရှိပြီးသား User PATH ကို ယူခြင်း
for /f "skip=2 tokens=1,2*" %%a in ('reg query HKCU\Environment /v PATH 2^>nul') do (
    if "%%a"=="PATH" SET "USER_PATH=%%c"
)

if not defined USER_PATH SET "USER_PATH="

REM Python PATH (environment variable ကို မဖြေဘဲ ထားရန်)
SET "PYTHON_PATH=%%LocalAppData%%\Programs\Python\Python311"

REM User PATH ထဲမှာ Python ရှိပြီးသားလား စစ်ဆေးခြင်း
echo %USER_PATH% | findstr /i "Python311" > nul
if %errorlevel% equ 0 (
    echo Python PATH already exist.
    echo Skip to add PATH.
    exit /b 0
)

REM နောက်ဆုံးမှာ ထည့်ခြင်း
if "%USER_PATH%"=="" (
    SET "NEW_PATH=%PYTHON_PATH%"
) else (
    SET "NEW_PATH=%USER_PATH%;%PYTHON_PATH%"
)

REM Registry ထဲသို့ ရေးခြင်း
reg add "HKCU\Environment" /v PATH /t REG_EXPAND_SZ /d "%NEW_PATH%" /f

echo Added Python PATH to User PATH
echo Open new Command Prompt



:: Virtual Enviroment ရှိမရှိစစ်ဆေး
:check_venv
if exist "venv\Scripts\activate.bat" ( 
    echo [INFO] Virtual environment 'venv' already created.
    echo Task [3] --- Done.
    echo.
    goto :activate_env :: ရှိရင် Activate လုပ်
) else if exist  "venv\bin\activate.bat" (
    echo [INFO] Virtual environment 'venv' already created.
    echo Task [3] --- Done.
    echo.
    goto :activate_env :: ရှိရင် Activate လုပ်
) else (
    goto :create_venv :: မရှိရင် Virtual Enviroment ဖန်တီး
)


:: Virtual Enviroment ကို ဖန်တီး
:create_venv
echo [3] Creating virtual environment (venv). Please wait...
"%PYTHON_PATH%" -m venv venv
if %errorlevel% neq 0 (
    echo [ERROR] Failed to create virtual environment.
    pause
    exit /b 1
)
echo [SUCCESS] Virtual environment 'venv' created.
echo Task [3] --- Done.
echo.


:: Virtual Enviroment ကို Activate လုပ်
:activate_env
echo [4] Activating virtual environment...
if exist venv\Scripts\activate.bat (
    call venv\Scripts\activate.bat
) else (
    call venv\bin\activate.bat
)
echo [SUCCESS] Virtual environment activated!
echo Task [4] --- Done.
echo.


:: Requirement.txt ဖိုင် ရှိလားစစ်
echo [5] Checking for requirements.txt...
if exist "requirements.txt" (
    echo [INFO] requirements.txt found.
    echo Task [5] --- Done.
    echo.
    goto :checkDependencies
) else (
    echo [INFO] Downloading requirements.txt.. Please wait...
    timeout /t 3 /nobreak >nul
    powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/YawStar/yawstar-sac-manager/refs/heads/main/requirements.txt' -OutFile '%~dp0requirements.txt'" -ErrorAction Stop
    if %errorlevel% neq 0 (
        echo [ERROR] Download failed.
        pause
        exit /b 1
    )
    echo Task [5] --- Done.
    echo.
    goto :checkDependencies
)


:: Check Dependencies
:checkDependencies
echo [INFO] Checking Dependencies. Please wait...
pip list | findstr /i "customtkiter Pillow pystray"

if !errorlevel! equ 0 (
    goto :checkYS_SAC_Manager_Script
) else (
    goto :installDependencies
)


:installDependencies
echo [6] Installing packages. Please wait...
echo.
pip install -r requirements.txt
if !errorlevel! equ 0 (
    echo [SUCCESS] All packages installed successfully!
    echo Task [6] --- Done.
    echo.
) else (
    echo [WARNING] Some packages failed to install. Check errors above.
    echo.
)
:: echo [INFO] Installed Packages:
:: pip list


:: Check if Python script exists
:checkYS_SAC_Manager_Script
if not exist "YS_SAC_Manager.py" (
   echo [7] Downloading YS_SAC_Manager script. Please wait...
   timeout /t 3 /nobreak >nul
   powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/YawStar/yawstar-sac-manager/refs/heads/main/YS_SAC_Manager.py' -OutFile '%~dp0YS_SAC_Manager.py'" -ErrorAction Stop
    if %errorlevel% neq 0 (
        echo [ERROR] Download failed.
        pause
        exit /b 1
    )
    echo Task [7] --- Done.
    echo.
)

if not exist "Assets" (
    mkdir "Assets"
)
if not exist "%~dp0Assets/Main_Icon.ico" (
    echo [8] Downloading Main_Icon.ico. Please wait...
    timeout /t 1 /nobreak >nul
    powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/YawStar/yawstar-sac-manager/refs/heads/main/Assets/Main_Icon.ico' -OutFile '%~dp0Assets/Main_Icon.ico'" -ErrorAction Stop
    if %errorlevel% neq 0 (
        echo [ERROR] Download failed.
        pause
        exit /b 1
    ) else (
        echo Task [8] --- Done.
        echo.
    )
)


if not exist "%~dp0Assets/PyidaungSu.ttf" (
    echo [9] Downloading PyidaungSu.ttf. Please wait...
    timeout /t 1 /nobreak >nul
    powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/YawStar/yawstar-sac-manager/refs/heads/main/Assets/PyidaungSu.ttf' -OutFile '%~dp0Assets/PyidaungSu.ttf'" -ErrorAction Stop
    if %errorlevel% neq 0 (
        echo [ERROR] Download failed.
        pause
        exit /b 1
    ) else (
        echo Task [9] --- Done.
        echo.
    )
)

:: Check if Python script exists
if not exist "YS_SAC_Manager.py" (
    color 04
	echo [ERROR] "YS_SAC_Manager.py" not found!
    pause
    exit /b 1
)

if not exist "Launcher.bat" (
    echo [10] Downloading Launcher.bat. Please wait...
    timeout /t 1 /nobreak >nul
    powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/YawStar/yawstar-sac-manager/refs/heads/main/Launcher.bat' -OutFile '%~dp0Launcher.bat'" -ErrorAction Stop
    if %errorlevel% neq 0 (
        echo [ERROR] Download failed.
        pause
        exit /b 1
    ) else (
        echo Task [10] --- Done.
        echo.
        echo ========================================
        echo             Setup Complete!
        echo ========================================
        timeout /t 3 /nobreak >nul
        Launcher.bat
    )
) else (
    echo.
    echo ========================================
    echo             Setup Complete!
    echo ========================================
    timeout /t 3 /nobreak >nul
    Launcher.bat
)
exit /b 0


:refresh_env
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SysPath=%%b"
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "UserPath=%%b"
set "PATH=%SysPath%;%UserPath%"
exit /b
