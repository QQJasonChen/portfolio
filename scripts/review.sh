#!/usr/bin/env bash
# 🔍 叫第二個 agent 審這個作品集，站在用人主管的角度。
#
#   ./scripts/review.sh            正常跑（背景，跑完通知）
#   ./scripts/review.sh --now      前景跑，直接看結果
#
# 設計取捨：
# - **不擋推送**。擋 5 分鐘的 hook，你三天內就會關掉它。所以背景跑、跑完通知。
# - **只在內容真的變動時跑**。改 CSS 或修錯字不值得燒一次 API。
# - 每次結果都留檔，可以回頭比對前後兩輪講的是不是同一件事。
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"
CODEX="${CODEX_BIN:-/Applications/ChatGPT.app/Contents/Resources/codex}"
OUT_DIR=".review"
STAMP="$(date +%Y%m%d-%H%M)"
OUT="$OUT_DIR/review-$STAMP.md"
mkdir -p "$OUT_DIR"

[ -x "$CODEX" ] || { echo "❌ 找不到 Codex：$CODEX"; exit 1; }

PROMPT=$(cat <<'EOF'
You are a hiring manager for an "AI Project Lead" role in Customer Support at a
large semiconductor equipment company. An internal employee has sent you this
portfolio. Read products.json and casestudy.html.

The role wants: identifying AI opportunities in Customer Support, leading
initiatives from idea to deployment, stakeholder management without direct
authority, pilots and rollout and adoption, and measuring business value. The JD
says business outcomes matter more than technical implementation.

He does not claim to be a software engineer — he uses AI-assisted development
and owns vision, roadmap and release.

Answer only these four:

1. Would you take the coffee meeting? Yes or no, and the single reason.
2. Which claim is weakest or least credible? Quote it exactly.
3. What is the strongest thing here that a reader might miss?
4. Name one thing that would most improve it. Be concrete.

Be harsh. Do not list strengths except in answer 3. Do not edit any files.
EOF
)

run() {
  {
    echo "# 作品集審查 · $STAMP"
    echo
    echo "> 由 Codex 以用人主管視角審查。手動重跑：\`./scripts/review.sh --now\`"
    echo
    "$CODEX" exec --sandbox read-only "$PROMPT" 2>&1 |
      sed $'s/\x1b\\[[0-9;]*m//g' |
      awk '/^1\./{f=1} f' |
      sed '/tokens used/,$d'
  } > "$OUT"

  ln -sf "$(basename "$OUT")" "$OUT_DIR/latest.md"

  local verdict
  verdict=$(grep -oiE '^1\..*' "$OUT" | head -1 | cut -c1-110)
  osascript -e "display notification \"${verdict:-審查完成}\" with title \"作品集審查完成\"" 2>/dev/null || true
  afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &
}

if [ "${1:-}" = "--now" ]; then
  echo "🔍 審查中（3–8 分鐘）…"
  run
  echo
  cat "$OUT"
else
  echo "🔍 已在背景送審，跑完會通知。結果：$OUT"
  ( run >/dev/null 2>&1 & ) &
fi
