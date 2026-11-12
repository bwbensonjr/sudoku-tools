# Spec Delta

## MODIFIED Requirements

### Requirement: Level from hardest technique
A solved puzzle's level SHALL be set by the hardest technique applied: Easy for
`naked-single`; Medium for `hidden-single`; Hard for `pointing` and `box-line`;
Expert for `naked-pair`, `hidden-pair`, `naked-triple`, `hidden-triple`, and
`x-wing`.

#### Scenario: Naked-singles-only puzzle
- **WHEN** a puzzle is solved using only naked singles
- **THEN** its level is `Easy`

#### Scenario: Singles-only puzzle
- **WHEN** a puzzle is solved using only naked and hidden singles, with at least one hidden single
- **THEN** its level is `Medium`

#### Scenario: Locked candidates needed
- **WHEN** the hardest technique a solve applied is `box-line`
- **THEN** its level is `Hard`

#### Scenario: Pair needed
- **WHEN** the hardest technique a solve applied is `naked-pair`
- **THEN** its level is `Expert`

#### Scenario: Triple needed
- **WHEN** the hardest technique a solve applied is `hidden-triple`
- **THEN** its level is `Expert`

#### Scenario: X-Wing needed
- **WHEN** a solve applied `x-wing` at least once
- **THEN** its level is `Expert`, regardless of how often easier techniques were used

### Requirement: Report format
`p-diff` SHALL print one line per rated puzzle to standard output, with
tab-separated fields: input line number, level, hardest technique (or `-`), and the
technique counts as space-separated `name=count` pairs in technique order, omitting
techniques never applied.

#### Scenario: Solved puzzle report
- **WHEN** the puzzle on line 1 is solved with 30 naked singles, 21 hidden singles, and 2 naked pairs
- **THEN** the output line is `1<TAB>Expert<TAB>naked-pair<TAB>naked-single=30 hidden-single=21 naked-pair=2`

#### Scenario: Unsolved puzzle report
- **WHEN** the puzzle on line 4 stalls with 40 empty cells after 5 naked singles
- **THEN** the output line is `4<TAB>Unsolved<TAB>naked-single<TAB>naked-single=5 remaining=40`

#### Scenario: Invalid puzzle report
- **WHEN** the puzzle on line 2 is malformed
- **THEN** the output line is `2<TAB>Invalid<TAB>-<TAB>bad-format`
