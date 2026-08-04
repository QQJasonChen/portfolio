# AI 產品作品集

10 個一人開發的 AI 產品，每個都配一段實際操作影片。純靜態，走 GitHub Pages。

**線上位置**：`https://qqjasonchen.github.io/ai-works/`（部署後）

---

## 現在的狀態

網站本體、資料、篩選、RWD 都完成了。**還缺的只有影片**——10 個卡片目前都是「操作影片準備中」的佔位。

## 怎麼加影片

### 1. 錄

| 產品類型 | 怎麼錄 |
|---|---|
| iOS App | iPhone 控制中心 → 螢幕錄影 |
| 網頁 | macOS `Cmd+Shift+5` → 錄製選取範圍 |

**錄影原則**（決定這頁好不好看）：

- **10–15 秒就好**。卡片是自動播放的靜音迴圈，沒人會停下來看 60 秒。
- **只演一件事**，而且是那個產品最不可取代的那件事。
  例：聽摘就錄「說一聲『筆記』→ 摘錄跳出來」，不要錄註冊登入。
- **從動作開始**，不要錄開場畫面。前 2 秒沒東西動，觀眾就滑掉了。
- 手機錄直式、網頁錄橫式都可以，卡片會自己裁切成 16:10。

### 2. 壓縮並自動填進資料

```bash
./add-video.sh <產品id> <錄影檔> [起點秒] [長度秒]

# 例：從第 3 秒開始取 14 秒
./add-video.sh tingzhai ~/Desktop/rec.mov 3 14
```

腳本會做三件事：壓成 web 用的 mp4（通常 1–3MB）、抽第一幀當封面、把路徑寫回 `products.json`。

需要 `ffmpeg`（`brew install ffmpeg`）。

**產品 id**：`tingzhai` `mailuo` `yuqiao` `huisheng` `woordjes` `tango` `yike` `yicheng` `gongdu` `lph`

### 3. 預覽

```bash
python3 -m http.server 8899
open http://localhost:8899
```

---

## 部署到 GitHub Pages

```bash
gh repo create ai-works --public --source=. --push
# 然後：GitHub → Settings → Pages → Source 選 main / root
```

---

## 檔案結構

```
index.html      版面與互動（讀 products.json 算圖）
products.json   產品資料的唯一真相——加新產品只改這裡
add-video.sh    壓縮影片並自動填資料
videos/         壓好的 mp4
posters/        封面圖
```

## 加一個新產品

在 `products.json` 的 `products` 陣列加一筆，欄位照現有的抄。`video` 與 `poster` 先留空字串，之後用 `add-video.sh` 補。

首頁的統計數字（幾個產品／幾個上架／幾種技術）是**從資料算出來的**，不用手動改——寫死的數字遲早會跟現實對不上。

## 維護原則

**產品狀態要定期查證，不要憑印象寫。** `products.json` 裡的 `_verified` 記錄最後查證日期，網頁頁尾會顯示。

查證方式：

```bash
# 網站是否還活著
curl -s -o /dev/null -w "%{http_code}\n" -L https://mytingzhai.com

# App Store 上架版本（權威來源）
curl -s "https://itunes.apple.com/lookup?bundleId=com.qqchen.tingzhai" | python3 -m json.tool | grep '"version"'
```
