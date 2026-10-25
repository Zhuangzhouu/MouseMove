namespace MouseEngine;

/// <summary>
/// 全局应用信息，版本常量统一定义在此。
/// 需求：定义版本常量为 v0.3
/// </summary>
public static class AppInfo
{
    /// <summary>版本常量（对外展示，如标题栏 / 关于框）</summary>
    public const string Version = "v0.3";

    /// <summary>数字版本号（用于程序集版本、安装包版本）</summary>
    public const string VersionNumber = "0.3.0";

    /// <summary>应用名称</summary>
    public const string AppName = "AutoMouseMover";

    /// <summary>显示名，例如 "AutoMouseMover v0.2"</summary>
    public static string DisplayName => $"{AppName} {Version}";
}
