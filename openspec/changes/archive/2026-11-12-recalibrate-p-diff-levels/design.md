# Design

## Context

Levels come from one table, `level-table` in `lib/p-diff/rating.sld`, which maps
each technique to a level. A solved puzzle takes the level of the hardest
technique it used. The solver tries techniques simplest first (naked-single
before hidden-single), so "hardest technique" means the hardest one this solver
needed, not the hardest one a person might pick. See proposal.md (Why) for how
`calibrate-1.csv` compares with the current ratings.

The only check today is `test/expected.txt`, which is p-diff's own past output.
It catches regressions, but nothing says whether the levels are right.

## Goals / Non-Goals

**Goals:**
- Match all 9 rows of `calibrate-1.csv` with the smallest change that does it.
- Make the user's labels an automated check that later changes must pass.
- Have a repeatable way to add calibration puzzles, including from outside
  sources.

**Non-Goals:**
- Splitting `hidden-single` into box and row/column forms. The current data
  does not need it (see Open Questions).
- Weighted or count-based scores.
- New techniques beyond `x-wing`.

## Decisions

### D1: Move every level down one technique tier

The new table is naked-single = Easy; hidden-single = Medium; pointing,
box-line = Hard; pairs, triples, and x-wing = Expert (see D2 for the pairs).

The data is clear for the first three boundaries. All 9 rows match when the
level depends only on the hardest technique, and the counts give no reason to
add a threshold. For example, the Medium rows use 8 to 16 hidden singles and
the Easy rows use none.

Alternatives considered:
- *Count thresholds* (such as "Easy if hidden singles are below N"). Rejected:
  it adds a tuning parameter, and the hardest-technique rule already separates
  every row.
- *Point scores* (SE or HoDoKu style). Rejected for now: it changes the output
  model, and 9 rows cannot fit the weights.

### D2: Pairs start Expert; Hard is locked candidates only

`calibrate-1.csv` has no puzzle whose hardest technique is a pair, triple, or
x-wing. The first draft of this design put pairs in Hard, by analogy with
HoDoKu. The site-labeled data in D4 contradicts that. Two independent
publishers place pairs a full tier above locked candidates:

- websudoku.com: none of 100 "Hard" puzzles needs a pair (the hardest is
  pointing or box-line). 99 of 100 "Evil" puzzles need a naked or hidden pair,
  and the other needs a naked triple.
- sudoku.com: "Master" is mostly locked candidates (42 of 100 have pointing or
  box-line as their hardest technique; 14 need a pair or harder). "Extreme" is
  where pairs dominate (58 of 100 need a pair or harder).

The user's Hard rows all top out at box-line, which fits "Hard = locked
candidates". So pairs, triples, and x-wing are Expert.

Alternative considered: pairs in Hard (the first draft). Rejected because the
two site-labeled sources both contradict it, and no labeled data supports it.

### D3: Calibration check runs in `make test`

Add `test/calibrate.sh`, a POSIX shell script that `run-tests.sh` calls after
the golden check. For each `test/calibrate-*.csv` it:
1. Takes the puzzle column (skipping the header) and runs `build/p-diff` on it.
2. Pairs output line N with CSV data row N and compares the levels.
3. Prints `file:row label=X rated=Y` for each mismatch, plus a summary of
   agreement by level, and exits non-zero on any mismatch or bad row.

Shell plus `cut` and `awk` keeps test dependencies the same as now (no Python
in the p-diff toolchain). It tests the built binary, as the golden check does.

Alternative: a SRFI 64 suite that reads the CSV in Scheme. Rejected because it
needs CSV parsing in Emit, and the shell version tests the shipped binary.

### D4: External calibration sources go in their own files

Add outside puzzles as `test/calibrate-<source>.csv` with a short entry
in `test/calibration-sources.md`. The entry records
the source, the license, and how its labels map onto Easy/Medium/Hard/Expert.
Accept a source only if its mapped labels agree with p-diff on almost all of a
sample of about 50 puzzles. If a source disagrees systematically, that
suggests its scale differs from the user's, not that p-diff is wrong.
`calibrate-1.csv` and any later user-labeled sets win over outside sources.

A mapping must come from the source's own labels, never from p-diff's
technique profile, or the check would just restate the table. A source tier
that straddles a boundary on the user's scale is left out rather than forced
into one level; this is recorded in `calibration-sources.md`.

Sources evaluated (details and numbers in `p-diff/test/calibration-sources.md`):
1. The Sudoku Exchange puzzle bank (SE ratings). Rejected: SE ranks naked
   singles above hidden singles, the reverse of the user's scale.
2. sudoku.com's six levels (Easy through Extreme, 100 puzzles each, from the
   TN1ck/sudoku-analysis benchmark data). Rejected as a label source: its scale
   is much softer, since 89 of its "Expert" puzzles need only hidden singles. It
   still corroborates D2.
3. websudoku.com's four levels (Easy, Medium, Hard, Evil, 100 puzzles each, same
   data). Accepted for one tier, Evil = Expert. All 100 Evil puzzles need a pair
   or harder. Easy and Medium agree with the user's scale (93% and 82%) but add
   no new coverage. "Hard" straddles the user's Medium and Hard (72 need only
   hidden singles, 24 need locked candidates), so it is left out. A sample of
   Evil puzzles becomes `calibrate-websudoku.csv`.

The user does not want to label Expert puzzles, so the site-labeled Expert
tier is the source for Expert rows. More user-labeled newspaper puzzles
remain welcome for Easy through Hard. The newspaper scale appears to stop at
Hard.

Only puzzles with a unique solution are added. An external puzzle that p-diff
rates `Unsolved` is left out of calibration, because it is outside what p-diff
can rate.

## Risks / Trade-offs

- [9 rows is a small sample] → The calibration check is meant to grow. The
  coverage requirement asks for an Expert row before archive, and D4 adds more.
- [Hidden-single boundary depends on solver order] → A puzzle that a person
  can solve with hidden singles but this solver solves with naked singles
  first is rated Easy. That matches the user's Easy rows, but hidden singles
  in a box (easy to spot) and in a row or column (harder) are treated the
  same. → Watch for mismatches in new data before splitting the technique.
- [Breaking change for existing ratings] → p-diff has no outside users yet.
  The README and golden output are updated in the same change.
- [External labels skew the table] → D4: outside sources are only checked
  against, never used to override, user labels.

## Migration Plan

One commit. To roll back, revert `level-table`; the calibration check will then
fail, which shows the disagreement.

## Open Questions

- Should a puzzle that needs only box hidden singles be Easy rather than
  Medium? Decide when a labeled puzzle forces the question. This would add a
  technique split; the table approach stays the same.
- Can the websudoku-derived puzzles be redistributed? They come from a
  public GitHub repo with no license, and websudoku.com holds the original
  rights. Only a 25-puzzle sample is kept. If that is a concern for a public
  repo, keep the file local and drop it from the commit; the mapping and the
  numbers in `calibration-sources.md` still stand.
