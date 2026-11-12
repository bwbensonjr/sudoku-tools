# Proposal

## Why

The repository describes `p-diff`, a Scheme Sudoku solver that rates puzzle difficulty
by solving with human techniques, but only a README exists. Building it now gives
sudoku-tools its first working tool and exercises the Emit Scheme compiler (installed
as `emit`, version 0.6.0) on a real program.

## What Changes

- Add the `p-diff` program under `p-diff/`, written in R7RS Scheme and compiled with
  Emit (`emit run` for development, `emit build` for a native executable).
- Read puzzles as 81-character lines (digits `1`-`9`, `0` or `.` for blanks), one per
  line, from a file argument or standard input.
- Solve each puzzle using only human techniques, applied simplest first: naked single,
  hidden single, pointing pair/triple, box/line reduction, naked pair, hidden pair,
  naked triple, hidden triple, and X-Wing. No guessing or backtracking.
- Rate each puzzle by the hardest technique the solve required, mapped to a named
  level (Easy, Medium, Hard, Expert), or Unsolved when the techniques stall.
- Report, per puzzle, the rating, the hardest technique, and how many times each
  technique was applied; report invalid input lines without stopping the run.
- Include a SRFI 64 test suite run under `emit run`, and update `p-diff/README.md`
  with build, run, and output documentation.

## Capabilities

### New Capabilities

- `p-diff/puzzle-input`: Accepted puzzle format, input sources, and how malformed or
  contradictory puzzles are reported.
- `p-diff/human-solver`: The set of human solving techniques, their order of
  application, and the guarantee that the solver never guesses.
- `p-diff/difficulty-rating`: How a solve maps to a difficulty level, the per-puzzle
  report format, and the program's exit status.

### Modified Capabilities

None. The project has no existing specs.

## Impact

- New code: `p-diff/` program source, Scheme libraries, tests, and a Makefile or script.
- New build dependency: Emit 0.6.0 or later on `PATH` as `emit` (LLVM and Boehm GC
  come with it). No other runtime dependencies; `emit build` output is a standalone
  native executable.
- Documentation: `p-diff/README.md` and the top-level `README.md` link.
- Out of scope: generating puzzles, rating by numeric score, grid-layout input,
  techniques beyond X-Wing (Swordfish, XY-Wing, coloring, chains), and finding all
  solutions or proving uniqueness.
