# AutoMouseMover

自动鼠标移动工具（**版本常量 `v0.6.6`**）。可设定 **0.1s–60s** 的间隔，让鼠标按
**横向 / 纵向 / 圆圈 / 随机 / 方形 / 螺旋 / 8字 / 斜弹** 八种轨迹自动移动，并可按所选方式（左键/右键/双击）点击。

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

> **想要更像普通软件？** 先双击一次 `build_exe.bat`（用系统自带编译器生成 `AutoMouseMover.exe`，
> 约 10 秒），之后双击 exe：有专属图标、标题栏/托盘/任务栏都是它、没有黑色控制台窗。
> 这一步是可选的，不编译也能正常用。

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
4. 程序以**终端菜单**形式运行（macOS 上 PowerShell 没有图形界面），按菜单提示操作；
   也可运行 `pwsh ./Run-GUI.ps1 -web` 用**浏览器图形界面**（见下方「网页图形界面」）。
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
- 🖱 **八种移动模式**：横向 / 纵向 / 圆圈（可调半径、角速度）/ 随机 / 方形 / 螺旋 / 8字 / 斜向反弹
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
- 🌐 **网页图形界面**（macOS/Linux/Windows 通用）：命令行 `-web` 或菜单「网页图形界面」，用浏览器控制，零编译、离线
- 🧩 **内置方案**：meeting/minimal/gaming/wide 开箱即用（`-preset` 或菜单）
- 📤 **统计导出**：停止自动写 `stats-last.json`，`-export 路径` 自定义
- 🚀 **本地下载运行**：无需安装运行时，脚本即程序

---

## 目录结构

```
run_gui.bat              # ★ Windows 双击即用（优先调 exe，无 exe 则隐藏窗口启动）
build_exe.bat            # ★ 一键生成 AutoMouseMover.exe（用系统自带 csc.exe，约 10 秒，只跑一次）
AutoMouseMover.ico       #   应用图标（鼠标指针，含 16/24/32/48/64 五档）
Launcher.cs              #   exe 启动器源码（极小，只负责“像正常软件一样被双击”）
AutoMouseMover.exe       #   ★ 编译产物：真·窗口程序，有图标、无黑色控制台窗（运行 build_exe.bat 生成）
Run-GUI.ps1              #   PowerShell 主程序（跨平台核心，被上面几个启动器调用）
run_gui.sh               # ★ macOS/Linux 启动器（chmod +x 后 ./run_gui.sh）
setup.iss                # 可选：Inno Setup 脚本，生成 Windows 安装包 setup.exe
README.md                # 本说明
archive-others/          # 历史版本（C# / Python 实现）归档，可删除
```

> **Windows 上想让它「像个普通软件」**（有图标、双击直接出界面、后面不拖黑色控制台窗）：
> 先运行一次 `build_exe.bat` 生成 `AutoMouseMover.exe`，之后双击 exe 即可。
> 用的是 Windows 自带的 .NET Framework 编译器，**不需要装 Visual Studio / .NET SDK**。
> 不编译也完全能用——`run_gui.bat` 会以隐藏窗口方式启动，同样没有控制台窗。

> `archive-others/` 是早期 C# / Python 实现的归档备份。既然已统一到 PowerShell 单一版本，
> 这个目录可以直接删除，不影响任何功能。

---

## 各平台对比

| 平台 | 入口 | 需要安装 | 界面形式 |
|------|------|----------|----------|
| **Windows** | 双击 `run_gui.bat` | 无（系统自带 PowerShell） | 原生图形窗口 |
| **macOS** | `pwsh ./Run-GUI.ps1` | PowerShell 7（一次） | 终端菜单 |
| **Linux** | `pwsh ./Run-GUI.ps1` | PowerShell 7 + xdotool | 终端菜单 |

> macOS / Linux 默认用终端菜单（PowerShell 在这些系统上没有 WinForms）。若想要图形界面，
> 可用内置的**网页图形界面**：`pwsh ./Run-GUI.ps1 -web`，用浏览器控制（零编译、离线）。
> 鼠标移动分别通过系统自带的 `osascript`（macOS）和 `xdotool`（Linux）实现，核心引擎三平台完全一致。

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
  3. 预设方案 / 内置方案 / 导出统计
  4. 关于 / 使用帮助
  5. 网页图形界面（浏览器控制）
  6. 退出
```

### 网页图形界面（macOS / Linux / Windows 通用，推荐）

不想用终端菜单？一条命令即可用**浏览器**当图形界面（无需安装任何 GUI 框架，离线可用）：

```bash
pwsh ./Run-GUI.ps1 -web
# 启动后会自动打开浏览器，地址默认 http://localhost:8777/
```

网页里可 **开始 / 暂停 / 继续 / 停止 / 退出服务**，并实时设置 间隔、移动模式（8 种）、步长、半径、
点击方式、自动暂停、声音；运行次数 / 点击 / 距离 / 时长实时刷新，设置即时生效并自动保存。
关闭浏览器不影响移动；点页面「停止」或「退出服务」，或在终端按 `Ctrl+C` 退出。

> 也可在终端主菜单选 **5. 网页图形界面** 进入。端口默认 8777，被占用会自动顺延到 8787。

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

### 🆕 v0.6.6 变更（修复底部信息区显示 bug）

- **右列文本截断**：底部「已运行」与「模式/间隔/步长/总距离」信息行原先 `AutoSize` 且起点固定在 x=220，文本一长就顶出窗口右缘被硬裁（窗口越窄截得越多）。
- **左右两列重叠**：左侧「状态」最长文案（"状态：运行中（热键停止 / 动鼠标自动暂停）"，约 250px）会压进 x=220 起的右列，两串文字叠在一起。
- **修复**：底部改为三行全宽布局——① 状态行 + 运行时长（`Anchor=Bottom,Right` 贴右缘）；② 已移动/点击统计行；③ 信息行独占全宽（`AutoEllipsis` 超宽显示「…」，随窗口横向拉伸）。窗体高度 692→714，MinimumSize 740→762。

### 🆕 v0.6.5 变更（修虫子）

- **随机模式边缘不可达**：`Get-Random -Maximum` 是开区间（不含上限），原代码用 `right`/`bottom` 当上限，导致最右一列、最底一行的像素永远到不了。现改为 `right+1`/`bottom+1`，整块区域均匀覆盖。
- **长时运行轨迹走形**：圆周 / 螺旋 / 8字 的角度每个 tick 无限累加，数小时~数天后浮点精度劣化，圆会慢慢画成椭圆、8字漂移。现每种角度每过 2π 折回，长期运行轨迹稳定。
- **螺旋模式半径滑块无效**：螺旋半径原本靠自增从 0 长到屏幕边界，用户拖「圆圈半径」滑块毫无反应（该控件在螺旋下是死的）。现取「屏幕半径」与「圆圈半径」较小值为上限，半径滑块在螺旋下也生效，与圆形模式一致。

### 🆕 v0.6.4 变更（修虫子）

- **方形模式卡死修复**：方形巡逻原本借用方向变量 `dir` 当角标，`($ci+1)%4` 会让 `dir` 变成 `0`；若运行中切到横向/纵向/斜弹，`dir=0` 会使鼠标完全不动。现改用独立的 `sqCorner` 角标，`dir` 不再被污染。
- **圆圈半径实时生效**：圆圈模式原本读的是「开始运行时快照」的半径，运行中拖半径滑块无效（而步长滑块是实时的，行为不一致）。现改为实时读配置，与步长一致。
- **Windows 图形界面无声修复**：提示音原本用 `[console]::Beep`，在「无控制台窗」的 `AutoMouseMover.exe`（WinExe）里会抛「句柄无效」而无声。现改用 `kernel32.dll` 的 `Beep`，GUI/终端都能正常发声。

### 🆕 v0.6.3 变更（响应式布局）

- 窗口拉大/最大化时内容不再挤在左上角：两个卡片区（基本设置/动作与系统）横向铺开，其中的下拉框、数值框跟随拉伸填满宽度；预设方案行拉伸，「关于 / 保存 / 加载」贴到右下角。
- `MinimumSize` 提高到 440×740，保证最小时控件不重叠。

### 🆕 v0.6.2 变更（窗口可调整大小 / 可全屏）

- 窗体改为 `Sizable` + 打开最大化按钮（`MaximizeBox`），可拖拽边缘调整大小、点标题栏最大化按钮或双击标题栏进入全屏；设了最小尺寸防止缩得太小。
- 移除了之前「圆角窗体」用的固定 `Region`（固定 Region 会让窗口缩放时被裁剪回原尺寸，与可调整大小冲突）。
- 底栏的按钮 / 状态文字改为 `Anchor=Bottom`，最大化后贴着底部，不会悬在半空。

### 🆕 v0.6.1 变更（界面现代化）

- **新增 GUI 皮肤 `Set-GuiTheme`**：亮灰色窗体 + 白色卡片式 GroupBox（圆角窗体 + Segoe UI 字体），主按钮「开始」改为蓝色实心、悬停加深；下拉框/数值框改为扁平白底；整体脱离 WinForms 默认灰底 3D 控件，观感更接近现代 Windows 应用。

### 🆕 v0.6.0 变更（「像个真正的软件」）

- **新增应用图标** `AutoMouseMover.ico`：鼠标指针造型，白描边 + 蓝色渐变，含 16/24/32/48/64 五档尺寸。标题栏、任务栏、系统托盘、快捷方式、安装包全部换成自有图标（原来用的是系统那个灰色通用图标）。
- **新增 `AutoMouseMover.exe`**：`Launcher.cs` + `build_exe.bat`，用 Windows 自带的 `csc.exe` 编译成 Win32 窗口程序——**不需要装 Visual Studio / .NET SDK**。双击体验与普通软件一致：有图标、无控制台窗口、任务管理器里就是一个应用。
- **去掉黑色控制台窗**：`run_gui.bat` 现在优先调用 exe；没有 exe 时也改为隐藏窗口启动，不再在主界面后面拖一个黑窗。
- **安装包升级**：`setup.iss` 纳入图标 / exe / 构建链，快捷方式与安装包自身改用自定义图标。

### 🆕 v0.5.2 变更（修虫子）

- **修复螺旋模式一启动就崩溃**：`[math]::Min` 被误用 4 个参数（.NET 只有 2 参数重载），报 `Cannot find an overload for "Min" and the argument count: "4"`，导致选择 `spiral` 后点「开始」整个程序弹出异常对话框。已改为嵌套取最小值。
- **不再弹出英文异常对话框**：原来界面线程一有未处理异常，WinForms 就弹出 .NET 自带的「Unhandled exception has occurred...」对话框（这段文字是 .NET Framework 的语言资源，固定英文且带 Continue/Quit）。现已接管 `ThreadException`，改为中文提示并自动停止移动，防止同一个错误在每个 tick 连环弹窗。
- 对 v0.4.7 新增的 4 种模式（方形/螺旋/8字/斜弹）补做了隔离逻辑测试，覆盖常规分辨率、极小屏（200×150）与负坐标副屏场景，零越界。

### 🆕 v0.5.1 变更（修虫子）

- **修复全局热键完全无效**：C# 侧 `HotkeyForm.HotkeyPressed` 事件早已定义，但 PowerShell 侧从未订阅——热键注册成功、系统消息也收到了，却没有任何响应。这是本版最重要的一处修复。
- **修复托盘「退出」直接关窗**：原来真正退出时不会停止移动（光标不回起点、无提示音），运行统计也不落盘；现已与点「停止」行为一致。
- **修复引擎状态跨轮残留**：`Reset-Engine` 此前不复位 `spiralR / figPhase / dirY`，导致重启后螺旋/8字从上一轮的中间半径继续、斜向反弹的 y 方向可能残留反向。
- **性能**：拟人抖动移入 `Next-Move`，复用已算好的边界，Windows/Linux 每 tick 少一次屏幕枚举。
- **资源**：`New-BeepWav` 的 `BinaryWriter`/`MemoryStream` 改为保证释放；提示音缓存清理后同步清空，避免重复删除/播放已删文件。
- **网页界面**：`/set` 对 `"0"` 不再误判为未提供；「停止」时导出统计；新增「退出服务」按钮。
- **其它**：终端输入无效模式时给出明确提示；主菜单文案与预设子菜单实际选项对齐；热键注册失败时在状态栏可见；`run_gui.sh` 现在透传命令行参数（`./run_gui.sh -web` 可用）。

### 🆕 v0.5.0 变更

- **新增网页图形界面**（macOS/Linux/Windows 通用）：`HttpListener` 本地服务 + 内嵌 HTML，浏览器即界面；命令行 `-web` 或主菜单「网页图形界面」进入。
- 移动模式扩展到 8 种（新增 方形/螺旋/8字/斜向反弹），图形界面改为下拉框选择。
- 新增内置方案（meeting/minimal/gaming/wide）、运行统计导出（`-export` / 自动 `stats-last.json`）、自动暂停去抖、终端 Stopwatch 计时。

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
$VERSION = 'v0.6.6'
```

如需升级版本，改这一处，并同步 `setup.iss` 的 `#define MyAppVersion "x.y.z"`。

---

## 可选：生成 AutoMouseMover.exe（推荐先做）

```bat
build_exe.bat
```

用 **Windows 自带的 `csc.exe`**（.NET Framework 4.x，无需安装任何 SDK）把 `Launcher.cs`
编译成 `AutoMouseMover.exe`：Win32 窗口程序、嵌入应用图标、启动时不出现控制台窗口。
只需运行一次，之后直接双击 exe。

> `Run-GUI.ps1` 与 `AutoMouseMover.ico` 必须与 exe 保持在同一文件夹。

## 可选：生成 Windows 安装包 setup.exe

1. （建议）先运行一次 `build_exe.bat` 生成 `AutoMouseMover.exe`
2. 安装 **Inno Setup**：<https://jrsoftware.org/isdl.php>
3. 用 **Inno Setup Compiler** 打开 `setup.iss` 并 **Build**
4. 生成的安装包位于 `installer\Setup-AutoMouseMover-0.6.0.exe`

安装包会把 `Run-GUI.ps1` / `run_gui.bat` / `run_gui.sh` / `README.md` / `AutoMouseMover.ico` /
`Launcher.cs` / `build_exe.bat` / `AutoMouseMover.exe`（若已生成）复制到位，
并在开始菜单和桌面建立带自定义图标的快捷方式。

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
