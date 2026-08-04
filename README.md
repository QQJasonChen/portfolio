# AI Product Portfolio

Ten AI products shipped solo. Static site, deployed on GitHub Pages.

**Live:** https://qqjasonchen.github.io/portfolio/

---

## Structure

```
index.html      Layout and interaction — renders from products.json
products.json   Single source of truth. Add a product here only.
add-video.sh    Compress a screen recording for the web and wire it up
posters/        Cover images and galleries
videos/         Compressed walkthrough clips
```

Products are grouped automatically by `tier`:

| tier | Section | Meaning |
|---|---|---|
| `shipped` | On the App Store | Reviewed and live on the App Store |
| `live` | Live on the web | Publicly usable right now |
| `beta` | In beta | Invite-only or experimental |

The headline metrics (products, App Store count, technologies) are **computed from the
data**, never hard-coded. Hard-coded numbers drift out of truth the moment you add
something and forget to update them.

---

## Adding a walkthrough video

Every card falls back to its cover image, so videos are optional — add them one at a time.

### 1. Record

| Product type | How |
|---|---|
| iOS app | iPhone Control Centre → Screen Recording |
| Web | macOS `Cmd+Shift+5` → record selection |

Three rules that decide whether this page works:

- **10–15 seconds.** Cards autoplay silently on loop. Nobody stops to watch 60 seconds.
- **Show one thing** — the thing that product does that nothing else does. For TingZhai
  that's *say "note" out loud → the highlight appears*. Not signup, not settings.
- **Start on the action.** If nothing moves in the first two seconds, people scroll past.

### 2. Compress and wire it up

```bash
./add-video.sh <product-id> <recording> [start-sec] [duration-sec]

# e.g. take 14 seconds starting at 0:03
./add-video.sh tingzhai ~/Desktop/rec.mov 3 14
```

Compresses to a web-sized mp4 (typically 1–3 MB), pulls a poster frame, and writes the
paths back into `products.json`. Requires `ffmpeg` (`brew install ffmpeg`).

GitHub Pages caps a single file at 100 MB, and a raw 20-second iPhone recording is often
30 MB+. Ten of those unprocessed would make the page unusable.

**Product ids:** `tingzhai` `woordjes` `tango` `mailuo` `yike` `huisheng` `yicheng`
`yuqiao` `gongdu` `lph`

### 3. Preview

```bash
python3 -m http.server 8899 && open http://localhost:8899
```

---

## Keeping it honest

`products.json` carries a `_verified` date, shown in the page footer. Every status claim
was checked against a live endpoint — not from memory.

```bash
# is the site actually up?
curl -s -o /dev/null -w "%{http_code}\n" -L https://mytingzhai.com

# what version is really on the App Store?
curl -s "https://itunes.apple.com/lookup?bundleId=com.qqchen.tingzhai" \
  | python3 -m json.tool | grep '"version"'
```

Re-run these before sending the link to anyone. A portfolio that claims a dead product is
worse than one that lists fewer.
