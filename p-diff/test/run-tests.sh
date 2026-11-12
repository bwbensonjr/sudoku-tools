#!/bin/sh
# Run every SRFI 64 suite in test/ with emit run, from the p-diff directory so
# Emit resolves (p-diff ...) libraries from lib/.  Exits non-zero if any suite
# fails.  The golden-output comparison and the calibration check follow the
# suites.
cd "$(dirname "$0")/.." || exit 2
EMIT="${EMIT:-emit}"
status=0
for t in test/*-test.scm; do
    [ -e "$t" ] || continue
    echo "== $t"
    if ! "$EMIT" run "$t"; then
        echo "FAILED: $t"
        status=1
    fi
done

# Golden output: the built binary over the fixture puzzles.  p-diff exits 1
# here because the fixtures include invalid lines on purpose.
echo "== golden: build/p-diff test/puzzles.txt"
if [ ! -x build/p-diff ]; then
    echo "FAILED: build/p-diff is missing; run make build"
    status=1
else
    ./build/p-diff test/puzzles.txt > build/actual.txt
    code=$?
    if [ "$code" -ne 1 ]; then
        echo "FAILED: expected exit status 1, got $code"
        status=1
    fi
    if ! diff -u test/expected.txt build/actual.txt; then
        echo "FAILED: output differs from test/expected.txt"
        status=1
    fi
fi

# Calibration: rated levels must match the human labels in test/calibrate-*.csv.
echo "== calibration: test/calibrate.sh"
if ! ./test/calibrate.sh; then
    echo "FAILED: calibration levels differ from their labels"
    status=1
fi
exit $status
