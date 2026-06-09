# Workshop 04 — Code Volume 🏗️

> 2026-06-09 | Oracle School | ต่อจาก WS03 — digest บอก "เกิดอะไรขึ้น" → **WS04 วัดว่าเราเขียนโค้ดไปเยอะน้อยแค่ไหนจริง ๆ**

---

## 🎯 เป้าหมาย

สร้าง **skill** ที่วัดปริมาณโค้ดใน repo — ใครเขียนเท่าไร, โตจริงแค่ไหน, churn (เขียนแล้วลบ) เท่าไร

## 📌 โจทย์

วัด code volume ของ → https://github.com/Soul-Brews-Studio/maw-js

## 🏗️ ทำยังไง (4 ขั้น)

**1. Fetch** — ดึง additions/deletions ต่อคน
```bash
# วิธีเร็ว (ไม่ต้อง clone): contributor stats
gh api repos/Soul-Brews-Studio/maw-js/stats/contributors \
  --jq '.[] | {login: .author.login, commits: .total,
        added: ([.weeks[].a]|add), deleted: ([.weeks[].d]|add)}'
# หรือถ้า clone แล้ว: git log --numstat
```
> ⚠️ endpoint นี้คืน 202 (computing) ครั้งแรก — retry สัก 2-3 รอบ และระวัง entry ที่ `author=null`

**2. Aggregate** — รวมตาม author / ภาษา (นามสกุลไฟล์) / ช่วงเวลา
**3. Measure** — total LOC, **net** (added−deleted), **churn** (added+deleted), %ต่อคน
**4. Highlight** — ใครเขียนเยอะสุด, ไฟล์/area ที่โตสุด, **net vs churn** (เขียนเยอะ ≠ โตเยอะ)

## 🌈 Stretch — "net ≠ churn"

เขียน 7 แสนบรรทัด ไม่ได้แปลว่าโค้ดโต 7 แสน — แยก **net growth** (โตจริง) ออกจาก **churn** (เขียนแล้วลบ/rewrite) → ใครคือ "ผู้สร้าง" ใครคือ "ผู้ขัดเกลา"
ต่อยอด: แยกตามภาษา, โตตามเวลา, bot vs คน

## 📦 Deliverable

```
submissions/<your-name>/
├── SKILL.md        ← frontmatter name + description
├── volume.sh       ← รันได้จริง
├── OUTPUT.md       ← ผลที่รันกับ maw-js
└── book/           ← หนังสือควบคู่ (BOOK.md + BOOK.pdf + page-*.png)
```

## ✅ เกณฑ์ผ่าน

รันจริง (ไม่ mock) · แยก author ถูก · คำนวณ net + churn ได้ · ชี้ insight ≥3 จุด · rerun ได้ · **คิดต่าง ทำให้ดีกว่าตัวอย่าง**

## 🚀 วิธีส่ง

Fork → เพิ่มงานใน `submissions/<your-name>/` → เปิด PR เข้า `main`

---

💡 **ตัวอย่าง (ChaiKlang ทำกับ maw-js):** TOTAL +873,740 / −536,749 = **net 336,991 บรรทัด** จาก 25 คน
อันดับ churn: `nazt` (2119 commits, +479k/−282k, churn 762k) · `claude` (+268k/−207k) · `neo-oracle` (+116k/−42k, net efficiency สูง)
→ nazt เขียนเยอะสุดแต่ churn สูง (rewrite เยอะ), neo-oracle net/churn ดีสุด — **นี่คือ net vs churn**
