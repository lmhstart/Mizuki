@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================================
:: Mizuki 博客一键发布工具 (Windows 版)
:: 双击运行，按提示操作即可
:: ============================================================

title Mizuki 博客一键发布

echo.
echo  ╔══════════════════════════════════════════════╗
echo  ║     Mizuki 博客一键发布工具 (Windows版)       ║
echo  ╚══════════════════════════════════════════════╝
echo.

:: ── 获取项目目录 ────────────────────────────────────────
set "PROJECT_DIR=%~dp0.."
cd /d "%PROJECT_DIR%"

:: ── 第1步：拖入/输入文件路径 ──────────────────────────────
echo  [步骤 1/4] 请输入你的 Markdown 文件路径
echo  ----------------------------------------
echo  提示：可以直接把 .md 文件拖到这个窗口里！
echo.
set /p INPUT_FILE="  文件路径: "

:: 去掉路径两端的引号
set INPUT_FILE=%INPUT_FILE:"=%

if not exist "%INPUT_FILE%" (
    echo.
    echo  [错误] 文件不存在: %INPUT_FILE%
    pause
    exit /b 1
)

:: ── 第2步：输入文章信息 ──────────────────────────────────
echo.
echo  [步骤 2/4] 输入文章信息
echo  ----------------------------------------
set /p TITLE="  文章标题: "
set /p DESC="  文章摘要: "
set /p TAGS="  标签 (用逗号分隔): "
set /p CATEGORY="  分类: "

:: ── 第3步：确认 ──────────────────────────────────────────
echo.
echo  [步骤 3/4] 确认信息
echo  ----------------------------------------
echo   源文件:   %INPUT_FILE%
echo   标题:     %TITLE%
echo   摘要:     %DESC%
echo   标签:     %TAGS%
echo   分类:     %CATEGORY%
echo.
set /p CONFIRM="  确认发布? [Y/n]: "
if /i "%CONFIRM%"=="n" exit /b 0

:: ── 第4步：生成文件 + 提交 ──────────────────────────────
echo.
echo  [步骤 4/4] 生成文章并提交到 GitHub...
echo  ----------------------------------------

:: 生成安全的英文文件名
for %%F in ("%INPUT_FILE%") do set "BASENAME=%%~nF"
set "BASENAME=%BASENAME: =-%"
set "SAFE_NAME=%BASENAME%.md"

:: 获取当前日期
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "DATETIME=%%I"
set "TODAY=%DATETIME:~0,4%-%DATETIME:~4,2%-%DATETIME:~6,2%"

:: 生成 frontmatter YAML 标签列表
set "TAG_YAML="
if not "%TAGS%"=="" (
    for %%t in (%TAGS%) do (
        set "TAG_YAML=!TAG_YAML!  - %%~t\n"
    )
)

:: 写入文件
set "OUTPUT_FILE=src\content\posts\%SAFE_NAME%"
(
    echo ---
    echo title: %TITLE%
    echo published: %TODAY%
    echo description: %DESC%
    if not "%TAGS%"=="" echo tags:
    if not "%TAG_YAML%"=="" echo !TAG_YAML!
    if not "%CATEGORY%"=="" echo category: %CATEGORY%
    echo draft: false
    echo ---
    echo.
    type "%INPUT_FILE%"
) > "%OUTPUT_FILE%"

echo   √ 文章已生成: %OUTPUT_FILE%

:: Git 提交
git add "%OUTPUT_FILE%"
git commit -m "feat: add %TITLE%"

echo   √ 已提交到本地仓库

:: Git 推送
echo.
echo  正在推送到 GitHub...
git push origin master

if errorlevel 1 (
    echo.
    echo   × 推送失败！请检查:
    echo     1. 是否开启了梯子/代理
    echo     2. 网络连接是否正常
    echo.
    echo   可以稍后手动在 Git Bash 中执行: git push origin master
) else (
    echo.
    echo   √ 发布成功！Vercel 将自动部署，稍后访问博客即可看到。
)

echo.
pause
