@echo off
setlocal EnableExtensions
set "DIR=%~dp0"
set "SCRIPT=%DIR%Run-GUI.ps1"

if not exist "%SCRIPT%" (
    echo [错误] 找不到 Run-GUI.ps1
    pause
    exit /b 1
)

echo 正在启动 Run-GUI.ps1（若出错会显示在这里）……
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
echo.
echo [结束] 退出码=%errorlevel%
pause
