@echo off
REM ============================================================
REM  一键把 Launcher.cs 编译成 AutoMouseMover.exe
REM
REM  用的是 Windows 自带的 .NET Framework C# 编译器 csc.exe，
REM  不需要安装 Visual Studio / .NET SDK / 任何第三方工具。
REM  只需运行一次；之后直接双击 AutoMouseMover.exe 即可。
REM ============================================================
setlocal
set "DIR=%~dp0"

set "CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist "%CSC%" set "CSC=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%CSC%" (
    echo [错误] 未找到 .NET Framework 的 C# 编译器 csc.exe。
    echo        Windows 通常自带 .NET Framework 4.x，请确认系统组件完整。
    echo.
    pause
    exit /b 1
)

if not exist "%DIR%Launcher.cs" (
    echo [错误] 未找到 Launcher.cs，请确认它与本文件在同一个文件夹。
    echo.
    pause
    exit /b 1
)

if not exist "%DIR%AutoMouseMover.ico" (
    echo [错误] 未找到 AutoMouseMover.ico，无法嵌入应用图标。
    echo.
    pause
    exit /b 1
)

echo 正在编译 AutoMouseMover.exe ...
"%CSC%" -nologo -optimize+ -target:winexe -win32icon:"%DIR%AutoMouseMover.ico" -out:"%DIR%AutoMouseMover.exe" -r:System.Windows.Forms.dll -r:System.Drawing.dll "%DIR%Launcher.cs"

if errorlevel 1 (
    echo.
    echo [错误] 编译失败，请把上面的错误信息反馈给作者。
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  编译完成：%DIR%AutoMouseMover.exe
echo.
echo  以后直接双击 AutoMouseMover.exe 运行（无需再运行本脚本）。
echo  Run-GUI.ps1 与 AutoMouseMover.ico 需与 exe 保持在同一文件夹。
echo ============================================================
echo.
pause
