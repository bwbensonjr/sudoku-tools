# p-diff

The `p-diff` program is a Scheme Sudoku solver that uses human solving
techniques to evaluate the difficulty level of a Sudoku puzzle.

`p-diff` uses the
[Emit Scheme implementation](https://github.com/bwbensonjr/emit).

## Requirements

- Emit 0.6.0 or later, on `PATH` as `emit` (`emit --version` to check).
  Emit brings its own LLVM and Boehm GC requirements; see its
  installation docs.

## Build and test

Run these from the `p-diff/` directory. Emit looks for the `(p-diff ...)`
libraries in `lib/` under the current directory, so running from elsewhere
fails to resolve them.

```sh
make build        # native executable at build/p-diff
make test         # SRFI 64 suites plus a golden-output check
make clean
```

During development you can skip the build and run the source directly:

```sh
emit run main.scm test/puzzles.txt
```

## Usage

```sh
build/p-diff [FILE ...]
build/p-diff --help
```

Puzzles are read from each `FILE` in order, or from standard input when no
file is given or a file is named `-`:

```sh
build/p-diff test/puzzles.txt
echo 530070000600195000098000060800060003400803001700020006060000280000419005000080079 | build/p-diff
```

### Input

One puzzle per line: 81 characters in row-major order, `1`-`9` for givens
and `0` or `.` for empty cells. Leading and trailing whitespace (including a
Windows `\r`) is ignored. Blank lines and lines starting with `#` are skipped.

### Output

One line per puzzle, with four tab-separated fields:

```text
LINE  LEVEL  HARDEST  DETAIL
```

- `LINE` is the puzzle's line number in its input (skipped lines count;
  numbering restarts at 1 for each file).
- `LEVEL` is `Easy`, `Medium`, `Hard`, `Expert`, `Unsolved`, or `Invalid`.
- `HARDEST` is the hardest technique applied, or `-` if none.
- `DETAIL` is a space-separated list of `technique=count` pairs, in technique
  order. An `Unsolved` puzzle adds `remaining=N`, the empty cells left. An
  `Invalid` puzzle gives the reason instead.

```text
5	Easy	naked-single	naked-single=51
18	Expert	x-wing	naked-single=34 hidden-single=1 pointing=2 hidden-pair=1 x-wing=1
22	Unsolved	-	remaining=60
26	Invalid	-	bad-format
```

### Techniques and levels

The solver applies the first technique in this list that makes progress,
then starts again from the top. It never guesses: when nothing applies, the
puzzle is `Unsolved`.

| Technique       | Level  |
|-----------------|--------|
| `naked-single`  | Easy   |
| `hidden-single` | Medium |
| `pointing`      | Hard   |
| `box-line`      | Hard   |
| `naked-pair`    | Expert |
| `hidden-pair`   | Expert |
| `naked-triple`  | Expert |
| `hidden-triple` | Expert |
| `x-wing`        | Expert |

A solved puzzle's level is the level of the hardest technique it needed.
Because the solver tries naked singles before hidden singles, a puzzle is
`Easy` only if naked singles alone solve it.

### Calibration

The levels are tuned against puzzles that a person has already labeled. Each
`test/calibrate-*.csv` file has a `puzzle,level` header, then one puzzle and
its label (`Easy`, `Medium`, `Hard`, or `Expert`) per row. `make test` runs
`test/calibrate.sh`, which rates every puzzle and fails if any level differs
from its label:

```sh
test/calibrate.sh                     # every test/calibrate-*.csv
test/calibrate.sh path/to/other.csv   # check another labeled set
```

`test/calibration-sources.md` records where each calibration file came from.

### Invalid puzzles

| Reason               | Meaning                                                   |
|----------------------|-----------------------------------------------------------|
| `bad-format`         | not 81 cells, or a character other than `1`-`9`, `0`, `.` |
| `conflicting-givens` | a row, column, or box gives the same digit twice          |
| `no-solution`        | solving reached a cell or digit with no possible place    |

An invalid line is reported and the run continues.

### Exit status

| Status | Meaning                                         |
|--------|-------------------------------------------------|
| 0      | every puzzle was valid (including `Unsolved`)   |
| 1      | at least one puzzle was `Invalid`               |
| 2      | unknown option, or an input file cannot be read |

## Layout

```text
main.scm                    command line, input loop, report output
lib/p-diff/grid.sld         cells, units, peers, solve state, parsing
lib/p-diff/techniques.sld   the nine techniques, in order
lib/p-diff/solver.sld       simplest-first solve loop, contradiction checks
lib/p-diff/rating.sld       levels and report lines
test/                       SRFI 64 suites, fixture puzzles, golden output,
                            calibration sets and check
```
