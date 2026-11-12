# Tasks

## 1. Project scaffolding

- [x] 1.1 Create `p-diff/emit-libs.scm` with the `p-diff` program entry, a stub `p-diff/main.scm`, and `p-diff/Makefile` with `build`, `test`, and `clean` targets that run Emit from `p-diff/`; verify `make build` produces `p-diff/build/p-diff` and it runs
- [x] 1.2 Add `p-diff/build/` and SRFI 64 `*.log` files to `.gitignore`; verify `git status` is clean after `make build test`
- [x] 1.3 Create `p-diff/test/run-tests.sh` that runs every `test/*-test.scm` with `emit run` and exits non-zero on any failure; verify with a deliberately failing placeholder test, then remove it

## 2. Grid and input parsing (`lib/p-diff/grid.sld`)

- [x] 2.1 Implement cell indexing, the 27 units, per-cell peers, and the state record (design D2); verify in `test/grid-test.scm` that every cell has exactly 3 units and 20 peers
- [x] 2.2 Implement puzzle line parsing with whitespace trimming, `.`/`0` blanks, and `bad-format` detection, using a local `char->digit` (design D8); verify scenarios from puzzle-input "Puzzle line format" and "Malformed lines are reported, not fatal" in `test/grid-test.scm`
- [x] 2.3 Implement the conflicting-givens check and initial candidate computation; verify the "Duplicate digit in a row" scenario and that candidates of a known puzzle match hand-computed values

## 3. Techniques (`lib/p-diff/techniques.sld`)

- [x] 3.1 Define the step record and the ordered technique table (design D3, D6); verify the table lists the nine spec names in human-solver order
- [x] 3.2 Implement `naked-single` and `hidden-single`; verify each with one positive and one negative hand-built state in `test/techniques-test.scm`
- [x] 3.3 Implement `pointing` and `box-line`; verify positive and negative states, including a pointing triple
- [x] 3.4 Implement `naked-pair`, `hidden-pair`, `naked-triple`, and `hidden-triple` (including triples where a cell holds only two of the three digits); verify positive and negative states for each
- [x] 3.5 Implement `x-wing` in both row and column orientation; verify positive states for each orientation and a negative state

## 4. Solver (`lib/p-diff/solver.sld`)

- [x] 4.1 Implement step application with placement propagation (design D4) and the simplest-first loop that restarts after each step; verify in `test/solver-test.scm` that a singles-only puzzle solves with only `naked-single` and `hidden-single` counted
- [x] 4.2 Implement contradiction detection after each step (design D5); verify a no-solution puzzle yields `no-solution`
- [x] 4.3 Return a solve result with status, technique counts, and remaining empty cells; verify a puzzle needing a technique beyond X-Wing stops Unsolved with the correct remaining count and no guessed placements
- [x] 4.4 Add a solved-grid validity check and verify every solved fixture puzzle satisfies row, column, and box constraints with givens unchanged (human-solver "Sound deductions")

## 5. Rating and CLI (`lib/p-diff/rating.sld`, `main.scm`)

- [x] 5.1 Implement the level table, hardest-technique selection, and report-field formatting; verify in `test/rating-test.scm` the Easy, Medium, and Expert scenarios and that the level table and technique table cover the same nine names
- [x] 5.2 Implement `main.scm`: argument handling (`--help`, unknown options, files, `-`, stdin), line numbering with skipped blank and `#` lines, tab-separated reports, and exit statuses 0, 1, and 2, calling `read-line` with an explicit port (design D8); verify each difficulty-rating and puzzle-input CLI scenario by running the built binary
- [x] 5.3 Assemble `test/puzzles.txt` with at least two puzzles per level (Easy, Medium, Hard, Expert), Unsolved, malformed, conflicting, and no-solution lines, and comments; confirm with an independent brute-force solver that every valid puzzle has a unique solution and every solved grid matches it (no external human-technique solver was used; levels reflect p-diff's own technique order), then add `test/expected.txt` and add the golden diff to `run-tests.sh`; verify `make test` passes

## 6. Documentation and integration

- [x] 6.1 Update `p-diff/README.md` with requirements (Emit 0.6.0+), build and run commands, input format, output format, levels, techniques, and exit statuses; verify each documented command runs as written from a clean checkout
- [x] 6.2 Fix the top-level `README.md` link to `p-diff` so it resolves; verify the link target exists
- [x] 6.3 Run `make clean build test` from a clean checkout and `openspec validate add-p-diff-solver --strict`; verify both succeed

## Workflow follow-up

- Archive the change after review with the `openspec-archive-change` skill.
