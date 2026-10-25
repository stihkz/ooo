@echo off
rem Copyright (c) 2026 Celestial
rem Licensed under the PolyForm Noncommercial License 1.0.0. See LICENSE.md.
rem Finds a VS 2022 (17.x) MSBuild with the C++ toolset; installs VS Build Tools if none exists.
rem Pinned to 17.x because the projects use the v143 toolset and a newer VS (18) would be picked by -latest otherwise.
rem On success sets MSBUILD in the caller's environment (call this, do not start it).
setlocal EnableExtensions EnableDelayedExpansion

rem Double-clicked (not called from Build.bat or a prompt): keep the window open at the end.
set "PAUSE_AT_END="
if defined GRANITE_BUILD goto :SkipDetect
echo %cmdcmdline% | find /i "%~nx0" >nul && set "PAUSE_AT_END=1"
:SkipDetect

set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "FOUND="

call :Find
if defined FOUND goto :Done

echo [INFO] No Visual Studio with the C++ toolset was found.
net session >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Installing Visual Studio needs an Administrator prompt. Re-run this from an elevated command prompt.
  if defined PAUSE_AT_END pause
  endlocal & exit /b 1
)

where winget >nul 2>nul
if errorlevel 1 (
  echo [ERROR] winget is not available. Install "App Installer" from the Microsoft Store, then re-run.
  if defined PAUSE_AT_END pause
  endlocal & exit /b 1
)

echo [INFO] Installing Visual Studio 2022 Build Tools with the C++ desktop workload. This takes a while.
winget install --id Microsoft.VisualStudio.2022.BuildTools -e --accept-package-agreements --accept-source-agreements --override "--passive --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
rem winget returns non-zero when the package is already present, so verify by searching instead of trusting the code.

set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
call :Find
if not defined FOUND (
  echo [ERROR] Install finished but MSBuild with the C++ toolset still was not found.
  if defined PAUSE_AT_END pause
  endlocal & exit /b 1
)

:Done
echo [INFO] MSBuild: %FOUND%
if defined PAUSE_AT_END pause
endlocal & set "MSBUILD=%FOUND%"
exit /b 0

:Find
if not exist "%VSWHERE%" exit /b 0
rem The version range goes through a delayed-expansion variable: a literal ")" inside this for() or extra quotes breaks parsing.
set "VSARGS=-latest -version [17.0,18.0) -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -find MSBuild\**\Bin\MSBuild.exe"
for /f "usebackq delims=" %%P in (`"%VSWHERE%" !VSARGS!`) do set "FOUND=%%P"
if defined FOUND if not exist "%FOUND%" set "FOUND="
exit /b 0
