# Spec Delta

## Purpose

Defines how `p-diff` turns a human-technique solve into a difficulty level, what it
prints for each puzzle, and what exit status it returns.

## ADDED Requirements

### Requirement: Level from hardest technique
A solved puzzle's level SHALL be set by the hardest technique applied: Easy for
`naked-single` and `hidden-single`; Medium for `pointing`, `box-line`, `naked-pair`,
and `hidden-pair`; Hard for `naked-triple` and `hidden-triple`; Expert for `x-wing`.

#### Scenario: Singles-only puzzle
- **WHEN** a puzzle is solved using only naked and hidden singles
- **THEN** its level is `Easy`

#### Scenario: Pair needed
- **WHEN** the hardest technique a solve applied is `naked-pair`
- **THEN** its level is `Medium`

#### Scenario: X-Wing needed
- **WHEN** a solve applied `x-wing` at least once
- **THEN** its level is `Expert`, regardless of how often easier techniques were used

### Requirement: Unsolved level
A valid puzzle the solver cannot complete SHALL have level `Unsolved`, and its report
SHALL include the number of empty cells remaining.

#### Scenario: Stalled solve
- **WHEN** the solver stops with 40 empty cells remaining
- **THEN** the report's level is `Unsolved` and it states 40 cells remaining

### Requirement: Report format
`p-diff` SHALL print one line per rated puzzle to standard output, with
tab-separated fields: input line number, level, hardest technique (or `-`), and the
technique counts as space-separated `name=count` pairs in technique order, omitting
techniques never applied.

#### Scenario: Solved puzzle report
- **WHEN** the puzzle on line 1 is solved with 30 naked singles, 21 hidden singles, and 2 naked pairs
- **THEN** the output line is `1<TAB>Medium<TAB>naked-pair<TAB>naked-single=30 hidden-single=21 naked-pair=2`

#### Scenario: Unsolved puzzle report
- **WHEN** the puzzle on line 4 stalls with 40 empty cells after 5 naked singles
- **THEN** the output line is `4<TAB>Unsolved<TAB>naked-single<TAB>naked-single=5 remaining=40`

#### Scenario: Invalid puzzle report
- **WHEN** the puzzle on line 2 is malformed
- **THEN** the output line is `2<TAB>Invalid<TAB>-<TAB>bad-format`

### Requirement: Exit status
`p-diff` SHALL exit 0 when every non-skipped line was a valid puzzle (solved or
Unsolved), 1 when at least one line was Invalid, and 2 for a usage error or an
unreadable input file.

#### Scenario: All valid
- **WHEN** every input puzzle is rated Easy through Unsolved
- **THEN** the exit status is 0

#### Scenario: Some invalid
- **WHEN** one of three input lines is malformed
- **THEN** the other two are still reported and the exit status is 1

### Requirement: Usage help
`p-diff --help` SHALL print a usage summary to standard output and exit 0; any other
argument starting with `-` (except `-` alone) SHALL print the usage to standard error
and exit 2.

#### Scenario: Unknown option
- **WHEN** `p-diff --verbose` is run
- **THEN** usage is printed to standard error and the exit status is 2
