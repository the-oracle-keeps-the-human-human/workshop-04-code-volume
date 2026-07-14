# 🍺 yeast-foam — Code Volume (Weizen)

> วัดปริมาณโค้ดแบบแยก **ยีสต์** (net growth) ออกจาก **ฟอง** (churn)

**Oracle**: Weizen 🍺 · **Human**: goff · **Target**: `Soul-Brews-Studio/maw-js`

---

## มุมที่คิด (approach): ยีสต์ 🌾 vs ฟอง 🫧

WS03 ตอบ *"เกิดอะไรขึ้น"* → WS04 ตอบ *"เขียนไปเยอะแค่ไหนจริงๆ"*

```
NET   = added − deleted   → ยีสต์ 🌾 โค้ดที่ "อยู่" ถาวร หล่อเลี้ยงงานต่อไป
CHURN = added + deleted   → แรงเขียนทั้งหมด (ยีสต์ + ฟองที่ยุบ)
EFF%  = net / churn        → brew-efficiency: เขียนแล้ว "อยู่" กี่ %
```

**ทำไมสำคัญ:** เขียน 7 แสนบรรทัด ไม่ได้แปลว่าโค้ดโต 7 แสน — ส่วนใหญ่คือ rewrite/ลบ (ฟองที่ยุบ)
yeast-foam แยก **"ผู้สร้าง"** (net สูง) ออกจาก **"ผู้ขัดเกลา"** (churn สูง net ต่ำ) —
ทั้งคู่มีค่า แต่คนละบทบาท เหมือนยีสต์ที่หล่อเลี้ยงกับฟองที่ดันรสให้ลงตัว

หลักการ Weizen: **ยีสต์ที่หล่อเลี้ยงเรา ยังอยู่เพื่อหล่อเลี้ยงคนต่อไป** — net คือมรดกโค้ดที่ส่งต่อ (Loop of Giving)

## วิธีใช้

```bash
./yeast-foam.sh <owner/repo>
./yeast-foam.sh Soul-Brews-Studio/maw-js
```
ต้องมี `gh` (auth) + `python3`. ดึงผ่าน `stats/contributors` API — ไม่ต้อง clone

## 4 ขั้น (ตามโจทย์ WS04)

1. **Fetch** — `gh api repos/<repo>/stats/contributors` (retry `202 computing` + filter `author=null`)
2. **Aggregate** — รวม added/deleted ต่อคนจากทุกสัปดาห์
3. **Measure** — total, **net** (added−deleted), **churn** (added+deleted), eff% ต่อคน
4. **Highlight** — ผู้สร้าง (net สูง) · ผู้ขัดเกลา (eff ต่ำ) · brew-efficiency champ

## สิ่งที่เจอกับ maw-js (ดู `OUTPUT.md`)

- 📊 **net เป็นแค่ 25% ของ churn** — 75% ของแรงเขียนคือฟองที่ยุบ (rewrite/ลบ)
- 🌾 **nazt** = builder เบอร์ 1 (net 217k) แต่ eff 28% (rewrite เยอะ)
- ⚡ **neo-oracle** = brew-efficiency champ (**47%**) — สร้างจริงต่อแรงเขียนคุ้มสุดในกลุ่ม heavy
- 🫧 **claude** = eff 13% (churn 476k ได้ net แค่ 61k) = ฟองเยอะสุด
