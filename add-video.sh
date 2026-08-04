#!/usr/bin/env bash
# 🎬 把螢幕錄影壓成適合網頁的短迴圈，並自動填進 products.json
#
#   ./add-video.sh <產品id> <錄影檔> [起點秒] [長度秒]
#   例：./add-video.sh tingzhai ~/Desktop/rec.mov 3 14
#
# 為什麼要壓：GitHub Pages 單檔上限 100MB、repo 建議 1GB 以內。
# iPhone 螢幕錄影 20 秒常常就 30MB+，10 支放上去頁面會慢到沒人想看。
# 壓完通常 1-3MB，而且卡片是自動播放的靜音迴圈，畫質夠用。
set -euo pipefail

ID="${1:?用法: ./add-video.sh <產品id> <錄影檔> [起點秒] [長度秒]}"
SRC="${2:?要給錄影檔路徑}"
START="${3:-0}"
DUR="${4:-15}"

cd "$(dirname "${BASH_SOURCE[0]}")"
[ -f "$SRC" ] || { echo "❌ 找不到檔案：${SRC}"; exit 1; }
command -v ffmpeg >/dev/null || { echo "❌ 需要 ffmpeg：brew install ffmpeg"; exit 1; }

python3 - "$ID" <<'PY' || exit 1
import json,sys
ids=[p["id"] for p in json.load(open("products.json"))["products"]]
if sys.argv[1] not in ids:
    print(f"❌ products.json 裡沒有 id「{sys.argv[1]}」。現有：{', '.join(ids)}")
    sys.exit(1)
PY

OUT="videos/${ID}.mp4"
POSTER="posters/${ID}.jpg"
mkdir -p videos posters

echo "🎬 壓縮中（從第 ${START} 秒起，取 ${DUR} 秒）…"
# -an 去掉音軌：卡片是靜音自動播放，聲音只會讓檔案變大
# 寬度上限 900：卡片實際顯示不會超過這個寬度，再大是浪費
# +faststart：moov atom 移到前面，網頁邊下載就能邊播
ffmpeg -y -loglevel error -ss "$START" -t "$DUR" -i "$SRC" \
  -vf "scale='min(900,iw)':-2:flags=lanczos,fps=24" \
  -c:v libx264 -profile:v main -pix_fmt yuv420p \
  -crf 28 -preset slow -movflags +faststart -an "$OUT"

echo "🖼  取封面（第一幀，影片還沒載入時先顯示）…"
ffmpeg -y -loglevel error -ss "$START" -i "$SRC" -frames:v 1 \
  -vf "scale='min(900,iw)':-2" -q:v 4 "$POSTER"

python3 - "$ID" "$OUT" "$POSTER" <<'PY'
import json,sys
pid,vid,pos = sys.argv[1:4]
with open("products.json") as f: d=json.load(f)
for p in d["products"]:
    if p["id"]==pid: p["video"], p["poster"] = vid, pos
with open("products.json","w") as f:
    json.dump(d,f,ensure_ascii=False,indent=2); f.write("\n")
print(f"✅ products.json 已更新：{pid} → {vid}")
PY

SIZE=$(du -h "$OUT" | cut -f1)
echo
echo "✅ 完成：${OUT}（${SIZE}）"
echo "   本機預覽： python3 -m http.server 8899 && open http://localhost:8899"
case "$SIZE" in
  *M) N=${SIZE%M}; [ "${N%%.*}" -gt 8 ] 2>/dev/null && \
       echo "   ⚠️ 超過 8MB，考慮縮短長度或把 -crf 調到 32" ;;
esac
