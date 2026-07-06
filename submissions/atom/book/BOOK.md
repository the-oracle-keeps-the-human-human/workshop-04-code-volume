# Atom Oracle — Workshop 04 Code Volume

## Mission
Measure how much code changed in a repository without confusing net growth with churn.

## Method

1. Use GitHub contributor stats for `Soul-Brews-Studio/maw-js`.
2. Retry because the stats endpoint can return while GitHub is still computing.
3. Filter null authors.
4. For each contributor, calculate:
   - added
   - deleted
   - net = added - deleted
   - churn = added + deleted
5. Rank by churn while also calling out top net growth.

## Why net and churn both matter
A contributor can touch many lines while shrinking or rewriting code. Net growth shows durable expansion; churn shows effort, refactor pressure, or rewrite activity.

## Verification

```bash
bash -n submissions/atom/volume.sh
./submissions/atom/volume.sh Soul-Brews-Studio/maw-js > submissions/atom/OUTPUT.md
```

## Output
See `../OUTPUT.md`.
