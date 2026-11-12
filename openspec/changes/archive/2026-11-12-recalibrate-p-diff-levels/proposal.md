# Proposal

## Why

`p-diff` rates puzzles easier than the human-labeled reference set in
`p-diff/test/calibrate-1.csv`. It agrees with only 2 of the 9 labels, and every
miss is exactly one tier too easy:

| # | Label  | p-diff now | Hardest technique | hidden-single | pointing / box-line |
|---|--------|------------|-------------------|---------------|---------------------|
| 1 | Easy   | Easy       | naked-single      | 0             | 0 / 0               |
| 4 | Easy   | Easy       | naked-single      | 0             | 0 / 0               |
| 2 | Medium | Easy       | hidden-single     | 16            | 0 / 0               |
| 5 | Medium | Easy       | hidden-single     | 15            | 0 / 0               |
| 7 | Medium | Easy       | hidden-single     | 14            | 0 / 0               |
| 9 | Medium | Easy       | hidden-single     | 8             | 0 / 0               |
| 3 | Hard   | Medium     | box-line          | 16            | 4 / 1               |
| 6 | Hard   | Medium     | box-line          | 11            | 4 / 1               |
| 8 | Hard   | Medium     | box-line          | 9             | 3 / 1               |

The labels split cleanly on the hardest technique needed: naked singles only
means Easy, hidden singles mean Medium, and locked candidates (pointing,
box-line) mean Hard. The current level table puts the Easy/Medium line one
technique tier too high. This matches newspaper-style ratings, which seem to
be what the reference set uses (the OCR test image is a newspaper puzzle).

## What Changes

- **BREAKING** Change the technique-to-level table so each level starts one
  tier lower:
  - Easy: `naked-single`
  - Medium: `hidden-single`
  - Hard: `pointing`, `box-line`
  - Expert: `naked-pair`, `hidden-pair`, `naked-triple`, `hidden-triple`, `x-wing`
  Pairs go in Expert because two site-labeled sources (websudoku.com,
  sudoku.com) put them a full tier above locked candidates (design D2).
  Ratings of existing puzzles change. The fixture golden output
  (`test/expected.txt`) and rating tests are updated to match.
- Add a calibration check: a test that runs `p-diff` over every
  `test/calibrate-*.csv` file and fails if any rated level differs from its
  label. This keeps the user's labels as the source of truth for later
  technique or level changes.
- Grow the calibration data. `calibrate-1.csv` has no Expert or pair
  puzzles, so add a sample of websudoku.com "Evil" puzzles as
  `calibrate-websudoku.csv` (labeled Expert by the site). External sources are
  used only for tiers whose own labels agree with the user's scale.
- Update the README technique/level table.

Out of scope: new solving techniques, score-based or count-weighted ratings,
and changes to the output format or exit codes.

## Capabilities

### New Capabilities
- `p-diff/difficulty-calibration`: the labeled reference puzzle sets, their
  file format, and the requirement that `p-diff` reproduces their labels.

### Modified Capabilities
- `p-diff/difficulty-rating`: the "Level from hardest technique" requirement
  changes its technique-to-level mapping, and the report-format example
  scenario's level changes with it.

## Impact

- `p-diff/lib/p-diff/rating.sld`: `level-table`.
- `p-diff/test/rating-test.scm`, `p-diff/test/expected.txt`,
  `p-diff/test/puzzles.txt` (section comments), `p-diff/test/run-tests.sh`
  (new calibration step).
- `p-diff/test/calibrate-*.csv`: existing and new reference data.
- `p-diff/README.md`: technique/level table and examples.
- Anyone relying on current `p-diff` levels will see most puzzles rated one
  level harder.
