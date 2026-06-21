#!/usr/bin/env bash
# volume.sh — measure CODE VOLUME of a git repo: net growth vs churn.
#
# WS04 — Code Volume · submission 03-tinky [ubuntu-dev-one:tinky]
#
# WS03 answered "what happened" (commit/PR/issue timeline).
# WS04 answers "how much was actually written" — and crucially separates
#   NET growth (added − deleted = real code that survived)
#   from CHURN  (added + deleted = total writing effort, incl. rewrites/deletes).
#
# Writing 700k lines does NOT mean the codebase grew 700k. A "builder" has high
# net; a "polisher" has high churn but low net. This tool makes that visible.
#
# WHY git log (not just the stats API):
#   The contributor-stats API keys on GitHub *login* and silently merges
#   identities. git log --numstat exposes the raw author name+email, which
#   reveals identity fragmentation (e.g. "Nat" and "Nat White" share one email
#   but the API hides it) AND gives per-file data we need for the language and
#   time-growth breakdowns. We normalize identities by EMAIL, then map to login.
#
# HARD-WON GOTCHAS baked in:
#   1. git's pager truncates piped output to ~50 lines in non-TTY shells, even
#      through `sort`/`uniq`. We ALWAYS use `git --no-pager` AND aggregate via a
#      temp file, never a fragile pipe. (Cost Tinky an hour. Never again.)
#   2. numstat reports "-\t-" for binary files — counted as 0, not as text LOC.
#
# Usage:
#   ./volume.sh <owner/repo | git-url | local-path> [--since YYYY-MM-DD]
#                                                    [--until YYYY-MM-DD]
#                                                    [--branch <name|--all>]
#                                                    [--top N] [--no-cache]
#
# Examples:
#   ./volume.sh Soul-Brews-Studio/maw-js
#   ./volume.sh Soul-Brews-Studio/maw-js --since 2026-01-01 --top 15
#   ./volume.sh ./my-local-repo --branch main
#
set -euo pipefail

# ---- defaults --------------------------------------------------------------
SINCE=""
UNTIL=""
BRANCH="--all"          # analyze every branch by default (full picture)
TOP=25                  # how many authors to show
USE_CACHE=1
CACHE_DIR="${VOLUME_CACHE_DIR:-${TMPDIR:-/tmp}/volume-cache}"

# ---- arg parse -------------------------------------------------------------
TARGET="${1:-}"
if [[ -z "$TARGET" || "$TARGET" == "-h" || "$TARGET" == "--help" ]]; then
  sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --since)    SINCE="$2"; shift 2 ;;
    --until)    UNTIL="$2"; shift 2 ;;
    --branch)   BRANCH="$2"; shift 2 ;;
    --top)      TOP="$2"; shift 2 ;;
    --no-cache) USE_CACHE=0; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

command -v git >/dev/null || { echo "git is required" >&2; exit 1; }

# ---- resolve TARGET -> a local git repo path -------------------------------
REPO_SLUG=""   # owner/repo if known (for the API cross-check)
REPO_PATH=""

IS_LOCAL=0
if [[ -d "$TARGET" ]] && git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
  IS_LOCAL=1
fi
if [[ "$IS_LOCAL" -eq 1 ]]; then
  REPO_PATH="$(cd "$TARGET" && pwd)"
  REPO_SLUG="$(git -C "$REPO_PATH" config --get remote.origin.url 2>/dev/null \
                | sed -E 's#.*github.com[:/]##; s#\.git$##' || true)"
else
  # treat as remote: accept "owner/repo" or a full git URL
  if [[ "$TARGET" == http*://* || "$TARGET" == git@* ]]; then
    URL="$TARGET"
    REPO_SLUG="$(echo "$TARGET" | sed -E 's#.*github.com[:/]##; s#\.git$##')"
  else
    URL="https://github.com/${TARGET}.git"
    REPO_SLUG="$TARGET"
  fi
  SAFE="$(echo "$REPO_SLUG" | tr '/:@' '___')"
  REPO_PATH="$CACHE_DIR/$SAFE"
  mkdir -p "$CACHE_DIR"
  if [[ -d "$REPO_PATH/.git" && "$USE_CACHE" -eq 1 ]]; then
    echo "▸ reusing cache: $REPO_PATH" >&2
    git -C "$REPO_PATH" fetch --quiet --all 2>/dev/null || true
  else
    [[ "$USE_CACHE" -eq 0 ]] && rm -rf "$REPO_PATH"
    echo "▸ cloning $URL (full history, no blobs of tags) ..." >&2
    rm -rf "$REPO_PATH"
    # full history is required — net/churn over time needs every commit.
    git clone --no-tags --quiet "$URL" "$REPO_PATH"
  fi
fi

# ---- build the git-log range/scope ----------------------------------------
GIT=(git --no-pager -C "$REPO_PATH")
RANGE=()
[[ "$BRANCH" == "--all" ]] && RANGE+=(--all) || RANGE+=("$BRANCH")
RANGE+=(--no-merges)                       # merges double-count; exclude them
[[ -n "$SINCE" ]] && RANGE+=(--since="$SINCE")
[[ -n "$UNTIL" ]] && RANGE+=(--until="$UNTIL")

# ---- extract numstat to a TEMP FILE (gotcha #1: never a fragile pipe) ------
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
RAW="$WORK/raw.tsv"
# Each commit: a header line  @C<TAB>email<TAB>name<TAB>isoDate
# then numstat lines:         add<TAB>del<TAB>path
"${GIT[@]}" log "${RANGE[@]}" \
  --numstat --pretty=format:'@C%x09%ae%x09%an%x09%aI' > "$RAW"

NCOMMITS="$(grep -c '^@C' "$RAW" || true)"
if [[ "$NCOMMITS" -eq 0 ]]; then
  echo "no commits in range — nothing to measure" >&2
  exit 1
fi

# ---- aggregate with one awk pass ------------------------------------------
# Outputs three sections to separate files for clean rendering.
AUTHORS="$WORK/authors.tsv"
LANGS="$WORK/langs.tsv"
MONTHS="$WORK/months.tsv"

awk -F'\t' -v authors="$AUTHORS" -v langs="$LANGS" -v months="$MONTHS" '
function ext(path,   n,a,e) {
  # language bucket from extension / well-known filenames
  if (path ~ /\.d\.ts$/)            return "d.ts"   # TS declarations (compound)
  if (path ~ /(^|\/)Dockerfile$/)   return "dockerfile"
  if (path ~ /(^|\/)Makefile$/)     return "makefile"
  if (path ~ /(^|\/)LICENSE$/)      return "license"
  if (path ~ /\.[A-Za-z0-9]+$/) { n=split(path,a,"."); e=tolower(a[n]); return e }
  return "(noext)"
}
/^@C/ {
  email=$2; name=$3; iso=$4;
  if (email=="") email="(unknown)";
  # canonical identity = EMAIL (merges "Nat" + "Nat White"); remember a label.
  if (!(email in label) || length(name) < length(label[email])) label[email]=name;
  month=substr(iso,1,7);                 # YYYY-MM
  ccount[email]++;
  curEmail=email; curMonth=month;
  next;
}
NF>=3 {
  a=$1; d=$2; p=$3;
  if (a=="-") a=0; if (d=="-") d=0;       # binary files -> 0 (gotcha #2)
  a+=0; d+=0;
  add[curEmail]+=a; del[curEmail]+=d;
  e=ext(p);
  ladd[e]+=a; ldel[e]+=d;
  madd[curMonth]+=a; mdel[curMonth]+=d;
  TOTADD+=a; TOTDEL+=d;
}
END {
  for (e in add)
    printf "%s\t%s\t%d\t%d\t%d\n", e, label[e], ccount[e], add[e], del[e] > authors;
  for (l in ladd)
    printf "%s\t%d\t%d\n", l, ladd[l], ldel[l] > langs;
  for (m in madd)
    printf "%s\t%d\t%d\n", m, madd[m], mdel[m] > months;
  printf "%d\t%d\n", TOTADD, TOTDEL > (authors ".tot");
}
' "$RAW"

read -r TOTADD TOTDEL < "$AUTHORS.tot"
TOTNET=$(( TOTADD - TOTDEL ))
TOTCHURN=$(( TOTADD + TOTDEL ))
NAUTHORS="$(wc -l < "$AUTHORS" | tr -d ' ')"

# ---- (optional) GitHub login cross-check via stats API ---------------------
# The API keys on login and warms up with HTTP 202; we retry a few times.
API_NOTE=""
if [[ -n "$REPO_SLUG" ]] && command -v gh >/dev/null 2>&1; then
  for _ in 1 2 3 4 5; do
    if gh api "repos/${REPO_SLUG}/stats/contributors" >/dev/null 2>&1; then
      API_NOTE="(login-based stats API reachable — see OUTPUT.md for cross-check)"
      break
    fi
    sleep 3
  done
fi

# ---- render report ---------------------------------------------------------
hr() { printf '%s\n' "------------------------------------------------------------------------------"; }
num() { printf "%'d" "$1" 2>/dev/null || printf "%d" "$1"; }

echo
echo "CODE VOLUME — ${REPO_SLUG:-$REPO_PATH}"
[[ -n "$SINCE$UNTIL" ]] && echo "range: ${SINCE:-start}..${UNTIL:-now}"
echo "scope: ${BRANCH}  · no-merges · $(num "$NCOMMITS") commits · $NAUTHORS identities (by email)"
hr
printf "TOTAL: +%s / -%s  =  net %s lines   |   churn %s lines\n" \
  "$(num "$TOTADD")" "$(num "$TOTDEL")" "$(num "$TOTNET")" "$(num "$TOTCHURN")"
hr

# --- authors, sorted by net, with churn + net/churn efficiency --------------
printf "%-26s %7s  %11s %11s  %11s %11s  %5s\n" \
  "author (by email)" "commits" "++added" "--deleted" "net" "churn" "net%"
sort -t$'\t' -k4 -rn "$AUTHORS" | head -n "$TOP" | \
while IFS=$'\t' read -r email name commits a d; do
  net=$(( a - d )); churn=$(( a + d ));
  eff="0"; [[ "$churn" -gt 0 ]] && eff=$(( 100 * net / churn ));
  label="$name"; [[ -z "$label" ]] && label="$email";
  printf "%-26.26s %7d  +%10s -%10s  %11s %11s  %4s%%\n" \
    "$label" "$commits" "$(num "$a")" "$(num "$d")" "$(num "$net")" "$(num "$churn")" "$eff"
done
hr

# --- top languages by churn -------------------------------------------------
echo "LANGUAGES (top 12 by churn) — net vs churn per ext:"
printf "  %-12s %11s %11s %11s %11s\n" "ext" "++added" "--deleted" "net" "churn"
awk -F'\t' '{print $0"\t"($2+$3)}' "$LANGS" | sort -t$'\t' -k4 -rn | head -12 | \
while IFS=$'\t' read -r ext a d churn; do
  printf "  %-12s +%10s -%10s %11s %11s\n" \
    ".$ext" "$(num "$a")" "$(num "$d")" "$(num "$((a-d))")" "$(num "$churn")"
done
hr

# --- growth over time (monthly net) -----------------------------------------
echo "GROWTH OVER TIME (monthly net · cumulative):"
printf "  %-9s %12s %12s %14s\n" "month" "net" "churn" "cumulative-net"
cum=0
sort -t$'\t' -k1 "$MONTHS" | \
while IFS=$'\t' read -r m a d; do
  net=$(( a - d )); churn=$(( a + d )); cum=$(( cum + net ));
  bar=""; n=$(( net / 5000 )); [[ "$n" -gt 40 ]] && n=40;
  [[ "$n" -lt 0 ]] && { n=$(( -n )); [[ "$n" -gt 40 ]] && n=40; barchar="▽"; } || barchar="█";
  for ((i=0;i<n;i++)); do bar="${bar}${barchar}"; done
  printf "  %-9s %12s %12s %14s  %s\n" \
    "$m" "$(num "$net")" "$(num "$churn")" "$(num "$cum")" "$bar"
done
hr
echo "net = real growth that survived · churn = total writing effort (incl. rewrites)"
echo "high net  = builder · high churn + low net = polisher/refactorer"
[[ -n "$API_NOTE" ]] && echo "$API_NOTE"
echo
