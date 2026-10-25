@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM ============================================================
REM  零环境构建：使用 Windows 自带的 csc.exe 编译
REM  .NET Framework 随 Windows 10/11 预装，无需安装任何东西
REM  双击本文件即可生成 AutoMouseMover.exe + MouseEngine.dll
REM ============================================================

set "CSC="
set "CSCDIR="
for %%D in (Framework64 Framework) do (
    set "P=%SystemRoot%\Microsoft.NET\%%D\v4.0.30319\csc.exe"
    if exist "!P!" (
        set "CSC=!P!"
        set "CSCDIR=%SystemRoot%\Microsoft.NET\%%D\v4.0.30319"
    )
)

if not defined CSC (
    echo [错误] 未找到系统自带的 csc.exe（.NET Framework）。
    echo 请确认系统已启用 .NET Framework 4.x（Windows 10/11 默认已启用）。
    pause
    exit /b 1
)

set "SRC=%~dp0"
set "OUT=%~dp0publish"
if not exist "%OUT%" mkdir "%OUT%"

echo [1/2] 编译 MouseEngine.dll ...
"%CSC%" /nologo /codepage:65001 /target:library /lib:"%CSCDIR%" /out:"%OUT%\MouseEngine.dll" /reference:System.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll "%SRC%AppInfo.cs" "%SRC%MouseController.cs" "%SRC%MovementEngine.cs"
if errorlevel 1 ( echo 编译失败。 & pause & exit /b 1 )

echo [2/2] 编译 AutoMouseMover.exe ...
"%CSC%" /nologo /codepage:65001 /target:winexe /lib:"%CSCDIR%" /out:"%OUT%\AutoMouseMover.exe" /reference:System.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll /reference:"%OUT%\MouseEngine.dll" "%SRC%Program.cs" "%SRC%MainForm.cs"
if errorlevel 1 ( echo 编译失败。 & pause & exit /b 1 )

echo.
echo 完成！可直接运行： %OUT%\AutoMouseMover.exe
echo   - AutoMouseMover.exe  （主程序）
echo   - MouseEngine.dll     （移动引擎库）
echo.
echo 想生成安装包 setup.exe：用 Inno Setup 打开 setup.iss 编译即可（源目录已是 publish）。
pause
