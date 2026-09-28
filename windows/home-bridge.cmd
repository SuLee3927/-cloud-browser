@echo off
rem ============================================================
rem  Cloud Browser Bridge - home side (Windows)
rem  1) starts a dedicated Chrome (separate profile, for automation)
rem  2) tunnels that Chrome's debug port back to your server
rem  3) optionally tunnels the local ADB server for emulator / USB devices
rem  Auto-reconnects. To stop: close the Chrome window, then close this window.
rem ============================================================
setlocal

rem ---- EDIT THESE THREE LINES ----
set "SERVER=user@your-server.example.com"
set "PORT=22"
set "KEY=%USERPROFILE%\.ssh\cloudbrowser"

rem ---- OPTIONAL ANDROID BRIDGE ----
rem Set to 1 only after Android platform-tools is installed and `adb devices` works.
set "ENABLE_ANDROID=0"
set "ADB_EXE=adb"
set "ADB_LOCAL_PORT=5037"
set "ADB_REMOTE_PORT=5039"

set "PROFILE=%LOCALAPPDATA%\cloudbrowser-chrome"
set "REMOTE_PORT=9223"
set "LOCAL_PORT=9222"
set "FORWARD_ARGS=-R %REMOTE_PORT%:127.0.0.1:%LOCAL_PORT%"

if not exist "%KEY%" (
  echo [ERROR] key not found: %KEY%
  echo Run this first: ssh-keygen -t ed25519 -f "%KEY%" -N "" -C cloud-browser
  pause
  exit /b 1
)

set "CHROME="
for %%P in (
  "C:\Program Files\Google\Chrome\Application\chrome.exe"
  "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
  "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
) do if not defined CHROME if exist %%P set "CHROME=%%~P"
if not defined CHROME (
  echo [ERROR] Chrome not found. Install Chrome and run this again.
  pause
  exit /b 1
)

if "%ENABLE_ANDROID%"=="1" (
  "%ADB_EXE%" version >nul 2>&1
  if errorlevel 1 (
    echo [ERROR] adb not found: %ADB_EXE%
    echo Install Android platform-tools, or set ADB_EXE to the full path of adb.exe.
    pause
    exit /b 1
  )
  echo [android] starting local ADB server ...
  "%ADB_EXE%" start-server
  "%ADB_EXE%" devices -l
  set "FORWARD_ARGS=%FORWARD_ARGS% -R %ADB_REMOTE_PORT%:127.0.0.1:%ADB_LOCAL_PORT%"
)

echo [1/2] starting Chrome on port %LOCAL_PORT% ...
if not exist "%PROFILE%" mkdir "%PROFILE%"
start "" "%CHROME%" --remote-debugging-port=%LOCAL_PORT% --user-data-dir="%PROFILE%" --no-first-run --no-default-browser-check

echo [2/2] opening tunnel to %SERVER% ...
echo       keep this window open while the server is browsing.
:loop
ssh -i "%KEY%" -p %PORT% -N -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o StrictHostKeyChecking=accept-new %FORWARD_ARGS% %SERVER%
echo [%date% %time%] tunnel dropped, reconnecting in 5s ...
timeout /t 5 /nobreak >/dev/null
goto loop
