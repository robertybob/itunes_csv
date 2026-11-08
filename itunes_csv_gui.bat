@echo off
rem Double-click this file to open the iTunes CSV Export window.
rem The first run installs the Ruby gems it needs (internet connection required).
setlocal
cd /d "%~dp0"

where rubyw >nul 2>nul
if errorlevel 1 (
  echo Ruby was not found on this computer.
  echo.
  echo Install Ruby from https://rubyinstaller.org/ ^(keep the default options,
  echo including "Add Ruby executables to your PATH"^), then double-click this file again.
  echo.
  pause
  exit /b 1
)

call bundle check >nul 2>nul
if errorlevel 1 (
  echo Installing the parts iTunes CSV needs. This only happens the first time...
  echo.
  call bundle install
  if errorlevel 1 (
    echo.
    echo Installing failed. Check your internet connection and try again.
    pause
    exit /b 1
  )
)

start "" rubyw -rbundler/setup bin\itunes_csv_gui
