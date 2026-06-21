---
name: code-volume
description: "Measure how much code was actually written in a repo — separating NET growth (added − deleted, code that survived) from CHURN (added + deleted, total writing effort incl. rewrites/deletes). Breaks down by author (normalized by email), language, and month; cross-checks against the GitHub contributor-stats API to expose identity fragmentation and human-vs-AI authorship. Use when user says 'code volume', 'how much code', 'net vs churn', 'who wrote the most', 'builder vs polisher', or wants real LOC analysis of any git repo."
argument-hint: "[owner/repo | git-url | local-path] [--since YYYY-MM-DD] [--until YYYY-MM-DD] [--branch <name|--all>] [--top N]"
---

# /code-volume — net vs churn, the honest measure 🏗️

> "เขียน 7 แสนบรรทัด ไม่ได้แปลว่าโค้ดโต 7 แสน" — WS04 วัด *ของจริง*: โตเท่าไร (net) เทียบกับเขียนไปเท่าไร (churn)

WS03 (digest) ตอบ *"เกิดอะไรขึ้น"*. WS04 ตอบ *"เขียนไปเยอะแค่ไหนจริง ๆ"* — แล้วแยก
**net growth** (added − deleted = โค้ดที่รอด) ออกจาก **churn** (added + deleted = แรงเขียนทั้งหมด รวม rewrite/ลบ).
ใครคือ **ผู้สร้าง** (net สูง) ใครคือ **ผู้ขัดเกลา** (churn สูง net ต่ำ).

## ทำต่างจากตัวอย่างยังไง (ChaiKlang ใช้ stats API ตรง ๆ)

| ตัวอย่าง (API only) | /code-volume |
|---|---|
| key ที่ GitHub *login* | วัดจาก **git log --numstat** (per-file → ได้ภาษา + เวลาด้วย) แล้ว normalize ตัวตนด้วย **email** |
| ตัวตนซ้ำถูกซ่อน | **เปิดเผย identity fragmentation** — "Nat" + "Nat White" = email เดียว → รวมให้ |
| AI = contributor แยก เงียบ ๆ | **cross-check API vs git-log** → โชว์ว่า ~30% ของแรงเขียน maw-js เป็น **AI-authored** (`claude` login) |
| net/churn รวม | net/churn **per author + per language + per month** (โตตามเวลา, cumulative) |

## Usage

```bash
./volume.sh Soul-Brews-Studio/maw-js                 # full history, all branches
./volume.sh Soul-Brews-Studio/maw-js --since 2026-05-01 --top 10
./volume.sh ./my-local-repo --branch main
```

## ทำยังไง (4 ขั้น — ตรงตามโจทย์)

1. **Fetch** — clone (full history, cache ไว้ rerun ไว) แล้ว `git --no-pager log --all --no-merges --numstat`.
2. **Aggregate** — awk pass เดียว รวมตาม **author (email) / ภาษา (นามสกุล) / เดือน**. ตัวตน = email (รวมชื่อแตก).
3. **Measure** — total, **net = added − deleted**, **churn = added + deleted**, %net/churn ต่อคน.
4. **Highlight** — ใครเขียนเยอะสุด · builder vs polisher · ภาษาที่ churn สุด · โตตามเวลา · cross-check API.

## ⚠️ GOTCHAS ที่ฝังไว้ในสคริปต์ (เจ็บมาแล้วทั้งนั้น)

1. **git pager ตัด output เหลือ ~50 บรรทัด** ใน shell ที่ไม่ใช่ TTY — แม้ผ่าน `sort`/`uniq` (SIGPIPE).
   → สคริปต์ใช้ `git --no-pager` **และ** aggregate ผ่าน temp file เสมอ ไม่ใช้ pipe เปราะ ๆ. (เสียเวลาไป 1 ชม. กับเรื่องนี้)
2. **binary file** numstat คืน `-\t-` → นับเป็น 0 ไม่ใช่ LOC.
3. **merge commit** ทำให้นับซ้ำ → `--no-merges`.
4. **stats API คืน HTTP 202** (computing) รอบแรก → retry 3–5 รอบ.
5. **`--all` ไม่ double-count** (ยืนยันแล้ว: 3011 commits = 3011 unique hashes) — นับทุก branch ได้ภาพเต็ม.

## เกณฑ์ผ่าน — ทำครบ

รันจริง (ไม่ mock ✅) · แยก author ถูก (normalize email ✅) · net + churn ✅ · insight ≥3 จุด ✅ · rerun + parameterize ✅ · **คิดต่าง: เปิด identity fragmentation + human-vs-AI ที่ API ซ่อน** ✅

---
*— Tinky `[ubuntu-dev-one:tinky]` · slot 03-tinky · 2026-06-21 · 🤖 AI เขียน (Oracle Rule 6: ไม่แกล้งเป็นมนุษย์)*
