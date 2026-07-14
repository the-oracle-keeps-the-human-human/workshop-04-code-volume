#!/usr/bin/env bash
# yeast-foam — Weizen 🍺 code-volume skill (WS04)
#
# วัดปริมาณโค้ดแบบแยก "ยีสต์" ออกจาก "ฟอง":
#   NET   = added - deleted   = ยีสต์ 🌾 โค้ดที่อยู่ถาวร หล่อเลี้ยงงานต่อไป (Loop of Giving)
#   CHURN = added + deleted   = แรงเขียนทั้งหมด (ยีสต์ + ฟองที่ยุบ)
#   EFF%  = net / churn        = "brew efficiency" ยิ่งสูง = เขียนแล้วอยู่ (สร้าง) · ยิ่งต่ำ = rewrite เยอะ (ขัดเกลา)
# เขียน 7 แสนบรรทัดไม่ได้แปลว่าโค้ดโต 7 แสน — yeast-foam แยกให้เห็น "ผู้สร้าง" vs "ผู้ขัดเกลา"
#
# Usage:  ./yeast-foam.sh <owner/repo>
# Example: ./yeast-foam.sh Soul-Brews-Studio/maw-js
set -euo pipefail
REPO="${1:?usage: yeast-foam.sh <owner/repo>}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# stats/contributors returns 202 (computing) on first hit — retry until ready
echo "🍺 yeast-foam: fetching contributor stats for $REPO ..." >&2
for i in 1 2 3 4 5 6; do
  gh api "repos/$REPO/stats/contributors" > "$TMP/contrib.json" 2>/dev/null || true
  n=$(python3 -c "import json;d=json.load(open('$TMP/contrib.json'));print(len(d) if isinstance(d,list) else 0)" 2>/dev/null || echo 0)
  [ "$n" -gt 0 ] 2>/dev/null && break
  echo "  attempt $i: GitHub computing stats (202)... retry" >&2; sleep 3
done

REPO="$REPO" TMP="$TMP" python3 - <<'PY'
import json, os
REPO=os.environ['REPO']; d=json.load(open(f"{os.environ['TMP']}/contrib.json"))
rows=[]
for c in d:
    if not c.get('author'): continue   # author=null = deleted user, filter out
    a=sum(w['a'] for w in c['weeks']); de=sum(w['d'] for w in c['weeks'])
    rows.append(dict(login=c['author']['login'], commits=c['total'],
                     added=a, deleted=de, net=a-de, churn=a+de))
rows.sort(key=lambda r:-r['net'])
TA=sum(r['added'] for r in rows); TD=sum(r['deleted'] for r in rows)
NET=TA-TD; CHURN=TA+TD
print(f"\n🍺 YEAST vs FOAM — {REPO}\n"+"="*72)
print(f"TOTAL: +{TA:,} / -{TD:,}  =  net {NET:,}  ·  churn {CHURN:,}  ·  {len(rows)} authors")
print(f"→ ยีสต์ (net) เป็นแค่ {100*NET/CHURN:.0f}% ของแรงเขียนทั้งหมด — อีก {100-100*NET/CHURN:.0f}% คือฟองที่ยุบ (rewrite/ลบ)\n")
print(f"{'author':16}{'commits':>8}{'+added':>11}{'-deleted':>11}{'net(ยีสต์)':>13}{'churn':>11}{'eff%':>6}")
print("-"*72)
for r in rows:
    if r['churn']==0: continue
    eff=round(100*r['net']/r['churn'])
    print(f"{r['login'][:15]:16}{r['commits']:>8}{r['added']:>11,}{r['deleted']:>11,}{r['net']:>13,}{r['churn']:>11,}{eff:>6}")
# builders vs refiners (among meaningful contributors)
big=[r for r in rows if r['churn']>=20000]
print("\n🌾 ผู้สร้าง (net สูงสุด):")
for r in sorted(big,key=lambda r:-r['net'])[:3]:
    print(f"   {r['login']:14} net {r['net']:>10,}  (eff {100*r['net']/r['churn']:.0f}%)")
print("🫧 ผู้ขัดเกลา (churn สูง / eff ต่ำ = rewrite เยอะ):")
for r in sorted(big,key=lambda r:(r['net']/r['churn']))[:3]:
    print(f"   {r['login']:14} churn {r['churn']:>10,}  (eff {100*r['net']/r['churn']:.0f}%)")
print("⚡ brew-efficiency สูงสุด (net/churn, churn>=20k):")
for r in sorted(big,key=lambda r:-(r['net']/r['churn']))[:3]:
    print(f"   {r['login']:14} eff {100*r['net']/r['churn']:.0f}%  (net {r['net']:,} จาก churn {r['churn']:,})")
PY
