#!/usr/bin/env python3
"""從 codex exec 的輸出裡抽出「最後那段真正的回答」。

為什麼需要這支：codex exec 會把 prompt、思考過程、exec 的檔案內容一起印出來。
用 `awk '/^1\./{f=1}'` 之類的簡單過濾會先命中 **prompt 裡的題號**，
把整份提問當成答案存起來（2026-08-05 實際踩到）。
做法是切出所有區塊，取最後一個「有編號回答但不含提問語」的那塊。
"""
import re, sys

t = re.sub(r'\x1b\[[0-9;]*m', '', sys.stdin.read())
t = t.split('tokens used')[0]

blocks = re.split(r'\n(?:codex|exec|thinking)\n', t)
answers = [
    b for b in blocks
    if re.search(r'^\s*1\.\s+\S', b, re.M)
    and 'Answer only these' not in b
    and 'Do NOT read files' not in b
]
out = (answers[-1] if answers else t).strip()

# 砍掉開頭殘留的指令回音
out = re.sub(r'^/bin/\w+ -\w+ .*?\n(?:\s*succeeded.*?\n)?', '', out, flags=re.S)
print(out[:6000])
