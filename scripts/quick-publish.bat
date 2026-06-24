@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: Mizuki Blog Quick Publish Tool (Windows)
:: Double-click to run, follow the prompts
:: ============================================================

title Mizuki - Quick Publish

echo.
echo ================================================
echo    Mizuki Blog - One-Click Publish
echo ================================================
echo.

REM -- Get project directory --
set "PROJECT_DIR=%~dp0.."
cd /d "%PROJECT_DIR%"

REM -- Step 1: Input file path --
echo [Step 1/4] Enter your markdown file path
echo   Tip: You can drag the .md file directly into this window!
echo.
set /p INPUT_FILE="  File path: "

REM Remove quotes
set INPUT_FILE=%INPUT_FILE:"=%

if not exist "%INPUT_FILE%" (
    echo.
    echo [ERROR] File not found: %INPUT_FILE%
    pause
    exit /b 1
)

REM -- Step 2: Input article info --
echo.
echo [Step 2/4] Enter article information
echo ----------------------------------------
set /p TITLE="  Title: "
set /p DESC="  Description: "
set /p TAGS="  Tags (comma separated): "
set /p CATEGORY="  Category: "

REM -- Step 3: Confirm --
echo.
echo [Step 3/4] Confirm
echo ----------------------------------------
echo   Source file: %INPUT_FILE%
echo   Title:       %TITLE%
echo   Description: %DESC%
echo   Tags:        %TAGS%
echo   Category:    %CATEGORY%
echo.
set /p CONFIRM="  Confirm publish? [Y/n]: "
if /i "%CONFIRM%"=="n" exit /b 0

REM -- Step 4: Generate file + commit + push --
echo.
echo [Step 4/4] Generating and publishing...
echo ----------------------------------------

REM Generate safe English filename
for %%F in ("%INPUT_FILE%") do set "BASENAME=%%~nF"
REM Replace spaces with hyphens, remove Chinese chars etc
set "SAFE_NAME=%BASENAME: =-%"
REM Generate timestamp-based safe name
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "DT=%%I"
set "TS=%DT:~0,4%%DT:~4,2%%DT:~6,2%-%DT:~8,2%%DT:~10,2%%DT:~12,2%"
set "OUTPUT_FILE=src\content\posts\post-%TS%.md"

REM Get today's date
set "TODAY=%DT:~0,4%-%DT:~4,2%-%DT:~6,2%"

REM Generate YAML frontmatter
(
    echo ---
    echo title: %TITLE%
    echo published: %TODAY%
    echo description: %DESC%
    if not "%TAGS%"=="" echo tags: [%TAGS%]
    if not "%CATEGORY%"=="" echo category: %CATEGORY%
    echo draft: false
    echo ---
    echo.
    type "%INPUT_FILE%"
) > "%OUTPUT_FILE%"

echo   [OK] Article created: %OUTPUT_FILE%

REM Git add and commit
git add "%OUTPUT_FILE%"
git commit -m "feat: add %TITLE%"
echo   [OK] Committed

REM Git push
echo.
echo   Pushing to GitHub...
git push origin master

if errorlevel 1 (
    echo.
    echo   [FAIL] Push failed. Please check:
    echo      1. Is your VPN/proxy turned on?
    echo      2. Is the network working?
    echo.
    echo   You can retry manually: git push origin master
) else (
    echo.
    echo   [OK] Published successfully!
    echo   Vercel will auto-deploy. Check your blog shortly.
)

echo.
pause
