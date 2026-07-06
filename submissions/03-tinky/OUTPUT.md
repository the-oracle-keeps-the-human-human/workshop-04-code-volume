# OUTPUT — `/code-volume` รันจริงกับ `Soul-Brews-Studio/maw-js`

> รันจริง ไม่ mock · `2026-06-21` · เครื่อง `[ubuntu-dev-one:tinky]` · maw-js @ alpha (3,011 commits, no-merges, --all)
> คำสั่ง: `./volume.sh Soul-Brews-Studio/maw-js`

---

## TOTAL

```
TOTAL: +585,281 / -281,361  =  net 303,920 lines   |   churn 866,642 lines
scope: --all · no-merges · 3,011 commits · 20 identities (by email)
```

**เขียนไป 866,642 บรรทัด แต่โค้ดโตจริงแค่ 303,920** — แปลว่า **65% ของแรงเขียนคือ churn** (rewrite/ลบ).
นี่คือหัวใจของ WS04: ปริมาณที่พิมพ์ ≠ ปริมาณที่โต.

## AUTHORS (เรียงตาม net · normalize ด้วย email)

| author (email) | commits | ++added | −deleted | net | churn | net% |
|---|--:|--:|--:|--:|--:|--:|
| Nat (nat.wrw@…)        | 2341 | +482,073 | −257,377 | 224,696 | 739,450 | **30%** |
| neo-oracle             | 611  | +98,509  | −23,655  | 74,854  | 122,164 | **61%** |
| Nattan (nattan@…)      | 21   | +1,729   | −111     | 1,618   | 1,840   | 87% |
| Yutthakit Tanthasatian | 8    | +1,478   | −31      | 1,447   | 1,509   | 95% |
| modtanoii / natkingsize2 / … | — | — | — | — | — | 56–100% |
| dependabot[bot]        | 11   | +42      | −44      | **−2**  | 86      | **−2%** |

→ **`Nat` = ผู้สร้างตัวจริง** (net 224k) แต่ **net% แค่ 30%** — rewrite หนักมาก (churn 739k).
→ **`neo-oracle` คุ้มสุด net% 61%** — สร้างจริงต่อแรงเขียนสูงสุดในกลุ่มคนเขียนเยอะ.
→ **`dependabot[bot]` net ติดลบ** — bump dependency = เขียนแล้วลบ ไม่โต (bot ≠ builder).

## LANGUAGES (top by churn)

| ext | ++added | −deleted | net | churn |
|---|--:|--:|--:|--:|
| `.ts`   | +467,663 | −137,837 | **329,826** | 605,500 |
| `.js`   | +48,554  | −72,958  | **−24,404** | 121,512 |
| `.tsx`  | +13,995  | −13,995  | **0**       | 27,990  |
| `.md`   | +17,005  | −4,041   | 12,964      | 21,046  |
| `.d.ts` | +9,053   | −7,611   | 1,442       | 16,664  |

→ **`.ts` คือแกนจริง** — net +330k (โค้ดที่รอด 96% ของ net ทั้ง repo).
→ **`.js` net ติดลบ −24k** — โปรเจกต์ **migrate JS → TS**: ลบ js มากกว่าเพิ่ม (เห็น migration จากตัวเลข).
→ **`.tsx` net = 0 พอดี (+13,995 / −13,995)** — UI ทดลอง สร้างเต็มแล้ว**ลบทิ้งทั้งหมด** = churn บริสุทธิ์ โตศูนย์.

## GROWTH OVER TIME (monthly net · cumulative)

```
month       net        churn     cumulative-net
2026-03   -40,406    235,112    -40,406   ▽▽▽▽▽▽▽▽   ← เขียน 235k แต่ net ติดลบ (rewrite ยุคแรก)
2026-04    67,585    276,759     27,179   █████████████
2026-05   227,654    267,098    254,833   ████████████████████████████████████████  ← เดือนทอง
2026-06    49,087     87,673    303,920   █████████
```

→ **มี.ค. = เดือน churn ล้วน** (เขียน 235k, net ติดลบ — วาง rewrite รากฐาน).
→ **พ.ค. = เดือนทอง** net +227k จาก churn 267k (**net% 85%** — สร้างจริงมากกว่ารื้อ).

## 🔬 CROSS-CHECK: git-log (email) vs stats API (login) — สิ่งที่ API ซ่อน

นี่คือจุดที่ `/code-volume` **ทำต่างจากตัวอย่าง** (ChaiKlang ใช้ API อย่างเดียว):

| metric | **stats API** (login) | **git-log** (email, tool นี้) | ส่วนต่าง |
|---|--:|--:|--:|
| total added   | 897,082 | 585,281 | API นับ merge + diff algo ต่าง |
| total deleted | 539,435 | 281,361 | — |
| #1            | `nazt` +502k | `Nat` +482k | ใกล้กัน |
| **#2**        | **`claude` +269k** | **(หายไป — ถูกรวมเป็น Nat)** | ⚠️ |

**2 ความจริงที่ตัวเลขเปิดออก:**

1. **`claude` = contributor อันดับ 2 ของ maw-js (+268,915 บรรทัด ≈ 30% ของแรงเขียน)** — นี่คือ **AI co-author**.
   API นับ AI เป็น "คน" คนหนึ่ง แต่ git-log (วัดจาก author email) folds มันรวมกับ human. → **คำตอบ "ใครเขียนเยอะสุด" เปลี่ยน ขึ้นกับว่านับ AI เป็นคนไหม.** maw-js ≈ 1/3 เขียนโดย AI.
2. **Identity fragmentation** — `Nat` + `Nat White` ใช้ email เดียว (`nat.wrw@…`), `Nattan` + `natman95` email เดียว (`nattan@…`). git log ดิบเห็นเป็นคนละคน → tool นี้ **รวมด้วย email** ให้ตัวเลขถูก (ที่ API ทำให้เงียบ ๆ ด้วย login).

## RERUN / PARAMETERIZE (พิสูจน์รันซ้ำได้)

`./volume.sh Soul-Brews-Studio/maw-js --since 2026-05-01`:

```
range: 2026-05-01..now · 1,603 commits
TOTAL: +315,582 / -39,025  =  net 276,557 | churn 354,607
Nat: net% 77%   (vs 30% lifetime)
```

→ **insight #จาก rerun**: ตัด churn ยุคแรกออก `Nat` net% พุ่งจาก 30% → **77%** — ช่วงหลังเขียน "โตจริง" มากกว่ารื้อเยอะ. โปรเจกต์เข้าสู่ยุค **build > refactor**.

---

## สรุป insight (≥3 ✅)

1. **65% ของแรงเขียน maw-js คือ churn** — โตจริงแค่ 304k จาก 867k ที่เขียน.
2. **`.js` net ติดลบ −24k** = หลักฐาน migration JS→TS เห็นได้จากตัวเลข; **`.tsx` net=0** = UI ทดลองที่ลบทิ้งหมด.
3. **AI (`claude`) = #2 contributor (~30% แรงเขียน)** ที่ API นับเป็น "คน" แต่ git-log ซ่อน — `/code-volume` cross-check เปิดออก.
4. **เดือนทอง พ.ค. net% 85%** vs **มี.ค. net ติดลบ** — เห็น rhythm "รื้อรากฐาน → สร้างจริง".
5. **dependabot net ติดลบ** = bot ≠ builder.

*— Tinky 🌟 `[ubuntu-dev-one:tinky]` · 🤖 รายงานนี้ AI เขียน (Oracle Rule 6)*
