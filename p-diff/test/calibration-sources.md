# Calibration sources

Each `test/calibrate-*.csv` file is a set of puzzles with human difficulty
labels. `test/calibrate.sh` (run by `make test`) fails if `p-diff` rates any of
them differently. This file records where each set came from and how its labels
map onto `Easy`, `Medium`, `Hard`, and `Expert`.

Rules for adding a set:

- Labels a person assigned on this project's scale take precedence over
  everything else.
- An external set is used only if its labels, after mapping, agree with
  `p-diff` on almost all of a sample of about 50 puzzles, and only if the
  mapping does not just restate p-diff's own technique-to-level table. A
  systematic disagreement means the source uses a different scale.
- Every puzzle must have a unique solution and must not be rated `Unsolved`.

## Accepted

### calibrate-1.csv

- Source: newspaper puzzles labeled by the project owner.
- License: puzzles used for testing only.
- Mapping: none; labels are already on the project scale.
- Coverage: Easy 2, Medium 4, Hard 3, Expert 0.
- Result: 9/9 agree.

### calibrate-websudoku.csv

- Source: websudoku.com "Evil" puzzles, from the benchmark data in
  <https://github.com/TN1ck/sudoku-analysis> (`benchmark_ac3.csv`, `source`
  websudoku.com, `level` 4). That repository has no license, and websudoku.com
  holds the original rights. Only a 25-puzzle sample is kept here.
- Mapping: websudoku Evil = Expert. This mapping comes from the site's label,
  not from p-diff's technique table.
- Selection: in dataset order, the one puzzle whose hardest technique is a
  naked triple, the first 8 that need a hidden pair, and the first 16 that
  need a naked pair.
- Result: 25/25 agree. All 100 Evil puzzles in the source rate Expert.

#### websudoku.com and sudoku.com, all tiers (evaluated 2026-11-12)

The same benchmark data has 100 puzzles from each websudoku.com level (Easy,
Medium, Hard, Evil) and each sudoku.com level (Easy, Medium, Hard, Expert,
Master, Extreme). Each puzzle's site label against its p-diff level:

| Site tier          | Easy | Medium | Hard | Expert | Unsolved |
|--------------------|------|--------|------|--------|----------|
| websudoku Easy     | 93   | 7      |      |        |          |
| websudoku Medium   | 18   | 82     |      |        |          |
| websudoku Hard     | 4    | 72     | 24   |        |          |
| websudoku Evil     |      |        |      | 100    |          |
| sudoku.com Easy    | 99   | 1      |      |        |          |
| sudoku.com Medium  | 41   | 59     |      |        |          |
| sudoku.com Hard    | 53   | 47     |      |        |          |
| sudoku.com Expert  | 5    | 89     | 4    | 2      |          |
| sudoku.com Master  |      | 44     | 42   | 14     |          |
| sudoku.com Extreme |      |        | 35   | 58     | 7        |

Decisions:

- websudoku Evil is accepted as Expert.
- websudoku Easy and Medium mostly agree with the project scale but add no
  coverage beyond `calibrate-1.csv`, so they are not included.
- websudoku Hard is left out. It spans the project's Medium and Hard levels
  (72 need only hidden singles), so it is not one level on this scale.
- sudoku.com is rejected as a label source. Its scale is much softer: its
  "Expert" is mostly Medium here.
- Where pairs go: both sites put pair puzzles a tier above locked-candidate
  puzzles. No websudoku Hard puzzle needs a pair, but 99 of its Evil puzzles
  do. On sudoku.com, pairs or triples are the hardest technique in 14 Master
  puzzles but 58 Extreme ones. This is why p-diff rates pairs Expert rather
  than Hard.

## Evaluated and rejected

### Sudoku Exchange puzzle bank

- Source: <https://github.com/grantm/sudoku-exchange-puzzle-bank>. Generated
  by QQWing and graded by Sukaku Explainer (SE rating), in four files: `easy`
  (SE < 1.5), `medium` (< 2.5), `hard` (< 5.0), and `diabolical` (>= 5.0).
- License: public domain.
- Sample: the first 60 records of each file. The files are in hash order, so
  this is a random sample. Evaluated 2026-11-12.
- Result by file:

  | File       | p-diff levels                         |
  |------------|---------------------------------------|
  | easy       | Easy 22, Medium 38                    |
  | medium     | Easy 7, Medium 33, Hard 20            |
  | hard       | Hard 19, Expert 11, Unsolved 30       |
  | diabolical | Unsolved 60                           |

- Result by SE rating:
  - Below 2.5, the ratings conflict with the project scale. SE rates
    naked singles (2.3) as harder than hidden singles (1.2 to 1.5). So SE
    1.2 splits 22 Easy to 38 Medium, and some SE 2.0 puzzles need only naked
    singles (Easy).
  - From 2.5 to 3.6, 29 of 30 agree with the hardest-technique levels: SE 2.5
    to 3.0 are Hard, and SE 3.2 and 3.6 are Expert. The exception is one SE 3.4
    (hidden pair) puzzle where p-diff needed an X-Wing.
  - 3.8 and above are all Unsolved: they need techniques p-diff lacks.
- Decision: rejected as a label source. The file buckets do not match the
  project scale. In the range where SE agrees, mapping its ratings to levels
  just restates p-diff's own technique table. That cannot test where the
  Hard/Expert line belongs (whether pairs count as Hard and triples as
  Expert). The bank is still a good large corpus for regression or speed
  testing.
