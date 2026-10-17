@echo off
setlocal
set "gameEngine=%GODOT_EXECUTABLE%"
if not defined gameEngine set "gameEngine=%LOCALAPPDATA%\Programs\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe"
if not exist "%gameEngine%" (
    echo Godot was not found. Set GODOT_EXECUTABLE to your Godot executable.
    pause
    exit /b 1
)
start "Defend the Kingdom" "%gameEngine%" --path "%~dp0." --fullscreen
