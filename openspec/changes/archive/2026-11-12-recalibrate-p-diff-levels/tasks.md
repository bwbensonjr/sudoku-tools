# Tasks

## 1. Calibration check

- [x] 1.1 Add `p-diff/test/calibrate.sh` (design D3): for each `test/calibrate-*.csv`, rate the puzzle column with `build/p-diff`, compare each level with its label, print `file:row label=X rated=Y` per mismatch and an agreement summary by level, and exit non-zero on any mismatch, bad label, or `Invalid` puzzle. Verify by running it before the table change: it exits non-zero and reports exactly 7 mismatches in `calibrate-1.csv` (data rows 2, 3, 5, 6, 7, 8, 9).
- [x] 1.2 Check the malformed-row path. Run the script on a temporary CSV with a bad level and an 80-character puzzle in the scratchpad (point the script at it through an optional file argument), and verify it fails and names both rows.
- [x] 1.3 Call `test/calibrate.sh` from `test/run-tests.sh` after the golden check, so its status feeds the overall exit code. Verify `make test` now fails only on the calibration step.

## 2. Level table

- [x] 2.1 Change `level-table` in `p-diff/lib/p-diff/rating.sld` to: naked-single Easy; hidden-single Medium; pointing, box-line, naked-pair, hidden-pair Hard; naked-triple, hidden-triple, x-wing Expert. Verify `test/calibrate.sh` passes on `calibrate-1.csv` (9/9).
- [x] 2.2 Update `p-diff/test/rating-test.scm` to the new mapping. Rename the singles-only test to naked-singles-only, change the pointing puzzle to Hard and the triple puzzle to Expert, set `naked-pair` to Hard, set the solved report line level as needed, and add a hidden-single to Medium case using `calibrate-1.csv` row 2. Verify `emit run test/rating-test.scm` passes.
- [x] 2.3 Regenerate `p-diff/test/expected.txt` with `build/p-diff test/puzzles.txt`. Check that the only change is the LEVEL column: lines 9 and 10 become Hard, lines 13 to 15 become Expert, and lines 5, 6, 18, 19 and the Unsolved/Invalid lines stay the same. Update the section comments in `test/puzzles.txt` (for example "Hard: locked candidates or pairs", "Expert: triples or X-Wing"). Verify `make test` passes.
- [x] 2.4 Update the technique/level table and the sample output in `p-diff/README.md`, and add a short "Calibration" subsection that describes `test/calibrate-*.csv` and the check. Verify the README sample lines match real `build/p-diff` output for those puzzles.

## 3. More calibration data

- [x] 3.1 Add `p-diff/test/calibration-sources.md`, which lists each calibration file with its source, license, label mapping, and acceptance result (design D4). Record `calibrate-1.csv` as user-labeled. Verify every `test/calibrate-*.csv` file has an entry.
- [x] 3.2 Evaluate one external graded source (HoDoKu-style or the Sudoku Exchange bank, design D4). Take about 50 unique-solution puzzles spread across its levels, map its labels, and run them through `test/calibrate.sh` in the scratchpad. Record the agreement rate and any systematic offset in `calibration-sources.md`. Commit it as `test/calibrate-<source>.csv` only if it meets the D4 acceptance bar; otherwise record why it was rejected.
- [x] 3.3 Evaluate site-labeled sources with an Expert-or-harder tier (design D4): sudoku.com and websudoku.com, 100 puzzles per level from the TN1ck/sudoku-analysis benchmark data. Record the cross-tabulation and decisions in `calibration-sources.md`. Verify the record states the agreement per tier and the reason each tier was accepted or left out.

## 4. Pairs to Expert (revised design D2)

- [x] 4.1 Move `naked-pair` and `hidden-pair` to Expert in `level-table`, and update the `rating-test.scm` pair case, the `puzzles.txt` Hard section comment, and the README level table to match. Verify `make test` passes, `calibrate-1.csv` is still 9/9, and `test/expected.txt` does not change (no fixture's hardest technique is a pair).
- [x] 4.2 Add `p-diff/test/calibrate-websudoku.csv`: 25 websudoku.com Evil puzzles labeled `Expert`, including the hidden-pair and naked-triple cases, and record it as accepted in `calibration-sources.md`. Verify `make test` passes and the calibration summary covers all four levels across the two files.

## Workflow follow-up

- More user-labeled newspaper puzzles (collected with `ocr/`) for Easy through Hard can be appended to `calibrate-1.csv` at any time.
- Before pushing, confirm that keeping the websudoku-derived sample in a public repo is acceptable (design Open Questions).
- Archive the change after review; the main `p-diff/difficulty-rating` spec takes the new mapping and `p-diff/difficulty-calibration` becomes a main spec.
