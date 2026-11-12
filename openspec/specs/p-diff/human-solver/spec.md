# p-diff/human-solver Specification

## Purpose

Defines the human solving techniques `p-diff` uses, the order it tries them in, and
the guarantee that every deduction is one a person could make without guessing.

## Requirements

### Requirement: Supported techniques
The solver SHALL support exactly these techniques, identified in output by the given
names: `naked-single`, `hidden-single`, `pointing`, `box-line`, `naked-pair`,
`hidden-pair`, `naked-triple`, `hidden-triple`, `x-wing`.

#### Scenario: Technique names in output
- **WHEN** a puzzle's solve applies a hidden single and an X-Wing
- **THEN** the report names them `hidden-single` and `x-wing`

### Requirement: Simplest technique first
At each step the solver SHALL apply the first technique, in the order listed under
Supported techniques, that places a digit or removes a candidate, and SHALL restart
from the first technique after any progress.

#### Scenario: Singles preferred over harder techniques
- **WHEN** a puzzle can be fully solved with naked and hidden singles alone
- **THEN** the report counts no technique other than `naked-single` and `hidden-single`

#### Scenario: Harder technique used only when needed
- **WHEN** a puzzle stalls on singles and an X-Wing elimination unblocks it, with no pair, triple, pointing, or box-line move available at that point
- **THEN** the report counts `x-wing` at least once

### Requirement: No guessing
The solver SHALL NOT use trial and error, backtracking, or brute-force search. When no
supported technique makes progress, the solve SHALL stop and the puzzle is Unsolved.

#### Scenario: Puzzle beyond the technique set
- **WHEN** a valid puzzle requires a technique harder than X-Wing
- **THEN** the solve stops with empty cells remaining and the report is `Unsolved`

#### Scenario: Puzzle with multiple solutions
- **WHEN** a puzzle has too few givens to determine a unique solution
- **THEN** the report is `Unsolved` and no digit is placed by guessing

### Requirement: Sound deductions
Every digit the solver places SHALL agree with the puzzle's solution, and the final
grid of a solved puzzle SHALL satisfy all row, column, and box constraints.

#### Scenario: Solved grid is valid
- **WHEN** the solver completes a puzzle
- **THEN** every row, column, and box of the final grid contains each digit 1-9 exactly once and every given is unchanged

### Requirement: Contradiction detection
If the solver reaches a state where a cell has no candidates, or a digit has no
possible place in a row, column, or box, the puzzle SHALL be reported `Invalid` with
reason `no-solution`.

#### Scenario: Puzzle with no solution
- **WHEN** a puzzle's givens do not conflict directly but leave some empty cell with no possible digit
- **THEN** the report is `Invalid` with reason `no-solution`
