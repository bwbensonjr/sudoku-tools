# Spec Delta

## Purpose

Defines the puzzle text `p-diff` accepts, where it reads puzzles from, and how it
reports input it cannot rate.

## ADDED Requirements

### Requirement: Puzzle line format
`p-diff` SHALL accept a puzzle as one line of exactly 81 cell characters in row-major
order, where `1`-`9` is a given and `0` or `.` is an empty cell. Leading and trailing
whitespace on the line SHALL be ignored.

#### Scenario: Dots and zeros both mark empty cells
- **WHEN** two lines describe the same puzzle, one using `.` and one using `0` for blanks
- **THEN** `p-diff` reports identical ratings for both

#### Scenario: Surrounding whitespace is ignored
- **WHEN** a valid 81-character puzzle line has leading spaces and a trailing carriage return
- **THEN** `p-diff` rates it as if the whitespace were absent

### Requirement: Skipped lines
`p-diff` SHALL skip blank lines and lines whose first non-whitespace character is `#`,
producing no output for them, while still counting them for line numbering.

#### Scenario: Comment and blank lines are skipped
- **WHEN** the input is a comment line, a blank line, then a valid puzzle
- **THEN** `p-diff` prints exactly one report, numbered as line 3

### Requirement: Input sources
`p-diff` SHALL read puzzles from each file named on the command line in order, or from
standard input when no file is named or the name is `-`. Each puzzle is rated
independently, in input order.

#### Scenario: Reading from standard input
- **WHEN** `p-diff` is run with no arguments and two puzzle lines on standard input
- **THEN** it prints two reports, in the same order as the input

#### Scenario: Reading from a file argument
- **WHEN** `p-diff puzzles.txt` is run and the file holds three puzzle lines
- **THEN** it prints three reports, in file order

#### Scenario: Unreadable file
- **WHEN** a named file does not exist
- **THEN** `p-diff` prints an error naming the file to standard error and exits with status 2

### Requirement: Malformed lines are reported, not fatal
A line that is not 81 cell characters, or contains a character other than `1`-`9`,
`0`, or `.`, SHALL produce an `Invalid` report with reason `bad-format`, and
processing SHALL continue with the next line.

#### Scenario: Short line
- **WHEN** a line has 80 cell characters followed by a valid puzzle line
- **THEN** the first report is `Invalid` with reason `bad-format` and the second puzzle is rated normally

#### Scenario: Illegal character
- **WHEN** a line of 81 characters contains the letter `x`
- **THEN** the report is `Invalid` with reason `bad-format`

### Requirement: Conflicting givens are reported
A puzzle whose givens repeat a digit within a row, column, or box SHALL produce an
`Invalid` report with reason `conflicting-givens`, without attempting a solve.

#### Scenario: Duplicate digit in a row
- **WHEN** a puzzle has the digit `5` given twice in its first row
- **THEN** the report is `Invalid` with reason `conflicting-givens`
