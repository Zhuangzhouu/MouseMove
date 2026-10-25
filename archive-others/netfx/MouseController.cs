using System;
using System.Runtime.InteropServices;

namespace MouseEngine
{
    /// <summary>点击方式。</summary>
    public enum ClickType
    {
        None = 0,
        Left,
        Right,
        Double
    }

    /// <summary>
    /// 通过 Win32 API 直接控制鼠标，性能高、无第三方依赖。
    /// </summary>
    public sealed class MouseController
    {
        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool SetCursorPos(int x, int y);

        [DllImport("user32.dll")]
        private static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, UIntPtr dwExtraInfo);

        [DllImport("user32.dll")]
        private static extern bool GetCursorPos(out POINT lpPoint);

        [StructLayout(LayoutKind.Sequential)]
        public struct POINT
        {
            public int X;
            public int Y;
        }

        private const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
        private const uint MOUSEEVENTF_LEFTUP = 0x0004;
        private const uint MOUSEEVENTF_RIGHTDOWN = 0x0008;
        private const uint MOUSEEVENTF_RIGHTUP = 0x0010;

        public bool GetCursorPosition(out int x, out int y)
        {
            POINT p;
            if (GetCursorPos(out p))
            {
                x = p.X;
                y = p.Y;
                return true;
            }
            x = 0;
            y = 0;
            return false;
        }

        public void MoveTo(int x, int y) { SetCursorPos(x, y); }

        private void ClickLeft()
        {
            mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, UIntPtr.Zero);
            mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, UIntPtr.Zero);
        }

        private void ClickRight()
        {
            mouse_event(MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, UIntPtr.Zero);
            mouse_event(MOUSEEVENTF_RIGHTUP, 0, 0, 0, UIntPtr.Zero);
        }

        public void Click(ClickType type)
        {
            if (type == ClickType.Right) ClickRight();
            else if (type == ClickType.Double) { ClickLeft(); ClickLeft(); }
            else if (type == ClickType.Left) ClickLeft();
        }

        public void MoveAndClick(int x, int y, ClickType type)
        {
            MoveTo(x, y);
            if (type != ClickType.None) Click(type);
        }
    }
}
