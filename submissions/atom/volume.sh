#!/usr/bin/env bash
set -euo pipefail
REPO="${1:-Soul-Brews-Studio/maw-js}"
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

for attempt in 1 2 3 4 5; do
  if gh api "repos/$REPO/stats/contributors" > "$TMP" 2>/dev/null && jq -e 'type == "array"' "$TMP" >/dev/null; then
    break
  fi
  sleep 2
done

jq -e 'type == "array"' "$TMP" >/dev/null

printf '# Atom Code Volume\n\n'
printf 'repo: `%s`\n\n' "$REPO"
printf '## Totals\n\n```text\n'
jq -r '
  map(select(.author != null) | {login:.author.login, commits:.total, added:([.weeks[].a] | add), deleted:([.weeks[].d] | add)}) as $rows |
  ($rows | map(.added) | add) as $added |
  ($rows | map(.deleted) | add) as $deleted |
  "authors: \($rows|length)",
  "added:   +\($added)",
  "deleted: -\($deleted)",
  "net:     \($added - $deleted)",
  "churn:   \($added + $deleted)"
' "$TMP"
printf '```\n\n'
printf '## Contributors by churn\n\n```text\n'
printf '%-24s %8s %12s %12s %12s %12s\n' author commits added deleted net churn
jq -r '
  map(select(.author != null) | {login:.author.login, commits:.total, added:([.weeks[].a] | add), deleted:([.weeks[].d] | add)})
  | map(. + {net:(.added-.deleted), churn:(.added+.deleted)})
  | sort_by(.churn) | reverse | .[:15][]
  | [.login, .commits, .added, .deleted, .net, .churn] | @tsv
' "$TMP" | awk -F'\t' '{printf "%-24s %8d %12d %12d %12d %12d\n", $1,$2,$3,$4,$5,$6}'
printf '```\n\n'
printf '## Insights\n\n'
jq -r '
  map(select(.author != null) | {login:.author.login, commits:.total, added:([.weeks[].a] | add), deleted:([.weeks[].d] | add)})
  | map(. + {net:(.added-.deleted), churn:(.added+.deleted)}) as $rows |
  ($rows | sort_by(.added) | reverse | .[0]) as $top_added |
  ($rows | sort_by(.net) | reverse | .[0]) as $top_net |
  ($rows | sort_by(.churn) | reverse | .[0]) as $top_churn |
  "- Top added: `\($top_added.login)` with +\($top_added.added) lines.",
  "- Top net growth: `\($top_net.login)` with \($top_net.net) net lines.",
  "- Top churn: `\($top_churn.login)` with \($top_churn.churn) touched lines."
' "$TMP"
