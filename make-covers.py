#!/usr/bin/env python3
"""把 App Store 的直式手機截圖組成 16:10 的卡片封面。

為什麼需要這支：iTunes API 預設給的是 320x480 縮圖，直接放大會糊；
而且手機截圖是 9:19.5 直式，硬裁成 16:10 橫式等於把畫面主體切掉。
做法是抓 2000x0w 的原圖（1284x2778），排兩支手機在取自截圖的底色上。
"""
from PIL import Image, ImageDraw, ImageFilter
import glob, os, colorsys

W, H = 1600, 1000          # 16:10，2x 供 retina
OUT = "posters"


def dominant(im, box=(0, 0, 1, 0.25)):
    """取上緣的主色當背景——App Store 截圖的品牌色通常在頂部。"""
    w, h = im.size
    crop = im.crop((int(w*box[0]), int(h*box[1]), int(w*box[2]), int(h*box[3])))
    crop = crop.resize((1, 1), Image.LANCZOS)
    return crop.getpixel((0, 0))[:3]


def shade(rgb, mul):
    h, l, s = colorsys.rgb_to_hls(*[c/255 for c in rgb])
    r, g, b = colorsys.hls_to_rgb(h, max(0, min(1, l*mul)), s)
    return (int(r*255), int(g*255), int(b*255))


def rounded(im, r):
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, *im.size], radius=r, fill=255)
    out = Image.new("RGBA", im.size)
    out.paste(im, (0, 0), mask)
    return out


def compose(pid, shots):
    base = Image.open(shots[0]).convert("RGB")
    c = dominant(base)
    top, bot = shade(c, 1.05), shade(c, 0.72)

    # 垂直漸層底
    canvas = Image.new("RGB", (W, H), top)
    d = ImageDraw.Draw(canvas)
    for y in range(H):
        t = y / H
        d.line([(0, y), (W, y)],
               fill=tuple(int(top[i]*(1-t) + bot[i]*t) for i in range(3)))

    # 兩支手機並排，右邊那支往下偏一點做出層次
    ph = int(H * 0.92)
    imgs = []
    for s in shots[:2]:
        im = Image.open(s).convert("RGB")
        pw = int(im.width * ph / im.height)
        imgs.append(rounded(im.resize((pw, ph), Image.LANCZOS), 34))

    gap = 46
    total = sum(i.width for i in imgs) + gap * (len(imgs) - 1)
    x = (W - total) // 2
    for k, im in enumerate(imgs):
        y = int(H * 0.14) + (0 if k == 0 else 40)
        # 陰影讓手機浮起來，不然會糊成一片
        sh = Image.new("RGBA", (im.width + 60, im.height + 60), (0, 0, 0, 0))
        ImageDraw.Draw(sh).rounded_rectangle(
            [30, 34, im.width + 30, im.height + 30], radius=34, fill=(0, 0, 0, 96))
        sh = sh.filter(ImageFilter.GaussianBlur(18))
        canvas.paste(Image.alpha_composite(
            Image.new("RGBA", sh.size, (0, 0, 0, 0)), sh).convert("RGB"),
            (x - 30, y - 30), sh)
        canvas.paste(im, (x, y), im)
        x += im.width + gap

    out = f"{OUT}/{pid}.jpg"
    canvas.save(out, quality=88, optimize=True)
    print(f"  {pid:10} → {out}  {W}x{H}  {os.path.getsize(out)//1024}KB")


for pid in ("tingzhai", "woordjes", "tango"):
    shots = sorted(glob.glob(f"{OUT}/hi/{pid}-*.png"))
    if not shots:
        print(f"  ⚠️ {pid}: 找不到高解析截圖"); continue
    compose(pid, shots)
