# ============================================================
#  AutoMouseMover v0.6.1 —— 纯 PowerShell 跨平台版（零编译、双击即用）
#  依赖：
#    • Windows：系统自带 PowerShell + .NET Framework（无需安装）
#    • macOS  ：PowerShell 7（pwsh）+ 系统自带 osascript（无需额外工具）
#    • Linux  ：PowerShell 7（pwsh）+ xdotool（apt/dnf 安装一次）
#  鼠标控制后端：
#    • Windows：user32.dll（内联 C# P/Invoke）
#    • macOS  ：osascript（AppleScript System Events）
#    • Linux  ：xdotool（鼠标移动 / 点击）
#  界面：
#    • Windows：原生 WinForms 图形界面（含托盘、热键）
#    • macOS/Linux：终端交互菜单（因为 PowerShell 在这些系统上没有 WinForms）
#  用法：
#    Windows：双击 run_gui.bat
#    macOS/Linux：pwsh ./Run-GUI.ps1   （或 ./run_gui.sh）
#  v0.6.6 修复底部信息区显示 bug：右列（运行时长/信息行）AutoSize 长文本会顶出窗口右缘截断，且左侧最长状态文案会与右列重叠——改为三行全宽布局：状态行+运行时长（贴右缘）、统计行、信息行独占全宽（AutoEllipsis 超宽省略、随窗口拉伸）；窗体高度 692→714
#  v0.6.5 修虫子：随机模式改用 right+1/bottom+1 作上限，修复最右列/最底行永远到不了；圆周/螺旋/8字的角度每过 2π 折回，修复长时间运行后浮点精度劣化导致轨迹走形；螺旋最大半径取「屏幕半径」与「圆圈半径」较小值，让半径滑块在螺旋模式下也生效
#  v0.6.4 修虫子：方形模式改用独立 sqCorner 角标（修复运行中切到横/纵/斜弹时 dir=0 导致鼠标卡死）；圆圈半径改为实时读取配置（与步长一致，运行中拖动滑块即生效）；Windows 图形界面改用 kernel32 Beep，修复无控制台时「开始/停止」无声
#  v0.6.0 「像个真正的软件」：新增应用图标 AutoMouseMover.ico（鼠标指针+白描边+蓝色渐变，含 16/24/32/48/64 五档，标题栏与托盘改用自有图标而非系统灰图标）；新增 AutoMouseMover.exe 启动器（Launcher.cs + build_exe.bat，用 Windows 自带 csc.exe 编译，Win32 窗口程序、无控制台窗、嵌入图标，双击体验与普通软件一致）；run_gui.bat 改为优先调用 exe、无 exe 时隐藏窗口启动（不再拖黑色控制台窗）；setup.iss 纳入图标/exe/构建链，快捷方式与安装包改用自定义图标
#  v0.6.3 响应式布局：两个卡片区与其中输入框 Anchor 横向铺开、预设方案行拉伸、关于/保存/加载贴右下角，窗口拉大不再挤在左上角；MinimumSize 提到 440x740
#  v0.6.2 窗口可调整大小 + 可最大化全屏：FormBorderStyle=Sizable、MaximizeBox=$true、设 MinimumSize；移除固定圆角 Region（会裁剪缩放）；底栏控件 Anchor=Bottom 贴底
#  v0.6.1 界面现代化：新增 Set-GuiTheme 皮肤（亮色窗体 + 白色卡片式 GroupBox + 蓝色主按钮「开始」+ 扁平下拉/数值框 + Segoe UI 字体 + 圆角窗体），脱离默认灰底 3D 控件，观感更接近现代 Windows 应用
#  v0.5.2 修虫子：修复螺旋模式一点「开始」就整个程序崩溃（[math]::Min 误用 4 个参数，.NET 只有 2 参数重载，报 "Cannot find an overload for Min and the argument count: 4"，改用嵌套取最小值）；接管 WinForms 未处理异常，不再弹出 .NET 自带的英文「Unhandled exception」对话框（改中文提示并自动停止移动，防止连环弹窗）；热键订阅失败时的降级提示改为如实描述；已对 square/spiral/figure8/bounce 四种新模式做隔离逻辑测试（含极小屏与负坐标副屏场景，零越界）
#  v0.5.1 修虫子：修复全局热键完全无效（C# HotkeyPressed 事件从未在 PowerShell 侧订阅，注册成功却无任何响应）；托盘「退出」不再直接关窗（会停止移动、光标回起点并导出统计）；Reset-Engine 补充复位 spiralR/figPhase/dirY（重启后螺旋/8字不再从中间半径继续）；拟人抖动移入 Next-Move（复用已算好的边界，Windows/Linux 每 tick 少一次屏幕枚举）；New-BeepWav 的流对象保证释放；提示音缓存清理后同步清空（避免重复删除/播放已删文件）；网页 /set 对 "0" 不再误判为未提供；网页「停止」导出统计并新增「退出服务」按钮；终端模式输入无效模式时给出提示；主菜单文案与预设子菜单实际选项对齐；热键注册失败时在状态栏可见；run_gui.sh 透传命令行参数
#  v0.5.0 新增网页图形界面：PowerShell 内置 HttpListener 起本地服务（macOS/Linux/Windows 通用，零编译），浏览器即图形界面；命令行 -web 或终端主菜单「网页图形界面」进入；页面支持开始/暂停/继续/停止与 间隔/模式(8种)/步长/半径/点击/自动暂停/声音 实时设置，状态轮询刷新；鼠标移动循环与服务同线程交替，无跨线程问题
#  v0.4.7 自优化迭代 38–46：新增 4 种移动模式(方形/螺旋/8字/斜弹)与未知模式兜底+坐标取整保护；GUI 移动模式由 4 单选钮改为下拉框(可选全部 8 种)；合法模式集中到 $script:validModes(Apply-Dict/终端/命令行共用)；关于/帮助文案同步更新
#  v0.4.6 自优化迭代 29–37：自动暂停去抖(连续2个tick确认，防驱动抖动误判)；终端节奏改用 Stopwatch 消除长期漂移；运行统计导出(-export 自定义路径 / 停止自动写 stats-last.json，GUI·终端·无界面通用)；内置方案 meeting/minimal/gaming/wide 开箱即用(-preset 或终端菜单4)；引擎状态重置抽 Reset-EngineState 去重(-once 复用)；关于/帮助文案补充
#  v0.4.5 自优化迭代 20–28：终端续跑逻辑抽 Term-Resume 去重；自动暂停读取失败不再误暂停；命令行扩展(-click/-sound/-autoPause/-duration/-once/-profile/-help)无界面自动化(Windows 下亦生效，自动跳过图形界面)；Wayland 会话检测与可操作提示；Windows/Linux 显示边界实时读取(macOS 仍缓存)；新增单次移动(-once)与定时自动停止(-duration)
#  v0.4.4 自优化迭代 11–19：终端自动暂停后可按 r 原地继续；停止键升级(s停止/p暂停/r继续)；命令行参数(-interval/-mode/-step/-radius/-run)无界面自动化；显示器序号越界钳制；Windows 光标读取复用 POINT 缓冲；Linux 提示音按频率缓存+会话清理；预设名清洗抽函数；关于/帮助文案更新；暂停时按钮显示「继续」
#  v0.4.3 跨平台性能/体验：macOS/Linux 每 tick 鼠标读/写位置复用缓存（autoPause 关时每 tick 仅 1 个子进程）；点击用缓存坐标省子进程；WAV 生成改用 ASCII 字节（跨 PowerShell 版本稳）；Windows 自动暂停后可「继续」而非回中心重启
#  v0.4.2 健壮性/体验：间隔序列化用 InvariantCulture（跨区域不崩）；加载预设后重注册热键；设置防抖保存（拖动滑块不再反复写盘）；极小屏边界防御；终端运行时实时统计
#  v0.4.1 性能优化：显示范围缓存（macOS 不再每个 tick 调用慢速 system_profiler）；每 tick 鼠标位置只读取一次（减少跨平台子进程开销）
#  v0.4 新增/变更：跨平台（Windows/macOS/Linux）适配，仅保留 PowerShell 单一实现
#  v0.3 功能：多显示器选择、随机模式、缓动曲线、点击节流、托盘菜单、
#             停止回起点、延迟启动、预设方案、运行统计、声音提示
#  v0.2 功能：拟人随机、点击方式、配置持久化、全局热键、开机自启、运行时长
# ============================================================
$ErrorActionPreference = 'Stop'

# ---- 版本常量 ----
$VERSION = 'v0.6.6'
$APP_NAME = 'AutoMouseMover'

# ---- 平台检测 ----
function Get-Platform {
    if ($IsMacOS) { return 'macOS' }
    if ($IsLinux) { return 'Linux' }
    if ($IsWindows) { return 'Windows' }
    if ($env:OS -eq 'Windows_NT') { return 'Windows' }
    $p = [System.Environment]::OSVersion.Platform
    if ($p -eq 'Win32NT') { return 'Windows' }
    # 其余情况（未知）按 Linux 处理（xdotool 路径）
    return 'Linux'
}
$script:platform = Get-Platform

# ---- 配置（跨平台共用，引擎只读写这份 $cfg） ----
$script:cfg = @{
    interval   = 5.0      # decimal，0.1~60
    mode       = 'horizontal'   # 合法值见 $script:validModes：横向/纵/圆/随机/方形/螺旋/8字/斜弹
    ease       = 0        # 0线性 1渐快 2渐慢 3正弦
    step       = 20       # 横/纵步长（像素）
    radius     = 150      # 圆圈半径（像素）
    jitter     = 0        # 随机抖动（像素）
    randPct    = 0        # 间隔随机度（%）
    screen     = 0        # 目标显示器序号（仅 Windows 生效）
    clickType  = 0        # 0无 1左键 2右键 3双击
    clickEvery = 1        # 每 N 次移动点击 1 次
    autoPause  = $true    # 检测到手动移动自动暂停
    tray       = $true    # 关闭窗口最小化到托盘（仅 Windows）
    hotkeyMod  = 0        # 全局热键修饰键（仅 Windows）
    hotkeyKey  = 0        # 全局热键主键（仅 Windows）
    autoStart  = $false   # 开机自启（仅 Windows）
    returnHome = $false   # 停止回到起点
    delay      = 0        # 延迟启动秒数
    sound      = $false   # 声音提示
}

# 合法移动模式（新增模式改这里；Apply-Dict / 终端设置 / 命令行校验共用）
$script:validModes = @('horizontal','vertical','circular','random','square','spiral','figure8','bounce')

# 配置存放位置（跨平台）
if ($script:platform -eq 'Windows') {
    $appDir = Join-Path $env:LOCALAPPDATA 'AutoMouseMover'
} else {
    $xdg = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
    $appDir = Join-Path $xdg 'AutoMouseMover'
}
$settingsPath = Join-Path $appDir 'settings.ini'
$profilesDir  = Join-Path $appDir 'profiles'

# 内置方案（开箱即用，无需用户保存）
$BUILTIN_PRESETS = [ordered]@{
    'meeting' = [ordered]@{ interval=10;  mode='circular';  radius=80;  step=10; clickType=0; clickEvery=1; autoPause=$false; jitter=0 }
    'minimal' = [ordered]@{ interval=30;  mode='horizontal';step=5;  clickType=0; clickEvery=1; autoPause=$true;  jitter=0 }
    'gaming'  = [ordered]@{ interval=3;   mode='random';    radius=120;step=15; clickType=1; clickEvery=5; autoPause=$false; jitter=40 }
    'wide'    = [ordered]@{ interval=8;   mode='circular';  radius=300;step=20; clickType=0; clickEvery=1; autoPause=$true;  jitter=0 }
}
function Apply-BuiltinPreset { param($key)
    if (-not $BUILTIN_PRESETS.Contains($key)) { return $false }
    foreach ($k in $BUILTIN_PRESETS[$key].Keys) { $script:cfg[$k] = $BUILTIN_PRESETS[$key][$k] }
    return $true
}

function Clamp-Int { param([int]$v, [int]$min, [int]$max)
    if ($v -lt $min) { return $min }
    if ($v -gt $max) { return $max }
    return $v
}

# 把 $cfg 序列化成 ini 行（供保存/预设方案复用）
function Get-SettingsLines {
    return @(
        "interval=$($script:cfg.interval.ToString([System.Globalization.CultureInfo]::InvariantCulture))"
        "mode=$($script:cfg.mode)"
        "ease=$($script:cfg.ease)"
        "step=$($script:cfg.step)"
        "radius=$($script:cfg.radius)"
        "jitter=$($script:cfg.jitter)"
        "randPct=$($script:cfg.randPct)"
        "screen=$($script:cfg.screen)"
        "clickType=$($script:cfg.clickType)"
        "clickEvery=$($script:cfg.clickEvery)"
        "autoPause=$(if ($script:cfg.autoPause) { 1 } else { 0 })"
        "tray=$(if ($script:cfg.tray) { 1 } else { 0 })"
        "hotkeyMod=$($script:cfg.hotkeyMod)"
        "hotkeyKey=$($script:cfg.hotkeyKey)"
        "autoStart=$(if ($script:cfg.autoStart) { 1 } else { 0 })"
        "returnHome=$(if ($script:cfg.returnHome) { 1 } else { 0 })"
        "delay=$($script:cfg.delay)"
        "sound=$(if ($script:cfg.sound) { 1 } else { 0 })"
    )
}

# 把读取到的字典写回 $cfg（带钳制与类型转换）
function Apply-Dict { param($dict)
    if ($dict.ContainsKey('interval')) {
        try {
            $inv = [System.Globalization.CultureInfo]::InvariantCulture
            $v = [decimal]::Parse([string]$dict['interval'], $inv)
            if ($v -lt 0.1) { $v = 0.1 }; if ($v -gt 60) { $v = 60 }
            $script:cfg.interval = $v
        } catch { }
    }
    if ($dict.ContainsKey('mode')) {
        $m = $dict['mode']
        if ($script:validModes -contains $m) { $script:cfg.mode = $m }
    }
    if ($dict.ContainsKey('ease'))       { $script:cfg.ease       = Clamp-Int ([int]$dict['ease']) 0 3 }
    if ($dict.ContainsKey('step'))       { $script:cfg.step       = Clamp-Int ([int]$dict['step']) 1 1000 }
    if ($dict.ContainsKey('radius'))     { $script:cfg.radius     = Clamp-Int ([int]$dict['radius']) 10 2000 }
    if ($dict.ContainsKey('jitter'))     { $script:cfg.jitter     = Clamp-Int ([int]$dict['jitter']) 0 200 }
    if ($dict.ContainsKey('randPct'))    { $script:cfg.randPct    = Clamp-Int ([int]$dict['randPct']) 0 100 }
    if ($dict.ContainsKey('clickEvery')) { $script:cfg.clickEvery = Clamp-Int ([int]$dict['clickEvery']) 1 100 }
    if ($dict.ContainsKey('delay'))      { $script:cfg.delay      = Clamp-Int ([int]$dict['delay']) 0 120 }
    if ($dict.ContainsKey('screen'))     { $script:cfg.screen     = [int]$dict['screen'] }
    if ($dict.ContainsKey('clickType'))  { $script:cfg.clickType  = Clamp-Int ([int]$dict['clickType']) 0 3 }
    if ($dict.ContainsKey('hotkeyMod'))  { $script:cfg.hotkeyMod  = Clamp-Int ([int]$dict['hotkeyMod']) 0 5 }
    if ($dict.ContainsKey('hotkeyKey'))  { $script:cfg.hotkeyKey  = Clamp-Int ([int]$dict['hotkeyKey']) 0 17 }
    if ($dict.ContainsKey('autoPause'))  { $script:cfg.autoPause  = (([int]$dict['autoPause'])  -eq 1) }
    if ($dict.ContainsKey('tray'))       { $script:cfg.tray       = (([int]$dict['tray'])       -eq 1) }
    if ($dict.ContainsKey('returnHome')) { $script:cfg.returnHome = (([int]$dict['returnHome']) -eq 1) }
    if ($dict.ContainsKey('sound'))      { $script:cfg.sound      = (([int]$dict['sound'])      -eq 1) }
    if ($dict.ContainsKey('autoStart'))  { $script:cfg.autoStart  = (([int]$dict['autoStart'])  -eq 1) }
}

function Save-Settings {
    try {
        if (-not (Test-Path $appDir)) { New-Item -ItemType Directory -Path $appDir -Force | Out-Null }
        Set-Content -Path $settingsPath -Value (Get-SettingsLines) -Encoding ASCII
    } catch { }
}

function Load-Settings {
    $script:cfgDirty = $false
    $script:loading = $true
    try {
        if (-not (Test-Path $settingsPath)) { return }
        $dict = @{}
        foreach ($ln in (Get-Content $settingsPath)) {
            $eq = $ln.IndexOf('=')
            if ($eq -gt 0) { $dict[$ln.Substring(0, $eq)] = $ln.Substring($eq + 1) }
        }
        Apply-Dict $dict
    } catch { }
    $script:loading = $false
}

# 设置防抖：编辑控件时只置脏标记，由 saveTimer 周期性落盘，避免拖动滑块反复写文件
function Mark-Dirty { $script:cfgDirty = $true }

# 预设方案名清洗：去掉文件系统非法字符，避免生成怪异文件名（多处复用）
function Sanitize-Name { param($name)
    $name = $name.Trim()
    foreach ($c in [System.IO.Path]::GetInvalidFileNameChars()) { $name = $name.Replace([string]$c, '_') }
    return $name
}

# 运行统计导出（JSON）；CLI -export 或停止时自动落盘 stats-last.json
function Export-Stats { param([string]$path)
    try {
        $obj = [ordered]@{
            app            = $APP_NAME
            version        = $VERSION
            platform       = $script:platform
            exportedAt     = (Get-Date).ToString('o')
            moves          = $script:count
            clicks         = $script:clickCount
            totalDistancePx = $script:totalDist
            config         = $script:cfg
        }
        Set-Content -Path $path -Value ($obj | ConvertTo-Json -Depth 2) -Encoding UTF8
        return $true
    } catch { return $false }
}
function Write-StatsIfRequested {
    try {
        if ($null -ne $script:cliExport) {
            if (Export-Stats $script:cliExport) { Write-Host ("统计已导出：$($script:cliExport)") -ForegroundColor Green }
        } elseif ($script:count -gt 0) {
            $def = Join-Path $appDir 'stats-last.json'
            if (Export-Stats $def) { Write-Host ("统计已保存：$def") -ForegroundColor DarkGray }
        }
    } catch { }
}

# ============================================================
#  鼠标后端（按平台统一封装，引擎只调用下面四个函数）
# ============================================================
if ($script:platform -eq 'Windows') {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()

    # 未处理异常统一接管。
    # 背景：原来不注册 ThreadException，界面线程（计时器 tick / 按钮点击）里一旦抛异常，
    # WinForms 就会弹出 .NET 自带的「Unhandled exception has occurred...」对话框——
    # 那段文字是 .NET Framework 的语言资源写的、固定为英文，而且带 Continue/Quit 按钮，
    # 用户完全看不懂发生了什么。这里换成中文提示，并顺手把移动停下来，避免连环弹窗。
    try {
        [System.Windows.Forms.Application]::SetUnhandledExceptionMode([System.Windows.Forms.UnhandledExceptionMode]::CatchException)
        [System.Windows.Forms.Application]::add_ThreadException({
            param($sender, $te)
            try {
                # 引擎出错时先停掉移动：否则同一个错误会在每个 tick 反复触发、连环弹窗
                if ($script:running -or $script:counting -or $script:paused) {
                    try { Stop-GuiMover } catch { }
                }
                [void][System.Windows.Forms.MessageBox]::Show(
                    "程序内部出现了一个错误，已被安全拦截，可以继续使用。`n`n错误信息：`n$($te.Exception.Message)`n`n如果这个问题反复出现，请把上面这段文字反馈给作者。",
                    "$APP_NAME $VERSION")
            } catch { }
        })
    } catch { }

    $win32 = @'
using System;
using System.Runtime.InteropServices;
public class Win32Mouse {
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, UIntPtr dwExtraInfo);
    [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT lpPoint);
    [DllImport("user32.dll")] public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);
    [DllImport("user32.dll")] public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
}
// 提示音：用 kernel32 的 Beep 而非 [console]::Beep。后者在「无控制台窗」的 WinExe（双击 AutoMouseMover.exe）里
// 会抛「The handle is invalid」，导致 Windows 图形界面下开始/停止完全无声；kernel32 Beep 不依赖控制台，GUI/终端都可用。
public class Win32Beep {
    [DllImport("kernel32.dll")] public static extern bool Beep(uint dwFreq, uint dwDuration);
}
public struct POINT { public int X; public int Y; }
public class HotkeyForm : System.Windows.Forms.Form {
    public event System.Action HotkeyPressed;
    private const int WM_HOTKEY = 0x0312;
    protected override void WndProc(ref System.Windows.Forms.Message m) {
        if (m.Msg == WM_HOTKEY && HotkeyPressed != null) HotkeyPressed();
        base.WndProc(ref m);
    }
}
'@
    Add-Type -TypeDefinition $win32 -Language CSharp -ReferencedAssemblies System.Windows.Forms,System.Drawing
}

function Set-MousePosition { param([int]$x, [int]$y)
    if ($script:platform -eq 'Windows') {
        [Win32Mouse]::SetCursorPos($x, $y) | Out-Null
    } elseif ($script:platform -eq 'macOS') {
        $sc = "tell application `"System Events`" to set mouse position to {$x, $y}"
        & osascript -e $sc 2>$null
    } else {
        if ($script:hasXdotool) { & xdotool mousemove $x $y 2>$null }
    }
    # 记录我们“发出的”目标位置，供下一 tick 计距离/点击复用，避免再读一次鼠标（macOS/Linux 省一个子进程）
    $script:lastSetX = $x; $script:lastSetY = $y
}

function Get-MousePosition {
    if ($script:platform -eq 'Windows') {
        if ($null -eq $script:ptBuf) { $script:ptBuf = New-Object POINT }
        if ([Win32Mouse]::GetCursorPos([ref]$script:ptBuf)) { return @{ x = $script:ptBuf.X; y = $script:ptBuf.Y } }
        return $null
    } elseif ($script:platform -eq 'macOS') {
        $out = & osascript -e "tell application `"System Events`" to get mouse position" 2>$null
        if ($out -match '\{?\s*(-?\d+)\s*,\s*(-?\d+)\s*\}?') {
            return @{ x = [int]$Matches[1]; y = [int]$Matches[2] }
        }
        return $null
    } else {
        if (-not $script:hasXdotool) { return $null }
        $out = & xdotool getmouselocation --shell 2>$null
        $mx = $null; $my = $null
        foreach ($line in $out) {
            if ($line -match '^X=(\d+)') { $mx = [int]$Matches[1] }
            if ($line -match '^Y=(\d+)') { $my = [int]$Matches[1] }
        }
        if ($null -ne $mx) { return @{ x = $mx; y = $my } }
        return $null
    }
}

function Send-Click { param([int]$type)
    if ($type -eq 0) { return }
    if ($script:platform -eq 'Windows') {
        switch ($type) {
            1 { [Win32Mouse]::mouse_event(0x0002,0,0,0,[UIntPtr]::Zero); [Win32Mouse]::mouse_event(0x0004,0,0,0,[UIntPtr]::Zero) }
            2 { [Win32Mouse]::mouse_event(0x0008,0,0,0,[UIntPtr]::Zero); [Win32Mouse]::mouse_event(0x0010,0,0,0,[UIntPtr]::Zero) }
            3 { 1..2 | ForEach-Object { [Win32Mouse]::mouse_event(0x0002,0,0,0,[UIntPtr]::Zero); [Win32Mouse]::mouse_event(0x0004,0,0,0,[UIntPtr]::Zero) } }
        }
    } elseif ($script:platform -eq 'macOS') {
        # 优先用我们刚移动到的位置（同一 tick 内与真实光标一致），省掉一次 Get-MousePosition 子进程
        $x = $script:lastSetX; $y = $script:lastSetY
        if ($null -eq $x) { $p = Get-MousePosition; if ($null -eq $p) { $x = 10; $y = 10 } else { $x = $p.x; $y = $p.y } }
        if (Get-Command cliclick -ErrorAction SilentlyContinue) {
            switch ($type) {
                1 { & cliclick "c:$x,$y" }
                2 { & cliclick "rc:$x,$y" }
                3 { & cliclick "c:$x,$y"; & cliclick "c:$x,$y" }
            }
        } else {
            $sc = "tell application `"System Events`" to click at {$x, $y}"
            & osascript -e $sc 2>$null
            if ($type -eq 3) { & osascript -e $sc 2>$null }
            # 注：无 cliclick 时，右键/双击退化为左键单击
        }
    } else {
        if (-not $script:hasXdotool) { return }
        switch ($type) {
            1 { & xdotool click 1 }
            2 { & xdotool click 3 }
            3 { & xdotool click 1; & xdotool click 1 }
        }
    }
}

function Get-DisplayBounds {
    if ($script:platform -eq 'Windows') {
        $idx = [int]$script:cfg.screen
        $screens = [System.Windows.Forms.Screen]::AllScreens
        if ($idx -ge 0 -and $idx -lt $screens.Count) {
            $wa = $screens[$idx].WorkingArea
        } else {
            $s = [System.Windows.Forms.Screen]::PrimaryScreen
            if ($null -eq $s) { $s = $screens[0] }
            $wa = $s.WorkingArea
        }
        return @{ x = $wa.X; y = $wa.Y; w = $wa.Width; h = $wa.Height }
    } elseif ($script:platform -eq 'macOS') {
        $out = & system_profiler SPDisplaysDataType 2>$null
        $w = $null; $h = $null
        foreach ($line in $out) {
            if ($line -match 'UI Looks like:\s*(\d+)\s*x\s*(\d+)') { $w = [int]$Matches[1]; $h = [int]$Matches[2]; break }
            if ($null -eq $w -and $line -match 'Resolution:\s*(\d+)\s*x\s*(\d+)') { $w = [int]$Matches[1]; $h = [int]$Matches[2] }
        }
        if ($null -eq $w) { $w = 1440; $h = 900 }
        return @{ x = 0; y = 0; w = $w; h = $h }
    } else {
        $w = $null; $h = $null
        if ($script:hasXdotool) {
            $g = & xdotool getdisplaygeometry 2>$null
            if ($g -match '(\d+)\s+(\d+)') { $w = [int]$Matches[1]; $h = [int]$Matches[2] }
        }
        if ($null -eq $w) {
            $r = & xrandr 2>$null | Select-String 'primary' | Select-Object -First 1
            if ($r -and $r -match '(\d+)x(\d+)') { $w = [int]$Matches[1]; $h = [int]$Matches[2] }
        }
        if ($null -eq $w) { $w = 1920; $h = 1080 }
        return @{ x = 0; y = 0; w = $w; h = $h }
    }
}

# 显示范围缓存：Get-DisplayBounds 在 macOS 上会调用慢速 system_profiler（每次 1~2 秒），
# 绝对不能每个 tick 都调。统一从这里取，必要时 Invalidate-Bounds 后重载。
$script:boundsCache = $null
function Get-Bounds {
    # macOS 上 system_profiler 慢，仍用缓存；Windows/Linux 实时读取（便宜且支持热插拔显示器）
    if ($script:platform -eq 'macOS') {
        if ($null -eq $script:boundsCache) { $script:boundsCache = Get-DisplayBounds }
        return $script:boundsCache
    }
    return Get-DisplayBounds
}
function Invalidate-Bounds { $script:boundsCache = $null }

# Linux：检测 xdotool 是否可用；Wayland 会话下 xdotool 通常无效
$script:isWayland = $false
if ($script:platform -eq 'Linux') {
    if ($env:XDG_SESSION_TYPE -eq 'wayland') { $script:isWayland = $true }
    $script:hasXdotool = [bool](Get-Command xdotool -ErrorAction SilentlyContinue)
    if (-not $script:hasXdotool) {
        if ($script:isWayland) {
            Write-Host '[警告] 当前为 Wayland 会话，xdotool 默认无效。可二选一：' -ForegroundColor Yellow
            Write-Host '        1) 注销后选择「Ubuntu on Xorg」等 X11 会话登录（最省事）' -ForegroundColor Yellow
            Write-Host '        2) 安装 ydotool 并启动 ydotoold 守护进程（sudo apt install ydotool）' -ForegroundColor Yellow
            Write-Host '        若已装 xdotool 且走 XWayland 兼容层，可忽略此提示。' -ForegroundColor DarkGray
        } else {
            Write-Host '[警告] 未检测到 xdotool，鼠标移动/点击可能无效。请安装：' -ForegroundColor Yellow
            Write-Host '        Debian/Ubuntu: sudo apt install xdotool' -ForegroundColor Yellow
            Write-Host '        Fedora/RHEL  : sudo dnf install xdotool' -ForegroundColor Yellow
        }
    }
} else {
    $script:hasXdotool = $false
}

# 声音提示（跨平台）
function Play-NotifySound { param([int]$freq)
    if (-not $script:cfg.sound) { return }
    try {
        if ($script:platform -eq 'Windows') {
            try { [Win32Beep]::Beep([uint]$freq, 120) } catch { try { [console]::Beep($freq, 120) } catch { } }
        } elseif ($script:platform -eq 'macOS') {
            & osascript -e 'beep' 2>$null
        } else {
            $tmpdir = if ($env:TMP) { $env:TMP } elseif ($env:TEMP) { $env:TEMP } else { '/tmp' }
            $key = [string]$freq
            if (-not $script:beepCache.ContainsKey($key)) {
                $tmp = Join-Path $tmpdir ("amm_beep_$freq.wav")
                New-BeepWav $tmp $freq 120
                $script:beepCache[$key] = $tmp
            }
            $tmp = $script:beepCache[$key]
            if (Get-Command aplay -ErrorAction SilentlyContinue) { & aplay $tmp 2>$null }
            elseif (Get-Command paplay -ErrorAction SilentlyContinue) { & paplay $tmp 2>$null }
            else { Write-Host ([char]7) -NoNewline }
        }
    } catch { }
}
function New-BeepWav { param($path, $freq, $ms)
    $msb = $null; $bw = $null
    try {
        $sr = 44100; $dur = [double]$ms / 1000; $n = [int]($sr * $dur)
        $msb = New-Object System.IO.MemoryStream
        $bw = New-Object System.IO.BinaryWriter($msb)
        $bw.Write([System.Text.Encoding]::ASCII.GetBytes('RIFF')); $bw.Write([int32](36 + 2 * $n)); $bw.Write([System.Text.Encoding]::ASCII.GetBytes('WAVE'))
        $bw.Write([System.Text.Encoding]::ASCII.GetBytes('fmt ')); $bw.Write([int32]16); $bw.Write([int16]1); $bw.Write([int16]1)
        $bw.Write([int32]$sr); $bw.Write([int32]($sr * 2)); $bw.Write([int16]2); $bw.Write([int16]16)
        $bw.Write([System.Text.Encoding]::ASCII.GetBytes('data')); $bw.Write([int32](2 * $n))
        for ($i = 0; $i -lt $n; $i++) {
            $s = [int16](28000 * [math]::Sin(2 * [math]::PI * $freq * $i / $sr))
            $bw.Write($s)
        }
        [System.IO.File]::WriteAllBytes($path, $msb.ToArray())
    } catch { }
    finally {
        # 无论成功失败都释放：否则异常路径下 MemoryStream/BinaryWriter 会一直持有句柄
        if ($null -ne $bw)  { try { $bw.Close() } catch { } }
        if ($null -ne $msb) { try { $msb.Dispose() } catch { } }
    }
}

# 清理提示音临时文件并清空缓存（原实现只删文件不清缓存，
# 导致再次进入网页模式时会拿着已删除的路径去播放、且重复删除）
function Clear-BeepCache {
    foreach ($k in @($script:beepCache.Keys)) {
        try { Remove-Item $script:beepCache[$k] -ErrorAction SilentlyContinue } catch { }
    }
    $script:beepCache = @{}
}

# ============================================================
#  移动引擎（平台无关）
# ============================================================
$script:engine = @{ margin = 10; radius = 150; circleStep = 6.0; angle = 0.0; dir = 1; easePhase = 0.0; current = $null }
# 运行态
$script:running = $false
$script:counting = $false
$script:countdownLeft = 0
$script:count = 0
$script:clickCount = 0
$script:totalDist = 0
$script:moveSinceClick = 0
$script:lastX = $null
$script:lastY = $null
$script:lastSetX = $null
$script:lastSetY = $null
$script:paused = $false
$script:ptBuf = $null
$script:beepCache = @{}
$script:homeX = $null
$script:homeY = $null
$script:firstTick = $false
$script:startTime = $null
$script:exiting = $false
$script:trunning = $false
$script:loading = $false
$script:cfgDirty = $false
$script:moveStreak = 0      # 自动暂停去抖：连续 N 个 tick 检测到移动才暂停
$script:cliExport = $null   # 命令行 -export 指定的统计导出路径
$script:webRunning = $false # 网页图形界面：服务运行中
$script:nextTickAt  = $null # 网页图形界面：下一 tick 的计划时间
$script:webListener = $null # 网页图形界面：HttpListener 实例

function Get-EaseFactor {
    switch ([int]$script:cfg.ease) {
        1 { return (0.4 + 0.8 * $script:engine.easePhase) }              # 渐快
        2 { return (1.2 - 0.8 * $script:engine.easePhase) }              # 渐慢
        3 { return (1.0 + 0.5 * [math]::Sin($script:engine.easePhase * 2 * [math]::PI)) }  # 正弦
        default { return 1.0 }
    }
}

function Reset-Engine {
    Invalidate-Bounds
    $b = Get-Bounds
    # 钳制目标显示器序号，避免 settings.ini 里残留的越界序号与界面下拉框不一致
    if ($script:platform -eq 'Windows') {
        $cnt = [System.Windows.Forms.Screen]::AllScreens.Count
        if ([int]$script:cfg.screen -lt 0 -or [int]$script:cfg.screen -ge $cnt) { $script:cfg.screen = 0 }
    }
    # 连同各模式专属状态一起复位：否则螺旋/8字会从上一轮的中间半径继续，
    # 斜向反弹的 dirY 也可能残留为 -1（表现为"重启后轨迹不对称/不从中心开始"）
    $script:engine.current   = @{ x = [int]($b.x + $b.w / 2); y = [int]($b.y + $b.h / 2) }
    $script:engine.angle     = 0.0
    $script:engine.dir       = 1
    $script:engine.dirY      = 1
    $script:engine.spiralR   = 0.0
    $script:engine.figPhase  = 0.0
    $script:engine.easePhase = 0.0
    $script:engine.radius    = [int]$script:cfg.radius
    $script:engine.sqCorner  = 0      # 方形模式专属角标：必须独立，否则会复用 dir 并可能取到 0，切到横/纵/斜弹时卡死
}

function Next-Move {
    if ($null -eq $script:engine.current) { Reset-Engine }
    $b = Get-Bounds
    $m = $script:engine.margin
    $left = $b.x + $m; $right = $b.x + $b.w - $m
    $top = $b.y + $m; $bottom = $b.y + $b.h - $m
    if ($right -lt $left) { $right = $left }
    if ($bottom -lt $top) { $bottom = $top }
    $x = $script:engine.current.x; $y = $script:engine.current.y

    $script:engine.easePhase += 0.08
    if ($script:engine.easePhase -gt 1.0) { $script:engine.easePhase -= 1.0 }
    $effStep = [int][math]::Round($script:cfg.step * (Get-EaseFactor))
    if ($effStep -lt 1) { $effStep = 1 }

    $mode = $script:cfg.mode
    if ($mode -eq 'horizontal') {
        $nx = $x + $script:engine.dir * $effStep
        if ($nx -ge $right) { $nx = $right; $script:engine.dir = -1 }
        elseif ($nx -le $left) { $nx = $left; $script:engine.dir = 1 }
        $x = $nx
    } elseif ($mode -eq 'vertical') {
        $ny = $y + $script:engine.dir * $effStep
        if ($ny -ge $bottom) { $ny = $bottom; $script:engine.dir = -1 }
        elseif ($ny -le $top) { $ny = $top; $script:engine.dir = 1 }
        $y = $ny
    } elseif ($mode -eq 'random') {
        # Get-Random 的 -Maximum 是「开区间」（不含该值），要用 right+1/bottom+1 才能让最右列、最底行也被选中
        $x = Get-Random -Minimum $left -Maximum ([math]::Max($left + 1, $right + 1))
        $y = Get-Random -Minimum $top -Maximum ([math]::Max($top + 1, $bottom + 1))
    } elseif ($mode -eq 'square') {
        # 方形巡逻：依次朝四个角斜向移动（用独立的 sqCorner 当角标，绝不碰 dir，否则 dir 可能被置 0 导致切到横/纵/斜弹时卡死）
        $corners = @(@{x=$left;y=$top}, @{x=$right;y=$top}, @{x=$right;y=$bottom}, @{x=$left;y=$bottom})
        $ci = ([int]$script:engine.sqCorner) % 4; if ($ci -lt 0) { $ci = 0 }
        $tgt = $corners[$ci]
        $dx = $tgt.x - $x; $dy = $tgt.y - $y
        if ([math]::Abs($dx) -le $effStep -and [math]::Abs($dy) -le $effStep) {
            $x = $tgt.x; $y = $tgt.y; $script:engine.sqCorner = ($ci + 1) % 4
        } else {
            if ($dx -ne 0) { $x += [math]::Sign($dx) * [math]::Min($effStep, [math]::Abs($dx)) }
            if ($dy -ne 0) { $y += [math]::Sign($dy) * [math]::Min($effStep, [math]::Abs($dy)) }
        }
    } elseif ($mode -eq 'spiral') {
        # 螺旋：从中心向外，半径递增，触边界后重来
        $cx = [int]($b.x + $b.w / 2); $cy = [int]($b.y + $b.h / 2)
        if ($null -eq $script:engine.spiralR) { $script:engine.spiralR = 0.0 }
        $script:engine.angle += 0.25
        # 角度无限累加会让浮点精度在长期运行后劣化、轨迹走形；每过 2π 折回
        if ($script:engine.angle -gt [math]::PI * 2) { $script:engine.angle -= [math]::PI * 2 }
        $script:engine.spiralR += 0.8
        # 螺旋最大半径取「屏幕可用半径」与「用户设定的圆圈半径」较小值，
        # 这样「圆圈半径」滑块在螺旋模式下也生效（否则该控件在螺旋下完全无效）。
        $screenMaxR = [math]::Min([math]::Min($cx - $left, $right - $cx), [math]::Min($cy - $top, $bottom - $cy))
        if ($screenMaxR -le 1) { $screenMaxR = 1 }
        $maxR = [math]::Min([int]$script:cfg.radius, $screenMaxR)
        if ($maxR -lt 10) { $maxR = 10 }
        if ($script:engine.spiralR -gt $maxR) { $script:engine.spiralR = 0.0 }
        $x = $cx + [int]($script:engine.spiralR * [math]::Cos($script:engine.angle))
        $y = $cy + [int]($script:engine.spiralR * [math]::Sin($script:engine.angle))
    } elseif ($mode -eq 'figure8') {
        # 8字：双纽线参数方程
        $cx = [int]($b.x + $b.w / 2); $cy = [int]($b.y + $b.h / 2)
        if ($null -eq $script:engine.figPhase) { $script:engine.figPhase = 0.0 }
        $script:engine.figPhase += 0.06
        # 角度无限累加会令浮点精度在长期运行后劣化；每过 2π 折回，保证 8 字轨迹稳定
        if ($script:engine.figPhase -gt [math]::PI * 2) { $script:engine.figPhase -= [math]::PI * 2 }
        $rx = [math]::Max(10, ($right - $left) / 2); $ry = [math]::Max(10, ($bottom - $top) / 2)
        $x = $cx + [int]($rx * [math]::Sin($script:engine.figPhase))
        $y = $cy + [int]($ry * [math]::Sin($script:engine.figPhase) * [math]::Cos($script:engine.figPhase))
    } elseif ($mode -eq 'bounce') {
        # 斜向反弹：带 y 方向速度（dirY），撞四边都反弹
        if ($null -eq $script:engine.dirY) { $script:engine.dirY = 1 }
        $nx = $x + $script:engine.dir * $effStep
        $ny = $y + $script:engine.dirY * $effStep
        if ($nx -ge $right) { $nx = $right; $script:engine.dir = -1 } elseif ($nx -le $left) { $nx = $left; $script:engine.dir = 1 }
        if ($ny -ge $bottom) { $ny = $bottom; $script:engine.dirY = -1 } elseif ($ny -le $top) { $ny = $top; $script:engine.dirY = 1 }
        $x = $nx; $y = $ny
    } elseif ($mode -eq 'circular') {
        $cx = [int]($b.x + $b.w / 2); $cy = [int]($b.y + $b.h / 2)
        $script:engine.angle += $script:engine.circleStep * [math]::PI / 180
        # 角度无限累加会让浮点精度在长期运行后劣化、圆越画越「椭圆」；每过 2π 折回
        if ($script:engine.angle -gt [math]::PI * 2) { $script:engine.angle -= [math]::PI * 2 }
        $r = [int]$script:cfg.radius
        $nx = $cx + [int]($r * [math]::Cos($script:engine.angle))
        $ny = $cy + [int]($r * [math]::Sin($script:engine.angle))
        if ($nx -lt $left) { $nx = $left } elseif ($nx -gt $right) { $nx = $right }
        if ($ny -lt $top) { $ny = $top } elseif ($ny -gt $bottom) { $ny = $bottom }
        $x = $nx; $y = $ny
    } else {
        # 未知模式兜底：按横向处理（settings.ini 残留旧/异常值时不至于静止）
        $nx = $x + $script:engine.dir * $effStep
        if ($nx -ge $right) { $nx = $right; $script:engine.dir = -1 }
        elseif ($nx -le $left) { $nx = $left; $script:engine.dir = 1 }
        $x = $nx
    }
    # 拟人化：目标点附近附加随机抖动。
    # 放在这里而不是 Do-Step：Next-Move 已经算好了 $left/$right/$top/$bottom，
    # 无需再调一次 Get-Bounds（Windows/Linux 上每次都是屏幕枚举，省一次）。
    $j = [int]$script:cfg.jitter
    if ($j -gt 0) {
        $x = $x + (Get-Random -Minimum (-$j) -Maximum ($j + 1))
        $y = $y + (Get-Random -Minimum (-$j) -Maximum ($j + 1))
        if ($x -lt $left) { $x = $left } elseif ($x -gt $right) { $x = $right }
        if ($y -lt $top) { $y = $top } elseif ($y -gt $bottom) { $y = $bottom }
    }
    $x = [int]$x; $y = [int]$y
    $script:engine.current = @{ x = $x; y = $y }
    return @{ x = $x; y = $y }
}

function Do-Step {
    param($prePos = $null)
    $ct = [int]$script:cfg.clickType
    $every = [int]$script:cfg.clickEvery
    if ($every -lt 1) { $every = 1 }

    if ($null -eq $prePos) {
        if ($null -ne $script:lastSetX) { $prePos = @{ x = $script:lastSetX; y = $script:lastSetY } }
        else { $prePos = Get-MousePosition }
    }
    $ox = $null; $oy = $null
    if ($null -ne $prePos) { $ox = $prePos.x; $oy = $prePos.y }

    $pt = Next-Move

    Set-MousePosition $pt.x $pt.y

    if ($ct -gt 0 -and ($script:moveSinceClick % $every) -eq 0) {
        Send-Click $ct
        $script:clickCount++
    }
    $script:moveSinceClick++
    $script:count++

    if ($null -ne $ox) {
        $script:totalDist += ([math]::Abs($pt.x - $ox) + [math]::Abs($pt.y - $oy))
    }
    $script:lastX = $pt.x; $script:lastY = $pt.y
}

# 单个 tick：先做首 tick 跳过自动暂停，否则检测手动移动；再移动。返回 $false 表示应暂停
function Apply-Once {
    if ($script:firstTick) {
        $script:firstTick = $false
        Do-Step
        return $true
    }
    if ($script:cfg.autoPause -and $null -ne $script:lastX) {
        $p = Get-MousePosition
        if ($null -eq $p) {
            # 读取失败（如后端临时不可用）：不误判为手动移动，也不把 null 传给 Do-Step（避免重复读取）
            Do-Step
            return $true
        }
        $moved = ([math]::Abs($p.x - $script:lastX) -gt 3 -or [math]::Abs($p.y - $script:lastY) -gt 3)
        if ($moved) {
            # 去抖：个别驱动/高 DPI 下会有 1 像素抖动，需连续 2 个 tick 都检测到移动才判定为手动操作
            $script:moveStreak++
            if ($script:moveStreak -ge 2) { return $false }
            # 宽限 1 个 tick：本 tick 让出控制权（不移动），避免与用户抢光标
            return $true
        }
        $script:moveStreak = 0
        Do-Step $p
        return $true
    }
    Do-Step
    return $true
}

function Compute-IntervalMs {
    $baseMs = [math]::Max(10, [int][math]::Round($script:cfg.interval * 1000))
    $rp = [int]$script:cfg.randPct
    if ($rp -gt 0) {
        $delta = Get-Random -Minimum (-$rp) -Maximum ($rp + 1)
        $factor = 1.0 + $delta / 100.0
        return [math]::Max(10, [int][math]::Round($baseMs * $factor))
    }
    return $baseMs
}

# 重置引擎与运行计数（界面无关；-once 与 Begin-RunCore 共用，避免重复代码）
function Reset-EngineState {
    Reset-Engine
    $script:count = 0
    $script:clickCount = 0
    $script:totalDist = 0
    $script:moveSinceClick = 0
    $script:lastX = $null; $script:lastY = $null
    $script:homeX = $null; $script:homeY = $null
    $script:moveStreak = 0
    $hp = Get-MousePosition
    if ($null -ne $hp) { $script:homeX = $hp.x; $script:homeY = $hp.y }
}

# 开始运行的核心（界面无关）
function Begin-RunCore {
    Reset-EngineState
    $script:startTime = Get-Date
    Do-Step
    $script:running = $true
    $script:firstTick = $true
    Play-NotifySound 880
}

# 停止运行的核心（界面无关）
function Stop-MoverCore {
    $wasActive = ($script:running -or $script:counting)
    $script:counting = $false
    $script:running = $false
    $script:lastX = $null; $script:lastY = $null
    $script:startTime = $null
    if ($wasActive -and $script:cfg.returnHome -and $null -ne $script:homeX) {
        Set-MousePosition $script:homeX $script:homeY
    }
    if ($wasActive) { Play-NotifySound 440 }
}

# 载入上次配置
Load-Settings

# ============================================================
#  网页图形界面（macOS / Linux / Windows 通用，零编译）
#  用 PowerShell 内置 HttpListener 起本地服务，浏览器即图形界面；
#  鼠标移动循环与服务处理在同一个线程交替执行，无跨线程状态问题。
#  入口：命令行 -web，或终端主菜单「网页图形界面」。
# ============================================================
function Open-Browser { param($url)
    try {
        if ($script:platform -eq 'macOS') { & open $url 2>$null }
        elseif ($script:platform -eq 'Linux') { if (Get-Command xdg-open -ErrorAction SilentlyContinue) { & xdg-open $url 2>$null } }
        else { try { Start-Process $url } catch { } }
    } catch { }
}

function Get-WebStatusJson {
    $up = 0
    if ($null -ne $script:startTime) { $up = [int]((Get-Date) - $script:startTime).TotalSeconds }
    $o = [ordered]@{
        running   = [bool]$script:running
        paused    = [bool]$script:paused
        count     = [int]$script:count
        clicks    = [int]$script:clickCount
        dist      = [int]$script:totalDist
        uptime    = $up
        mode      = [string]$script:cfg.mode
        interval  = ($script:cfg.interval.ToString([System.Globalization.CultureInfo]::InvariantCulture))
        step      = [int]$script:cfg.step
        radius    = [int]$script:cfg.radius
        click     = [int]$script:cfg.clickType
        autoPause = [bool]$script:cfg.autoPause
        sound     = [bool]$script:cfg.sound
        platform  = [string]$script:platform
        version   = [string]$VERSION
    }
    return ($o | ConvertTo-Json -Depth 2 -Compress)
}

function Send-WebResponse { param($ctx, [string]$content, [string]$ctype = 'application/json; charset=utf-8')
    try {
        $buf = [System.Text.Encoding]::UTF8.GetBytes($content)
        $ctx.Response.ContentType = $ctype
        $ctx.Response.ContentLength64 = $buf.Length
        $ctx.Response.OutputStream.Write($buf, 0, $buf.Length)
    } catch { } finally { try { $ctx.Response.Close() } catch { } }
}

# 网页模式下的单个 tick：到点才移动；返回 false（应自动暂停）时置暂停
function Web-Tick {
    if (-not $script:webRunning) { return }
    if (-not $script:running -or $script:paused) { return }
    $now = Get-Date
    if ($null -ne $script:nextTickAt -and $now -lt $script:nextTickAt) { return }
    $script:nextTickAt = $now.AddMilliseconds([double](Compute-IntervalMs))
    $ok = Apply-Once
    if (-not $ok) { $script:paused = $true }
}

function Get-WebPageHtml {
    return @'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>AutoMouseMover 控制台</title>
<style>
:root{color-scheme:light dark}
body{font-family:system-ui,"PingFang SC","Microsoft YaHei",sans-serif;max-width:540px;margin:24px auto;padding:0 14px;line-height:1.5}
h1{font-size:20px;display:flex;align-items:center;gap:10px}
.card{border:1px solid rgba(128,128,128,.35);border-radius:12px;padding:14px 16px;margin:12px 0}
.row{display:flex;gap:10px;flex-wrap:wrap;align-items:center;margin:10px 0}
label{min-width:92px;color:#666}
input,select{padding:6px 8px;border:1px solid rgba(128,128,128,.5);border-radius:8px;background:transparent;color:inherit}
button{padding:9px 18px;border:none;border-radius:9px;background:#2d6cdf;color:#fff;cursor:pointer;font-size:14px}
button:disabled{opacity:.45;cursor:not-allowed}
button.gray{background:#7a7a7a}button.red{background:#d43a3a}
.stat{font-size:14px}
.badge{padding:3px 12px;border-radius:12px;font-size:13px;color:#fff;background:#7a7a7a}
.badge.run{background:#2a9d4a}.badge.pause{background:#e0a125}
.hint{color:#888;font-size:12px}
</style>
</head>
<body>
<h1>🖱️ AutoMouseMover <span class="badge" id="badge">已停止</span></h1>
<div class="card stat">
<div>已移动：<b id="count">0</b> 次 · 已点击：<b id="clicks">0</b> 次 · 距离：<b id="dist">0</b> px</div>
<div>已运行：<b id="uptime">00:00:00</b> · 平台：<span id="platform">-</span> · 版本：<span id="version">-</span></div>
</div>
<div class="card row">
<button id="btnStart" onclick="cmd('start')">开始</button>
<button id="btnPause" class="gray" onclick="cmd('pause')">暂停</button>
<button id="btnResume" class="gray" onclick="cmd('resume')">继续</button>
<button id="btnStop" class="red" onclick="cmd('stop')">停止</button>
<button id="btnExit" class="gray" onclick="cmd('exit')">退出服务</button>
</div>
<div class="card">
<div class="row"><label>间隔（秒）</label><input id="interval" type="number" step="0.1" min="0.1" max="60" value="5" onchange="setv()"></div>
<div class="row"><label>移动模式</label><select id="mode" onchange="setv()">
<option>horizontal</option><option>vertical</option><option>circular</option><option>random</option>
<option>square</option><option>spiral</option><option>figure8</option><option>bounce</option>
</select></div>
<div class="row"><label>步长（像素）</label><input id="step" type="number" min="1" max="1000" value="20" onchange="setv()"></div>
<div class="row"><label>圆圈半径</label><input id="radius" type="number" min="10" max="2000" value="150" onchange="setv()"></div>
<div class="row"><label>点击方式</label><select id="click" onchange="setv()">
<option value="0">不点击</option><option value="1">左键单击</option><option value="2">右键单击</option><option value="3">左键双击</option>
</select></div>
<div class="row"><label>自动暂停</label><input id="autoPause" type="checkbox" onchange="setv()"> <span class="hint">检测到手动移动鼠标时自动暂停</span></div>
<div class="row"><label>声音提示</label><input id="sound" type="checkbox" onchange="setv()"></div>
</div>
<p class="hint">提示：运行中手动移动鼠标会触发自动暂停；设置随操作实时生效并自动保存。关闭浏览器不影响移动，点「停止」或「退出服务」，或在此终端按 Ctrl+C 退出。</p>
<script>
function fmtUp(s){var h=Math.floor(s/3600),m=Math.floor(s%3600/60),x=s%60;return ('0'+h).slice(-2)+':'+('0'+m).slice(-2)+':'+('0'+x).slice(-2);}
function setVal(id,v){var el=document.getElementById(id);if(document.activeElement!==el)el.value=v;}
function setChk(id,v){var el=document.getElementById(id);if(document.activeElement!==el)el.checked=v;}
function cmd(a){fetch('/cmd?action='+a).then(function(r){return r.json();}).then(apply);}
function setv(){
var p=new URLSearchParams();
p.set('interval',document.getElementById('interval').value);
p.set('mode',document.getElementById('mode').value);
p.set('step',document.getElementById('step').value);
p.set('radius',document.getElementById('radius').value);
p.set('click',document.getElementById('click').value);
p.set('autoPause',document.getElementById('autoPause').checked?'1':'0');
p.set('sound',document.getElementById('sound').checked?'1':'0');
fetch('/set?'+p.toString()).then(function(r){return r.json();}).then(apply);
}
function apply(s){
document.getElementById('count').textContent=s.count;
document.getElementById('clicks').textContent=s.clicks;
document.getElementById('dist').textContent=s.dist;
document.getElementById('uptime').textContent=fmtUp(s.uptime);
document.getElementById('platform').textContent=s.platform;
document.getElementById('version').textContent=s.version;
var b=document.getElementById('badge');
if(s.running&&s.paused){b.textContent='已暂停';b.className='badge pause';}
else if(s.running){b.textContent='运行中';b.className='badge run';}
else{b.textContent='已停止';b.className='badge';}
document.getElementById('btnStart').disabled=s.running;
document.getElementById('btnPause').disabled=!(s.running&&!s.paused);
document.getElementById('btnResume').disabled=!(s.running&&s.paused);
document.getElementById('btnStop').disabled=!s.running;
setVal('interval',s.interval);setVal('mode',s.mode);setVal('step',s.step);setVal('radius',s.radius);setVal('click',s.click);
setChk('autoPause',s.autoPause);setChk('sound',s.sound);
}
setInterval(function(){fetch('/status').then(function(r){return r.json();}).then(apply);},700);
fetch('/status').then(function(r){return r.json();}).then(apply);
</script>
</body>
</html>
'@
}

function Route-Web { param($ctx)
    $path = $ctx.Request.Url.AbsolutePath
    $q = $ctx.Request.QueryString
    switch ($path) {
        '/' {
            Send-WebResponse $ctx (Get-WebPageHtml) 'text/html; charset=utf-8'
        }
        '/status' {
            Send-WebResponse $ctx (Get-WebStatusJson)
        }
        '/cmd' {
            switch ($q['action']) {
                'start'  { if (-not $script:running) { Begin-RunCore }; $script:paused = $false; $script:nextTickAt = (Get-Date).AddMilliseconds([double](Compute-IntervalMs)) }
                'pause'  { if ($script:running -and -not $script:paused) { $script:paused = $true } }
                'resume' { if ($script:running -and $script:paused) { $script:paused = $false; $script:firstTick = $true; $script:nextTickAt = (Get-Date).AddMilliseconds([double](Compute-IntervalMs)) } }
                'stop'   { Stop-MoverCore; $script:paused = $false; $script:nextTickAt = $null; Write-StatsIfRequested }
                'exit'   { $script:webRunning = $false }
            }
            Send-WebResponse $ctx (Get-WebStatusJson)
        }
        '/set' {
            # 用「非 null 且非空串」判断：原来的 if ($q['interval']) 会把合法的 "0" 当成未提供而跳过
            if ($null -ne $q['interval'] -and $q['interval'] -ne '') { try { $d = [decimal]::Parse($q['interval'], [System.Globalization.CultureInfo]::InvariantCulture); if ($d -lt 0.1) { $d = 0.1 }; if ($d -gt 60) { $d = 60 }; $script:cfg.interval = $d } catch { } }
            if ($null -ne $q['mode'] -and $q['mode'] -ne '' -and $script:validModes -contains $q['mode']) { $script:cfg.mode = $q['mode'] }
            if ($null -ne $q['step']   -and $q['step']   -ne '') { try { $n = [int]$q['step'];   if ($n -lt 1)   { $n = 1 };   if ($n -gt 1000) { $n = 1000 }; $script:cfg.step   = $n } catch { } }
            if ($null -ne $q['radius'] -and $q['radius'] -ne '') { try { $n = [int]$q['radius']; if ($n -lt 10)  { $n = 10 };  if ($n -gt 2000) { $n = 2000 }; $script:cfg.radius = $n } catch { } }
            if ($null -ne $q['click'])     { try { $n = [int]$q['click'];     if ($n -ge 0 -and $n -le 3) { $script:cfg.clickType  = $n } } catch { } }
            if ($null -ne $q['autoPause']) { $script:cfg.autoPause = ($q['autoPause'] -eq '1') }
            if ($null -ne $q['sound'])     { $script:cfg.sound     = ($q['sound'] -eq '1') }
            Mark-Dirty
            Send-WebResponse $ctx (Get-WebStatusJson)
        }
        default { Send-WebResponse $ctx '{"error":"not found"}' }
    }
}

function Start-WebUi {
    $port = 0
    for ($p = 8777; $p -le 8787; $p++) {
        $l = New-Object System.Net.HttpListener
        try { $l.Prefixes.Add("http://localhost:$p/"); $l.Start(); $script:webListener = $l; $port = $p; break }
        catch { try { $l.Close() } catch { }; $l = $null }
    }
    if ($port -eq 0) {
        Write-Host '无法启动本地网页服务：端口 8777-8787 均被占用或系统受限（可尝试管理员运行，或换用终端模式）。' -ForegroundColor Red
        return
    }
    $script:webRunning = $true
    $script:running = $false
    $script:paused = $false
    $script:nextTickAt = $null
    $url = "http://localhost:$port/"
    Write-Host "网页图形界面已启动：$url" -ForegroundColor Green
    Write-Host '请在浏览器中打开上面的地址进行控制；关闭浏览器不影响移动，点页面「停止」或「退出服务」，或在此窗口按 Ctrl+C 退出。' -ForegroundColor DarkGray
    Open-Browser $url
    try {
        while ($script:webRunning) {
            $iar = $script:webListener.BeginGetContext($null, $null)
            while (-not $iar.IsCompleted -and $script:webRunning) {
                Web-Tick
                Start-Sleep -Milliseconds 50
            }
            if (-not $script:webRunning) { break }
            $ctx = $script:webListener.EndGetContext($iar)
            Route-Web $ctx
        }
    } catch { }
    finally {
        try { $script:webListener.Stop(); $script:webListener.Close() } catch { }
        Stop-MoverCore
        Save-Settings
        Write-StatsIfRequested
        Clear-BeepCache
        Write-Host '网页服务已停止。' -ForegroundColor Cyan
    }
}

# 无界面/自动化标志：含 -run/-once/-help/-h/-web 时，Windows 下跳过图形界面，改走终端核心
$script:headless = $false
foreach ($a in $args) { if ($a -in @('-run','-once','-help','-h','-?','-web')) { $script:headless = $true } }

# ============================================================
#  Windows：WinForms 图形界面
# ============================================================
if ($script:platform -eq 'Windows' -and -not $script:headless) {
    try {

    # 应用图标：优先加载同目录下的 AutoMouseMover.ico；缺失或加载失败则退回系统默认图标。
    # 原来标题栏/托盘用的是 SystemIcons::Application（那个灰色通用图标），
    # 一眼看不出这是什么东西，现在有了自己的图标。
    $script:appIcon  = $null
    $script:trayIcon = $null
    $iconBaseDir = $PSScriptRoot
    if (-not $iconBaseDir) { $iconBaseDir = $PWD.Path }
    $iconFile = Join-Path $iconBaseDir 'AutoMouseMover.ico'
    $iconLoaded = $false
    if (Test-Path $iconFile) {
        try {
            $script:appIcon  = New-Object System.Drawing.Icon($iconFile)
            try { $script:trayIcon = New-Object System.Drawing.Icon($iconFile, 16, 16) }
            catch { $script:trayIcon = $script:appIcon }
            $iconLoaded = $true
        } catch {
            $script:appIcon = $null; $script:trayIcon = $null
        }
    }
    if (-not $iconLoaded) {
        $script:appIcon  = [System.Drawing.SystemIcons]::Application
        $script:trayIcon = [System.Drawing.SystemIcons]::Application
    }

    # ===== 现代化皮肤（亮色 / 扁平 / 圆角）=====
    function Set-GuiTheme {
        param($root)
        $accent     = [System.Drawing.Color]::FromArgb(255,45,140,235)   # 主色 蓝
        $accentDark = [System.Drawing.Color]::FromArgb(255,28,108,200)   # 主色按下/悬停
        $accentText = [System.Drawing.Color]::FromArgb(255,23,92,160)    # 主色文字
        $fg         = [System.Drawing.Color]::FromArgb(255,43,52,64)     # 正文
        $bgForm     = [System.Drawing.Color]::FromArgb(255,238,242,247)  # 窗体底
        $bgSec      = [System.Drawing.Color]::FromArgb(255,231,239,248)  # 次级按钮底
        $secHover   = [System.Drawing.Color]::FromArgb(255,214,227,244)
        $white      = [System.Drawing.Color]::White

        $root.Font = New-Object System.Drawing.Font('Segoe UI', 9.5)
        $root.BackColor = $bgForm
        try { $root.DoubleBuffered = $true } catch {}

        $queue = New-Object System.Collections.Queue
        foreach ($c in $root.Controls) { $queue.Enqueue($c) }
        while ($queue.Count -gt 0) {
            $c = $queue.Dequeue()
            if ($c.Controls -and $c.Controls.Count -gt 0) {
                foreach ($ch in $c.Controls) { $queue.Enqueue($ch) }
            }
            try { $c.Font = New-Object System.Drawing.Font('Segoe UI', 9.5) } catch {}
            switch ($c.GetType().Name) {
                'Label'    { $c.BackColor = [System.Drawing.Color]::Transparent; $c.ForeColor = $fg }
                'GroupBox' { $c.BackColor = $white; $c.ForeColor = $accentText }
                'CheckBox' { $c.BackColor = [System.Drawing.Color]::Transparent; $c.ForeColor = $fg }
                'ComboBox' {
                    $c.BackColor = $white; $c.ForeColor = $fg
                    try { $c.FlatStyle = 'Flat' } catch {}
                }
                'NumericUpDown' { $c.BackColor = $white; $c.ForeColor = $fg }
                'TextBox'       { $c.BackColor = $white; $c.ForeColor = $fg }
                'Button' {
                    $c.FlatStyle = 'Flat'
                    $c.UseVisualStyleBackColor = $false
                    $c.FlatAppearance.BorderSize = 1
                    $c.FlatAppearance.BorderColor = $accent
                    $c.BackColor = $bgSec
                    $c.ForeColor = $accentText
                    if ($c.Text -eq '开始') {
                        $c.BackColor = $accent
                        $c.ForeColor = $white
                        $c.FlatAppearance.BorderSize = 0
                        $c.Font = New-Object System.Drawing.Font('Segoe UI', 9.5, [System.Drawing.FontStyle]::Bold)
                    }
                    $c.Add_MouseEnter({ param($s,$e)
                        if ($s.Text -eq '开始') { $s.BackColor = [System.Drawing.Color]::FromArgb(255,28,108,200) }
                        else { $s.BackColor = [System.Drawing.Color]::FromArgb(255,214,227,244) } })
                    $c.Add_MouseLeave({ param($s,$e)
                        if ($s.Text -eq '开始') { $s.BackColor = [System.Drawing.Color]::FromArgb(255,45,140,235) }
                        else { $s.BackColor = [System.Drawing.Color]::FromArgb(255,231,239,248) } })
                }
                default { }
            }
        }

        # 圆角窗体（已移除：可调整大小的窗口不兼容固定 Region，否则缩放时被裁剪为原尺寸）


    }

    $form = New-Object HotkeyForm
    $form.Text = "$APP_NAME $VERSION"
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'Sizable'
    $form.MaximizeBox = $true
    $form.ClientSize = New-Object System.Drawing.Size(420, 714)
    $form.MinimumSize = New-Object System.Drawing.Size(440, 762)
    $form.Icon = $script:appIcon
    $form.KeyPreview = $true

    $gb = New-Object System.Windows.Forms.GroupBox
    $gb.Text = '基本设置'; $gb.Location = New-Object System.Drawing.Point(12, 12); $gb.Size = New-Object System.Drawing.Size(396, 296)
    $form.Controls.Add($gb)

    $lblInterval = New-Object System.Windows.Forms.Label; $lblInterval.Text = '间隔时间（秒）'; $lblInterval.Location = New-Object System.Drawing.Point(14, 24); $lblInterval.AutoSize = $true; $gb.Controls.Add($lblInterval)
    $numInterval = New-Object System.Windows.Forms.NumericUpDown; $numInterval.Location = New-Object System.Drawing.Point(150, 22); $numInterval.Size = New-Object System.Drawing.Size(90, 23); $numInterval.Minimum = 0.1; $numInterval.Maximum = 60; $numInterval.Increment = 0.1; $numInterval.DecimalPlaces = 1; $numInterval.Value = 5; $gb.Controls.Add($numInterval)

    $lblMode = New-Object System.Windows.Forms.Label; $lblMode.Text = '移动模式'; $lblMode.Location = New-Object System.Drawing.Point(14, 58); $lblMode.AutoSize = $true; $gb.Controls.Add($lblMode)
    $cmbMode = New-Object System.Windows.Forms.ComboBox; $cmbMode.DropDownStyle = 'DropDownList'; $cmbMode.Location = New-Object System.Drawing.Point(150, 56); $cmbMode.Size = New-Object System.Drawing.Size(230, 23)
    foreach ($mm in $script:validModes) { [void]$cmbMode.Items.Add($mm) }
    $cmbMode.SelectedIndex = 0; $gb.Controls.Add($cmbMode)

    $lblEase = New-Object System.Windows.Forms.Label; $lblEase.Text = '缓动曲线'; $lblEase.Location = New-Object System.Drawing.Point(14, 92); $lblEase.AutoSize = $true; $gb.Controls.Add($lblEase)
    $cmbEase = New-Object System.Windows.Forms.ComboBox; $cmbEase.DropDownStyle = 'DropDownList'; $cmbEase.Location = New-Object System.Drawing.Point(150, 90); $cmbEase.Size = New-Object System.Drawing.Size(120, 23)
    [void]$cmbEase.Items.Add('线性（恒速）'); [void]$cmbEase.Items.Add('渐快'); [void]$cmbEase.Items.Add('渐慢'); [void]$cmbEase.Items.Add('正弦起伏')
    $cmbEase.SelectedIndex = 0; $gb.Controls.Add($cmbEase)

    $lblStep = New-Object System.Windows.Forms.Label; $lblStep.Text = '步长（像素）'; $lblStep.Location = New-Object System.Drawing.Point(14, 126); $lblStep.AutoSize = $true; $gb.Controls.Add($lblStep)
    $numStep = New-Object System.Windows.Forms.NumericUpDown; $numStep.Location = New-Object System.Drawing.Point(150, 124); $numStep.Size = New-Object System.Drawing.Size(90, 23); $numStep.Minimum = 1; $numStep.Maximum = 1000; $numStep.Increment = 1; $numStep.Value = 20; $gb.Controls.Add($numStep)

    $lblRadius = New-Object System.Windows.Forms.Label; $lblRadius.Text = '圆圈半径（像素）'; $lblRadius.Location = New-Object System.Drawing.Point(14, 160); $lblRadius.AutoSize = $true; $gb.Controls.Add($lblRadius)
    $numRadius = New-Object System.Windows.Forms.NumericUpDown; $numRadius.Location = New-Object System.Drawing.Point(150, 158); $numRadius.Size = New-Object System.Drawing.Size(90, 23); $numRadius.Minimum = 10; $numRadius.Maximum = 2000; $numRadius.Increment = 1; $numRadius.Value = 150; $gb.Controls.Add($numRadius)

    $lblJitter = New-Object System.Windows.Forms.Label; $lblJitter.Text = '随机抖动（像素）'; $lblJitter.Location = New-Object System.Drawing.Point(14, 194); $lblJitter.AutoSize = $true; $gb.Controls.Add($lblJitter)
    $numJitter = New-Object System.Windows.Forms.NumericUpDown; $numJitter.Location = New-Object System.Drawing.Point(150, 192); $numJitter.Size = New-Object System.Drawing.Size(90, 23); $numJitter.Minimum = 0; $numJitter.Maximum = 200; $numJitter.Increment = 1; $numJitter.Value = 0; $gb.Controls.Add($numJitter)

    $lblRand = New-Object System.Windows.Forms.Label; $lblRand.Text = '间隔随机度（%）'; $lblRand.Location = New-Object System.Drawing.Point(14, 228); $lblRand.AutoSize = $true; $gb.Controls.Add($lblRand)
    $numRand = New-Object System.Windows.Forms.NumericUpDown; $numRand.Location = New-Object System.Drawing.Point(150, 226); $numRand.Size = New-Object System.Drawing.Size(90, 23); $numRand.Minimum = 0; $numRand.Maximum = 100; $numRand.Increment = 1; $numRand.Value = 0; $gb.Controls.Add($numRand)

    $lblScreen = New-Object System.Windows.Forms.Label; $lblScreen.Text = '目标显示器'; $lblScreen.Location = New-Object System.Drawing.Point(14, 262); $lblScreen.AutoSize = $true; $gb.Controls.Add($lblScreen)
    $cmbScreen = New-Object System.Windows.Forms.ComboBox; $cmbScreen.DropDownStyle = 'DropDownList'; $cmbScreen.Location = New-Object System.Drawing.Point(150, 260); $cmbScreen.Size = New-Object System.Drawing.Size(230, 23)
    $i = 1
    foreach ($s in [System.Windows.Forms.Screen]::AllScreens) {
        [void]$cmbScreen.Items.Add("显示器 $i ($($s.Bounds.Width)x$($s.Bounds.Height))")
        $i++
    }
    $cmbScreen.SelectedIndex = 0; $gb.Controls.Add($cmbScreen)

    $gbAction = New-Object System.Windows.Forms.GroupBox
    $gbAction.Text = '动作与系统'; $gbAction.Location = New-Object System.Drawing.Point(12, 314); $gbAction.Size = New-Object System.Drawing.Size(396, 252)
    $form.Controls.Add($gbAction)

    $lblClick = New-Object System.Windows.Forms.Label; $lblClick.Text = '点击方式'; $lblClick.Location = New-Object System.Drawing.Point(14, 12); $lblClick.AutoSize = $true; $gbAction.Controls.Add($lblClick)
    $cmbClick = New-Object System.Windows.Forms.ComboBox; $cmbClick.DropDownStyle = 'DropDownList'; $cmbClick.Location = New-Object System.Drawing.Point(150, 10); $cmbClick.Size = New-Object System.Drawing.Size(120, 23)
    [void]$cmbClick.Items.Add('不点击'); [void]$cmbClick.Items.Add('左键单击'); [void]$cmbClick.Items.Add('右键单击'); [void]$cmbClick.Items.Add('左键双击')
    $cmbClick.SelectedIndex = 0; $gbAction.Controls.Add($cmbClick)

    $lblClickEvery = New-Object System.Windows.Forms.Label; $lblClickEvery.Text = '点击节流'; $lblClickEvery.Location = New-Object System.Drawing.Point(14, 44); $lblClickEvery.AutoSize = $true; $gbAction.Controls.Add($lblClickEvery)
    $numClickEvery = New-Object System.Windows.Forms.NumericUpDown; $numClickEvery.Location = New-Object System.Drawing.Point(150, 42); $numClickEvery.Size = New-Object System.Drawing.Size(60, 23); $numClickEvery.Minimum = 1; $numClickEvery.Maximum = 100; $numClickEvery.Increment = 1; $numClickEvery.Value = 1; $gbAction.Controls.Add($numClickEvery)
    $lblClickEvery2 = New-Object System.Windows.Forms.Label; $lblClickEvery2.Text = '次移动点击 1 次（1=每次都点）'; $lblClickEvery2.Location = New-Object System.Drawing.Point(218, 44); $lblClickEvery2.AutoSize = $true; $gbAction.Controls.Add($lblClickEvery2)

    $chkAutoPause = New-Object System.Windows.Forms.CheckBox; $chkAutoPause.Text = '检测到手动移动鼠标时自动暂停（推荐）'; $chkAutoPause.Location = New-Object System.Drawing.Point(14, 74); $chkAutoPause.AutoSize = $true; $chkAutoPause.Checked = $true; $gbAction.Controls.Add($chkAutoPause)
    $chkTray = New-Object System.Windows.Forms.CheckBox; $chkTray.Text = '关闭窗口时最小化到系统托盘'; $chkTray.Location = New-Object System.Drawing.Point(14, 98); $chkTray.AutoSize = $true; $gbAction.Controls.Add($chkTray)

    $lblHotkey = New-Object System.Windows.Forms.Label; $lblHotkey.Text = '全局热键'; $lblHotkey.Location = New-Object System.Drawing.Point(14, 124); $lblHotkey.AutoSize = $true; $gbAction.Controls.Add($lblHotkey)
    $cmbMods = New-Object System.Windows.Forms.ComboBox; $cmbMods.DropDownStyle = 'DropDownList'; $cmbMods.Location = New-Object System.Drawing.Point(150, 122); $cmbMods.Size = New-Object System.Drawing.Size(110, 23)
    foreach ($it in @('Ctrl+Shift','Ctrl+Alt','Alt+Shift','Ctrl+Shift+Alt','Win+Shift','Ctrl')) { [void]$cmbMods.Items.Add($it) }
    $cmbMods.SelectedIndex = 0; $gbAction.Controls.Add($cmbMods)

    $cmbKey = New-Object System.Windows.Forms.ComboBox; $cmbKey.DropDownStyle = 'DropDownList'; $cmbKey.Location = New-Object System.Drawing.Point(270, 122); $cmbKey.Size = New-Object System.Drawing.Size(110, 23)
    foreach ($it in @('M','Space','F1','F2','F3','F4','F5','F6','F7','F8','F9','F10','F11','F12','A','S','D','W')) { [void]$cmbKey.Items.Add($it) }
    $cmbKey.SelectedIndex = 0; $gbAction.Controls.Add($cmbKey)

    $chkAutoStart = New-Object System.Windows.Forms.CheckBox; $chkAutoStart.Text = '开机自动启动（写入注册表）'; $chkAutoStart.Location = New-Object System.Drawing.Point(14, 150); $chkAutoStart.AutoSize = $true; $gbAction.Controls.Add($chkAutoStart)
    $chkReturnHome = New-Object System.Windows.Forms.CheckBox; $chkReturnHome.Text = '停止后光标回到启动前的位置'; $chkReturnHome.Location = New-Object System.Drawing.Point(14, 174); $chkReturnHome.AutoSize = $true; $gbAction.Controls.Add($chkReturnHome)

    $lblDelay = New-Object System.Windows.Forms.Label; $lblDelay.Text = '延迟启动'; $lblDelay.Location = New-Object System.Drawing.Point(14, 202); $lblDelay.AutoSize = $true; $gbAction.Controls.Add($lblDelay)
    $numDelay = New-Object System.Windows.Forms.NumericUpDown; $numDelay.Location = New-Object System.Drawing.Point(150, 200); $numDelay.Size = New-Object System.Drawing.Size(60, 23); $numDelay.Minimum = 0; $numDelay.Maximum = 120; $numDelay.Increment = 1; $numDelay.Value = 0; $gbAction.Controls.Add($numDelay)
    $lblDelay2 = New-Object System.Windows.Forms.Label; $lblDelay2.Text = '秒后开始（0=立即）'; $lblDelay2.Location = New-Object System.Drawing.Point(218, 202); $lblDelay2.AutoSize = $true; $gbAction.Controls.Add($lblDelay2)

    $chkSound = New-Object System.Windows.Forms.CheckBox; $chkSound.Text = '开始/停止时声音提示'; $chkSound.Location = New-Object System.Drawing.Point(14, 226); $chkSound.AutoSize = $true; $gbAction.Controls.Add($chkSound)

    $lblProfile = New-Object System.Windows.Forms.Label; $lblProfile.Text = '预设方案'; $lblProfile.Location = New-Object System.Drawing.Point(14, 576); $lblProfile.AutoSize = $true; $form.Controls.Add($lblProfile)
    $cmbProfile = New-Object System.Windows.Forms.ComboBox; $cmbProfile.Location = New-Object System.Drawing.Point(84, 572); $cmbProfile.Size = New-Object System.Drawing.Size(150, 23); $cmbProfile.DropDownStyle = 'DropDown'; $form.Controls.Add($cmbProfile)
    $btnProfileSave = New-Object System.Windows.Forms.Button; $btnProfileSave.Text = '保存'; $btnProfileSave.Location = New-Object System.Drawing.Point(244, 571); $btnProfileSave.Size = New-Object System.Drawing.Size(70, 25); $form.Controls.Add($btnProfileSave)
    $btnProfileLoad = New-Object System.Windows.Forms.Button; $btnProfileLoad.Text = '加载'; $btnProfileLoad.Location = New-Object System.Drawing.Point(320, 571); $btnProfileLoad.Size = New-Object System.Drawing.Size(70, 25); $form.Controls.Add($btnProfileLoad)

    $btnStart = New-Object System.Windows.Forms.Button; $btnStart.Text = '开始'; $btnStart.Location = New-Object System.Drawing.Point(14, 606); $btnStart.Size = New-Object System.Drawing.Size(90, 30); $form.Controls.Add($btnStart)
    $btnStop = New-Object System.Windows.Forms.Button; $btnStop.Text = '停止'; $btnStop.Location = New-Object System.Drawing.Point(114, 606); $btnStop.Size = New-Object System.Drawing.Size(90, 30); $btnStop.Enabled = $false; $form.Controls.Add($btnStop)
    $btnAbout = New-Object System.Windows.Forms.Button; $btnAbout.Text = '关于'; $btnAbout.Location = New-Object System.Drawing.Point(314, 606); $btnAbout.Size = New-Object System.Drawing.Size(90, 30); $form.Controls.Add($btnAbout)

    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = '状态：已停止'; $lblStatus.Location = New-Object System.Drawing.Point(14, 644); $lblStatus.AutoSize = $true; $form.Controls.Add($lblStatus)
    $lblCount = New-Object System.Windows.Forms.Label; $lblCount.Text = '已移动：0 次 · 点击：0 次'; $lblCount.Location = New-Object System.Drawing.Point(14, 666); $lblCount.AutoSize = $true; $form.Controls.Add($lblCount)
    # 运行时长贴右缘（Anchor 在下方响应式区设为 Bottom,Right）；x=300 保证与左侧最长状态文案（约 250px）不重叠
    $lblUptime = New-Object System.Windows.Forms.Label; $lblUptime.Text = '已运行：00:00:00'; $lblUptime.Location = New-Object System.Drawing.Point(300, 644); $lblUptime.AutoSize = $true; $form.Controls.Add($lblUptime)
    # 信息行独占第三行全宽：AutoSize 在窄窗口下会把文本顶出右缘截断，还会与左列重叠；
    # 改为固定宽度 + AutoEllipsis（超宽显示「…」），并随窗口横向拉伸
    $lblInfo = New-Object System.Windows.Forms.Label; $lblInfo.Location = New-Object System.Drawing.Point(14, 688); $lblInfo.AutoSize = $false; $lblInfo.AutoEllipsis = $true; $lblInfo.Size = New-Object System.Drawing.Size(392, 18); $form.Controls.Add($lblInfo)

    # 底栏控件随窗口放大贴底，避免最大化后悬空
    foreach ($ctl in @($btnStart,$btnStop,$btnAbout,$lblStatus,$lblCount,$lblUptime,$lblInfo,$lblProfile,$cmbProfile,$btnProfileSave,$btnProfileLoad)) {
        $ctl.Anchor = 'Bottom'
    }

    # 响应式布局：窗口拉大时内容铺开，而不是挤在左上角
    $gb.Anchor       = 'Top,Left,Right'
    $gbAction.Anchor = 'Top,Left,Right'
    foreach ($ctl in @($numInterval,$cmbMode,$cmbEase,$numStep,$numRadius,$numJitter,$numRand,$cmbScreen,$cmbClick,$cmbKey)) {
        $ctl.Anchor = 'Left,Right'
    }
    $btnAbout.Anchor       = 'Bottom,Right'
    $btnProfileSave.Anchor = 'Bottom,Right'
    $btnProfileLoad.Anchor = 'Bottom,Right'
    # 底部信息区：运行时长贴右缘；信息行全宽拉伸（超宽省略号而非截断/重叠）
    $lblUptime.Anchor = 'Bottom,Right'
    $lblInfo.Anchor   = 'Bottom,Left,Right'
    $cmbProfile.Anchor     = 'Bottom,Left,Right'

    # 托盘（创建失败也不影响主窗口，仅降级为无托盘）
    $script:hasTray = $false
    try {
        $notifyIcon = New-Object System.Windows.Forms.NotifyIcon
        $notifyIcon.Icon = $script:trayIcon
        $notifyIcon.Text = "$APP_NAME $VERSION"
        $notifyIcon.Visible = $false
        $trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
        $trayToggle = New-Object System.Windows.Forms.ToolStripMenuItem
        $trayToggle.Text = '开始'
        $null = $trayToggle.Click.Add({ Toggle-GuiMover })
        $null = $trayMenu.Items.Add($trayToggle)
        $miShow = New-Object System.Windows.Forms.ToolStripMenuItem; $miShow.Text = '显示'
        $null = $miShow.Click.Add({ Restore-FromTray })
        $null = $trayMenu.Items.Add($miShow)
        $miExit = New-Object System.Windows.Forms.ToolStripMenuItem; $miExit.Text = '退出'
        $null = $miExit.Click.Add({ $script:exiting = $true; $form.Close() })
        $null = $trayMenu.Items.Add($miExit)
        $notifyIcon.ContextMenuStrip = $trayMenu
        $notifyIcon.Add_DoubleClick({ Restore-FromTray })
        $script:hasTray = $true
    } catch {
        $script:hasTray = $false
    }

    # 计时器
    $timer = New-Object System.Windows.Forms.Timer
    $uptimeTimer = New-Object System.Windows.Forms.Timer
    $uptimeTimer.Interval = 1000
    $countdownTimer = New-Object System.Windows.Forms.Timer
    $countdownTimer.Interval = 1000

    # 设置防抖落盘：编辑控件只置脏标记，这里每 1.5 秒真正写一次文件
    $saveTimer = New-Object System.Windows.Forms.Timer
    $saveTimer.Interval = 1500
    $saveTimer.Add_Tick({ if ($script:cfgDirty) { $script:cfgDirty = $false; Save-Settings } })
    $saveTimer.Start()

    # 自定义全局热键
    $modValues = @(0x6, 0x3, 0x5, 0x7, 0xC, 0x2)
    $keyValues = @(0x4D, 0x20, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B, 0x41, 0x53, 0x44, 0x57)
    $script:hotkeyOk = $true   # 上次 RegisterHotKey 是否成功（失败多为被其它程序占用）

    function Register-HotkeyCurrent {
        $mi = $cmbMods.SelectedIndex; if ($mi -lt 0) { $mi = 0 }
        $ki = $cmbKey.SelectedIndex; if ($ki -lt 0) { $ki = 0 }
        [void][Win32Mouse]::UnregisterHotKey($form.Handle, 1)
        # 原来不检查返回值：热键被占用时静默失败，用户完全看不出问题
        $script:hotkeyOk = [Win32Mouse]::RegisterHotKey($form.Handle, 1, [uint32]$modValues[$mi], [uint32]$keyValues[$ki])
    }
    function Update-HotkeyLabel {
        $mi = $cmbMods.SelectedIndex; if ($mi -lt 0) { $mi = 0 }
        $ki = $cmbKey.SelectedIndex; if ($ki -lt 0) { $ki = 0 }
        if ($script:hotkeyOk) {
            $script:hotkeyHint = "（$($cmbMods.Items[$mi]) + $($cmbKey.Items[$ki]) 开关）"
        } else {
            $script:hotkeyHint = '（热键注册失败，可能被其它程序占用）'
        }
        if (-not ($script:running -or $script:counting)) { $lblStatus.Text = "状态：已停止$script:hotkeyHint" }
    }

    function Mode-DisplayName { param($m)
        switch ($m) {
            'vertical' { '纵向' } 'circular' { '圆圈' } 'random' { '随机' } 'square' { '方形' } 'spiral' { '螺旋' } 'figure8' { '8字' } 'bounce' { '斜弹' } default { '横向' }
        }
    }
    function Update-Info {
        $sel = [string]$cmbMode.SelectedItem
        $mode = Mode-DisplayName $sel
        if ($sel -in @('circular','spiral')) { $extra = "半径 $($numRadius.Value)px" } else { $extra = "步长 $($numStep.Value)px" }
        $script:infoBase = "模式：$mode　间隔：$($numInterval.Value)s　$extra"
        $lblInfo.Text = $script:infoBase
    }

    function Update-Stats {
        $lblCount.Text = "已移动：$($script:count) 次 · 点击：$($script:clickCount) 次"
        $lblInfo.Text = "$script:infoBase　总距离：$($script:totalDist)px"
    }

    function On-ModeChanged {
        $sel = [string]$cmbMode.SelectedItem
        $circ = ($sel -in @('circular','spiral'))
        $linear = ($sel -in @('horizontal','vertical','square','bounce'))
        $numStep.Enabled = $linear; $lblStep.Enabled = $linear
        $numRadius.Enabled = $circ; $lblRadius.Enabled = $circ
        Update-Info
    }

    function Begin-GuiRun {
        $script:paused = $false
        Begin-RunCore
        $uptimeTimer.Start()
        $btnStart.Enabled = $false
        $btnStop.Enabled = $true
        if ($script:hasTray) { $trayToggle.Text = '停止' }
        $lblStatus.Text = '状态：运行中（热键停止 / 动鼠标自动暂停）'
        Update-Info
        Update-Stats
        Save-Settings
        $timer.Interval = Compute-IntervalMs
        $script:firstTick = $true
        $timer.Start()
    }

    # 开始 / 停止 / 继续 的统一切换入口（全局热键与托盘菜单共用）
    function Toggle-GuiMover {
        if ($script:paused) { Resume-GuiMover }
        elseif ($script:running -or $script:counting) { Stop-GuiMover }
        else { Start-GuiMover }
    }

    function Start-GuiMover {
        if ($script:running -or $script:counting) { return }
        $delay = [int]$script:cfg.delay
        if ($delay -gt 0) {
            $script:countdownLeft = $delay
            $script:counting = $true
            $btnStart.Enabled = $false
            $btnStop.Enabled = $true
            if ($script:hasTray) { $trayToggle.Text = '停止' }
            $lblStatus.Text = "状态：$delay 秒后开始（停止可取消）…"
            $countdownTimer.Start()
        } else {
            Begin-GuiRun
        }
    }

    function Stop-GuiMover {
        $countdownTimer.Stop()
        $timer.Stop()
        $uptimeTimer.Stop()
        $script:paused = $false
        Stop-MoverCore
        Write-StatsIfRequested
        $lblUptime.Text = '已运行：00:00:00'
        $lblStatus.Text = "状态：已停止$script:hotkeyHint"
        $btnStart.Enabled = $true
        $btnStart.Text = '开始'
        $btnStop.Enabled = $false
        if ($script:hasTray) { $trayToggle.Text = '开始' }
        Update-Info
        Save-Settings
    }

    function Pause-GuiMover {
        $timer.Stop()
        $uptimeTimer.Stop()
        $script:running = $false
        $script:paused = $true
        $lblStatus.Text = '状态：已暂停（检测到手动操作，点「继续」续跑）'
        $btnStart.Enabled = $true
        $btnStart.Text = '继续'
        $btnStop.Enabled = $false
        if ($script:hasTray) { $trayToggle.Text = '继续' }
    }

    function Resume-GuiMover {
        if ($script:running -or -not $script:paused) { return }
        # 继续：保留当前引擎位置（不从屏幕中心重启），仅重启计时器
        $script:running = $true
        $script:paused = $false
        $script:firstTick = $true
        $uptimeTimer.Start()
        $btnStart.Enabled = $false
        $btnStop.Enabled = $true
        if ($script:hasTray) { $trayToggle.Text = '停止' }
        $lblStatus.Text = '状态：运行中（已继续）'
        $btnStart.Text = '开始'
        $timer.Interval = Compute-IntervalMs
        $timer.Start()
    }

    function Restore-FromTray {
        if ($script:hasTray) { $notifyIcon.Visible = $false }
        $form.Show()
        $form.WindowState = 'Normal'
        $form.Activate()
    }

    function SyncControlsFromCfg {
        $mi = $cmbMode.Items.IndexOf([string]$script:cfg.mode); if ($mi -lt 0) { $mi = 0 }
        $cmbMode.SelectedIndex = $mi
        $numInterval.Value = [decimal]$script:cfg.interval
        $cmbEase.SelectedIndex = [int]$script:cfg.ease
        $numStep.Value = [decimal]$script:cfg.step
        $numRadius.Value = [decimal]$script:cfg.radius
        $numJitter.Value = [decimal]$script:cfg.jitter
        $numRand.Value = [decimal]$script:cfg.randPct
        $cmbClick.SelectedIndex = [int]$script:cfg.clickType
        $numClickEvery.Value = [decimal]$script:cfg.clickEvery
        $chkAutoPause.Checked = $script:cfg.autoPause
        $chkTray.Checked = $script:cfg.tray
        $cmbMods.SelectedIndex = [int]$script:cfg.hotkeyMod
        $cmbKey.SelectedIndex = [int]$script:cfg.hotkeyKey
        $chkReturnHome.Checked = $script:cfg.returnHome
        $numDelay.Value = [decimal]$script:cfg.delay
        $chkSound.Checked = $script:cfg.sound
        if ([int]$script:cfg.screen -lt $cmbScreen.Items.Count) { $cmbScreen.SelectedIndex = [int]$script:cfg.screen }
    }

    # 预设方案
    function Refresh-Profiles {
        $cur = $cmbProfile.Text
        $cmbProfile.Items.Clear()
        try {
            if (Test-Path $profilesDir) {
                foreach ($f in (Get-ChildItem -Path $profilesDir -Filter '*.ini' -ErrorAction SilentlyContinue)) {
                    [void]$cmbProfile.Items.Add([System.IO.Path]::GetFileNameWithoutExtension($f.Name))
                }
            }
        } catch { }
        if ($cmbProfile.Items -contains $cur) { $cmbProfile.Text = $cur }
    }
    function Save-Profile {
        $name = $cmbProfile.Text.Trim()
        if ($name.Length -eq 0) {
            [void][System.Windows.Forms.MessageBox]::Show('请先在上方的框中输入方案名称，再点保存。', '预设方案')
            return
        }
        $name = Sanitize-Name $name
        try {
            if (-not (Test-Path $profilesDir)) { New-Item -ItemType Directory -Path $profilesDir -Force | Out-Null }
            Set-Content -Path (Join-Path $profilesDir ($name + '.ini')) -Value (Get-SettingsLines) -Encoding ASCII
            Refresh-Profiles
            $cmbProfile.Text = $name
            [void][System.Windows.Forms.MessageBox]::Show("方案已保存：$name", '预设方案')
        } catch {
            [void][System.Windows.Forms.MessageBox]::Show("保存失败：$($_.Exception.Message)", '预设方案')
        }
    }
    function Load-Profile {
        $name = Sanitize-Name $cmbProfile.Text
        $path = Join-Path $profilesDir ($name + '.ini')
        if ($name.Length -eq 0 -or -not (Test-Path $path)) {
            [void][System.Windows.Forms.MessageBox]::Show('请先选择（或输入）一个已保存的方案名，再点加载。', '预设方案')
            return
        }
        $dict = @{}
        foreach ($ln in (Get-Content $path)) {
            $eq = $ln.IndexOf('=')
            if ($eq -gt 0) { $dict[$ln.Substring(0, $eq)] = $ln.Substring($eq + 1) }
        }
        Apply-Dict $dict
        $script:loading = $true
        SyncControlsFromCfg
        On-ModeChanged
        $script:loading = $false
        Register-HotkeyCurrent
        Update-HotkeyLabel
        Save-Settings
        [void][System.Windows.Forms.MessageBox]::Show("方案已加载：$name", '预设方案')
    }

    # 开机自启动（注册表 Run 键）
    $runKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    function Set-AutoStart { param([bool]$on)
        try {
            if (-not $PSCommandPath) { return }
            $cmd = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
            if ($on) { Set-ItemProperty -Path $runKeyPath -Name 'AutoMouseMoverPS' -Value $cmd }
            else { Remove-ItemProperty -Path $runKeyPath -Name 'AutoMouseMoverPS' -ErrorAction SilentlyContinue }
        } catch { }
    }
    function Test-AutoStart {
        try { return ($null -ne (Get-ItemProperty -Path $runKeyPath -Name 'AutoMouseMoverPS' -ErrorAction SilentlyContinue)) }
        catch { return $false }
    }

    # 事件绑定
    $cmbMode.Add_SelectedIndexChanged({ if ($script:loading) { return }; if ($null -ne $cmbMode.SelectedItem) { $script:cfg.mode = [string]$cmbMode.SelectedItem }; On-ModeChanged; Mark-Dirty })
    $numInterval.Add_ValueChanged({ if ($script:loading) { return }; $script:cfg.interval = [decimal]$numInterval.Value; Mark-Dirty })
    $cmbEase.Add_SelectedIndexChanged({ if ($script:loading) { return }; $script:cfg.ease = $cmbEase.SelectedIndex; Mark-Dirty })
    $numStep.Add_ValueChanged({ if ($script:loading) { return }; $script:cfg.step = [int]$numStep.Value; Mark-Dirty })
    $numRadius.Add_ValueChanged({ if ($script:loading) { return }; $script:cfg.radius = [int]$numRadius.Value; Mark-Dirty })
    $numJitter.Add_ValueChanged({ if ($script:loading) { return }; $script:cfg.jitter = [int]$numJitter.Value; Mark-Dirty })
    $numRand.Add_ValueChanged({ if ($script:loading) { return }; $script:cfg.randPct = [int]$numRand.Value; Mark-Dirty })
    $cmbScreen.Add_SelectedIndexChanged({ if ($script:loading) { return }; $script:cfg.screen = $cmbScreen.SelectedIndex; Mark-Dirty })
    $cmbClick.Add_SelectedIndexChanged({ if ($script:loading) { return }; $script:cfg.clickType = $cmbClick.SelectedIndex; Mark-Dirty })
    $numClickEvery.Add_ValueChanged({ if ($script:loading) { return }; $script:cfg.clickEvery = [int]$numClickEvery.Value; Mark-Dirty })
    $numDelay.Add_ValueChanged({ if ($script:loading) { return }; $script:cfg.delay = [int]$numDelay.Value; Mark-Dirty })
    $chkAutoPause.Add_CheckedChanged({ if ($script:loading) { return }; $script:cfg.autoPause = $chkAutoPause.Checked; Mark-Dirty })
    $chkTray.Add_CheckedChanged({ if ($script:loading) { return }; $script:cfg.tray = $chkTray.Checked; Mark-Dirty })
    $chkReturnHome.Add_CheckedChanged({ if ($script:loading) { return }; $script:cfg.returnHome = $chkReturnHome.Checked; Mark-Dirty })
    $chkSound.Add_CheckedChanged({ if ($script:loading) { return }; $script:cfg.sound = $chkSound.Checked; Mark-Dirty })
    $cmbMods.Add_SelectedIndexChanged({ if ($script:loading) { return }; $script:cfg.hotkeyMod = $cmbMods.SelectedIndex; Register-HotkeyCurrent; Update-HotkeyLabel; Mark-Dirty })
    $cmbKey.Add_SelectedIndexChanged({ if ($script:loading) { return }; $script:cfg.hotkeyKey = $cmbKey.SelectedIndex; Register-HotkeyCurrent; Update-HotkeyLabel; Mark-Dirty })
    $chkAutoStart.Add_CheckedChanged({ if ($script:loading) { return }; Set-AutoStart $chkAutoStart.Checked; Mark-Dirty })

    $timer.Add_Tick({
        if (-not $script:running) { return }
        $ok = Apply-Once
        if (-not $ok) { Pause-GuiMover; return }
        Update-Stats
        $timer.Interval = Compute-IntervalMs
    })
    $countdownTimer.Add_Tick({
        if (-not $script:counting) { return }
        $script:countdownLeft--
        if ($script:countdownLeft -gt 0) {
            $lblStatus.Text = "状态：$($script:countdownLeft) 秒后开始（停止可取消）…"
            return
        }
        $countdownTimer.Stop()
        $script:counting = $false
        Begin-GuiRun
    })
    $uptimeTimer.Add_Tick({
        if ($null -eq $script:startTime) { return }
        $ts = (Get-Date) - $script:startTime
        $total = [int]$ts.TotalSeconds
        $lblUptime.Text = "已运行：{0:D2}:{1:D2}:{2:D2}" -f [int]([math]::Floor($total / 3600)), [int]([math]::Floor(($total % 3600) / 60)), ($total % 60)
    })
    $form.Add_KeyDown({
        if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape -and ($script:running -or $script:counting)) { Stop-GuiMover }
    })
    $form.Add_Resize({
        if ($chkTray.Checked -and $form.WindowState -eq 'Minimized') {
            if ($script:hasTray) { $notifyIcon.Visible = $true }
            $form.Hide()
        }
    })
    $btnStart.Add_Click({ if ($script:paused) { Resume-GuiMover } else { Start-GuiMover } })
    $btnStop.Add_Click({ Stop-GuiMover })
    $btnProfileSave.Add_Click({ Save-Profile })
    $btnProfileLoad.Add_Click({ Load-Profile })
    $btnAbout.Add_Click({
        [System.Windows.Forms.MessageBox]::Show(
            "$APP_NAME $VERSION`n`n自动鼠标移动工具（纯 PowerShell 跨平台版）`n支持 Windows / macOS / Linux`n支持 8 种移动模式（横向/纵向/圆圈/随机/方形/螺旋/8字/斜弹，界面下拉选择），可设定 0.1s–60s 间隔并点击。`n`n停止方式（无需鼠标）：`n  • 全局热键（默认 Ctrl+Shift+M）开始/停止切换`n  • 窗口聚焦时按 Esc 停止`n  • 勾选「检测到手动移动自动暂停」后，一动鼠标即让出光标；暂停后点「继续」可从原位置续跑`n`n内置方案（终端菜单 4 / 命令行 -preset）：meeting 会议保活、minimal 最小干预、gaming 游戏防掉、wide 大范围游走`n统计导出：停止时自动保存 stats-last.json；命令行加 -export 路径 可自定义`n`nWindows 下想要「像个普通软件」：先运行一次 build_exe.bat 生成 AutoMouseMover.exe（用系统自带编译器，约 10 秒），之后双击 exe 即有图标、无黑色控制台窗`n`n网页图形界面：macOS/Linux 运行 -web（或主菜单选 5）即可用浏览器图形化控制`n`n终端模式：运行中 s/Esc 停止、p 暂停、r 继续；亦支持命令行 `n  pwsh Run-GUI.ps1 -interval 2 -mode circular -run`n`n版本常量：$VERSION",
            "关于 $APP_NAME")
    })
    $form.Add_FormClosing({
        param($sender, $e)
        Save-Settings
        [void][Win32Mouse]::UnregisterHotKey($form.Handle, 1)
        if (-not $script:exiting -and $chkTray.Checked) {
            $e.Cancel = $true
            if ($script:hasTray) { $notifyIcon.Visible = $true }
            $form.Hide()
        } else {
            # 真正退出：原来直接关闭窗口，正在跑的移动不会被停止（光标不回起点、无提示音），
            # 运行统计也不会落盘。这里补上，行为与点「停止」一致。
            Stop-MoverCore
            Write-StatsIfRequested
            if ($script:hasTray) { $notifyIcon.Visible = $false; $notifyIcon.Dispose() }
            Clear-BeepCache
        }
    })
    $form.Add_Shown({ Register-HotkeyCurrent })

    # 全局热键：开始 / 停止 / 继续 切换。
    # 修复：C# 侧 HotkeyForm 早就定义了 HotkeyPressed 事件，但这里从未订阅，
    # 导致热键注册成功、Windows 消息也收到了，却没有任何响应——关于文案里的
    # 「全局热键切换」实际完全无效。WndProc 在 UI 线程触发，可直接操作控件。
    try { $form.Add_HotkeyPressed({ Toggle-GuiMover }) } catch {
        # 订阅失败不影响主流程：退化为仅按钮/托盘可控，并在状态栏如实说明
        # （注意别把这里的失败说成「注册失败」——热键其实是注册成功的，只是没人响应）
        $script:hotkeyHint = '（热键响应不可用，请用按钮或托盘控制）'
        if (-not ($script:running -or $script:counting)) { $lblStatus.Text = "状态：已停止$script:hotkeyHint" }
    }

    # 初始化
    On-ModeChanged
    $null = $form.Handle
    SyncControlsFromCfg
    $chkAutoStart.Checked = Test-AutoStart
    Update-HotkeyLabel
    Refresh-Profiles
    Register-HotkeyCurrent
    $script:loading = $false
    Set-GuiTheme $form
    [System.Windows.Forms.Application]::Run($form)
    } catch {
        try { [System.Windows.Forms.MessageBox]::Show("启动图形界面失败：`n$($_.Exception.Message)`n`n可改用终端模式（在 macOS/Linux 上）或在其它 Windows 环境运行。", 'AutoMouseMover') } catch { Write-Host ("GUI 启动失败: " + $_.Exception.Message) }
    }

} else {

    # ============================================================
    #  macOS / Linux：终端交互菜单
    # ============================================================
    function Test-StopKey {
        try {
            if ([Console]::KeyAvailable) {
                $k = [Console]::ReadKey($true)
                if ($k.KeyChar -eq 's' -or $k.KeyChar -eq 'S' -or $k.Key -eq 'Escape') { return 'stop' }
                if ($k.KeyChar -eq 'p' -or $k.KeyChar -eq 'P') { return 'pause' }
                if ($k.KeyChar -eq 'r' -or $k.KeyChar -eq 'R') { return 'resume' }
            }
        } catch { }
        return $null
    }

    function Term-Resume {
        $cur = Get-MousePosition
        if ($null -ne $cur) { $script:lastX = $cur.x; $script:lastY = $cur.y }
        $script:firstTick = $true
        Write-Host "已继续。" -ForegroundColor Green
    }

    function Term-Start {
        if ($script:trunning) { Write-Host '已在运行中。' -ForegroundColor Yellow; return }
        $script:trunning = $true
        $delay = [int]$script:cfg.delay
        if ($delay -gt 0) {
            Write-Host "将在 $delay 秒后开始（按 s 取消）…" -ForegroundColor Cyan
            for ($i = $delay; $i -gt 0 -and $script:trunning; $i--) {
                Write-Host "`r倒计时：$i 秒   " -NoNewline
                for ($s = 0; $s -lt 10 -and $script:trunning; $s++) {
                    if ((Test-StopKey) -eq 'stop') { $script:trunning = $false; Write-Host "`n已取消。" -ForegroundColor Yellow; return }
                    Start-Sleep -Milliseconds 100
                }
            }
            Write-Host ""
        }
        Begin-RunCore
        $durStart = $null
        if ($null -ne $script:cliDuration) { $durStart = Get-Date; Write-Host ("将在此后 {0} 秒自动停止。" -f $script:cliDuration) -ForegroundColor DarkGray }
        Write-Host '运行中！s/Esc 停止；p 暂停；移动鼠标会触发自动暂停。' -ForegroundColor Green
        Write-Host ("模式:{0} 间隔:{1}s 步长:{2} 点击:{3}" -f $script:cfg.mode, $script:cfg.interval, $script:cfg.step, $script:cfg.clickType) -ForegroundColor DarkGray
        try {
            while ($script:trunning) {
                if ($null -ne $durStart -and ((Get-Date) - $durStart).TotalSeconds -ge $script:cliDuration) {
                    Write-Host "`n已达到设定的运行时长，自动停止。" -ForegroundColor Cyan
                    $script:trunning = $false
                    break
                }
                $ok = Apply-Once
                if (-not $ok) {
                    Write-Host "`n检测到手动移动，已自动暂停。" -ForegroundColor Yellow
                    $resp = Read-Host "  输入 r 继续运行，直接回车停止"
                    if ($resp -eq 'r' -or $resp -eq 'R') { Term-Resume; continue }
                    $script:trunning = $false
                    break
                }
                Write-Host ("`r 已移动:{0} 点击:{1} 距离:{2}px   " -f $script:count, $script:clickCount, $script:totalDist) -NoNewline
                # 用 Stopwatch 控制节奏，避免「每次睡眠 100ms 与轮询开销累加」造成的长期漂移
                $ms = Compute-IntervalMs
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                while ($sw.ElapsedMilliseconds -lt $ms -and $script:trunning) {
                    $sig = Test-StopKey
                    if ($sig -eq 'stop') { $script:trunning = $false; break }
                    if ($sig -eq 'pause') {
                        $sw.Stop()
                        Write-Host "`n已手动暂停。" -ForegroundColor Yellow
                        $resp = Read-Host "  输入 r 继续运行，直接回车停止"
                        if ($resp -eq 'r' -or $resp -eq 'R') { Term-Resume; $sw.Restart(); continue }
                        $script:trunning = $false; break
                    }
                    Start-Sleep -Milliseconds 50
                }
                $sw.Stop()
            }
        } catch {
            # 捕获 Ctrl+C 等中断
        } finally {
            $script:trunning = $false
        }
        Write-Host ""
        Stop-MoverCore
        Save-Settings
        Write-StatsIfRequested
        Write-Host ("已停止。共移动 {0} 次，点击 {1} 次，总距离 {2} 像素。" -f $script:count, $script:clickCount, $script:totalDist) -ForegroundColor Cyan
    }

    function Term-Settings {
        Write-Host '--- 修改设置（直接回车保持当前值）---' -ForegroundColor Yellow
        $v = Read-Host "间隔时间（秒，0.1-60）[当前 $($script:cfg.interval)]"
        if ($v -ne '') { try { $inv = [System.Globalization.CultureInfo]::InvariantCulture; $d = [decimal]::Parse($v, $inv); if ($d -lt 0.1) { $d = 0.1 }; if ($d -gt 60) { $d = 60 }; $script:cfg.interval = $d } catch { Write-Host '无效' -ForegroundColor Red } }
        $v = Read-Host "移动模式 (horizontal/vertical/circular/random/square/spiral/figure8/bounce) [当前 $($script:cfg.mode)]"
        if ($v -ne '') {
            # 原来输错时静默忽略，用户以为改成功了
            if ($script:validModes -contains $v) { $script:cfg.mode = $v }
            else { Write-Host "无效模式：$v（可选：$($script:validModes -join '/')）" -ForegroundColor Red }
        }
        $v = Read-Host "步长(像素,横/纵) [当前 $($script:cfg.step)]"
        if ($v -ne '') { try { $i = [int]$v; if ($i -lt 1) { $i = 1 }; if ($i -gt 1000) { $i = 1000 }; $script:cfg.step = $i } catch { } }
        $v = Read-Host "圆圈半径(像素) [当前 $($script:cfg.radius)]"
        if ($v -ne '') { try { $i = [int]$v; if ($i -lt 10) { $i = 10 }; if ($i -gt 2000) { $i = 2000 }; $script:cfg.radius = $i } catch { } }
        $v = Read-Host "缓动(0线性 1渐快 2渐慢 3正弦) [当前 $($script:cfg.ease)]"
        if ($v -ne '') { try { $i = [int]$v; if ($i -ge 0 -and $i -le 3) { $script:cfg.ease = $i } } catch { } }
        $v = Read-Host "点击方式(0无 1左键 2右键 3双击) [当前 $($script:cfg.clickType)]"
        if ($v -ne '') { try { $i = [int]$v; if ($i -ge 0 -and $i -le 3) { $script:cfg.clickType = $i } } catch { } }
        $v = Read-Host "点击节流(每N次移动点1次) [当前 $($script:cfg.clickEvery)]"
        if ($v -ne '') { try { $i = [int]$v; if ($i -lt 1) { $i = 1 }; if ($i -gt 100) { $i = 100 }; $script:cfg.clickEvery = $i } catch { } }
        $v = Read-Host "随机抖动(像素) [当前 $($script:cfg.jitter)]"
        if ($v -ne '') { try { $i = [int]$v; if ($i -lt 0) { $i = 0 }; if ($i -gt 200) { $i = 200 }; $script:cfg.jitter = $i } catch { } }
        $v = Read-Host "间隔随机度(%) [当前 $($script:cfg.randPct)]"
        if ($v -ne '') { try { $i = [int]$v; if ($i -lt 0) { $i = 0 }; if ($i -gt 100) { $i = 100 }; $script:cfg.randPct = $i } catch { } }
        $v = Read-Host "延迟启动(秒,0立即) [当前 $($script:cfg.delay)]"
        if ($v -ne '') { try { $i = [int]$v; if ($i -lt 0) { $i = 0 }; if ($i -gt 120) { $i = 120 }; $script:cfg.delay = $i } catch { } }
        $v = Read-Host "自动暂停(检测到手动移动)(y/n) [当前 $(if ($script:cfg.autoPause) { 'y' } else { 'n' })]"
        if ($v -eq 'y') { $script:cfg.autoPause = $true } elseif ($v -eq 'n') { $script:cfg.autoPause = $false }
        $v = Read-Host "停止回到起点(y/n) [当前 $(if ($script:cfg.returnHome) { 'y' } else { 'n' })]"
        if ($v -eq 'y') { $script:cfg.returnHome = $true } elseif ($v -eq 'n') { $script:cfg.returnHome = $false }
        $v = Read-Host "声音提示(y/n) [当前 $(if ($script:cfg.sound) { 'y' } else { 'n' })]"
        if ($v -eq 'y') { $script:cfg.sound = $true } elseif ($v -eq 'n') { $script:cfg.sound = $false }
        Save-Settings
        Write-Host '设置已保存。' -ForegroundColor Green
    }

    function Term-Profiles {
        while ($true) {
            Write-Host '--- 预设方案 ---' -ForegroundColor Yellow
            Write-Host '  1. 列出已有方案'
            Write-Host '  2. 保存当前设置为方案'
            Write-Host '  3. 加载方案'
            Write-Host '  4. 应用内置方案'
            Write-Host '  5. 导出上次运行统计（JSON）'
            Write-Host '  6. 返回主菜单'
            $c = Read-Host '请选择'
            switch ($c) {
                '1' {
                    $list = Get-ChildItem -Path $profilesDir -Filter '*.ini' -ErrorAction SilentlyContinue
                    if ($list) { $list | ForEach-Object { Write-Host "  - $($_.BaseName)" } } else { Write-Host '  （暂无）' }
                }
                '2' {
                    $n = Read-Host '方案名称'
                    if ($n -ne '') {
                        $n = Sanitize-Name $n
                        if (-not (Test-Path $profilesDir)) { New-Item -ItemType Directory -Path $profilesDir -Force | Out-Null }
                        Set-Content -Path (Join-Path $profilesDir ($n + '.ini')) -Value (Get-SettingsLines) -Encoding ASCII
                        Write-Host "已保存：$n" -ForegroundColor Green
                    }
                }
                '3' {
                    $n = Read-Host '方案名称'
                    if ($n -ne '') {
                        $n = Sanitize-Name $n
                        $p = Join-Path $profilesDir ($n + '.ini')
                        if (Test-Path $p) {
                            $d = @{}
                            foreach ($ln in (Get-Content $p)) { $eq = $ln.IndexOf('='); if ($eq -gt 0) { $d[$ln.Substring(0, $eq)] = $ln.Substring($eq + 1) } }
                            Apply-Dict $d
                            Save-Settings
                            Write-Host "已加载：$n" -ForegroundColor Green
                        } else { Write-Host "未找到方案：$n" -ForegroundColor Red }
                    }
                }
                '4' {
                    Write-Host '  内置方案：meeting(会议保活) / minimal(最小干预) / gaming(游戏防掉) / wide(大范围游走)'
                    $n = Read-Host '输入方案键名'
                    if ($n -ne '') {
                        if (Apply-BuiltinPreset $n) { Save-Settings; Write-Host "已应用内置方案：$n" -ForegroundColor Green }
                        else { Write-Host "未知内置方案：$n（可选：meeting/minimal/gaming/wide）" -ForegroundColor Red }
                    }
                }
                '5' {
                    $def = Join-Path $appDir 'stats-last.json'
                    if (Export-Stats $def) { Write-Host "统计已导出：$def" -ForegroundColor Green }
                    else { Write-Host '导出失败（可能尚未运行过）。' -ForegroundColor Red }
                }
                '6' { return }
                default { Write-Host '无效选择。' -ForegroundColor Red }
            }
            Write-Host ''
        }
    }

    function Term-Help {
        Write-Host ''
        Write-Host '==== 使用帮助 ====' -ForegroundColor Cyan
        Write-Host '• 运行后会按设定间隔自动移动/点击鼠标，用于保持屏幕/会话活跃。'
        Write-Host '• 八种模式：horizontal(横向) / vertical(纵向) / circular(圆圈) / random(随机) / square(方形) / spiral(螺旋) / figure8(8字) / bounce(斜弹)。'
        Write-Host '• 停止：运行中按 s 或 Esc；按 p 暂停、r 继续；或动一下鼠标触发自动暂停（需开启自动暂停）。'
        Write-Host '• 网页图形界面：macOS/Linux 运行 -web（或主菜单选 5）即可用浏览器图形化控制。'
        Write-Host '• 配置自动保存在：'
        Write-Host "    $settingsPath"
        Write-Host '• 多显示器选择、全局热键、托盘、开机自启为 Windows 图形界面专属；'
        Write-Host '  本终端模式已支持全部核心移动/点击/统计/预设功能。'
        if ($script:platform -eq 'macOS') {
            Write-Host '• macOS 需在「系统设置 → 隐私与安全性 → 辅助功能」中，'
            Write-Host '  给运行本脚本的终端授予「辅助功能」权限，否则无法移动鼠标。'
            Write-Host '• 右键/双击点击建议安装 cliclick：brew install cliclick'
        }
        if ($script:platform -eq 'Linux') {
            Write-Host '• Linux 需要 xdotool：sudo apt install xdotool（X11 会话）。'
            Write-Host '  Wayland 会话可用 XWayland 或安装 ydotool 后自行适配。'
        }
        Write-Host ''
    }

    function Start-TerminalUi {
        Write-Host ''
        Write-Host '==================================================' -ForegroundColor Cyan
        Write-Host "  $APP_NAME $VERSION   终端模式（平台：$($script:platform)）" -ForegroundColor Cyan
        Write-Host '==================================================' -ForegroundColor Cyan
        if ($script:platform -eq 'macOS') {
            Write-Host '提示：首次使用需在「系统设置 → 隐私与安全性 → 辅助功能」中，' -ForegroundColor DarkGray
            Write-Host '      授予终端「辅助功能」权限，否则无法移动鼠标。' -ForegroundColor DarkGray
        }
        if ($script:platform -eq 'Linux' -and -not $script:hasXdotool) {
            Write-Host '提示：未检测到 xdotool，请先安装后再运行（见帮助）。' -ForegroundColor DarkGray
        }
        Write-Host '命令：1=开始  2=设置  3=预设方案  4=帮助  5=网页界面  6=退出' -ForegroundColor DarkGray
        Write-Host ''
        while ($true) {
            Write-Host '=== 主菜单 ===' -ForegroundColor Yellow
            Write-Host '  1. 开始运行'
            Write-Host '  2. 修改设置'
            Write-Host '  3. 预设方案 / 内置方案 / 导出统计'
            Write-Host '  4. 关于 / 使用帮助'
            Write-Host '  5. 网页图形界面（浏览器控制）'
            Write-Host '  6. 退出'
            $c = Read-Host '请选择（默认 1）'
            if ($c -eq '') { $c = '1' }
            switch ($c) {
                '1' { Term-Start }
                '2' { Term-Settings }
                '3' { Term-Profiles }
                '4' { Term-Help }
                '5' { Start-WebUi }
                '6' { Save-Settings; Write-Host '已保存设置，再见。'; return }
                default { Write-Host '无效选择，请输入 1-6。' -ForegroundColor Red }
            }
            Write-Host ''
        }
    }

    # 命令行参数（无界面/自动化用）：-interval 2 -mode circular -step 20 -radius 150 -run
    #   额外：-click 0-3  -sound on|off  -autoPause on|off  -duration 秒  -once  -profile 名称  -help
    $doRun = $false
    $doWeb = $false
    $showHelp = $false
    $script:cliDuration = $null
    $script:cliOnce = $false
    $script:cliProfile = $null
    $ai = 0
    while ($ai -lt $args.Count) {
        $a = $args[$ai]
        $key = $a; $val = $null
        if ($a -match '^(.+?)=(.+)$') { $key = $matches[1]; $val = $matches[2]; $ai++ }
        else { $key = $a; if ($ai + 1 -lt $args.Count) { $val = $args[$ai + 1]; $ai += 2 } else { $ai++ } }
        switch ($key) {
            '-interval'  { try { $d = [decimal]::Parse($val, [System.Globalization.CultureInfo]::InvariantCulture); if ($d -lt 0.1) { $d = 0.1 }; if ($d -gt 60) { $d = 60 }; $script:cfg.interval = $d } catch { } }
            '-mode'      { if ($script:validModes -contains $val) { $script:cfg.mode = $val } }
            '-step'      { try { $n = [int]$val; if ($n -lt 1) { $n = 1 }; if ($n -gt 1000) { $n = 1000 }; $script:cfg.step = $n } catch { } }
            '-radius'    { try { $n = [int]$val; if ($n -lt 10) { $n = 10 }; if ($n -gt 2000) { $n = 2000 }; $script:cfg.radius = $n } catch { } }
            '-click'     { try { $n = [int]$val; if ($n -ge 0 -and $n -le 3) { $script:cfg.clickType = $n } } catch { } }
            '-sound'     { if ($val -eq 'on') { $script:cfg.sound = $true } elseif ($val -eq 'off') { $script:cfg.sound = $false } }
            '-autoPause' { if ($val -eq 'on') { $script:cfg.autoPause = $true } elseif ($val -eq 'off') { $script:cfg.autoPause = $false } }
            '-duration'  { try { $n = [int]$val; if ($n -gt 0) { $script:cliDuration = $n } } catch { } }
            '-profile'   { $script:cliProfile = Sanitize-Name $val }
            '-preset'    { if (-not (Apply-BuiltinPreset $val)) { Write-Host "未知内置方案：$val（可选：meeting/minimal/gaming/wide）" -ForegroundColor Red } }
            '-once'      { $script:cliOnce = $true }
            '-run'       { $doRun = $true }
            '-help'      { $showHelp = $true }
            '-h'         { $showHelp = $true }
            '-?'         { $showHelp = $true }
            '-export'    { $script:cliExport = $val }
            '-web'       { $doWeb = $true }
        }
    }
    if ($showHelp) {
        Write-Host ''
        Write-Host '==== AutoMouseMover 命令行用法 ====' -ForegroundColor Cyan
        Write-Host '  pwsh Run-GUI.ps1 [参数]'
        Write-Host '  无参数           启动交互式终端菜单（Windows 则启动图形界面）'
        Write-Host '  -run             按当前/指定配置直接开始运行（无界面）'
        Write-Host '  -once            只移动一次鼠标即退出（适合定时保活 ping）'
        Write-Host '  -interval 秒     间隔 0.1~60'
        Write-Host '  -mode 模式        horizontal/vertical/circular/random/square/spiral/figure8/bounce'
        Write-Host '  -step 像素        横/纵步长'
        Write-Host '  -radius 像素      圆圈半径'
        Write-Host '  -click 0-3        0无 1左键 2右键 3双击'
        Write-Host '  -sound on|off     开始/停止提示音'
        Write-Host '  -autoPause on|off 检测到手动移动自动暂停'
        Write-Host '  -duration 秒      运行指定秒数后自动停止（-run 时有效）'
        Write-Host '  -profile 名称     加载已保存的预设方案后运行'
        Write-Host '  -preset 键名      应用内置方案后运行（meeting/minimal/gaming/wide）'
        Write-Host '  -export 路径      运行结束后将统计导出为 JSON'
        Write-Host '  -web             启动网页图形界面（浏览器控制，macOS/Linux/Windows 通用）'
        Write-Host '  -help|-h|-?       显示本帮助并退出'
        Write-Host '  示例：'
        Write-Host '    pwsh Run-GUI.ps1 -interval 2 -mode circular -run'
        Write-Host '    pwsh Run-GUI.ps1 -web'
        Write-Host '    pwsh Run-GUI.ps1 -profile meeting -duration 3600 -run'
        Write-Host ''
        return
    }
    if ($script:cliProfile) {
        $pp = Join-Path $profilesDir ($script:cliProfile + '.ini')
        if (Test-Path $pp) {
            $pd = @{}
            foreach ($ln in (Get-Content $pp)) { $eq = $ln.IndexOf('='); if ($eq -gt 0) { $pd[$ln.Substring(0, $eq)] = $ln.Substring($eq + 1) } }
            Apply-Dict $pd
            Write-Host "已加载预设：$($script:cliProfile)" -ForegroundColor DarkGray
        } else { Write-Host "未找到预设方案：$($script:cliProfile)" -ForegroundColor Red }
    }
    if ($doWeb) {
        Start-WebUi
        return
    }
    if ($script:cliOnce) {
        Reset-EngineState
        Do-Step
        Save-Settings
        Write-StatsIfRequested
        Clear-BeepCache
        Write-Host '已执行一次鼠标移动并退出。' -ForegroundColor Green
        return
    }
    if ($doRun) {
        Term-Start
        Clear-BeepCache
        return
    }

    Start-TerminalUi
    # 清理提示音临时文件（每个频率一个）
    Clear-BeepCache
}
