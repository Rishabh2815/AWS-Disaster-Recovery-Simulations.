@echo off
setlocal
start "DR dashboard server" pwsh -NoExit -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1"
timeout /t 2 /nobreak >nul
start "" "http://localhost:4174/"
