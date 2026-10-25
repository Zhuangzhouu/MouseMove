@echo off
chcp 65001 >nul
REM 运行 AutoMouseMover.pyw（优先用 pythonw 隐藏控制台）
setlocal
set "SCRIPT=%~dp0AutoMouseMover.pyw"

where pythonw >nul 2>&1
if not errorlevel 1 (
    start "" pythonw "%SCRIPT%"
    goto :eof
)

where python >nul 2>&1
if not errorlevel 1 (
    python "%SCRIPT%"
    goto :eof
)

echo [错误] 未检测到 Python。请先安装 Python 3.8+：https://www.python.org/downloads/
echo 安装时勾选 "Add Python to PATH"。
pause
