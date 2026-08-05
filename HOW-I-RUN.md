# How I run AI projects — 你來改寫

> 這三條是你的判斷，用你的語氣寫會比較像你。
> 直接改下面的內容，改完跟我說，我放回網站。

格式說明：
- **title** 一句話的標題，最好是可以直接引用的那種
- **body** 兩三句，講清楚情境與你做了什麼
- **evidence** 這個決定實際產出了什麼（有數字放數字）
- **proof** 連到哪個產品（現有 id：examace / tingzhai / vocab）

---

## 01

**title**
I make AI agents review each other, and I verify before I trust them

**body**
I run Claude and Codex on the same repository under one written protocol: reviewer is never the author, and only the reviewer can close a ticket. Before trusting the second agent I ran a four-stage validation on it — including a deliberate trap asking it to close its own ticket with a plausible excuse.

**evidence**
It refused, citing the rule by line number. That result told me the document-level constraint was sufficient and saved me from building an enforcement layer I had already scoped.

**proof**: tingzhai

---

## 02

**title**
I measure the thing I am afraid of, on real data

**body**
A voice trigger that fires during normal speech is worse than no voice trigger. Rather than tuning by feel, I replayed 127,000 characters of real podcast transcripts through the matcher.

**evidence**
First run: 38 false triggers. After removing single-character matches and adding a debounce, zero — on the same corpus. The same discipline re-levelled a 10,000-word JLPT deck against a 44,000-word frequency corpus.

**proof**: tingzhai, tango

---

## 03

**title**
Deciding not to build is part of the job

**body**
Keeping a voice mode alive on a locked screen was technically possible and I had the design ready. I worked through who would actually use it and what it cost in battery.

**evidence**
Two existing paths already covered both real scenarios, so I did not build it and wrote down why. The same call killed an agent-enforcement layer after testing showed it was unnecessary.

**proof**: tingzhai

---

## 幾個你可能想加的（現在沒寫進去的真實素材）

- 好讀版時間戳：第一次修錯了，測試證明比舊版更差，才發現字數比例解決不了字數本來就不成比例的問題
- 節目搜尋去重：以為是繁簡問題，實際壞在作者名，寫了六個測試其中兩個專門防「合併過頭」
- 藍牙耳機免持失效：AEC 是最佳化不是必要條件，它卻擋死了自己不該管的場景
- 決定不做鎖屏免持：兩條既有路徑已覆蓋，不值得換持續錄音的耗電
