#!/usr/bin/env python3
"""從 App Store 高解析截圖裁出滿版 16:10 封面。

為什麼是「滿版裁切」而不是「排兩支手機」：
卡片在三欄版面下只有約 330px 寬。把整支 1284px 寬的手機塞進去，
內容會被壓到原尺寸的 9%——不是模糊，是字根本小到讀不到。
網頁產品的封面之所以看起來清楚，正是因為它們滿版。

所以這裡取截圖頂部那塊「行銷大字」，滿版填滿 16:10，
讓卡片上看到的字級跟網頁封面一致。
"""
from PIL import Image
import glob, os, re, json, subprocess

W, H = 1600, 1000
OUT = "posters"
APPS = {
    "tingzhai": "com.qqchen.tingzhai",
    "woordjes": "com.qqchen.woordjes",
    "tango":    "com.qqchen.tango",
}


def fetch(pid, bid):
    """iTunes 給的是 320x480 縮圖，要把 URL 的尺寸段換成 2000x0w 才拿得到原圖。"""
    raw = subprocess.run(
        ["curl", "-s", f"https://itunes.apple.com/lookup?bundleId={bid}&country=tw"],
        capture_output=True, text=True).stdout
    urls = json.loads(raw)["results"][0].get("screenshotUrls", [])[:5]
    os.makedirs(f"{OUT}/hi", exist_ok=True)
    got = []
    for i, u in enumerate(urls, 1):
        hi = re.sub(r"/\d+x\d+bb\.(jpg|png)$", "/2000x0w.png", u)
        p = f"{OUT}/hi/{pid}-{i}.png"
        subprocess.run(["curl", "-sL", "-o", p, hi], check=True)
        got.append(p)
    return got


def cover(pid, shot):
    im = Image.open(shot).convert("RGB")
    # 頂部 16:10 那塊就是行銷大字所在，正好也是最能一眼看懂的部分
    crop_h = int(im.width * H / W)
    im = im.crop((0, 0, im.width, min(crop_h, im.height)))
    im = im.resize((W, H), Image.LANCZOS)
    out = f"{OUT}/{pid}.jpg"
    im.save(out, quality=90, optimize=True)
    print(f"  {pid:10} → {out}  {W}x{H}  {os.path.getsize(out)//1024}KB")


for pid, bid in APPS.items():
    shots = sorted(glob.glob(f"{OUT}/hi/{pid}-*.png")) or fetch(pid, bid)
    if not shots:
        print(f"  ⚠️ {pid}: 抓不到截圖"); continue
    cover(pid, shots[0])
