@echo off
setlocal EnableExtensions
set "DIR=%~dp0"
set "SCRIPT=%DIR%Run-GUI.ps1"

if not exist "%SCRIPT%" (
    echo [错误] 找不到 Run-GUI.ps1，请确认它和本文件在同一个文件夹。
    pause
    exit /b 1
)

REM 优先启动编译好的 exe（真正的窗口程序，有图标、无控制台窗）
if exist "%DIR%AutoMouseMover.exe" (
    start "" "%DIR%AutoMouseMover.exe"
    exit /b 0
)

REM 没有 exe 时，直接用 PowerShell 跑脚本（前台可见，便于看到错误）
echo 未找到 AutoMouseMover.exe，改用 PowerShell 启动……
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
if errorlevel 1 (
    echo.
    echo [错误] 启动失败（错误码 %errorlevel%）。
    echo   可尝试：直接双击 AutoMouseMover.exe，或先运行 build_exe.bat 生成 exe。
    pause
)
exit /b %errorlevel%
