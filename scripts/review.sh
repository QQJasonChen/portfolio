#!/usr/bin/env bash
# 🔍 審查閘門：從共享狀態自動生出 prompt，叫第二個 agent 審。
#
#   ./scripts/review.sh          背景跑，跑完通知
#   ./scripts/review.sh --now    前景跑，直接看結果
#   ./scripts/review.sh --status 看目前的待辦發現
#
# ── 設計依據（2026-08-05 直接問 Codex 得到的規格）──
#
# 它指出六個「手動環節」裡真正要緊的只有兩個：**沒有可靠觸發** 和 **沒有共享狀態**。
# 另外三個它認為是特性不是缺陷：
#   「Read-only access and one-way invocation are healthy constraints for an
#     independent reviewer.」
# 讓審查者能寫，它就開始驗證自己的修改——獨立性就沒了。
#
# 它給的規格：每一輪都要有同一份 review contract——
#   目標、範圍、驗收標準、**前次發現與各自的處置**、當前 commit SHA、
#   自上次審查以來的 diff、需要的證據。
# 而且審查者應該「盯新引入的風險，並挑戰那些被宣稱已修好的項目」，
# 而不是每輪重跑一次通用稽核。
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"
CODEX="${CODEX_BIN:-/Applications/ChatGPT.app/Contents/Resources/codex}"
DIR=".review"; STATE="$DIR/state.json"; LEDGER="$DIR/findings.md"
mkdir -p "$DIR"
[ -x "$CODEX" ] || { echo "❌ 找不到 Codex：$CODEX"; exit 1; }

# ── 共享狀態：這是「兩個 agent 看不到對方在幹嘛」的解法 ──
[ -f "$STATE" ] || cat > "$STATE" <<'JSON'
{
  "objective": "A portfolio that makes an AI Project Lead hiring manager want to meet QQ.",
  "audience": "Hiring manager for an AI Project Lead role in Customer Support at a semiconductor equipment company.",
  "acceptance": [
    "Every factual claim is supported by evidence the reader could check",
    "A reader who never clicks into a detail page still understands each product",
    "Nothing implies capability or scale beyond what actually exists",
    "No side-project revenue figures appear anywhere"
  ],
  "lastReviewedSha": "",
  "round": 0
}
JSON

SHA=$(git rev-parse --short HEAD)
LAST=$(python3 -c "import json;print(json.load(open('$STATE')).get('lastReviewedSha',''))")
ROUND=$(python3 -c "import json;print(json.load(open('$STATE')).get('round',0)+1)")

if [ "${1:-}" = "--status" ]; then
  echo "第 $((ROUND-1)) 輪已完成 · HEAD $SHA · 上次審 ${LAST:-（無）}"
  [ -f "$LEDGER" ] && cat "$LEDGER" || echo "（還沒有發現紀錄）"
  exit 0
fi

# 自上次審查以來的改動——審查者該盯的是「新引入的風險」
DIFF=$([ -n "$LAST" ] && git diff --stat "$LAST..HEAD" 2>/dev/null | tail -20 || echo "（首次審查，無基準）")
PRIOR=$([ -f "$LEDGER" ] && cat "$LEDGER" || echo "（首輪，無前次發現）")

PROMPT=$(cat <<EOF
IMPORTANT: Do NOT read files under ~/.claude/, ~/.codex/, or any skills directory.
Read only products.json and casestudy.html in this repository. Nothing else.

You are reviewing round $ROUND of an ongoing collaboration. You have reviewed
this before. This is not a fresh audit — focus on what changed and on whether
the things previously called fixed actually hold.

## Objective
$(python3 -c "import json;print(json.load(open('$STATE'))['objective'])")

## Reader
$(python3 -c "import json;print(json.load(open('$STATE'))['audience'])")

## Acceptance criteria
$(python3 -c "import json;[print('- '+a) for a in json.load(open('$STATE'))['acceptance']]")

## Current revision
$SHA$([ -n "$LAST" ] && echo " (previously reviewed at $LAST)")

## Changed since your last review
$DIFF

## Your previous findings and what was done about them
$PRIOR

## Answer only these

1. Of your previous findings, which are genuinely resolved and which were
   papered over? Name any you now consider still open.
2. What NEW problem did these changes introduce?
3. Single weakest claim on the page right now. Quote it exactly.
4. Is this ready to send to the hiring manager? Yes or no, one reason.
5. Drift check: is this still solving the actual user need, or has it
   started optimising to pass your reviews? Say so plainly if the latter.

Be harsh. Do not edit files. Do not list strengths.
EOF
)

run() {
  local out="$DIR/round-$ROUND-$SHA.md"
  {
    echo "# 審查第 $ROUND 輪 · $SHA · $(date '+%Y-%m-%d %H:%M')"
    echo
    "$CODEX" exec --sandbox read-only "$PROMPT" 2>&1 | python3 "$REPO/scripts/extract-answer.py"
  } > "$out"

  # 發現紀錄：下一輪會把這份餵回去，讓它挑戰自己上次的判斷
  { echo "### 第 $ROUND 輪（${SHA}）"; echo; cat "$out" | sed -n '3,40p'; echo; } >> "$LEDGER"
  python3 - "$STATE" "$SHA" "$ROUND" <<'PY'
import json,sys
p,sha,r=sys.argv[1:4]
d=json.load(open(p)); d['lastReviewedSha']=sha; d['round']=int(r)
json.dump(d,open(p,'w'),ensure_ascii=False,indent=2)
PY
  ln -sf "$(basename "$out")" "$DIR/latest.md"
  local v; v=$(grep -oiE '^4\..*' "$out" | head -1 | cut -c1-100)
  osascript -e "display notification \"${v:-第 $ROUND 輪完成}\" with title \"作品集審查 · $SHA\"" 2>/dev/null || true
  afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &
}

if [ "${1:-}" = "--now" ]; then
  echo "🔍 第 $ROUND 輪審查中（3–8 分鐘）…"; run; echo; cat "$DIR/latest.md"
else
  echo "🔍 第 $ROUND 輪已送審（背景，跑完通知）· HEAD $SHA"
  ( run >/dev/null 2>&1 & ) &
fi

# 中英混寫腳本的兩個陷阱：
#  ① $VAR 後面接全形標點 → bash 把標點當變數名的一部分（用 ${VAR}）
#  ② $( ) 內的 heredoc 出現英文撇號（user's）→ 被當成引號配對，整段語法炸掉
