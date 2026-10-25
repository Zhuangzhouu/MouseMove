@echo off
chcp 65001 >nul
setlocal

echo ============================================================
echo  AutoMouseMover 构建脚本  (%date% %time%)
echo ============================================================

where dotnet >nul 2>&1
if errorlevel 1 (
    echo.
    echo [错误] 未检测到 .NET 8 SDK。
    echo 请先安装： https://dotnet.microsoft.com/download/dotnet/8.0
    echo 安装后重新打开本窗口再运行 build.bat。
    pause
    exit /b 1
)

echo.
echo [1/2] 正在发布（自包含 win-x64，无需安装运行时）...
dotnet publish src\AutoMouseMover\AutoMouseMover.csproj ^
    -c Release -r win-x64 --self-contained true ^
    -p:PublishSingleFile=false -o publish

if errorlevel 1 (
    echo.
    echo [失败] 发布过程中出现错误。
    pause
    exit /b 1
)

echo.
echo [2/2] 构建完成。
echo ------------------------------------------------------------
echo   输出目录： publish\
echo     - AutoMouseMover.exe   主程序（双击即可运行）
echo     - MouseEngine.dll      鼠标移动引擎库
echo.
echo   想生成安装包 setup.exe：
echo     1) 安装 Inno Setup  https://jrsoftware.org/isdl.php
echo     2) 用 Inno Setup Compiler 打开 setup.iss 并编译
echo     3) 生成的安装包位于 installer\Setup-AutoMouseMover-0.1.exe
echo ------------------------------------------------------------
echo.
pause
