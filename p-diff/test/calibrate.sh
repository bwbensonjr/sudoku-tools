#!/bin/sh
# Calibration check: rate every puzzle in each calibration CSV with
# build/p-diff and compare the level with its human label.
#
# Usage: test/calibrate.sh [CSV ...]
# With no arguments, checks every test/calibrate-*.csv.  Each CSV has a
# header row "puzzle,level" and then one "PUZZLE,LEVEL" row per puzzle, where
# LEVEL is Easy, Medium, Hard, or Expert.
#
# Prints one "file:row label=X rated=Y" line per mismatch or bad row, then a
# per-level agreement summary.  Exits 0 when every row agrees, 1 otherwise,
# and 2 when build/p-diff is missing.
top=$(cd "$(dirname "$0")/.." && pwd) || exit 2
P_DIFF="$top/build/p-diff"
if [ ! -x "$P_DIFF" ]; then
    echo "calibrate: build/p-diff is missing; run make build" >&2
    exit 2
fi
if [ $# -eq 0 ]; then
    cd "$top" || exit 2
    set -- test/calibrate-*.csv
fi

tmp=$(mktemp -d) || exit 2
trap 'rm -rf "$tmp"' EXIT

status=0
for csv in "$@"; do
    if [ ! -r "$csv" ]; then
        echo "$csv: cannot read"
        status=1
        continue
    fi
    # Data rows only, with any Windows \r removed.  p-diff numbers its output
    # by input line, so output line N is data row N.
    tail -n +2 "$csv" | tr -d '\r' > "$tmp/rows"
    cut -d, -f1 "$tmp/rows" | "$P_DIFF" | cut -f2 > "$tmp/rated"
    paste -d, "$tmp/rows" "$tmp/rated" | awk -F, -v file="$csv" '
        BEGIN { split("Easy Medium Hard Expert", order, " ") }
        {
            row = NR; label = $2; got = $3
            total[label]++
            if (label !~ /^(Easy|Medium|Hard|Expert)$/) {
                printf "%s:%d bad level \"%s\" (rated=%s)\n", file, row, label, got
                bad++
            } else if (got == "Invalid") {
                printf "%s:%d invalid puzzle (label=%s)\n", file, row, label
                bad++
            } else if (got != label) {
                printf "%s:%d label=%s rated=%s\n", file, row, label, got
                bad++
            } else {
                agree[label]++
            }
        }
        END {
            line = file ":"
            for (i = 1; i <= 4; i++) {
                l = order[i]
                line = line sprintf(" %s %d/%d", l, agree[l] + 0, total[l] + 0)
            }
            print line (bad ? sprintf(" -- %d mismatch(es)", bad) : " -- ok")
            exit (bad ? 1 : 0)
        }' || status=1
done
exit $status
