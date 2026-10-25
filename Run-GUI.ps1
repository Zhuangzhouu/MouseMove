# ============================================================
#  AutoMouseMover v0.4 —— 纯 PowerShell 跨平台版（零编译、双击即用）
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
#  v0.4 新增/变更：跨平台（Windows/macOS/Linux）适配，仅保留 PowerShell 单一实现
#  v0.3 功能：多显示器选择、随机模式、缓动曲线、点击节流、托盘菜单、
#             停止回起点、延迟启动、预设方案、运行统计、声音提示
#  v0.2 功能：拟人随机、点击方式、配置持久化、全局热键、开机自启、运行时长
# ============================================================
$ErrorActionPreference = 'Stop'

# ---- 版本常量 ----
$VERSION = 'v0.4'
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
    mode       = 'horizontal'   # horizontal/vertical/circular/random
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

# 配置存放位置（跨平台）
if ($script:platform -eq 'Windows') {
    $appDir = Join-Path $env:LOCALAPPDATA 'AutoMouseMover'
} else {
    $xdg = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
    $appDir = Join-Path $xdg 'AutoMouseMover'
}
$settingsPath = Join-Path $appDir 'settings.ini'
$profilesDir  = Join-Path $appDir 'profiles'

function Clamp-Int { param([int]$v, [int]$min, [int]$max)
    if ($v -lt $min) { return $min }
    if ($v -gt $max) { return $max }
    return $v
}

# 把 $cfg 序列化成 ini 行（供保存/预设方案复用）
function Get-SettingsLines {
    return @(
        "interval=$($script:cfg.interval)"
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
        try { $v = [decimal]([string]$dict['interval']); if ($v -lt 0.1) { $v = 0.1 }; if ($v -gt 60) { $v = 60 }; $script:cfg.interval = $v } catch { }
    }
    if ($dict.ContainsKey('mode')) {
        $m = $dict['mode']
        if (@('horizontal','vertical','circular','random') -contains $m) { $script:cfg.mode = $m }
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

# ============================================================
#  鼠标后端（按平台统一封装，引擎只调用下面四个函数）
# ============================================================
if ($script:platform -eq 'Windows') {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()

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
}

function Get-MousePosition {
    if ($script:platform -eq 'Windows') {
        $p = New-Object POINT
        if ([Win32Mouse]::GetCursorPos([ref]$p)) { return @{ x = $p.X; y = $p.Y } }
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
        $p = Get-MousePosition
        if ($null -eq $p) { $p = @{ x = 10; y = 10 } }
        $x = $p.x; $y = $p.y
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

# Linux：检测 xdotool 是否可用
if ($script:platform -eq 'Linux') {
    $script:hasXdotool = [bool](Get-Command xdotool -ErrorAction SilentlyContinue)
    if (-not $script:hasXdotool) {
        Write-Host '[警告] 未检测到 xdotool，鼠标移动/点击可能无效。请安装：' -ForegroundColor Yellow
        Write-Host '        Debian/Ubuntu: sudo apt install xdotool' -ForegroundColor Yellow
        Write-Host '        Fedora/RHEL  : sudo dnf install xdotool' -ForegroundColor Yellow
    }
} else {
    $script:hasXdotool = $false
}

# 声音提示（跨平台）
function Play-NotifySound { param([int]$freq)
    if (-not $script:cfg.sound) { return }
    try {
        if ($script:platform -eq 'Windows') {
            [console]::Beep($freq, 120)
        } elseif ($script:platform -eq 'macOS') {
            & osascript -e 'beep' 2>$null
        } else {
            $tmpdir = if ($env:TMP) { $env:TMP } elseif ($env:TEMP) { $env:TEMP } else { '/tmp' }
            $tmp = Join-Path $tmpdir 'amm_beep.wav'
            New-BeepWav $tmp $freq 120
            if (Get-Command aplay -ErrorAction SilentlyContinue) { & aplay $tmp 2>$null }
            elseif (Get-Command paplay -ErrorAction SilentlyContinue) { & paplay $tmp 2>$null }
            else { Write-Host ([char]7) -NoNewline }
        }
    } catch { }
}
function New-BeepWav { param($path, $freq, $ms)
    try {
        $sr = 44100; $dur = [double]$ms / 1000; $n = [int]($sr * $dur)
        $msb = New-Object System.IO.MemoryStream
        $bw = New-Object System.IO.BinaryWriter($msb)
        $bw.Write([byte[]]([char[]]'RIFF')); $bw.Write([int32](36 + 2 * $n)); $bw.Write([byte[]]([char[]]'WAVE'))
        $bw.Write([byte[]]([char[]]'fmt ')); $bw.Write([int32]16); $bw.Write([int16]1); $bw.Write([int16]1)
        $bw.Write([int32]$sr); $bw.Write([int32]($sr * 2)); $bw.Write([int16]2); $bw.Write([int16]16)
        $bw.Write([byte[]]([char[]]'data')); $bw.Write([int32](2 * $n))
        for ($i = 0; $i -lt $n; $i++) {
            $s = [int16](28000 * [math]::Sin(2 * [math]::PI * $freq * $i / $sr))
            $bw.Write($s)
        }
        [System.IO.File]::WriteAllBytes($path, $msb.ToArray()); $bw.Close()
    } catch { }
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
$script:homeX = $null
$script:homeY = $null
$script:firstTick = $false
$script:startTime = $null
$script:exiting = $false
$script:trunning = $false
$script:loading = $false

function Get-EaseFactor {
    switch ([int]$script:cfg.ease) {
        1 { return (0.4 + 0.8 * $script:engine.easePhase) }              # 渐快
        2 { return (1.2 - 0.8 * $script:engine.easePhase) }              # 渐慢
        3 { return (1.0 + 0.5 * [math]::Sin($script:engine.easePhase * 2 * [math]::PI)) }  # 正弦
        default { return 1.0 }
    }
}

function Reset-Engine {
    $b = Get-DisplayBounds
    $script:engine.current = @{ x = [int]($b.x + $b.w / 2); y = [int]($b.y + $b.h / 2) }
    $script:engine.angle = 0.0
    $script:engine.dir = 1
    $script:engine.easePhase = 0.0
    $script:engine.radius = [int]$script:cfg.radius
}

function Next-Move {
    if ($null -eq $script:engine.current) { Reset-Engine }
    $b = Get-DisplayBounds
    $m = $script:engine.margin
    $left = $b.x + $m; $right = $b.x + $b.w - $m
    $top = $b.y + $m; $bottom = $b.y + $b.h - $m
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
        $x = Get-Random -Minimum $left -Maximum ([math]::Max($left + 1, $right))
        $y = Get-Random -Minimum $top -Maximum ([math]::Max($top + 1, $bottom))
    } else {
        $cx = [int]($b.x + $b.w / 2); $cy = [int]($b.y + $b.h / 2)
        $script:engine.angle += $script:engine.circleStep * [math]::PI / 180
        $nx = $cx + [int]($script:engine.radius * [math]::Cos($script:engine.angle))
        $ny = $cy + [int]($script:engine.radius * [math]::Sin($script:engine.angle))
        if ($nx -lt $left) { $nx = $left } elseif ($nx -gt $right) { $nx = $right }
        if ($ny -lt $top) { $ny = $top } elseif ($ny -gt $bottom) { $ny = $bottom }
        $x = $nx; $y = $ny
    }
    $script:engine.current = @{ x = $x; y = $y }
    return @{ x = $x; y = $y }
}

function Do-Step {
    $ct = [int]$script:cfg.clickType
    $every = [int]$script:cfg.clickEvery
    if ($every -lt 1) { $every = 1 }

    $ox = $null; $oy = $null
    $p0 = Get-MousePosition
    if ($null -ne $p0) { $ox = $p0.x; $oy = $p0.y }

    $pt = Next-Move

    # 拟人化：目标点附近附加随机抖动
    $j = [int]$script:cfg.jitter
    if ($j -gt 0) {
        $b = Get-DisplayBounds; $m = $script:engine.margin
        $pt.x = $pt.x + (Get-Random -Minimum (-$j) -Maximum ($j + 1))
        $pt.y = $pt.y + (Get-Random -Minimum (-$j) -Maximum ($j + 1))
        if ($pt.x -lt ($b.x + $m)) { $pt.x = $b.x + $m } elseif ($pt.x -gt ($b.x + $b.w - $m)) { $pt.x = $b.x + $b.w - $m }
        if ($pt.y -lt ($b.y + $m)) { $pt.y = $b.y + $m } elseif ($pt.y -gt ($b.y + $b.h - $m)) { $pt.y = $b.y + $b.h - $m }
    }

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
    } else {
        if ($script:cfg.autoPause -and $null -ne $script:lastX) {
            $p = Get-MousePosition
            if ($null -ne $p -and ([math]::Abs($p.x - $script:lastX) -gt 3 -or [math]::Abs($p.y - $script:lastY) -gt 3)) {
                return $false
            }
        }
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

# 开始运行的核心（界面无关）
function Begin-RunCore {
    Reset-Engine
    $script:count = 0
    $script:clickCount = 0
    $script:totalDist = 0
    $script:moveSinceClick = 0
    $script:lastX = $null; $script:lastY = $null
    $script:homeX = $null; $script:homeY = $null
    $hp = Get-MousePosition
    if ($null -ne $hp) { $script:homeX = $hp.x; $script:homeY = $hp.y }
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
#  Windows：WinForms 图形界面
# ============================================================
if ($script:platform -eq 'Windows') {
    try {

    $form = New-Object HotkeyForm
    $form.Text = "$APP_NAME $VERSION"
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedSingle'
    $form.MaximizeBox = $false
    $form.ClientSize = New-Object System.Drawing.Size(420, 692)
    $form.Icon = [System.Drawing.SystemIcons]::Application
    $form.KeyPreview = $true

    $gb = New-Object System.Windows.Forms.GroupBox
    $gb.Text = '基本设置'; $gb.Location = New-Object System.Drawing.Point(12, 12); $gb.Size = New-Object System.Drawing.Size(396, 296)
    $form.Controls.Add($gb)

    $lblInterval = New-Object System.Windows.Forms.Label; $lblInterval.Text = '间隔时间（秒）'; $lblInterval.Location = New-Object System.Drawing.Point(14, 24); $lblInterval.AutoSize = $true; $gb.Controls.Add($lblInterval)
    $numInterval = New-Object System.Windows.Forms.NumericUpDown; $numInterval.Location = New-Object System.Drawing.Point(150, 22); $numInterval.Size = New-Object System.Drawing.Size(90, 23); $numInterval.Minimum = 0.1; $numInterval.Maximum = 60; $numInterval.Increment = 0.1; $numInterval.DecimalPlaces = 1; $numInterval.Value = 5; $gb.Controls.Add($numInterval)

    $lblMode = New-Object System.Windows.Forms.Label; $lblMode.Text = '移动模式'; $lblMode.Location = New-Object System.Drawing.Point(14, 58); $lblMode.AutoSize = $true; $gb.Controls.Add($lblMode)
    $rbH = New-Object System.Windows.Forms.RadioButton; $rbH.Text = '横向'; $rbH.Location = New-Object System.Drawing.Point(150, 56); $rbH.AutoSize = $true; $rbH.Checked = $true; $gb.Controls.Add($rbH)
    $rbV = New-Object System.Windows.Forms.RadioButton; $rbV.Text = '纵向'; $rbV.Location = New-Object System.Drawing.Point(212, 56); $rbV.AutoSize = $true; $gb.Controls.Add($rbV)
    $rbC = New-Object System.Windows.Forms.RadioButton; $rbC.Text = '圆圈'; $rbC.Location = New-Object System.Drawing.Point(274, 56); $rbC.AutoSize = $true; $gb.Controls.Add($rbC)
    $rbR = New-Object System.Windows.Forms.RadioButton; $rbR.Text = '随机'; $rbR.Location = New-Object System.Drawing.Point(336, 56); $rbR.AutoSize = $true; $gb.Controls.Add($rbR)

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
    $lblUptime = New-Object System.Windows.Forms.Label; $lblUptime.Text = '已运行：00:00:00'; $lblUptime.Location = New-Object System.Drawing.Point(220, 644); $lblUptime.AutoSize = $true; $form.Controls.Add($lblUptime)
    $lblInfo = New-Object System.Windows.Forms.Label; $lblInfo.Location = New-Object System.Drawing.Point(220, 666); $lblInfo.AutoSize = $true; $form.Controls.Add($lblInfo)

    # 托盘（创建失败也不影响主窗口，仅降级为无托盘）
    $script:hasTray = $false
    try {
        $notifyIcon = New-Object System.Windows.Forms.NotifyIcon
        $notifyIcon.Icon = [System.Drawing.SystemIcons]::Application
        $notifyIcon.Text = "$APP_NAME $VERSION"
        $notifyIcon.Visible = $false
        $trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
        $trayToggle = New-Object System.Windows.Forms.ToolStripMenuItem
        $trayToggle.Text = '开始'
        $null = $trayToggle.Click.Add({ if ($script:running -or $script:counting) { Stop-GuiMover } else { Start-GuiMover } })
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

    # 自定义全局热键
    $modValues = @(0x6, 0x3, 0x5, 0x7, 0xC, 0x2)
    $keyValues = @(0x4D, 0x20, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B, 0x41, 0x53, 0x44, 0x57)

    function Register-HotkeyCurrent {
        $mi = $cmbMods.SelectedIndex; if ($mi -lt 0) { $mi = 0 }
        $ki = $cmbKey.SelectedIndex; if ($ki -lt 0) { $ki = 0 }
        [void][Win32Mouse]::UnregisterHotKey($form.Handle, 1)
        [void][Win32Mouse]::RegisterHotKey($form.Handle, 1, [uint32]$modValues[$mi], [uint32]$keyValues[$ki])
    }
    function Update-HotkeyLabel {
        $mi = $cmbMods.SelectedIndex; if ($mi -lt 0) { $mi = 0 }
        $ki = $cmbKey.SelectedIndex; if ($ki -lt 0) { $ki = 0 }
        $script:hotkeyHint = "（$($cmbMods.Items[$mi]) + $($cmbKey.Items[$ki]) 开关）"
        if (-not ($script:running -or $script:counting)) { $lblStatus.Text = "状态：已停止$script:hotkeyHint" }
    }

    function Update-Info {
        $mode = if ($rbR.Checked) { '随机' } elseif ($rbC.Checked) { '圆圈' } elseif ($rbV.Checked) { '纵向' } else { '横向' }
        $extra = if ($rbC.Checked) { "半径 $($numRadius.Value)px" } else { "步长 $($numStep.Value)px" }
        $script:infoBase = "模式：$mode　间隔：$($numInterval.Value)s　$extra"
        $lblInfo.Text = $script:infoBase
    }

    function Update-Stats {
        $lblCount.Text = "已移动：$($script:count) 次 · 点击：$($script:clickCount) 次"
        $lblInfo.Text = "$script:infoBase　总距离：$($script:totalDist)px"
    }

    function On-ModeChanged {
        $circ = $rbC.Checked
        $linear = ($rbH.Checked -or $rbV.Checked)
        $numStep.Enabled = $linear; $lblStep.Enabled = $linear
        $numRadius.Enabled = $circ; $lblRadius.Enabled = $circ
        Update-Info
    }

    function Begin-GuiRun {
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
        Stop-MoverCore
        $lblUptime.Text = '已运行：00:00:00'
        $lblStatus.Text = "状态：已停止$script:hotkeyHint"
        $btnStart.Enabled = $true
        $btnStop.Enabled = $false
        if ($script:hasTray) { $trayToggle.Text = '开始' }
        Update-Info
        Save-Settings
    }

    function Pause-GuiMover {
        $timer.Stop()
        $uptimeTimer.Stop()
        $script:running = $false
        $lblStatus.Text = '状态：已暂停（检测到手动操作，点「开始」继续）'
        $btnStart.Enabled = $true
        $btnStop.Enabled = $false
        if ($script:hasTray) { $trayToggle.Text = '开始' }
    }

    function Restore-FromTray {
        if ($script:hasTray) { $notifyIcon.Visible = $false }
        $form.Show()
        $form.WindowState = 'Normal'
        $form.Activate()
    }

    function SyncControlsFromCfg {
        $rbH.Checked = ($script:cfg.mode -eq 'horizontal')
        $rbV.Checked = ($script:cfg.mode -eq 'vertical')
        $rbC.Checked = ($script:cfg.mode -eq 'circular')
        $rbR.Checked = ($script:cfg.mode -eq 'random')
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
        foreach ($c in [System.IO.Path]::GetInvalidFileNameChars()) { $name = $name.Replace($c, '_') }
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
        $name = $cmbProfile.Text.Trim()
        foreach ($c in [System.IO.Path]::GetInvalidFileNameChars()) { $name = $name.Replace($c, '_') }
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
    $rbH.Add_CheckedChanged({ if ($script:loading) { return }; if ($rbH.Checked) { $script:cfg.mode = 'horizontal' }; On-ModeChanged; Save-Settings })
    $rbV.Add_CheckedChanged({ if ($script:loading) { return }; if ($rbV.Checked) { $script:cfg.mode = 'vertical' }; On-ModeChanged; Save-Settings })
    $rbC.Add_CheckedChanged({ if ($script:loading) { return }; if ($rbC.Checked) { $script:cfg.mode = 'circular' }; On-ModeChanged; Save-Settings })
    $rbR.Add_CheckedChanged({ if ($script:loading) { return }; if ($rbR.Checked) { $script:cfg.mode = 'random' }; On-ModeChanged; Save-Settings })
    $numInterval.Add_ValueChanged({ if ($script:loading) { return }; $script:cfg.interval = [decimal]$numInterval.Value; Save-Settings })
    $cmbEase.Add_SelectedIndexChanged({ if ($script:loading) { return }; $script:cfg.ease = $cmbEase.SelectedIndex; Save-Settings })
    $numStep.Add_ValueChanged({ if ($script:loading) { return }; $script:cfg.step = [int]$numStep.Value; Save-Settings })
    $numRadius.Add_ValueChanged({ if ($script:loading) { return }; $script:cfg.radius = [int]$numRadius.Value; Save-Settings })
    $numJitter.Add_ValueChanged({ if ($script:loading) { return }; $script:cfg.jitter = [int]$numJitter.Value; Save-Settings })
    $numRand.Add_ValueChanged({ if ($script:loading) { return }; $script:cfg.randPct = [int]$numRand.Value; Save-Settings })
    $cmbScreen.Add_SelectedIndexChanged({ if ($script:loading) { return }; $script:cfg.screen = $cmbScreen.SelectedIndex; Save-Settings })
    $cmbClick.Add_SelectedIndexChanged({ if ($script:loading) { return }; $script:cfg.clickType = $cmbClick.SelectedIndex; Save-Settings })
    $numClickEvery.Add_ValueChanged({ if ($script:loading) { return }; $script:cfg.clickEvery = [int]$numClickEvery.Value; Save-Settings })
    $numDelay.Add_ValueChanged({ if ($script:loading) { return }; $script:cfg.delay = [int]$numDelay.Value; Save-Settings })
    $chkAutoPause.Add_CheckedChanged({ if ($script:loading) { return }; $script:cfg.autoPause = $chkAutoPause.Checked; Save-Settings })
    $chkTray.Add_CheckedChanged({ if ($script:loading) { return }; $script:cfg.tray = $chkTray.Checked; Save-Settings })
    $chkReturnHome.Add_CheckedChanged({ if ($script:loading) { return }; $script:cfg.returnHome = $chkReturnHome.Checked; Save-Settings })
    $chkSound.Add_CheckedChanged({ if ($script:loading) { return }; $script:cfg.sound = $chkSound.Checked; Save-Settings })
    $cmbMods.Add_SelectedIndexChanged({ if ($script:loading) { return }; $script:cfg.hotkeyMod = $cmbMods.SelectedIndex; Register-HotkeyCurrent; Update-HotkeyLabel; Save-Settings })
    $cmbKey.Add_SelectedIndexChanged({ if ($script:loading) { return }; $script:cfg.hotkeyKey = $cmbKey.SelectedIndex; Register-HotkeyCurrent; Update-HotkeyLabel; Save-Settings })
    $chkAutoStart.Add_CheckedChanged({ if ($script:loading) { return }; Set-AutoStart $chkAutoStart.Checked; Save-Settings })

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
    $btnStart.Add_Click({ Start-GuiMover })
    $btnStop.Add_Click({ Stop-GuiMover })
    $btnProfileSave.Add_Click({ Save-Profile })
    $btnProfileLoad.Add_Click({ Load-Profile })
    $btnAbout.Add_Click({
        [System.Windows.Forms.MessageBox]::Show(
            "$APP_NAME $VERSION`n`n自动鼠标移动工具（纯 PowerShell 跨平台版）`n支持 Windows / macOS / Linux`n支持横向 / 纵向 / 圆圈 / 随机移动，可设定 0.1s–60s 间隔并点击。`n`n新增（v0.4）：跨平台适配，仅保留 PowerShell 单一实现。`n新增（v0.3）：多显示器、随机模式、缓动曲线、点击节流、`n            托盘菜单、停止回起点、延迟启动、预设方案、运行统计、声音。`n`n停止方式（无需鼠标）：`n  • 全局热键（默认 Ctrl+Shift+M）开始/停止切换`n  • 窗口聚焦时按 Esc 停止`n  • 勾选「检测到手动移动自动暂停」后，你一动鼠标程序就让出光标`n`n版本常量：$VERSION",
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
            if ($script:hasTray) { $notifyIcon.Visible = $false; $notifyIcon.Dispose() }
        }
    })
    $form.Add_Shown({ Register-HotkeyCurrent })

    # 初始化
    On-ModeChanged
    $null = $form.Handle
    SyncControlsFromCfg
    $chkAutoStart.Checked = Test-AutoStart
    Update-HotkeyLabel
    Refresh-Profiles
    Register-HotkeyCurrent
    $script:loading = $false
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
                return ($k.KeyChar -eq 's' -or $k.KeyChar -eq 'S' -or $k.Key -eq 'Escape')
            }
        } catch { }
        return $false
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
                    if (Test-StopKey) { $script:trunning = $false; Write-Host "`n已取消。" -ForegroundColor Yellow; return }
                    Start-Sleep -Milliseconds 100
                }
            }
            Write-Host ""
        }
        Begin-RunCore
        Write-Host '运行中！按 s 或 Esc 停止；移动鼠标会触发自动暂停。' -ForegroundColor Green
        Write-Host ("模式:{0} 间隔:{1}s 步长:{2} 点击:{3}" -f $script:cfg.mode, $script:cfg.interval, $script:cfg.step, $script:cfg.clickType) -ForegroundColor DarkGray
        try {
            while ($script:trunning) {
                $ok = Apply-Once
                if (-not $ok) {
                    Write-Host "`n检测到手动移动，已自动暂停并停止。" -ForegroundColor Yellow
                    $script:trunning = $false
                    break
                }
                $ms = Compute-IntervalMs
                $chunks = [math]::Max(1, [math]::Ceiling($ms / 100))
                for ($k = 0; $k -lt $chunks -and $script:trunning; $k++) {
                    if (Test-StopKey) { $script:trunning = $false; break }
                    Start-Sleep -Milliseconds 100
                }
            }
        } catch {
            # 捕获 Ctrl+C 等中断
        } finally {
            $script:trunning = $false
        }
        Stop-MoverCore
        Save-Settings
        Write-Host ("已停止。共移动 {0} 次，点击 {1} 次，总距离 {2} 像素。" -f $script:count, $script:clickCount, $script:totalDist) -ForegroundColor Cyan
    }

    function Term-Settings {
        Write-Host '--- 修改设置（直接回车保持当前值）---' -ForegroundColor Yellow
        $v = Read-Host "间隔时间（秒，0.1-60）[当前 $($script:cfg.interval)]"
        if ($v -ne '') { try { $d = [decimal]$v; if ($d -lt 0.1) { $d = 0.1 }; if ($d -gt 60) { $d = 60 }; $script:cfg.interval = $d } catch { Write-Host '无效' -ForegroundColor Red } }
        $v = Read-Host "移动模式 (horizontal/vertical/circular/random) [当前 $($script:cfg.mode)]"
        if ($v -ne '' -and @('horizontal','vertical','circular','random') -contains $v) { $script:cfg.mode = $v }
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
            Write-Host '  4. 返回主菜单'
            $c = Read-Host '请选择'
            switch ($c) {
                '1' {
                    $list = Get-ChildItem -Path $profilesDir -Filter '*.ini' -ErrorAction SilentlyContinue
                    if ($list) { $list | ForEach-Object { Write-Host "  - $($_.BaseName)" } } else { Write-Host '  （暂无）' }
                }
                '2' {
                    $n = Read-Host '方案名称'
                    if ($n -ne '') {
                        $n = $n.Trim()
                        foreach ($c2 in [System.IO.Path]::GetInvalidFileNameChars()) { $n = $n.Replace([string]$c2, '_') }
                        if (-not (Test-Path $profilesDir)) { New-Item -ItemType Directory -Path $profilesDir -Force | Out-Null }
                        Set-Content -Path (Join-Path $profilesDir ($n + '.ini')) -Value (Get-SettingsLines) -Encoding ASCII
                        Write-Host "已保存：$n" -ForegroundColor Green
                    }
                }
                '3' {
                    $n = Read-Host '方案名称'
                    if ($n -ne '') {
                        $n = $n.Trim()
                        foreach ($c2 in [System.IO.Path]::GetInvalidFileNameChars()) { $n = $n.Replace([string]$c2, '_') }
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
                '4' { return }
                default { Write-Host '无效选择。' -ForegroundColor Red }
            }
            Write-Host ''
        }
    }

    function Term-Help {
        Write-Host ''
        Write-Host '==== 使用帮助 ====' -ForegroundColor Cyan
        Write-Host '• 运行后会按设定间隔自动移动/点击鼠标，用于保持屏幕/会话活跃。'
        Write-Host '• 四种模式：horizontal(横向) / vertical(纵向) / circular(圆圈) / random(随机)。'
        Write-Host '• 停止：运行中按 s 或 Esc；或动一下鼠标触发自动暂停（需开启自动暂停）。'
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
        Write-Host '命令：1=开始  2=设置  3=预设方案  4=帮助  5=退出' -ForegroundColor DarkGray
        Write-Host ''
        while ($true) {
            Write-Host '=== 主菜单 ===' -ForegroundColor Yellow
            Write-Host '  1. 开始运行'
            Write-Host '  2. 修改设置'
            Write-Host '  3. 预设方案（保存/加载）'
            Write-Host '  4. 关于 / 使用帮助'
            Write-Host '  5. 退出'
            $c = Read-Host '请选择（默认 1）'
            if ($c -eq '') { $c = '1' }
            switch ($c) {
                '1' { Term-Start }
                '2' { Term-Settings }
                '3' { Term-Profiles }
                '4' { Term-Help }
                '5' { Save-Settings; Write-Host '已保存设置，再见。'; return }
                default { Write-Host '无效选择，请输入 1-5。' -ForegroundColor Red }
            }
            Write-Host ''
        }
    }

    Start-TerminalUi
}
