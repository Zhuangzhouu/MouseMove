using System;
using System.Drawing;
using System.Windows.Forms;
using MouseEngine;

namespace AutoMouseMover
{
    /// <summary>
    /// 主窗口：参数设置 + 开始/停止 + 托盘 + 全局热键。
    /// v0.3 新增：多显示器、随机模式、缓动曲线、点击节流、托盘开始/停止、
    ///            停止回起点、延迟启动倒计时、预设方案、运行统计、声音提示。
    /// 兼容 .NET Framework 4.x（可由 Windows 自带 csc.exe 直接编译，无需安装 SDK）。
    /// </summary>
    public class MainForm : Form
    {
        // ---- 控件 ----
        private GroupBox _gbBasic = new GroupBox();
        private Label _lblInterval = new Label();
        private NumericUpDown _numInterval = new NumericUpDown();
        private Label _lblMode = new Label();
        private RadioButton _rbH = new RadioButton();
        private RadioButton _rbV = new RadioButton();
        private RadioButton _rbC = new RadioButton();
        private RadioButton _rbR = new RadioButton();
        private Label _lblEase = new Label();
        private ComboBox _cmbEase = new ComboBox();
        private Label _lblStep = new Label();
        private NumericUpDown _numStep = new NumericUpDown();
        private Label _lblRadius = new Label();
        private NumericUpDown _numRadius = new NumericUpDown();
        private Label _lblJitter = new Label();
        private NumericUpDown _numJitter = new NumericUpDown();
        private Label _lblRand = new Label();
        private NumericUpDown _numRand = new NumericUpDown();
        private Label _lblScreen = new Label();
        private ComboBox _cmbScreen = new ComboBox();

        private GroupBox _gbAction = new GroupBox();
        private Label _lblClick = new Label();
        private ComboBox _cmbClick = new ComboBox();
        private Label _lblClickEvery = new Label();
        private NumericUpDown _numClickEvery = new NumericUpDown();
        private Label _lblClickEvery2 = new Label();
        private CheckBox _chkAutoPause = new CheckBox();
        private CheckBox _chkTray = new CheckBox();
        private Label _lblHotkey = new Label();
        private ComboBox _cmbMods = new ComboBox();
        private ComboBox _cmbKey = new ComboBox();
        private CheckBox _chkAutoStart = new CheckBox();
        private CheckBox _chkReturnHome = new CheckBox();
        private Label _lblDelay = new Label();
        private NumericUpDown _numDelay = new NumericUpDown();
        private Label _lblDelay2 = new Label();
        private CheckBox _chkSound = new CheckBox();

        private Label _lblProfile = new Label();
        private ComboBox _cmbProfile = new ComboBox();
        private Button _btnProfileSave = new Button();
        private Button _btnProfileLoad = new Button();

        private Button _btnStart = new Button();
        private Button _btnStop = new Button();
        private Button _btnAbout = new Button();

        private Label _lblStatus = new Label();
        private Label _lblCount = new Label();
        private Label _lblUptime = new Label();
        private Label _lblInfo = new Label();

        private Timer _timer = new Timer();
        private Timer _uptimeTimer = new Timer();
        private Timer _countdownTimer = new Timer();
        private NotifyIcon _notifyIcon = new NotifyIcon();
        private ContextMenuStrip _trayMenu = new ContextMenuStrip();
        private ToolStripMenuItem _trayToggle = new ToolStripMenuItem("开始");

        // ---- 状态 ----
        private MovementEngine _engine = new MovementEngine();
        private MouseController _mouse = new MouseController();
        private bool _running = false;
        private bool _counting = false;
        private int _countdownLeft = 0;
        private int _count = 0;
        private int _clickCount = 0;
        private long _totalDist = 0;
        private int _moveSinceClick = 0;
        private bool _exiting = false;
        private int _lastX = -1;
        private int _lastY = -1;
        private int _homeX = -1;
        private int _homeY = -1;
        private bool _firstTick = false;
        private bool _loading = false;
        private DateTime _startTime = DateTime.MinValue;
        private readonly Random _rng = new Random();
        private string _statusHint = "";
        private string _infoBase = "";

        // ---- 全局热键 ----
        private const int HotkeyId = 1;
        private const int WM_HOTKEY = 0x0312;

        private static readonly uint[] ModValues = { 0x6, 0x3, 0x5, 0x7, 0xC, 0x2 };
        private static readonly string[] KeyNames = { "M", "Space", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "A", "S", "D", "W" };

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, int vk);

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

        public MainForm()
        {
            InitializeComponent();
        }

        private bool Active { get { return _running || _counting; } }

        private void InitializeComponent()
        {
            Text = AppInfo.DisplayName;
            ClientSize = new Size(420, 692);
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox = false;
            StartPosition = FormStartPosition.CenterScreen;
            Icon = SystemIcons.Application;

            // ===== 基本设置 =====
            _gbBasic.Text = "基本设置";
            _gbBasic.Location = new Point(12, 12);
            _gbBasic.Size = new Size(396, 296);
            Controls.Add(_gbBasic);

            _lblInterval.Text = "间隔时间（秒）";
            _lblInterval.Location = new Point(14, 24);
            _lblInterval.AutoSize = true;
            _gbBasic.Controls.Add(_lblInterval);

            _numInterval.Location = new Point(150, 22);
            _numInterval.Size = new Size(90, 23);
            _numInterval.Minimum = 0.1m;
            _numInterval.Maximum = 60m;
            _numInterval.Increment = 0.1m;
            _numInterval.DecimalPlaces = 1;
            _numInterval.Value = 5m;
            _gbBasic.Controls.Add(_numInterval);

            _lblMode.Text = "移动模式";
            _lblMode.Location = new Point(14, 58);
            _lblMode.AutoSize = true;
            _gbBasic.Controls.Add(_lblMode);

            _rbH.Text = "横向";
            _rbH.Location = new Point(150, 56);
            _rbH.AutoSize = true;
            _rbH.Checked = true;
            _gbBasic.Controls.Add(_rbH);

            _rbV.Text = "纵向";
            _rbV.Location = new Point(212, 56);
            _rbV.AutoSize = true;
            _gbBasic.Controls.Add(_rbV);

            _rbC.Text = "圆圈";
            _rbC.Location = new Point(274, 56);
            _rbC.AutoSize = true;
            _gbBasic.Controls.Add(_rbC);

            _rbR.Text = "随机";
            _rbR.Location = new Point(336, 56);
            _rbR.AutoSize = true;
            _gbBasic.Controls.Add(_rbR);

            _rbH.CheckedChanged += Mode_CheckedChanged;
            _rbV.CheckedChanged += Mode_CheckedChanged;
            _rbC.CheckedChanged += Mode_CheckedChanged;
            _rbR.CheckedChanged += Mode_CheckedChanged;
            Mode_CheckedChanged(null, EventArgs.Empty);

            _lblEase.Text = "缓动曲线";
            _lblEase.Location = new Point(14, 92);
            _lblEase.AutoSize = true;
            _gbBasic.Controls.Add(_lblEase);

            _cmbEase.DropDownStyle = ComboBoxStyle.DropDownList;
            _cmbEase.Location = new Point(150, 90);
            _cmbEase.Size = new Size(120, 23);
            _cmbEase.Items.Add("线性（恒速）");
            _cmbEase.Items.Add("渐快");
            _cmbEase.Items.Add("渐慢");
            _cmbEase.Items.Add("正弦起伏");
            _cmbEase.SelectedIndex = 0;
            _gbBasic.Controls.Add(_cmbEase);

            _lblStep.Text = "步长（像素）";
            _lblStep.Location = new Point(14, 126);
            _lblStep.AutoSize = true;
            _gbBasic.Controls.Add(_lblStep);

            _numStep.Location = new Point(150, 124);
            _numStep.Size = new Size(90, 23);
            _numStep.Minimum = 1;
            _numStep.Maximum = 1000;
            _numStep.Increment = 1;
            _numStep.Value = 20;
            _gbBasic.Controls.Add(_numStep);

            _lblRadius.Text = "圆圈半径（像素）";
            _lblRadius.Location = new Point(14, 160);
            _lblRadius.AutoSize = true;
            _gbBasic.Controls.Add(_lblRadius);

            _numRadius.Location = new Point(150, 158);
            _numRadius.Size = new Size(90, 23);
            _numRadius.Minimum = 10;
            _numRadius.Maximum = 2000;
            _numRadius.Increment = 1;
            _numRadius.Value = 150;
            _gbBasic.Controls.Add(_numRadius);

            _lblJitter.Text = "随机抖动（像素）";
            _lblJitter.Location = new Point(14, 194);
            _lblJitter.AutoSize = true;
            _gbBasic.Controls.Add(_lblJitter);

            _numJitter.Location = new Point(150, 192);
            _numJitter.Size = new Size(90, 23);
            _numJitter.Minimum = 0;
            _numJitter.Maximum = 200;
            _numJitter.Increment = 1;
            _numJitter.Value = 0;
            _gbBasic.Controls.Add(_numJitter);

            _lblRand.Text = "间隔随机度（%）";
            _lblRand.Location = new Point(14, 228);
            _lblRand.AutoSize = true;
            _gbBasic.Controls.Add(_lblRand);

            _numRand.Location = new Point(150, 226);
            _numRand.Size = new Size(90, 23);
            _numRand.Minimum = 0;
            _numRand.Maximum = 100;
            _numRand.Increment = 1;
            _numRand.Value = 0;
            _gbBasic.Controls.Add(_numRand);

            _lblScreen.Text = "目标显示器";
            _lblScreen.Location = new Point(14, 262);
            _lblScreen.AutoSize = true;
            _gbBasic.Controls.Add(_lblScreen);

            _cmbScreen.DropDownStyle = ComboBoxStyle.DropDownList;
            _cmbScreen.Location = new Point(150, 260);
            _cmbScreen.Size = new Size(230, 23);
            Screen[] screens = Screen.AllScreens;
            for (int i = 0; i < screens.Length; i++)
            {
                _cmbScreen.Items.Add("显示器 " + (i + 1).ToString() + " (" + screens[i].Bounds.Width + "x" + screens[i].Bounds.Height + ")");
            }
            _cmbScreen.SelectedIndex = 0;
            _gbBasic.Controls.Add(_cmbScreen);

            // ===== 动作与系统 =====
            _gbAction.Text = "动作与系统";
            _gbAction.Location = new Point(12, 314);
            _gbAction.Size = new Size(396, 252);
            Controls.Add(_gbAction);

            _lblClick.Text = "点击方式";
            _lblClick.Location = new Point(14, 12);
            _lblClick.AutoSize = true;
            _gbAction.Controls.Add(_lblClick);

            _cmbClick.DropDownStyle = ComboBoxStyle.DropDownList;
            _cmbClick.Location = new Point(150, 10);
            _cmbClick.Size = new Size(120, 23);
            _cmbClick.Items.Add("不点击");
            _cmbClick.Items.Add("左键单击");
            _cmbClick.Items.Add("右键单击");
            _cmbClick.Items.Add("左键双击");
            _cmbClick.SelectedIndex = 0;
            _gbAction.Controls.Add(_cmbClick);

            _lblClickEvery.Text = "点击节流";
            _lblClickEvery.Location = new Point(14, 44);
            _lblClickEvery.AutoSize = true;
            _gbAction.Controls.Add(_lblClickEvery);

            _numClickEvery.Location = new Point(150, 42);
            _numClickEvery.Size = new Size(60, 23);
            _numClickEvery.Minimum = 1;
            _numClickEvery.Maximum = 100;
            _numClickEvery.Increment = 1;
            _numClickEvery.Value = 1;
            _gbAction.Controls.Add(_numClickEvery);

            _lblClickEvery2.Text = "次移动点击 1 次（1=每次都点）";
            _lblClickEvery2.Location = new Point(218, 44);
            _lblClickEvery2.AutoSize = true;
            _gbAction.Controls.Add(_lblClickEvery2);

            _chkAutoPause.Text = "检测到手动移动鼠标时自动暂停（推荐）";
            _chkAutoPause.Location = new Point(14, 74);
            _chkAutoPause.AutoSize = true;
            _chkAutoPause.Checked = true;
            _gbAction.Controls.Add(_chkAutoPause);

            _chkTray.Text = "关闭窗口时最小化到系统托盘";
            _chkTray.Location = new Point(14, 98);
            _chkTray.AutoSize = true;
            _gbAction.Controls.Add(_chkTray);

            _lblHotkey.Text = "全局热键";
            _lblHotkey.Location = new Point(14, 124);
            _lblHotkey.AutoSize = true;
            _gbAction.Controls.Add(_lblHotkey);

            _cmbMods.DropDownStyle = ComboBoxStyle.DropDownList;
            _cmbMods.Location = new Point(150, 122);
            _cmbMods.Size = new Size(110, 23);
            _cmbMods.Items.Add("Ctrl+Shift");
            _cmbMods.Items.Add("Ctrl+Alt");
            _cmbMods.Items.Add("Alt+Shift");
            _cmbMods.Items.Add("Ctrl+Shift+Alt");
            _cmbMods.Items.Add("Win+Shift");
            _cmbMods.Items.Add("Ctrl");
            _cmbMods.SelectedIndex = 0;
            _cmbMods.SelectedIndexChanged += Hotkey_Changed;
            _gbAction.Controls.Add(_cmbMods);

            _cmbKey.DropDownStyle = ComboBoxStyle.DropDownList;
            _cmbKey.Location = new Point(270, 122);
            _cmbKey.Size = new Size(110, 23);
            foreach (string k in KeyNames) _cmbKey.Items.Add(k);
            _cmbKey.SelectedIndex = 0;
            _cmbKey.SelectedIndexChanged += Hotkey_Changed;
            _gbAction.Controls.Add(_cmbKey);

            _chkAutoStart.Text = "开机自动启动（写入注册表）";
            _chkAutoStart.Location = new Point(14, 150);
            _chkAutoStart.AutoSize = true;
            _chkAutoStart.CheckedChanged += AutoStart_Changed;
            _gbAction.Controls.Add(_chkAutoStart);

            _chkReturnHome.Text = "停止后光标回到启动前的位置";
            _chkReturnHome.Location = new Point(14, 174);
            _chkReturnHome.AutoSize = true;
            _gbAction.Controls.Add(_chkReturnHome);

            _lblDelay.Text = "延迟启动";
            _lblDelay.Location = new Point(14, 202);
            _lblDelay.AutoSize = true;
            _gbAction.Controls.Add(_lblDelay);

            _numDelay.Location = new Point(150, 200);
            _numDelay.Size = new Size(60, 23);
            _numDelay.Minimum = 0;
            _numDelay.Maximum = 120;
            _numDelay.Increment = 1;
            _numDelay.Value = 0;
            _gbAction.Controls.Add(_numDelay);

            _lblDelay2.Text = "秒后开始（0=立即）";
            _lblDelay2.Location = new Point(218, 202);
            _lblDelay2.AutoSize = true;
            _gbAction.Controls.Add(_lblDelay2);

            _chkSound.Text = "开始/停止时声音提示";
            _chkSound.Location = new Point(14, 226);
            _chkSound.AutoSize = true;
            _gbAction.Controls.Add(_chkSound);

            // ===== 预设方案 =====
            _lblProfile.Text = "预设方案";
            _lblProfile.Location = new Point(14, 576);
            _lblProfile.AutoSize = true;
            Controls.Add(_lblProfile);

            _cmbProfile.Location = new Point(84, 572);
            _cmbProfile.Size = new Size(150, 23);
            _cmbProfile.DropDownStyle = ComboBoxStyle.DropDown;
            Controls.Add(_cmbProfile);

            _btnProfileSave.Text = "保存";
            _btnProfileSave.Location = new Point(244, 571);
            _btnProfileSave.Size = new Size(70, 25);
            _btnProfileSave.Click += BtnProfileSave_Click;
            Controls.Add(_btnProfileSave);

            _btnProfileLoad.Text = "加载";
            _btnProfileLoad.Location = new Point(320, 571);
            _btnProfileLoad.Size = new Size(70, 25);
            _btnProfileLoad.Click += BtnProfileLoad_Click;
            Controls.Add(_btnProfileLoad);

            // ===== 按钮 =====
            _btnStart.Text = "开始";
            _btnStart.Location = new Point(14, 606);
            _btnStart.Size = new Size(90, 30);
            _btnStart.Click += BtnStart_Click;
            Controls.Add(_btnStart);

            _btnStop.Text = "停止";
            _btnStop.Location = new Point(114, 606);
            _btnStop.Size = new Size(90, 30);
            _btnStop.Enabled = false;
            _btnStop.Click += BtnStop_Click;
            Controls.Add(_btnStop);

            _btnAbout.Text = "关于";
            _btnAbout.Location = new Point(314, 606);
            _btnAbout.Size = new Size(90, 30);
            _btnAbout.Click += BtnAbout_Click;
            Controls.Add(_btnAbout);

            // ===== 状态 =====
            _lblStatus.Location = new Point(14, 644);
            _lblStatus.AutoSize = true;
            Controls.Add(_lblStatus);

            _lblCount.Text = "已移动：0 次 · 点击：0 次";
            _lblCount.Location = new Point(14, 666);
            _lblCount.AutoSize = true;
            Controls.Add(_lblCount);

            _lblUptime.Text = "已运行：00:00:00";
            _lblUptime.Location = new Point(220, 644);
            _lblUptime.AutoSize = true;
            Controls.Add(_lblUptime);

            _lblInfo.Location = new Point(220, 666);
            _lblInfo.AutoSize = true;
            Controls.Add(_lblInfo);

            // ===== Esc 键停止（窗口聚焦时） =====
            KeyPreview = true;
            KeyDown += MainForm_KeyDown;

            // ===== 计时器 =====
            _timer.Tick += Timer_Tick;
            _numInterval.ValueChanged += NumInterval_ValueChanged;

            _uptimeTimer.Interval = 1000;
            _uptimeTimer.Tick += Uptime_Tick;

            _countdownTimer.Interval = 1000;
            _countdownTimer.Tick += Countdown_Tick;

            // ===== 托盘 =====
            _trayToggle.Click += TrayToggle_Click;
            _trayMenu.Items.Add(_trayToggle);
            _trayMenu.Items.Add("显示", null, delegate { RestoreFromTray(); });
            _trayMenu.Items.Add("退出", null, delegate { ExitApp(); });
            _notifyIcon.Icon = SystemIcons.Application;
            _notifyIcon.Text = AppInfo.DisplayName;
            _notifyIcon.ContextMenuStrip = _trayMenu;
            _notifyIcon.DoubleClick += delegate { RestoreFromTray(); };
            _notifyIcon.Visible = false;

            // ===== 载入上次设置 =====
            LoadSettings();
            _chkAutoStart.Checked = ReadAutoStart();
            UpdateInfo();
            UpdateHotkeyLabel();
            RefreshProfiles();
            _lblStatus.Text = "状态：已停止" + _statusHint;
        }

        // ---- 事件 ----
        private void NumInterval_ValueChanged(object sender, EventArgs e)
        {
            if (_running)
                _timer.Interval = (int)Math.Max(10.0, Math.Round((double)_numInterval.Value * 1000.0));
        }

        private void TrayToggle_Click(object sender, EventArgs e)
        {
            if (Active) Stop(); else Start();
        }

        private void BtnStart_Click(object sender, EventArgs e) { Start(); }
        private void BtnStop_Click(object sender, EventArgs e) { Stop(); }

        private void MainForm_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Escape && Active) { Stop(); e.Handled = true; }
        }

        private void Mode_CheckedChanged(object sender, EventArgs e)
        {
            bool circular = _rbC.Checked;
            bool linear = _rbH.Checked || _rbV.Checked;
            _lblStep.Enabled = linear;
            _numStep.Enabled = linear;
            _lblRadius.Enabled = circular;
            _numRadius.Enabled = circular;
            UpdateInfo();
        }

        private void BtnAbout_Click(object sender, EventArgs e)
        {
            MessageBox.Show(
                AppInfo.DisplayName + "\n\n自动鼠标移动工具\n支持横向 / 纵向 / 圆圈 / 随机移动，可设定 0.1s–60s 间隔并点击。\n\n新增功能（v0.3）：\n  • 多显示器选择\n  • 随机移动模式\n  • 缓动曲线（拟人速度起伏）\n  • 点击节流（每 N 次移动点 1 次）\n  • 托盘菜单直接开始/停止\n  • 停止后光标回到起点\n  • 延迟启动倒计时\n  • 预设方案保存/加载\n  • 运行统计（总距离/点击数）\n  • 开始/停止声音提示\n\n停止方式（无需鼠标）：\n  • 全局热键（默认 Ctrl+Shift+M）开始/停止切换\n  • 勾选「检测到手动移动自动暂停」后，你一动鼠标程序就立即让出光标\n\n版本常量：" + AppInfo.Version,
                "关于 " + AppInfo.AppName,
                MessageBoxButtons.OK,
                MessageBoxIcon.Information);
        }

        private void Hotkey_Changed(object sender, EventArgs e)
        {
            if (_loading) return;
            RegisterCurrentHotkey();
            UpdateHotkeyLabel();
            SaveSettings();
        }

        private void AutoStart_Changed(object sender, EventArgs e)
        {
            if (_loading) return;
            SetAutoStart(_chkAutoStart.Checked);
            SaveSettings();
        }

        private void Uptime_Tick(object sender, EventArgs e)
        {
            if (_startTime == DateTime.MinValue) return;
            TimeSpan ts = DateTime.Now - _startTime;
            int total = (int)ts.TotalSeconds;
            int hh = total / 3600; int mm = (total % 3600) / 60; int ss = total % 60;
            _lblUptime.Text = string.Format("已运行：{0:D2}:{1:D2}:{2:D2}", hh, mm, ss);
        }

        // ---- 选择辅助 ----
        private ClickType SelectedClickType()
        {
            int i = _cmbClick.SelectedIndex;
            if (i < 0) i = 0;
            return (ClickType)i;
        }

        private MovementMode SelectedMode()
        {
            if (_rbH.Checked) return MovementMode.Horizontal;
            if (_rbV.Checked) return MovementMode.Vertical;
            if (_rbC.Checked) return MovementMode.Circular;
            return MovementMode.Random;
        }

        private EaseType SelectedEase()
        {
            int i = _cmbEase.SelectedIndex;
            if (i < 0) i = 0;
            return (EaseType)i;
        }

        private Rectangle SelectedScreenBounds()
        {
            int si = _cmbScreen.SelectedIndex;
            Screen[] screens = Screen.AllScreens;
            if (si >= 0 && si < screens.Length) return screens[si].WorkingArea;
            if (Screen.PrimaryScreen != null) return Screen.PrimaryScreen.WorkingArea;
            return screens[0].WorkingArea;
        }

        // ---- 启动/停止 ----
        private void Start()
        {
            if (Active) return;
            int delay = (int)_numDelay.Value;
            if (delay > 0)
            {
                _countdownLeft = delay;
                _counting = true;
                _btnStart.Enabled = false;
                _btnStop.Enabled = true;
                _trayToggle.Text = "停止";
                _lblStatus.Text = "状态：" + _countdownLeft.ToString() + " 秒后开始（停止可取消）…";
                _countdownTimer.Start();
            }
            else
            {
                BeginRun();
            }
        }

        private void Countdown_Tick(object sender, EventArgs e)
        {
            _countdownLeft--;
            if (_countdownLeft > 0)
            {
                _lblStatus.Text = "状态：" + _countdownLeft.ToString() + " 秒后开始（停止可取消）…";
                return;
            }
            _countdownTimer.Stop();
            _counting = false;
            BeginRun();
        }

        private void BeginRun()
        {
            _engine.Bounds = SelectedScreenBounds();
            _engine.Mode = SelectedMode();
            _engine.Ease = SelectedEase();
            _engine.StepPixels = (int)_numStep.Value;
            _engine.Radius = (int)_numRadius.Value;
            _engine.JitterPixels = (int)_numJitter.Value;
            _engine.Reset();

            double seconds = (double)_numInterval.Value;
            int ms = (int)Math.Max(10, Math.Round(seconds * 1000.0));
            _timer.Interval = ms;

            _count = 0;
            _clickCount = 0;
            _totalDist = 0;
            _moveSinceClick = 0;
            _homeX = -1; _homeY = -1;
            int hx = 0, hy = 0;
            if (_mouse.GetCursorPosition(out hx, out hy))
            {
                _homeX = hx; _homeY = hy;
            }
            _lastX = -1;
            _lastY = -1;
            _firstTick = true;

            DoStep();

            _startTime = DateTime.Now;
            _uptimeTimer.Start();
            _timer.Start();
            _running = true;

            if (_chkSound.Checked) { try { Console.Beep(880, 120); } catch { } }
            _lblStatus.Text = "状态：运行中（热键停止 / 动鼠标自动暂停）";
            _btnStart.Enabled = false;
            _btnStop.Enabled = true;
            _trayToggle.Text = "停止";
            UpdateInfo();
            UpdateStats();
            SaveSettings();
        }

        private void Stop()
        {
            _countdownTimer.Stop();
            _timer.Stop();
            _uptimeTimer.Stop();
            bool wasActive = Active;
            _counting = false;
            _running = false;

            // v0.3 停止后回到启动前的位置
            if (wasActive && _chkReturnHome.Checked && _homeX >= 0)
            {
                _mouse.MoveTo(_homeX, _homeY);
            }

            if (wasActive && _chkSound.Checked) { try { Console.Beep(440, 120); } catch { } }

            _lblStatus.Text = "状态：已停止" + _statusHint;
            _lblUptime.Text = "已运行：00:00:00";
            _startTime = DateTime.MinValue;
            _btnStart.Enabled = true;
            _btnStop.Enabled = false;
            _trayToggle.Text = "开始";
            UpdateInfo();
        }

        private void DoStep()
        {
            ClickType ct = SelectedClickType();
            int every = (int)_numClickEvery.Value;
            if (every < 1) every = 1;

            // 移动前光标位置（算距离用）
            int ox = -1, oy = -1;
            int px = 0, py = 0;
            if (_mouse.GetCursorPosition(out px, out py)) { ox = px; oy = py; }

            // 实时读取设置：运行中改步长/半径/抖动/缓动立即生效
            _engine.StepPixels = (int)_numStep.Value;
            _engine.Radius = (int)_numRadius.Value;
            _engine.JitterPixels = (int)_numJitter.Value;
            _engine.Ease = SelectedEase();
            _engine.Mode = SelectedMode();
            _engine.Tick(ClickType.None);

            // v0.3 点击节流：每 every 次移动点击 1 次
            bool doClick = (ct != ClickType.None) && (_moveSinceClick % every == 0);
            if (doClick) { _mouse.Click(ct); _clickCount++; }
            _moveSinceClick++;
            _count++;

            int nx = 0, ny = 0;
            if (_mouse.GetCursorPosition(out nx, out ny))
            {
                if (ox >= 0) _totalDist += Math.Abs(nx - ox) + Math.Abs(ny - oy);
                _lastX = nx;
                _lastY = ny;
            }
        }

        private void Timer_Tick(object sender, EventArgs e)
        {
            if (_firstTick)
            {
                _firstTick = false;
            }
            else
            {
                int cx = 0, cy = 0;
                if (_chkAutoPause.Checked && _lastX >= 0 &&
                    _mouse.GetCursorPosition(out cx, out cy) &&
                    (Math.Abs(cx - _lastX) > 3 || Math.Abs(cy - _lastY) > 3))
                {
                    PauseByUser();
                    return;
                }
            }

            DoStep();
            UpdateStats();

            // 间隔随机度：每 tick 重算下一次间隔，节奏更像真人
            int baseMs = (int)Math.Max(10.0, Math.Round((double)_numInterval.Value * 1000.0));
            int rp = (int)_numRand.Value;
            if (rp > 0)
            {
                int delta = _rng.Next(-rp, rp + 1);
                double factor = 1.0 + (double)delta / 100.0;
                _timer.Interval = (int)Math.Max(10.0, Math.Round(baseMs * factor));
            }
            else
            {
                _timer.Interval = baseMs;
            }
        }

        private void PauseByUser()
        {
            Stop();
            _lblStatus.Text = "状态：已暂停（检测到手动操作，点开始继续）";
            _trayToggle.Text = "开始";
        }

        private void UpdateStats()
        {
            _lblCount.Text = "已移动：" + _count.ToString() + " 次 · 点击：" + _clickCount.ToString() + " 次";
            _lblInfo.Text = _infoBase + "　总距离：" + _totalDist.ToString() + "px";
        }

        private void UpdateInfo()
        {
            string mode;
            MovementMode m = SelectedMode();
            if (m == MovementMode.Horizontal) mode = "横向";
            else if (m == MovementMode.Vertical) mode = "纵向";
            else if (m == MovementMode.Circular) mode = "圆圈";
            else mode = "随机";
            string extra = _rbC.Checked
                ? ("半径 " + _numRadius.Value.ToString() + "px")
                : ("步长 " + _numStep.Value.ToString() + "px");
            _infoBase = "模式：" + mode + "　间隔：" + _numInterval.Value.ToString() + "s　" + extra;
            _lblInfo.Text = _infoBase;
        }

        private void UpdateHotkeyLabel()
        {
            int mi = _cmbMods.SelectedIndex; if (mi < 0) mi = 0;
            int ki = _cmbKey.SelectedIndex; if (ki < 0) ki = 0;
            _statusHint = "（" + _cmbMods.Items[mi].ToString() + "+" + _cmbKey.Items[ki].ToString() + " 开关）";
        }

        // ---- 热键 ----
        private void RegisterCurrentHotkey()
        {
            if (!IsHandleCreated) return;
            try { UnregisterHotKey(Handle, HotkeyId); } catch { }
            int mi = _cmbMods.SelectedIndex; if (mi < 0) mi = 0;
            int ki = _cmbKey.SelectedIndex; if (ki < 0) ki = 0;
            uint mods = ModValues[mi];
            int vk = (int)Enum.Parse(typeof(Keys), KeyNames[ki]);
            RegisterHotKey(Handle, HotkeyId, mods, vk);
        }

        // ---- 预设方案（v0.3）----
        private string ProfilesDir
        {
            get
            {
                string dir = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                return System.IO.Path.Combine(dir, "AutoMouseMover", "profiles");
            }
        }

        private void RefreshProfiles()
        {
            string cur = _cmbProfile.Text;
            _cmbProfile.Items.Clear();
            try
            {
                if (System.IO.Directory.Exists(ProfilesDir))
                {
                    string[] files = System.IO.Directory.GetFiles(ProfilesDir, "*.ini");
                    foreach (string f in files)
                        _cmbProfile.Items.Add(System.IO.Path.GetFileNameWithoutExtension(f));
                }
            }
            catch { }
            if (_cmbProfile.Items.Contains(cur)) _cmbProfile.Text = cur;
        }

        private string SanitizeProfileName(string raw)
        {
            string name = raw.Trim();
            if (name.Length == 0) return "";
            foreach (char c in System.IO.Path.GetInvalidFileNameChars())
                name = name.Replace(c, '_');
            return name;
        }

        private void BtnProfileSave_Click(object sender, EventArgs e)
        {
            string name = SanitizeProfileName(_cmbProfile.Text);
            if (name.Length == 0)
            {
                MessageBox.Show("请先在上方的框中输入方案名称，再点保存。", "预设方案",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }
            try
            {
                string dir = ProfilesDir;
                if (!System.IO.Directory.Exists(dir)) System.IO.Directory.CreateDirectory(dir);
                System.IO.File.WriteAllLines(System.IO.Path.Combine(dir, name + ".ini"), CollectSettings().ToArray());
                RefreshProfiles();
                _cmbProfile.Text = name;
                MessageBox.Show("方案已保存：" + name, "预设方案",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show("保存失败：" + ex.Message, "预设方案",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BtnProfileLoad_Click(object sender, EventArgs e)
        {
            string name = SanitizeProfileName(_cmbProfile.Text);
            string path = System.IO.Path.Combine(ProfilesDir, name + ".ini");
            if (name.Length == 0 || !System.IO.File.Exists(path))
            {
                MessageBox.Show("请先选择（或输入）一个已保存的方案名，再点加载。", "预设方案",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }
            _loading = true;
            try { ApplySettingsFile(path); }
            finally { _loading = false; }
            UpdateInfo();
            UpdateHotkeyLabel();
            Mode_CheckedChanged(null, EventArgs.Empty);
            SaveSettings();
        }

        // ---- 托盘 ----
        private void RestoreFromTray()
        {
            _notifyIcon.Visible = false;
            Show();
            WindowState = FormWindowState.Normal;
            Activate();
        }

        private void ExitApp()
        {
            _exiting = true;
            _notifyIcon.Visible = false;
            Close();
        }

        protected override void OnResize(EventArgs e)
        {
            base.OnResize(e);
            if (_chkTray.Checked && WindowState == FormWindowState.Minimized)
            {
                _notifyIcon.Visible = true;
                Hide();
            }
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            SaveSettings();
            if (!_exiting && _chkTray.Checked)
            {
                e.Cancel = true;
                _notifyIcon.Visible = true;
                Hide();
                return;
            }
            _countdownTimer.Stop();
            _timer.Stop();
            _uptimeTimer.Stop();
            _notifyIcon.Visible = false;
            base.OnFormClosing(e);
        }

        protected override void OnHandleCreated(EventArgs e)
        {
            base.OnHandleCreated(e);
            RegisterCurrentHotkey();
        }

        protected override void WndProc(ref Message m)
        {
            if (m.Msg == WM_HOTKEY && m.WParam.ToInt32() == HotkeyId)
            {
                if (Active) Stop(); else Start();
            }
            base.WndProc(ref m);
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                try { UnregisterHotKey(Handle, HotkeyId); } catch { }
                _countdownTimer.Dispose();
                _timer.Dispose();
                _uptimeTimer.Dispose();
                _notifyIcon.Dispose();
                _trayMenu.Dispose();
            }
            base.Dispose(disposing);
        }

        // ---- 配置持久化（Key=Value）----
        private string SettingsPath
        {
            get
            {
                string dir = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                return System.IO.Path.Combine(dir, "AutoMouseMover", "settings.ini");
            }
        }

        private System.Collections.Generic.List<string> CollectSettings()
        {
            System.Collections.Generic.List<string> lines = new System.Collections.Generic.List<string>();
            lines.Add("interval=" + _numInterval.Value.ToString());
            lines.Add("mode=" + SelectedMode().ToString().ToLower());
            lines.Add("ease=" + Math.Max(0, _cmbEase.SelectedIndex).ToString());
            lines.Add("step=" + ((int)_numStep.Value).ToString());
            lines.Add("radius=" + ((int)_numRadius.Value).ToString());
            lines.Add("jitter=" + ((int)_numJitter.Value).ToString());
            lines.Add("randPct=" + ((int)_numRand.Value).ToString());
            lines.Add("screen=" + Math.Max(0, _cmbScreen.SelectedIndex).ToString());
            lines.Add("clickType=" + _cmbClick.SelectedIndex.ToString());
            lines.Add("clickEvery=" + ((int)_numClickEvery.Value).ToString());
            lines.Add("autoPause=" + (_chkAutoPause.Checked ? "1" : "0"));
            lines.Add("tray=" + (_chkTray.Checked ? "1" : "0"));
            lines.Add("hotkeyMod=" + _cmbMods.SelectedIndex.ToString());
            lines.Add("hotkeyKey=" + _cmbKey.SelectedIndex.ToString());
            lines.Add("autoStart=" + (_chkAutoStart.Checked ? "1" : "0"));
            lines.Add("returnHome=" + (_chkReturnHome.Checked ? "1" : "0"));
            lines.Add("delay=" + ((int)_numDelay.Value).ToString());
            lines.Add("sound=" + (_chkSound.Checked ? "1" : "0"));
            return lines;
        }

        private void SaveSettings()
        {
            try
            {
                string dir = System.IO.Path.GetDirectoryName(SettingsPath);
                if (!System.IO.Directory.Exists(dir)) System.IO.Directory.CreateDirectory(dir);
                System.IO.File.WriteAllLines(SettingsPath, CollectSettings().ToArray());
            }
            catch { }
        }

        private void LoadSettings()
        {
            _loading = true;
            try
            {
                if (System.IO.File.Exists(SettingsPath)) ApplySettingsFile(SettingsPath);
            }
            finally { _loading = false; }
        }

        private void ApplySettingsFile(string path)
        {
            try
            {
                var dict = new System.Collections.Generic.Dictionary<string, string>();
                string[] lines = System.IO.File.ReadAllLines(path);
                foreach (string ln in lines)
                {
                    int eq = ln.IndexOf('=');
                    if (eq > 0) dict[ln.Substring(0, eq)] = ln.Substring(eq + 1);
                }
                // 间隔是十进制（如 5.5、0.1），必须按 decimal 解析，并钳制到控件的真实范围 [0.1, 60]
                decimal iv;
                string ivRaw;
                if (dict.TryGetValue("interval", out ivRaw) &&
                    (decimal.TryParse(ivRaw, System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out iv)
                     || decimal.TryParse(ivRaw, out iv)))
                {
                    if (iv < _numInterval.Minimum) iv = _numInterval.Minimum;
                    if (iv > _numInterval.Maximum) iv = _numInterval.Maximum;
                    _numInterval.Value = iv;
                }
                if (dict.ContainsKey("mode"))
                {
                    string m = dict["mode"];
                    _rbH.Checked = (m == "horizontal");
                    _rbV.Checked = (m == "vertical");
                    _rbC.Checked = (m == "circular");
                    _rbR.Checked = (m == "random");
                }
                SetNum(_numStep, GetInt(dict, "step"), 1, 1000);
                SetNum(_numRadius, GetInt(dict, "radius"), 10, 2000);
                SetNum(_numJitter, GetInt(dict, "jitter"), 0, 200);
                SetNum(_numRand, GetInt(dict, "randPct"), 0, 100);
                SetNum(_numClickEvery, GetInt(dict, "clickEvery", 1), 1, 100);
                SetNum(_numDelay, GetInt(dict, "delay"), 0, 120);
                SetCombo(_cmbEase, GetInt(dict, "ease"), 0, 3);
                SetCombo(_cmbClick, GetInt(dict, "clickType"), 0, 3);
                int sc = GetInt(dict, "screen");
                if (sc >= 0 && sc < _cmbScreen.Items.Count) _cmbScreen.SelectedIndex = sc;
                _chkAutoPause.Checked = GetInt(dict, "autoPause", 1) == 1;
                _chkTray.Checked = GetInt(dict, "tray", 0) == 1;
                _chkReturnHome.Checked = GetInt(dict, "returnHome", 0) == 1;
                _chkSound.Checked = GetInt(dict, "sound", 0) == 1;
                SetCombo(_cmbMods, GetInt(dict, "hotkeyMod"), 0, ModValues.Length - 1);
                SetCombo(_cmbKey, GetInt(dict, "hotkeyKey"), 0, KeyNames.Length - 1);
            }
            catch { }
        }

        private static int GetInt(System.Collections.Generic.Dictionary<string, string> d, string key)
        {
            return GetInt(d, key, 0);
        }

        private static int GetInt(System.Collections.Generic.Dictionary<string, string> d, string key, int def)
        {
            if (d.ContainsKey(key))
            {
                int v;
                if (int.TryParse(d[key], out v)) return v;
            }
            return def;
        }

        private static void SetNum(NumericUpDown n, int v, int min, int max)
        {
            if (v < min) v = min;
            if (v > max) v = max;
            n.Value = v;
        }

        private static void SetCombo(ComboBox c, int v, int min, int max)
        {
            if (v < min) v = min;
            if (v > max) v = max;
            if (c.Items.Count > 0) c.SelectedIndex = v;
        }

        // ---- 开机自启动（注册表 Run 键）----
        private void SetAutoStart(bool on)
        {
            try
            {
                Microsoft.Win32.RegistryKey key = Microsoft.Win32.Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", true);
                if (key != null)
                {
                    if (on) key.SetValue("AutoMouseMover", Application.ExecutablePath);
                    else key.DeleteValue("AutoMouseMover", false);
                    key.Close();
                }
            }
            catch { }
        }

        private bool ReadAutoStart()
        {
            try
            {
                Microsoft.Win32.RegistryKey key = Microsoft.Win32.Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", false);
                if (key != null)
                {
                    object v = key.GetValue("AutoMouseMover");
                    key.Close();
                    return v != null;
                }
            }
            catch { }
            return false;
        }
    }
}
