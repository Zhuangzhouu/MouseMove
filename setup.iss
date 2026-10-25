; ============================================================
;  AutoMouseMover 安装包脚本（Inno Setup）
;  打包「纯 PowerShell 跨平台版」（零编译，无需 .NET SDK / Python）
;  用 Inno Setup Compiler 打开本文件 -> Build -> 生成 setup.exe
;  生成的安装包位于 installer\Setup-AutoMouseMover-0.4.exe
; ============================================================

#define MyAppName "AutoMouseMover"
#define MyAppVersion "0.4"
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

[Languages]
; 中文安装界面（Inno Setup 自带 ChineseSimplified.isl）
Name: "chinese"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Files]
; 打包 PowerShell 版全部文件（脚本 + 启动器 + 说明）
Source: "Run-GUI.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "run_gui.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "run_gui.sh"; DestDir: "{app}"; Flags: ignoreversion
Source: "README.md";  DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "快捷方式："

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "启动 {#MyAppName}"; Flags: nowait postinstall skipifsilent
