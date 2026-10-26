// ============================================================
//  AutoMouseMover.exe 启动器（极小，仅负责“像正常软件一样被双击”）
//
//  为什么需要它：
//    Run-GUI.ps1 是核心程序，但 .bat 启动会拖一个黑色控制台窗，
//    而且 .bat 无法拥有自己的图标。这个启动器编译成 Win32 窗口程序
//    （-target:winexe，无控制台），嵌入 AutoMouseMover.ico 图标，
//    再去调用同目录的 Run-GUI.ps1 —— 双击体验与普通软件一致。
//
//  编译方式：运行同目录的 build_exe.bat（用 Windows 自带的 csc.exe，
//    不需要安装任何 SDK / Visual Studio）。只需编译一次。
//
//  注意：本文件不含任何业务逻辑，真正的功能全在 Run-GUI.ps1 里。
// ============================================================
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

public static class Launcher
{
    [STAThread]
    public static int Main()
    {
        try
        {
            string dir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            string script = Path.Combine(dir, "Run-GUI.ps1");

            if (!File.Exists(script))
            {
                MessageBox.Show(
                    "找不到 Run-GUI.ps1。\n\n请确认它与 AutoMouseMover.exe 位于同一个文件夹中。",
                    "AutoMouseMover",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                return 2;
            }

            var psi = new ProcessStartInfo("powershell.exe");
            psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File \"" + script + "\"";
            psi.WorkingDirectory = dir;
            psi.UseShellExecute = false;
            psi.CreateNoWindow = true;          // 不弹出控制台窗口
            psi.WindowStyle = ProcessWindowStyle.Hidden;
            psi.RedirectStandardError = true;   // 捕获脚本报错，失败时弹窗显示

            using (var proc = Process.Start(psi))
            {
                proc.WaitForExit();             // 让本进程存活到界面关闭，任务管理器里看起来就是一个应用
                // 非零退出码 = 脚本启动阶段就报错（GUI 没起来），把 PowerShell 的错误原样弹出来
                if (proc.ExitCode != 0)
                {
                    string err = proc.StandardError.ReadToEnd();
                    if (string.IsNullOrWhiteSpace(err))
                        err = "Run-GUI.ps1 以错误码 " + proc.ExitCode + " 退出，但无详细输出。\n可能原因：脚本含运行时错误，或被安全软件拦截。";
                    MessageBox.Show("启动失败（Run-GUI.ps1 报错）：\n\n" + err,
                        "AutoMouseMover", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
                return proc.ExitCode;
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show("启动失败：\n" + ex.Message, "AutoMouseMover",
                MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }
}
