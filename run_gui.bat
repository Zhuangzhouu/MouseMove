@echo off
chcp 65001 >nul
REM Launch the PowerShell edition (zero-compile; Windows ships PowerShell + .NET Framework)
setlocal
set "SCRIPT=%~dp0Run-GUI.ps1"

REM Ensure the script has a UTF-8 BOM so Chinese is not misread as GBK
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='%SCRIPT%'; $b=[System.IO.File]::ReadAllBytes($f); if(-not($b.Length -ge 3 -and $b[0]-eq 0xEF -and $b[1]-eq 0xBB -and $b[2]-eq 0xBF)){ $c=[System.IO.File]::ReadAllText($f); $sw=New-Object System.IO.StreamWriter($f,$false,[System.Text.UTF8Encoding]::new($true)); $sw.Write($c); $sw.Close() }"

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
pause
