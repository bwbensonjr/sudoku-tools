# Design

## Context

See proposal.md for motivation and the specs under `specs/p-diff/` for the required
behavior. `p-diff/` currently holds only a README. The toolchain is Emit 0.6.0 at
`/opt/homebrew/bin/emit`. These Emit behaviors, checked on this machine, shape the
design:

- A program auto-imports `(scheme base)`; a library must import it explicitly.
- `(import (p-diff grid))` resolves to `lib/p-diff/grid.sld` under the **current working
  directory**, not the program file's directory. Running `emit run p-diff/main.scm` from
  the repo root fails to resolve project libraries; running from `p-diff/`, or passing
  `-L p-diff/lib`, works.
- `define-record-type`, `(scheme process-context)` `command-line` and `exit` with a
  status code, and `(srfi 64)` all work under both `emit run` and `emit build`.
- `read-line` with no argument fails with an arity error; it must be called as
  `(read-line port)`.
- `digit-value` is not in `(scheme base)`. No bitwise procedures are shipped.

## Goals / Non-Goals

**Goals:**
- Each technique is a separate, independently testable procedure.
- Solve state is simple enough to inspect in the REPL (`emit repl` from `p-diff/`).
- A single `make` target builds a native `p-diff` executable; tests run with `emit run`.

**Non-Goals:**
- Speed beyond rating a few thousand puzzles in reasonable time. No profiling work.
- Step-by-step explanation output. The step records (below) make it easy to add later.
- Portability to other Scheme implementations, though the code stays R7RS-small where
  Emit allows.

## Decisions

### D1. Layout: one program plus small libraries

```text
p-diff/
  main.scm              command line, input loop, report printing, exit status
  emit-libs.scm         manifest: (program p-diff (source "main.scm") (output "build/p-diff"))
  Makefile              build, test, clean; all commands run from p-diff/
  lib/p-diff/
    grid.sld            cell indexing, units, peers, state record, parse, conflict check
    techniques.sld      one procedure per technique, plus the ordered technique table
    solver.sld          step loop, contradiction detection, solve result
    rating.sld          technique -> level mapping, hardest technique, report fields
  test/
    *-test.scm          SRFI 64 suites, one per library
    puzzles.txt         rated fixture puzzles
    expected.txt        golden p-diff output for puzzles.txt
    run-tests.sh        runs each suite and the golden comparison
```

Libraries over a single file so each technique can be tested against hand-built
states without going through the CLI. Alternative considered: one `p-diff.scm` file,
rejected because the technique tests would need to load the whole program.

### D2. State: two 81-element vectors

A solve state is a record holding `values` (vector of 81 integers, 0 for empty) and
`candidates` (vector of 81 sorted digit lists, empty for filled cells). The 27 units
(9 rows, 9 columns, 9 boxes) are precomputed once as vectors of cell indices, and each
cell's 20 peers likewise.

Candidate sets as lists rather than integer bitmasks, because Emit ships no bitwise
procedures and lists of at most nine digits keep the technique code readable. A solve
copies the input vectors once and then mutates them in place.

### D3. Techniques return steps; the solver applies them

Each technique is `(state) -> step or #f`. A step record names the technique and
lists placements `(cell . digit)` and eliminations `(cell . digit)`. The solver walks
the technique table in spec order, applies the first non-`#f` step, records the
technique count, and restarts from the top (human-solver "Simplest technique first").

Alternative: techniques mutate state directly and return a boolean. Rejected because
steps make technique tests exact ("this state yields this elimination") and give a
future explanation mode its data for free.

A step counts as one application regardless of how many candidates it removes. A
naked single places one digit per step; a hidden single likewise.

### D4. Placement propagates eliminations immediately

Placing a digit removes it from all peers' candidates as part of applying the step.
This basic propagation is not counted as a technique. Without it, every placement
would be followed by a run of trivial eliminations that inflate counts and do not
match how people solve.

### D5. Contradiction checks after every step

After applying a step the solver checks for an empty cell with no candidates, or a
unit with a missing digit that has no candidate cell. Either yields `Invalid` /
`no-solution`. Conflicting givens are detected in `grid.sld` at parse time, before any
candidates are computed.

### D6. Technique order and level table live in one place

`techniques.sld` exports the ordered list of `(name . procedure)` pairs; `rating.sld`
holds the name-to-level table. The spec-order and level mapping are then each one
literal list, and a test asserts the two cover the same nine names.

### D7. Testing

- Unit suites per library with `(srfi 64)`, run via `emit run test/<lib>-test.scm` from
  `p-diff/`. Each technique gets at least one positive state (yields the expected
  step) and one negative state (returns `#f`).
- `test/puzzles.txt` holds published puzzles chosen to land in each level, plus
  Unsolved, malformed, conflicting, and no-solution lines. `run-tests.sh` runs the
  built binary over it and diffs against `test/expected.txt`. The solver suite solves
  the same fixtures in-process and checks each solved grid is valid (human-solver
  "Sound deductions").
- `run-tests.sh` exits non-zero if any suite reports a failure, so `make test` gates.

### D8. Emit workarounds are local helpers

`char->digit` (via `char->integer`) replaces `digit-value`; every `read-line` passes
its port. These live in `grid.sld` / `main.scm` with a comment naming the Emit
version, so they are easy to drop if Emit adds the missing pieces.

## Risks / Trade-offs

- [Fixture levels depend on exact technique order] A puzzle's level can shift if two
  techniques could each unblock it. → Fixtures are chosen and their expected output
  generated from the implementation. An independent brute-force solver confirms each
  valid fixture has a unique solution that p-diff's solved grid matches; the hardest
  technique was not cross-checked against an external human-technique solver.
- [List-based candidates are slower than bitmasks] → Acceptable for the non-goal on
  speed; the state record hides the representation if it needs to change.
- [Emit is pre-1.0 and changes quickly] → Pin "Emit 0.6.0 or later" in the README and
  keep workarounds isolated (D8).
- [cwd-relative library lookup surprises users] → The Makefile and README always run
  from `p-diff/`; the built executable has no lookup at run time.
