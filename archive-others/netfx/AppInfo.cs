using System;

namespace MouseEngine
{
    /// <summary>
    /// 全局应用信息，版本常量统一定义在此。
        /// 需求：定义版本常量为 v0.3
        /// </summary>
        public static class AppInfo
        {
            public const string Version = "v0.3";
            public const string VersionNumber = "0.3.0";
        public const string AppName = "AutoMouseMover";
        public static string DisplayName { get { return AppName + " " + Version; } }
    }
}
