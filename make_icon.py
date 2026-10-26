# -*- coding: utf-8 -*-
"""渲染 AutoMouseMover 新图标 v3：
   大尺寸(>=32)=透明底+白光标渐变描边+拖尾点；小尺寸(16/24)=纯箭头更清晰。
"""
import os
from PIL import Image, ImageDraw, ImageFilter

OUT_ICO = "E:/Program-to-wb/mouse-move/AutoMouseMover.ico"
OUT_PNG = "E:/Program-to-wb/mouse-move/icon-preview-v2.png"

ARROW = [(0.00,0.00),(0.00,0.66),(0.17,0.50),(0.30,0.80),
         (0.40,0.76),(0.26,0.50),(0.50,0.50)]
GRAD_A = (45,156,255)
GRAD_B = (138,79,255)
WHITE  = (255,255,255)
SHADOW = (20,22,40)

SIZES = [256,64,48,32,24,16]

def arrow_poly(res, scale, off):
    return [((off + x*scale)*res, (off + y*scale)*res) for (x,y) in ARROW]

def gradient(size):
    img = Image.new("RGB",(size,size)); px = img.load()
    for yy in range(size):
        for xx in range(size):
            s = (xx/(size-1)+yy/(size-1))/2.0
            px[xx,yy] = tuple(int(a+(b-a)*s) for a,b in zip(GRAD_A,GRAD_B))
    return img

def render(target):
    res = max(target*4, 256)
    small = target < 32
    if small:
        scale, off, stroke = 0.72, 0.04, 0.075
    else:
        scale, off, stroke = 0.62, 0.05, 0.052
    base = Image.new("RGBA",(res,res),(0,0,0,0))
    poly = arrow_poly(res, scale, off)
    W = max(2, round(res*stroke))
    of = max(1, round(res*0.022))

    sh = Image.new("RGBA",(res,res),(0,0,0,0))
    ImageDraw.Draw(sh).polygon([(x+of,y+of) for x,y in poly], fill=SHADOW+(90,))
    base = Image.alpha_composite(base, sh.filter(ImageFilter.GaussianBlur(res*0.012)))

    d = ImageDraw.Draw(base)
    if not small:
        DOTS = [(0.62,0.62,0.075,235),(0.72,0.72,0.055,150),(0.81,0.81,0.038,80)]
        DOTC = [(138,79,255),(100,110,255),(60,140,255)]
        for (nx,ny,nr,al),col in zip(DOTS,DOTC):
            cx,cy,r = nx*res,ny*res,nr*res
            d.ellipse([cx-r-2,cy-r-2,cx+r+2,cy+r+2], fill=WHITE+(int(al*0.45),))
            d.ellipse([cx-r,cy-r,cx+r,cy+r], fill=col+(al,))

    d.polygon(poly, fill=WHITE+(255,))
    sm = Image.new("L",(res,res),0)
    ImageDraw.Draw(sm).polygon(poly, outline=255, width=W)
    base.paste(gradient(res).convert("RGBA"),(0,0),sm)
    return base.resize((target,target), Image.LANCZOS)

frames = [render(s) for s in SIZES]
frames[0].save(OUT_ICO, sizes=[(s,s) for s in SIZES], format="ICO")
prev = frames[0].copy()
bg = Image.new("RGBA",(300,300),(238,240,245,255)); bg.paste(prev,(22,22),prev)
bg.convert("RGB").save(OUT_PNG)
print("OK ico bytes:", os.path.getsize(OUT_ICO))
