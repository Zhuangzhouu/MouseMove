# -*- coding: utf-8 -*-
"""
AutoMouseMover —— 自动鼠标移动工具（零构建单文件版）
====================================================
· 版本常量：v0.1
· 间隔可调：0.1s – 60s
· 三种移动：横向 / 纵向 / 圆圈
· 可选「每次移动后点击鼠标左键」
· 鼠标控制使用 Windows user32.dll（ctypes，标准库，无需 pip）
· UI 使用 tkinter（标准库）

使用：本机安装 Python 3.8+ 后，双击本文件（.pyw，无控制台）即可运行；
      也可以用附带的 run_python.bat 运行。
注意：本版本为纯单文件、零构建，未实现系统托盘与全局热键（与 C# 版 UI 形态略有差异）。
"""

import ctypes
import math
import tkinter as tk
from tkinter import ttk, messagebox

# ===================== 版本常量 =====================
VERSION = "v0.1"
APP_NAME = "AutoMouseMover"

# ===================== Win32 鼠标控制（ctypes） =====================
user32 = ctypes.windll.user32
user32.SetCursorPos.argtypes = [ctypes.c_int, ctypes.c_int]
user32.SetCursorPos.restype = ctypes.c_int
user32.mouse_event.argtypes = [
    ctypes.c_uint, ctypes.c_int, ctypes.c_int, ctypes.c_uint, ctypes.c_void_p
]
user32.mouse_event.restype = None
user32.GetSystemMetrics.argtypes = [ctypes.c_int]
user32.GetSystemMetrics.restype = ctypes.c_int

MOUSEEVENTF_LEFTDOWN = 0x0002
MOUSEEVENTF_LEFTUP = 0x0004


def move_to(x, y):
    """将光标移动到屏幕绝对坐标 (x, y)。"""
    user32.SetCursorPos(int(round(x)), int(round(y)))


def click():
    """在当前位置执行一次左键单击（按下 + 抬起）。"""
    user32.mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, None)
    user32.mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, None)


# ===================== 移动引擎 =====================
class Engine:
    """根据所选模式计算下一帧坐标，移动逻辑与 UI 解耦。"""

    def __init__(self):
        self.mode = "horizontal"      # horizontal / vertical / circular
        self.step = 20                # 横/纵：每步像素
        self.radius = 150             # 圆圈：半径（像素）
        self.circle_step = 6.0        # 圆圈：每步角度增量（度）
        self.margin = 10              # 边缘留白，避开屏幕外/任务栏
        self.angle = 0.0
        self.direction = 1
        self.current = None

    def _bounds(self):
        w = user32.GetSystemMetrics(0)   # SM_CXSCREEN
        h = user32.GetSystemMetrics(1)   # SM_CYSCREEN
        return w, h

    def reset(self):
        w, h = self._bounds()
        self.current = (w // 2, h // 2)
        self.angle = 0.0
        self.direction = 1

    def next(self):
        if self.current is None:
            self.reset()
        w, h = self._bounds()
        m = self.margin
        left, right = m, w - m
        top, bottom = m, h - m
        x, y = self.current

        if self.mode == "horizontal":
            nx = x + self.direction * self.step
            if nx >= right:
                nx, self.direction = right, -1
            elif nx <= left:
                nx, self.direction = left, 1
            x, y = nx, y

        elif self.mode == "vertical":
            ny = y + self.direction * self.step
            if ny >= bottom:
                ny, self.direction = bottom, -1
            elif ny <= top:
                ny, self.direction = top, 1
            x, y = x, ny

        else:  # circular
            cx, cy = w // 2, h // 2
            self.angle += math.radians(self.circle_step)
            nx = cx + int(round(self.radius * math.cos(self.angle)))
            ny = cy + int(round(self.radius * math.sin(self.angle)))
            nx = max(left, min(right, nx))
            ny = max(top, min(bottom, ny))
            x, y = nx, ny

        self.current = (x, y)
        return x, y


# ===================== 界面 =====================
class App:
    def __init__(self, root):
        self.root = root
        self.engine = Engine()
        self.running = False
        self.count = 0
        self._build_ui()

    def _build_ui(self):
        f = ttk.Frame(self.root, padding=12)
        f.grid(row=0, column=0, sticky="nsew")

        # 间隔时间
        ttk.Label(f, text="间隔时间（秒）").grid(row=0, column=0, sticky="w", pady=3)
        self.interval_var = tk.DoubleVar(value=5.0)
        self.interval_spin = ttk.Spinbox(
            f, from_=0.1, to=60.0, increment=0.1, width=10,
            textvariable=self.interval_var)
        self.interval_spin.grid(row=0, column=1, sticky="w", pady=3)

        # 移动模式
        ttk.Label(f, text="移动模式").grid(row=1, column=0, sticky="w", pady=3)
        self.mode_var = tk.StringVar(value="horizontal")
        mf = ttk.Frame(f)
        mf.grid(row=1, column=1, sticky="w", pady=3)
        for i, (txt, val) in enumerate([
            ("横向", "horizontal"), ("纵向", "vertical"), ("圆圈", "circular")]):
            ttk.Radiobutton(
                mf, text=txt, variable=self.mode_var, value=val,
                command=self._on_mode).grid(row=0, column=i, padx=6)

        # 步长
        ttk.Label(f, text="步长（像素）").grid(row=2, column=0, sticky="w", pady=3)
        self.step_var = tk.IntVar(value=20)
        self.step_spin = ttk.Spinbox(
            f, from_=1, to=1000, increment=1, width=10, textvariable=self.step_var)
        self.step_spin.grid(row=2, column=1, sticky="w", pady=3)

        # 圆圈半径
        ttk.Label(f, text="圆圈半径（像素）").grid(row=3, column=0, sticky="w", pady=3)
        self.radius_var = tk.IntVar(value=150)
        self.radius_spin = ttk.Spinbox(
            f, from_=10, to=2000, increment=1, width=10, textvariable=self.radius_var)
        self.radius_spin.grid(row=3, column=1, sticky="w", pady=3)

        # 点击
        self.click_var = tk.BooleanVar(value=False)
        ttk.Checkbutton(
            f, text="每次移动后点击鼠标左键", variable=self.click_var
        ).grid(row=4, column=0, columnspan=2, sticky="w", pady=3)

        # 按钮
        bf = ttk.Frame(f)
        bf.grid(row=5, column=0, columnspan=2, pady=8, sticky="w")
        self.start_btn = ttk.Button(bf, text="开始", command=self.start, width=10)
        self.start_btn.grid(row=0, column=0, padx=4)
        self.stop_btn = ttk.Button(
            bf, text="停止", command=self.stop, width=10, state="disabled")
        self.stop_btn.grid(row=0, column=1, padx=4)
        ttk.Button(bf, text="关于", command=self.about, width=10).grid(row=0, column=2, padx=4)

        # 状态
        self.status_var = tk.StringVar(value="状态：已停止")
        ttk.Label(f, textvariable=self.status_var).grid(
            row=6, column=0, columnspan=2, sticky="w", pady=2)
        self.count_var = tk.StringVar(value="已移动次数：0")
        ttk.Label(f, textvariable=self.count_var).grid(
            row=7, column=0, columnspan=2, sticky="w", pady=2)
        self.info_var = tk.StringVar(value="")
        ttk.Label(f, textvariable=self.info_var).grid(
            row=8, column=0, columnspan=2, sticky="w", pady=2)

        self._on_mode()
        self._update_info()

    def _on_mode(self):
        circular = self.mode_var.get() == "circular"
        self.step_spin.configure(state="disabled" if circular else "normal")
        self.radius_spin.configure(state="normal" if circular else "disabled")
        self._update_info()

    def _update_info(self):
        label = {"horizontal": "横向", "vertical": "纵向", "circular": "圆圈"}
        mode = self.mode_var.get()
        extra = (f"半径 {self.radius_var.get()}px" if mode == "circular"
                 else f"步长 {self.step_var.get()}px")
        self.info_var.set(f"模式：{label[mode]}　间隔：{self.interval_var.get()}s　{extra}")

    def _apply_once(self):
        x, y = self.engine.next()
        if self.click_var.get():
            move_to(x, y)
            click()
        else:
            move_to(x, y)
        self.count += 1
        self.count_var.set(f"已移动次数：{self.count}")

    def _schedule(self):
        if not self.running:
            return
        ms = max(10, int(round(self.interval_var.get() * 1000)))
        self.root.after(ms, self._tick)

    def _tick(self):
        if not self.running:
            return
        self._apply_once()
        self._schedule()

    def start(self):
        try:
            interval = float(self.interval_var.get())
            if not (0.1 <= interval <= 60.0):
                raise ValueError
        except Exception:
            messagebox.showerror("参数错误", "间隔时间需在 0.1 – 60 秒之间。")
            return

        self.engine.mode = self.mode_var.get()
        self.engine.step = max(1, int(self.step_var.get()))
        self.engine.radius = max(10, int(self.radius_var.get()))
        self.engine.reset()

        self.count = 0
        self._apply_once()        # 立即移动一次，避免空等一个周期
        self.running = True
        self.status_var.set("状态：运行中")
        self.start_btn.configure(state="disabled")
        self.stop_btn.configure(state="normal")
        self._update_info()
        self._schedule()

    def stop(self):
        self.running = False
        self.status_var.set("状态：已停止")
        self.start_btn.configure(state="normal")
        self.stop_btn.configure(state="disabled")

    def about(self):
        messagebox.showinfo(
            f"关于 {APP_NAME}",
            f"{APP_NAME} {VERSION}\n\n"
            "自动鼠标移动工具（零构建 Python 单文件版）\n"
            "支持横向 / 纵向 / 圆圈移动，可设定 0.1s–60s 间隔并点击。\n\n"
            f"版本常量：{VERSION}")


def main():
    # 高 DPI 适配，界面更清晰
    try:
        ctypes.windll.shcore.SetProcessDpiAwareness(2)
    except Exception:
        pass

    root = tk.Tk()
    root.title(f"{APP_NAME} {VERSION}")
    root.resizable(False, False)
    App(root)
    root.mainloop()


if __name__ == "__main__":
    main()
