using System;
using System.Drawing;

namespace MouseEngine;

/// <summary>移动模式。</summary>
public enum MovementMode
{
    /// <summary>横向（左右）往返移动</summary>
    Horizontal,

    /// <summary>纵向（上下）往返移动</summary>
    Vertical,

    /// <summary>沿圆圈轨迹移动</summary>
    Circular,

    /// <summary>在区域内随机跳点（v0.3）</summary>
    Random
}

/// <summary>缓动曲线：让每步位移大小起伏，移动节奏更拟人（v0.3）。</summary>
public enum EaseType
{
    /// <summary>线性（恒速）</summary>
    Linear = 0,

    /// <summary>渐快</summary>
    EaseIn = 1,

    /// <summary>渐慢</summary>
    EaseOut = 2,

    /// <summary>正弦起伏（快慢交替）</summary>
    Sine = 3
}

/// <summary>
/// 鼠标移动引擎：根据所选模式计算下一帧坐标，并通过 MouseController 应用。
/// 不依赖 UI，可独立测试。
/// </summary>
public sealed class MovementEngine
{
    private readonly MouseController _mouse = new();
    private int _dir = 1;            // 横向/纵向的往返方向
    private double _angle = 0.0;     // 圆圈的当前角度（弧度）
    private double _easePhase = 0.0; // 缓动相位（0~1 循环）
    private readonly Random _rng = new();

    /// <summary>移动所限定的屏幕区域（通常为所选显示器的工作区）。</summary>
    public Rectangle Bounds { get; set; }

    /// <summary>横向/纵向模式下，每次移动的像素步长。</summary>
    public int StepPixels { get; set; } = 20;

    /// <summary>圆圈模式的半径（像素）。</summary>
    public int Radius { get; set; } = 150;

    /// <summary>圆圈模式每步的角度增量（度）。</summary>
    public double CircleStepDegrees { get; set; } = 6.0;

    /// <summary>边缘留白，避免光标进入屏幕外或任务栏。</summary>
    public int Margin { get; set; } = 10;

    /// <summary>每次移动附加的随机抖动幅度（像素），0 表示不抖动。用于拟人化，避免被识别为机器脚本。</summary>
    public int JitterPixels { get; set; } = 0;

    /// <summary>当前光标坐标。</summary>
    public Point Current { get; private set; }

    /// <summary>当前移动模式。</summary>
    public MovementMode Mode { get; set; } = MovementMode.Horizontal;

    /// <summary>缓动曲线（v0.3）。</summary>
    public EaseType Ease { get; set; } = EaseType.Linear;

    /// <summary>
    /// 重置内部状态：把当前位置设为屏幕中心，方向/角度/缓动相位归零。
    /// 开始运行或切换模式时调用。
    /// </summary>
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

    /// <summary>计算并返回下一帧应移动到的坐标（不实际移动）。</summary>
    public Point Next()
    {
        Rectangle b = Bounds;
        int left = b.X + Margin;
        int right = b.X + b.Width - Margin;
        int top = b.Y + Margin;
        int bottom = b.Y + b.Height - Margin;

        // 缓动：推进相位并计算本步有效步长（随机/圆圈模式也受益）
        _easePhase += 0.08;
        if (_easePhase > 1.0) _easePhase -= 1.0;
        int effStep = Math.Max(1, (int)Math.Round(StepPixels * EaseFactor()));

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
                nx = Math.Max(left, Math.Min(right, nx));
                ny = Math.Max(top, Math.Min(bottom, ny));
                Current = new Point(nx, ny);
                break;
            }
            case MovementMode.Random:
            {
                int nx = _rng.Next(left, Math.Max(left + 1, right));
                int ny = _rng.Next(top, Math.Max(top + 1, bottom));
                Current = new Point(nx, ny);
                break;
            }
        }
        return Current;
    }

    /// <summary>执行一次移动（可选点击）。点击节流由调用方控制：传 None 只移动。</summary>
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
            nx = Math.Max(left, Math.Min(right, nx));
            ny = Math.Max(top, Math.Min(bottom, ny));
            p = new Point(nx, ny);
        }

        if (click == ClickType.None)
            _mouse.MoveTo(p.X, p.Y);
        else
            _mouse.MoveAndClick(p.X, p.Y, click);
    }
}
