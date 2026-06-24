@echo off
REM ============================================================
REM Mizuki Blog Quick Publish (Launcher)
REM Double-click this file, or drag a .md file onto it
REM ============================================================
cd /d "%~dp0.."
node "scripts/quick-publish.js" %*
pause
