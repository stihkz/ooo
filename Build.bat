@echo off
rem Copyright (c) 2026 Celestial
rem Licensed under the PolyForm Noncommercial License 1.0.0. See LICENSE.md.
rem Points Module.cpp at the server and builds Injector, Module and Launcher (Release x64).
rem Usage: Build.bat [server ip] [NBA 2K19 folder]   (default ip 23.26.135.133)
rem Creates Path.txt beside Launcher.exe if it is missing; an existing one is never overwritten.
setlocal EnableExtensions

rem Tells InstallVS.bat it is being called, so only this script decides when to pause.
set "GRANITE_BUILD=1"
set "DOUBLE_CLICKED="
echo %cmdcmdline% | find /i "%~nx0" >nul && set "DOUBLE_CLICKED=1"

set "SERVER_IP=%~1"
if not defined SERVER_IP set "SERVER_IP=23.26.135.133"

set "ROOT=%~dp0"
set "MODULE_CPP=%ROOT%Granite\Module\Module.cpp"
set "SOLUTION=%ROOT%Granite\Granite.sln"
set "OUTPUT=%ROOT%Granite\Build\Release"

if not exist "%MODULE_CPP%" (
  echo [ERROR] Module.cpp was not found: %MODULE_CPP%
  goto :Fail
)

call "%ROOT%InstallVS.bat"
if errorlevel 1 goto :Fail

if not exist "%MODULE_CPP%.bak" copy /y "%MODULE_CPP%" "%MODULE_CPP%.bak" >nul

powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%SetRedirectHost.ps1" "%MODULE_CPP%" "%SERVER_IP%"
if errorlevel 1 (
  echo [ERROR] Could not set RedirectHost in Module.cpp ^(missing line or bad IP^).
  goto :Fail
)
echo [INFO] RedirectHost set to %SERVER_IP%

set "PATH_FILE=%OUTPUT%\Path.txt"
set "PATH_KEEP=%TEMP%\Granite_Path.txt"
if exist "%PATH_FILE%" copy /y "%PATH_FILE%" "%PATH_KEEP%" >nul

"%MSBUILD%" "%SOLUTION%" -p:Configuration=Release -p:Platform=x64 -t:Rebuild -m -nologo -v:minimal
set "BUILD_RESULT=%errorlevel%"

rem Restore even on a failed build so Path.txt is never lost.
if exist "%PATH_KEEP%" (
  if not exist "%OUTPUT%" mkdir "%OUTPUT%"
  if not exist "%PATH_FILE%" copy /y "%PATH_KEEP%" "%PATH_FILE%" >nul
  del "%PATH_KEEP%" >nul 2>nul
)

if not "%BUILD_RESULT%"=="0" (
  echo [ERROR] Build failed.
  goto :Fail
)

for %%F in (Injector.exe Module.dll Launcher.exe) do (
  if not exist "%OUTPUT%\%%F" (
    echo [ERROR] Missing build output: %OUTPUT%\%%F
    goto :Fail
  )
)

if exist "%PATH_FILE%" goto :PathReady
set "GAME_DIR=%~2"
if defined GAME_DIR goto :WritePath
set "GAME_DIR=F:\NBA 2K19"
set /p "GAME_DIR=NBA 2K19 folder [%GAME_DIR%]: "

:WritePath
if not exist "%GAME_DIR%\NBA2K19.exe" echo [WARN] NBA2K19.exe was not found in %GAME_DIR% - Path.txt is written anyway.
>"%PATH_FILE%" echo %GAME_DIR%
echo [INFO] Created %PATH_FILE%

:PathReady
echo.
echo [DONE] Built Injector.exe, Module.dll and Launcher.exe in %OUTPUT%
echo        Path.txt: %PATH_FILE%
echo        Run Launcher.exe from that folder.
if defined DOUBLE_CLICKED pause
endlocal
exit /b 0

:Fail
pause
endlocal
exit /b 1
