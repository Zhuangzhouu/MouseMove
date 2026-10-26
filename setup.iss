; ============================================================
;  AutoMouseMover 安装包脚本（Inno Setup）
;  打包「纯 PowerShell 跨平台版」（零编译，无需 .NET SDK / Python）
;  用 Inno Setup Compiler 打开本文件 -> Build -> 生成 setup.exe
;  生成的安装包位于 installer\Setup-AutoMouseMover-0.6.0.exe
;
;  可选：打包前先运行一次 build_exe.bat 生成 AutoMouseMover.exe，
;  这样安装后的快捷方式指向真正的窗口程序（有图标、无控制台窗）。
;  即使没有 exe 也能正常打包，快捷方式会退回 run_gui.bat。
; ============================================================

#define MyAppName "AutoMouseMover"
#define MyAppVersion "0.6.6"
#define MyAppPublisher "Local"
#define MyAppExeName "run_gui.bat"

[Setup]
; 安装包标识与基本信息
AppId={{A1B2C3D4-1000-4A00-8A00-0000000000AA}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputBaseFilename=Setup-{#MyAppName}-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
OutputDir=installer
; 该应用不需要管理员权限
PrivilegesRequired=lowest
; 安装包自身也用我们的图标
SetupIconFile=AutoMouseMover.ico
UninstallDisplayIcon={app}\AutoMouseMover.ico

[Languages]
; 中文安装界面（Inno Setup 自带 ChineseSimplified.isl）
Name: "chinese"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Files]
; 打包 PowerShell 版全部文件（脚本 + 启动器 + 说明）
Source: "Run-GUI.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "run_gui.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "run_gui.sh"; DestDir: "{app}"; Flags: ignoreversion
Source: "README.md";  DestDir: "{app}"; Flags: ignoreversion
; 图标与 exe 构建链
Source: "AutoMouseMover.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "Launcher.cs";       DestDir: "{app}"; Flags: ignoreversion
Source: "build_exe.bat";     DestDir: "{app}"; Flags: ignoreversion
; exe 由 build_exe.bat 生成；未生成时跳过，快捷方式仍可用 run_gui.bat
Source: "AutoMouseMover.exe"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
; 快捷方式使用自定义图标（原来用的是默认灰色图标）
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; IconFilename: "{app}\AutoMouseMover.ico"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon; IconFilename: "{app}\AutoMouseMover.ico"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "快捷方式："

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "启动 {#MyAppName}"; Flags: nowait postinstall skipifsilent
