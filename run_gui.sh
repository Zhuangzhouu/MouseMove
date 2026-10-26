#!/usr/bin/env bash
# ============================================================
#  AutoMouseMover 启动器（macOS / Linux）
#  用法：
#     chmod +x run_gui.sh
#     ./run_gui.sh
#  依赖：PowerShell 7（命令名 pwsh）
#    • macOS ：brew install --cask powershell
#    • Linux ：见 https://learn.microsoft.com/powershell/scripting/install/installing-powershell
#  说明：macOS 首次使用需在「系统设置 → 隐私与安全性 → 辅助功能」
#        中给终端授予权限，否则无法移动鼠标；右键/双击点击建议装 cliclick。
#        Linux 需要 xdotool：sudo apt install xdotool（X11 会话）。
# ============================================================
DIR="$(cd "$(dirname "$0")" && pwd)"

if ! command -v pwsh >/dev/null 2>&1; then
  echo "未检测到 PowerShell 7（pwsh）。请先安装："
  echo "  macOS : brew install --cask powershell"
  echo "  Linux : 见 https://learn.microsoft.com/powershell/scripting/install/installing-powershell"
  exit 1
fi

# 原实现写死 exec pwsh "$DIR/Run-GUI.ps1"，导致 ./run_gui.sh -web 这类参数被静默丢弃
exec pwsh "$DIR/Run-GUI.ps1" "$@"
