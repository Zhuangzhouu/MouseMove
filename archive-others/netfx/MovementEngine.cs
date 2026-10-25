using System;
using System.Drawing;

namespace MouseEngine
{
    /// <summary>移动模式。</summary>
    public enum MovementMode
    {
        Horizontal,
        Vertical,
        Circular,
        Random
    }

    /// <summary>缓动曲线：让每步位移大小起伏，移动节奏更拟人（v0.3）。</summary>
    public enum EaseType
    {
        Linear = 0,
        EaseIn = 1,
        EaseOut = 2,
        Sine = 3
    }

    /// <summary>
    /// 鼠标移动引擎：按所选模式计算下一帧坐标并应用。不依赖 UI，可独立测试。
    /// </summary>
    public sealed class MovementEngine
    {
        private readonly MouseController _mouse = new MouseController();
        private int _dir = 1;
        private double _angle = 0.0;
        private double _easePhase = 0.0;
        private readonly Random _rng = new Random();

        public Rectangle Bounds { get; set; }
        public int StepPixels { get; set; } = 20;
        public int Radius { get; set; } = 150;
        public double CircleStepDegrees { get; set; } = 6.0;
        public int Margin { get; set; } = 10;
        /// <summary>每次移动附加的随机抖动幅度（像素），0 表示不抖动。用于拟人化，避免被识别为机器脚本。</summary>
        public int JitterPixels { get; set; } = 0;
        public Point Current { get; private set; }
        public MovementMode Mode { get; set; } = MovementMode.Horizontal;
        /// <summary>缓动曲线（v0.3）。</summary>
        public EaseType Ease { get; set; } = EaseType.Linear;

        public void Reset()
        {
            Current = GetCenter();
            _dir = 1;
            _angle = 0.0;
            _easePhase = 0.0;
        }

        private Point GetCenter()
        {
            int x = Bounds.X + Bounds.Width / 2;
            int y = Bounds.Y + Bounds.Height / 2;
            return new Point(x, y);
        }

        /// <summary>缓动因子：0.4 ~ 1.6 之间起伏，作用于步长。</summary>
        private double EaseFactor()
        {
            switch (Ease)
            {
                case EaseType.EaseIn: return 0.4 + 0.8 * _easePhase;
                case EaseType.EaseOut: return 1.2 - 0.8 * _easePhase;
                case EaseType.Sine: return 1.0 + 0.5 * Math.Sin(_easePhase * Math.PI * 2.0);
                default: return 1.0;
            }
        }

        public Point Next()
        {
            Rectangle b = Bounds;
            int left = b.X + Margin;
            int right = b.X + b.Width - Margin;
            int top = b.Y + Margin;
            int bottom = b.Y + b.Height - Margin;

            // 缓动：推进相位并计算本步有效步长
            _easePhase += 0.08;
            if (_easePhase > 1.0) _easePhase -= 1.0;
            int effStep = (int)Math.Round(StepPixels * EaseFactor());
            if (effStep < 1) effStep = 1;

            switch (Mode)
            {
                case MovementMode.Horizontal:
                {
                    int nx = Current.X + _dir * effStep;
                    if (nx >= right) { nx = right; _dir = -1; }
                    else if (nx <= left) { nx = left; _dir = 1; }
                    Current = new Point(nx, Current.Y);
                    break;
                }
                case MovementMode.Vertical:
                {
                    int ny = Current.Y + _dir * effStep;
                    if (ny >= bottom) { ny = bottom; _dir = -1; }
                    else if (ny <= top) { ny = top; _dir = 1; }
                    Current = new Point(Current.X, ny);
                    break;
                }
                case MovementMode.Circular:
                {
                    Point c = GetCenter();
                    _angle += CircleStepDegrees * Math.PI / 180.0;
                    int nx = c.X + (int)Math.Round(Radius * Math.Cos(_angle));
                    int ny = c.Y + (int)Math.Round(Radius * Math.Sin(_angle));
                    if (nx < left) nx = left; else if (nx > right) nx = right;
                    if (ny < top) ny = top; else if (ny > bottom) ny = bottom;
                    Current = new Point(nx, ny);
                    break;
                }
                case MovementMode.Random:
                {
                    int maxRx = right > left + 1 ? right : left + 1;
                    int maxRy = bottom > top + 1 ? bottom : top + 1;
                    int nx = _rng.Next(left, maxRx);
                    int ny = _rng.Next(top, maxRy);
                    Current = new Point(nx, ny);
                    break;
                }
            }
            return Current;
        }

        public void Tick(ClickType click)
        {
            Point p = Next();

            // 拟人化：在目标点附近附加随机抖动（不影响基准轨迹）
            if (JitterPixels > 0)
            {
                int jx = _rng.Next(-JitterPixels, JitterPixels + 1);
                int jy = _rng.Next(-JitterPixels, JitterPixels + 1);
                int nx = p.X + jx;
                int ny = p.Y + jy;
                Rectangle b = Bounds;
                int left = b.X + Margin;
                int right = b.X + b.Width - Margin;
                int top = b.Y + Margin;
                int bottom = b.Y + b.Height - Margin;
                if (nx < left) nx = left; else if (nx > right) nx = right;
                if (ny < top) ny = top; else if (ny > bottom) ny = bottom;
                p = new Point(nx, ny);
            }

            if (click == ClickType.None) _mouse.MoveTo(p.X, p.Y);
            else _mouse.MoveAndClick(p.X, p.Y, click);
        }
    }
}
