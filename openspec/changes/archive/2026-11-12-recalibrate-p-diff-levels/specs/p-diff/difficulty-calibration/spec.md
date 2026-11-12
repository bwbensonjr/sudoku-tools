# Spec Delta

## Purpose

Keeps `p-diff` difficulty levels anchored to human-labeled reference puzzles, so
that the technique-to-level mapping is checked against labels a person agrees
with instead of only against its own past output.

## ADDED Requirements

### Requirement: Calibration set format
Calibration sets SHALL be CSV files named `test/calibrate-*.csv` under `p-diff/`,
with a header row `puzzle,level`. Each later row SHALL hold an 81-character puzzle
in `p-diff` input format and one of `Easy`, `Medium`, `Hard`, or `Expert`.

#### Scenario: Reference row
- **WHEN** a calibration file contains the row `500004100084001006020570000000002480090045030705008020010800003800900274300450800,Easy`
- **THEN** that puzzle is labeled `Easy` for calibration

#### Scenario: Malformed row
- **WHEN** a calibration row has a level outside `Easy`, `Medium`, `Hard`, `Expert`, or a puzzle `p-diff` reports as `Invalid`
- **THEN** the calibration check fails and names the file and row

### Requirement: Calibration agreement
`p-diff` SHALL rate every puzzle in every calibration set at exactly its labeled
level. The test suite SHALL fail when any puzzle's rated level differs from its
label, and SHALL report each mismatch with its file, row, label, and rated level.

#### Scenario: All labels reproduced
- **WHEN** the test suite runs and every calibration puzzle's level matches its label
- **THEN** the calibration check passes

#### Scenario: Mismatch reported
- **WHEN** a puzzle labeled `Hard` is rated `Medium`
- **THEN** the calibration check fails and its output names the file, the row, `Hard`, and `Medium`

### Requirement: Reference set coverage
The calibration sets SHALL include at least one puzzle for each of `Easy`,
`Medium`, `Hard`, and `Expert`.

#### Scenario: Expert covered
- **WHEN** the calibration sets are checked
- **THEN** at least one row is labeled `Expert`
