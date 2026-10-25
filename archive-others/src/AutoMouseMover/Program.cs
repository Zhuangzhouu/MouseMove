using System;
using System.Windows.Forms;

namespace AutoMouseMover;

/// <summary>
/// 应用程序入口。
/// </summary>
internal static class Program
{
    [STAThread]
    private static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.SetHighDpiMode(HighDpiMode.SystemAware);
        Application.Run(new MainForm());
    }
}
