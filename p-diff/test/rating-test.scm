;;; Tests for (p-diff rating).  Run from p-diff/: emit run test/rating-test.scm
(import (scheme process-context) (srfi 64)
        (p-diff grid) (p-diff techniques) (p-diff solver) (p-diff rating))

(define (solve-line line) (solve (parse-puzzle line)))

(define tab (string #\tab))

(test-begin "rating")

(test-equal "level table covers the technique table"
  technique-names (map car level-table))

(test-equal "singles-only puzzle is Easy" "Easy"
  (result-level (solve-line "530070000600195000098000060800060003400803001700020006060000280000419005000080079")))
(test-equal "pointing puzzle is Medium" "Medium"
  (result-level (solve-line "400000938032094100095300240370609004529001673604703090957008300003900400240030709")))
(test-equal "naked-pair hardest is Medium" "Medium" (technique-level 'naked-pair))
(test-equal "triple puzzle is Hard" "Hard"
  (result-level (solve-line "000000000231090000065003100008924000100050006000136700009300570000010843000000000")))
(test-equal "x-wing puzzle is Expert regardless of easier counts" "Expert"
  (result-level (solve-line "100000569492056108056109240009640801064010000218035604040500016905061402621000005")))
(test-equal "stalled puzzle is Unsolved" "Unsolved"
  (result-level (solve-line "8..........36......7..9.2...5...7.......457.....1...3...1....68..85...1..9....4..")))

(test-equal "hardest technique" 'naked-pair
  (hardest-technique '((naked-single . 30) (hidden-single . 21) (naked-pair . 2))))
(test-equal "hardest technique when none" #f (hardest-technique '()))

(test-equal "solved report line"
  (string-append "1" tab "Easy" tab "naked-single" tab "naked-single=51")
  (report-line 1 (solve-line "530070000600195000098000060800060003400803001700020006060000280000419005000080079")))
(test-equal "unsolved report line with no technique"
  (string-append "4" tab "Unsolved" tab "-" tab "remaining=60")
  (report-line 4 (solve-line "8..........36......7..9.2...5...7.......457.....1...3...1....68..85...1..9....4..")))
(test-equal "unsolved report line with techniques"
  (string-append "7" tab "Unsolved" tab "hidden-pair" tab
                 "naked-single=1 hidden-single=2 pointing=6 box-line=2 naked-pair=1 hidden-pair=2 remaining=45")
  (report-line 7 (solve-line "017903600000080000900000507072010430000402070064370250701000065000030000005601720")))
(test-equal "invalid report line"
  (string-append "2" tab "Invalid" tab "-" tab "bad-format")
  (invalid-line 2 'bad-format))

(let ((fails (test-runner-fail-count (test-runner-current))))
  (test-end "rating")
  (exit (if (= fails 0) 0 1)))
