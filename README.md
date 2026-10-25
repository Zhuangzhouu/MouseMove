# AutoMouseMover

自动鼠标移动工具（**版本常量 `v0.4`**）。可设定 **0.1s–60s** 的间隔，让鼠标按
**横向 / 纵向 / 圆圈 / 随机** 四种轨迹自动移动，并可按所选方式（左键/右键/双击）点击。

**本仓库现在只有一份实现：纯 PowerShell 跨平台脚本。** 不再维护 C# / Python 版本。
支持 **Windows / macOS / Linux** 三大系统。

---

## 🟢 给普通用户：30 秒上手

> 三种系统都**不需要装编译器 / SDK / Python**。区别只在于「双击」还是「在终端里跑一条命令」。

### Windows（最省事，零安装）

1. 进入 `mouse-move` 文件夹。
2. **双击 `run_gui.bat`**。
3. 弹出图形窗口，设好间隔和模式，点「开始」即可。

它用 Windows 自带的 **PowerShell + .NET Framework** 直接生成界面，不需要下载、安装或联网。
首次若被 SmartScreen 拦截，点「仍要运行」即可。

### macOS（需装一次 PowerShell）

1. 安装 **PowerShell 7**（系统自带的旧版不行）：
   ```bash
   brew install --cask powershell
   ```
2. 在终端里进入文件夹，运行：
   ```bash
   ./run_gui.sh          # 或直接： pwsh ./Run-GUI.ps1
   ```
3. 首次使用需在 **系统设置 → 隐私与安全性 → 辅助功能** 中，给运行脚本的终端
   （Terminal / iTerm / VS Code 等）授予「辅助功能」权限，否则无法移动鼠标。
4. 程序以**终端菜单**形式运行（macOS 上 PowerShell 没有图形界面），按菜单提示操作。
   - 想要右键/双击点击？建议再装 `brew install cliclick`，否则右键/双击会退化为左键单击。

### Linux（需装 PowerShell + xdotool）

1. 安装 **PowerShell 7**：见 <https://learn.microsoft.com/powershell/scripting/install/installing-powershell>
2. 安装 **xdotool**（控制鼠标用）：
   ```bash
   sudo apt install xdotool        # Debian/Ubuntu
   sudo dnf install xdotool        # Fedora/RHEL
   ```
3. 在终端里运行：
   ```bash
   ./run_gui.sh          # 或直接： pwsh ./Run-GUI.ps1
   ```
4. 程序以**终端菜单**形式运行。X11 会话可直接用；Wayland 会话请改用 XWayland，
   或安装 `ydotool` 后自行适配。

> **普通用户记住一句**：Windows 双击 `run_gui.bat` 就能用；macOS / Linux 装好
> PowerShell 和 xdotool 后，在终端里 `pwsh ./Run-GUI.ps1` 即可。

---

## 功能

- ⏱ **间隔可调**：0.1 秒 ~ 60 秒（步进 0.1 秒）
- 🖱 **四种移动模式**：横向 / 纵向 / 圆圈（可调半径、角速度）/ 随机
- 👆 **点击方式**：不点击 / 左键单击 / 右键单击 / 左键双击
- 🎲 **拟人化随机**：随机抖动（像素）+ 间隔随机度（%），避免机械脚本特征
- 💾 **配置持久化**：自动保存/加载上次设置
  - Windows：`%LOCALAPPDATA%\AutoMouseMover\settings.ini`
  - macOS/Linux：`~/.config/AutoMouseMover/settings.ini`
- ⌨️ **自定义全局热键**（仅 Windows 图形界面）：默认 `Ctrl+Shift+M`
- 🔁 **开机自启动 + 运行时长显示**（仅 Windows）
- 🖥 **多显示器选择**（仅 Windows 图形界面）
- 🌊 **缓动曲线**：线性 / 渐快 / 渐慢 / 正弦起伏
- 🚦 **点击节流**：每 N 次移动才点击 1 次（1=每次都点）
- 🎛 **托盘菜单开始/停止**（仅 Windows）
- 🏠 **停止回到起点**
- ⏳ **延迟启动倒计时**
- 👤 **预设方案**：多套命名配置保存/加载（各平台通用）
- 📊 **运行统计**：已移动次数 + 点击次数 + 总移动距离（像素）
- 🔔 **声音提示**：开始/停止时提示音（可开关）
- 🚀 **本地下载运行**：无需安装运行时，脚本即程序

---

## 目录结构

```
run_gui.bat              # ★ Windows 双击即用（PowerShell 零编译）
run_gui.sh               # ★ macOS/Linux 启动器（chmod +x 后 ./run_gui.sh）
Run-GUI.ps1              #   PowerShell 主程序（跨平台核心，被上面两个启动器调用）
setup.iss                # 可选：Inno Setup 脚本，生成 Windows 安装包 setup.exe
README.md                # 本说明
archive-others/          # 历史版本（C# / Python 实现）归档，可删除
```

> `archive-others/` 是早期 C# / Python 实现的归档备份。既然已统一到 PowerShell 单一版本，
> 这个目录可以直接删除，不影响任何功能。

---

## 各平台对比

| 平台 | 入口 | 需要安装 | 界面形式 |
|------|------|----------|----------|
| **Windows** | 双击 `run_gui.bat` | 无（系统自带 PowerShell） | 原生图形窗口 |
| **macOS** | `pwsh ./Run-GUI.ps1` | PowerShell 7（一次） | 终端菜单 |
| **Linux** | `pwsh ./Run-GUI.ps1` | PowerShell 7 + xdotool | 终端菜单 |

> 之所以 macOS / Linux 用终端菜单而不是图形窗口：PowerShell 在这些系统上没有
> WinForms 图形界面能力。鼠标移动则分别通过系统自带的 `osascript`（macOS）和
> `xdotool`（Linux）实现，核心引擎三平台完全一致。

---

## 使用说明

1. 设置 **间隔时间（秒）**：建议 1~10 秒；0.1s 为最快档。
2. 选择 **移动模式**：横向 / 纵向 / 圆圈 / 随机。
   - 横/纵向下填 **步长（像素）**（每次移动的位移）；
   - 圆圈下填 **圆圈半径（像素）**。
3. 需要保持活跃时选择 **点击方式**（左键/右键/双击）并设置节流。
4. **开始**运行；可随时 **停止**。

### 终端菜单（macOS / Linux）操作

```
=== 主菜单 ===
  1. 开始运行
  2. 修改设置
  3. 预设方案（保存/加载）
  4. 关于 / 使用帮助
  5. 退出
```

---

## ⚠️ 运行中怎么停下来（重要）

程序一直在移动光标，你可能来不及把鼠标挪到「停止」上。所有平台都有**不需要用鼠标**的停止方式：

- **Windows 图形界面**
  - **快捷键 `Ctrl + Shift + M`**（默认，可自定义）：随时切换「开始 / 停止」，即使窗口没焦点也有效。
  - **`Esc` 键**：窗口聚焦时立即停止。
  - **检测到手动移动自动暂停（推荐，默认开启）**：运行中你一动鼠标，程序立刻暂停、把光标交还给你。
- **macOS / Linux 终端菜单**
  - 运行中按 **`s` 或 `Esc`** 停止。
  - **检测到手动移动自动暂停（推荐，默认开启）**：你一动鼠标，程序会打印提示并停止，此时你能正常操作。

> 记住第一句就够了：**Windows 动不了鼠标就按 `Ctrl+Shift+M`；Mac/Linux 就按 `s`。**

---

### 🆕 v0.4 变更

- **跨平台适配**：新增 macOS（osascript）与 Linux（xdotool）后端，三大系统统一引擎。
- **单一实现**：仅保留 PowerShell 版本，删除 C# / Python 实现（见 `archive-others/`）。
- 版本常量升级为 `v0.4`。

### 🆕 v0.3 变更

新增 10 个功能：多显示器选择、随机移动模式、缓动曲线、点击节流、托盘菜单开始/停止、
停止回到起点、延迟启动倒计时、预设方案保存/加载、运行统计增强（总距离/点击数）、
开始/停止声音提示；版本常量升级为 `v0.3`。

### 🆕 v0.2 变更

新增 5 个功能：拟人化随机（抖动+间隔随机度）、点击方式选择、配置持久化、
自定义全局热键、开机自启动+运行时长；版本常量升级为 `v0.2`。

---

## 版本常量

版本统一在 **`Run-GUI.ps1` 顶部**：

```powershell
$VERSION = 'v0.4'
```

如需升级版本，改这一处即可（无需改动其他文件）。

---

## 可选：生成 Windows 安装包 setup.exe

1. 安装 **Inno Setup**：<https://jrsoftware.org/isdl.php>
2. 用 **Inno Setup Compiler** 打开 `setup.iss` 并 **Build**
3. 生成的安装包位于 `installer\Setup-AutoMouseMover-0.4.exe`

安装包会把 `Run-GUI.ps1` / `run_gui.bat` / `run_gui.sh` / `README.md` 复制到位，
并在开始菜单和桌面建立指向 `run_gui.bat` 的快捷方式。

---

## 技术说明

- **Windows**：`System.Windows.Forms` 图形界面 + 内联 C#（P/Invoke `user32.dll` 的
  `SetCursorPos` / `mouse_event` / `GetCursorPos`），通过 `Add-Type` 即时编译，无第三方依赖。
- **macOS**：`osascript` 调用 AppleScript `System Events` 移动/读取/点击鼠标；
  右键/双击推荐配合 `cliclick`。
- **Linux**：`xdotool` 移动/读取/点击鼠标（X11）。
- 三平台共用同一套移动引擎（`Next-Move` / `Do-Step` / `Apply-Once`）与配置对象 `$cfg`，
  仅「鼠标后端」和「界面」按平台分支。计时最小间隔 10ms，满足 0.1s 需求；
  移动边界取屏幕工作区（避开任务栏；macOS/Linux 取主显示器逻辑分辨率）。
