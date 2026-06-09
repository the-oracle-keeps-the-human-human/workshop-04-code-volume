# Workshop 04 — Code Volume 🏗️

> 2026-06-09 | Oracle School | ต่อจาก WS03 — digest บอก "เกิดอะไรขึ้น" → **WS04 วัดว่าเราเขียนโค้ดไปเยอะน้อยแค่ไหนจริง ๆ**

---

## 🎯 เป้าหมาย

สร้าง **skill** ที่วัดปริมาณโค้ดใน repo — ใครเขียนเท่าไร, โตจริงแค่ไหน, churn (เขียนแล้วลบ) เท่าไร
WS03 ตอบ *"เกิดอะไรขึ้น"* (commit/PR/issue timeline) → WS04 ตอบ *"เขียนไปเยอะแค่ไหน"* (ปริมาณจริง)

## 📌 โจทย์

วัด code volume ของ → https://github.com/Soul-Brews-Studio/maw-js

## 🏗️ ทำยังไง (4 ขั้น)

**1. Fetch** — ดึง additions/deletions ต่อคน
```bash
# วิธีเร็ว (ไม่ต้อง clone): contributor stats
gh api repos/Soul-Brews-Studio/maw-js/stats/contributors \
  --jq '.[] | select(.author != null) | {login: .author.login, commits: .total,
        added: ([.weeks[].a]|add), deleted: ([.weeks[].d]|add)}'
# หรือถ้า clone แล้ว: git log --numstat --pretty="%an"
```
> ⚠️ **GOTCHA**: endpoint นี้คืน `202` (computing) ครั้งแรก — retry 2-3 รอบ · และมี entry ที่ `author=null` (user ถูกลบ) ต้อง filter ทิ้ง

**2. Aggregate** — รวมตาม author / ภาษา (นามสกุลไฟล์) / ช่วงเวลา

**3. Measure** — total LOC, **net** (added − deleted), **churn** (added + deleted), %ต่อคน

**4. Highlight** — ใครเขียนเยอะสุด, ไฟล์/area ที่โตสุด, **net vs churn**

## 🌈 Stretch — "net ≠ churn"

เขียน 7 แสนบรรทัด ไม่ได้แปลว่าโค้ดโต 7 แสน — แยก **net growth** (โตจริง) ออกจาก **churn** (เขียนแล้วลบ/rewrite)
→ ใครคือ "ผู้สร้าง" (net สูง) ใครคือ "ผู้ขัดเกลา" (churn สูง net ต่ำ)
ต่อยอด: แยกตามภาษา · โตตามเวลา · bot vs คน

## 💡 ตัวอย่าง (ChaiKlang ทำกับ maw-js)

```
TOTAL: +873,740 / −536,749  =  net 336,991 บรรทัด  จาก 25 คน

author        commits   ++added   --deleted   net       churn
nazt          2119      +479,330  −282,593    196,737   761,923
claude        1238      +268,555  −207,319     61,236   475,874
neo-oracle     610      +116,743  − 42,337     74,406   159,080
```
→ `nazt` เขียนเยอะสุดแต่ **churn สูง** (rewrite เยอะ) · `neo-oracle` **net/churn คุ้มสุด** (สร้างจริงต่อแรงเขียน) — นี่คือพลังของการแยก net ออกจาก churn

## 📦 Deliverable

```
submissions/<your-name>/
├── SKILL.md        ← frontmatter name + description
├── volume.sh       ← รันได้จริง (parameterize repo + since)
├── OUTPUT.md       ← ผลที่รันกับ maw-js
└── book/           ← หนังสือควบคู่ (BOOK.md + BOOK.pdf + page-*.png)
```

## ✅ เกณฑ์ผ่าน

รันจริง (ไม่ mock) · แยก author ถูก · คำนวณ net + churn ได้ · ชี้ insight ≥3 จุด · rerun ได้ · **คิดต่าง ทำให้ดีกว่าตัวอย่าง**

## 🚀 วิธีส่ง

Fork → เพิ่มงานใน `submissions/<your-name>/` → เปิด PR เข้า `main`

---

## 🐈 ภาคผนวก — Session Hygiene (forward-bg → self-compact)

ก่อน session ยาวจะ compact เราอยาก **snapshot ไว้ก่อน กันเสียรายละเอียด** Claude Code สั่ง compact ตัวเองตรง ๆ ไม่ได้ — แต่ใช้ **maw** ยิง `/compact` เข้า session ตัวเองได้ ขั้นตอน:

**1. `/forward-bg`** — spawn background agent (Haiku, `run_in_background`) ขุด session JSONL เขียน handoff โดยไม่ block
```bash
ORACLE_ROOT=$(git rev-parse --show-toplevel)
LATEST_JSONL=$(ls -t "$HOME/.claude/projects/$(echo "$ORACLE_ROOT"|sed 's|^/|-|;s|[/.]|-|g')"/*.jsonl|head -1)
# → spawn Haiku agent: python3 ~/.claude/skills/forward/dig-session.py "$LATEST_JSONL"
#   แล้วเขียน handoff ไป ψ/inbox/handoff/<date>_bg-forward.md
```

**2. `maw ls -v`** — เช็คหา session ตัวเองก่อน (อย่ายิงผิดตัว!)
```bash
maw ls -v          # หา target ตัวเอง เช่น 04-chai-klang:chai-klang-oracle.0
```

**3. self-compact** — ยิง `/compact` เข้า session ตัวเอง
```bash
maw hey <your-target> "/compact"     # → delivered → <target>: /compact
```

**กฎ:** snapshot (forward-bg) ก่อนเสมอ แล้วค่อย compact — เก็บกรรมไว้ก่อนล้าง context
