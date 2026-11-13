;;; Tests for (p-diff grid).  Run from p-diff/: emit run test/grid-test.scm
(import (scheme process-context) (srfi 64) (p-diff grid))

(define classic
  "530070000600195000098000060800060003400803001700020006060000280000419005000080079")

(define (every? pred lst)
  (or (null? lst) (and (pred (car lst)) (every? pred (cdr lst)))))

(define (all-cells) (let loop ((i 80) (acc '())) (if (< i 0) acc (loop (- i 1) (cons i acc)))))

(test-begin "grid")

;; 2.1 units and peers
(test-equal "27 units" 27 (vector-length units))
(test-assert "every unit has 9 cells"
  (every? (lambda (u) (= 9 (vector-length (unit-cells u))))
          (let loop ((u 26) (acc '())) (if (< u 0) acc (loop (- u 1) (cons u acc))))))
(test-assert "every cell has 3 units"
  (every? (lambda (c) (= 3 (length (vector-ref cell-units c)))) (all-cells)))
(test-assert "every cell has 20 peers"
  (every? (lambda (c) (= 20 (length (vector-ref cell-peers c)))) (all-cells)))
(test-assert "each cell is in each of its units"
  (every? (lambda (c)
            (every? (lambda (u)
                      (let ((cs (unit-cells u)))
                        (let loop ((i 0))
                          (cond ((= i 9) #f)
                                ((= c (vector-ref cs i)) #t)
                                (else (loop (+ i 1)))))))
                    (vector-ref cell-units c)))
          (all-cells)))
(test-equal "box of cell 80" 8 (cell-box 80))
(test-equal "box of cell 30" 4 (cell-box 30))
(test-equal "unit kinds" '(row col box) (list (unit-kind 0) (unit-kind 9) (unit-kind 26)))

;; 2.2 parsing
(define dotted
  "53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79")
(test-equal "dots and zeros parse the same"
  (parse-puzzle classic) (parse-puzzle dotted))
(test-equal "surrounding whitespace is ignored"
  (parse-puzzle classic)
  (parse-puzzle (string-append "   " classic (string #\return))))
(test-equal "first cell" 5 (vector-ref (parse-puzzle classic) 0))
(test-equal "short line is bad-format"
  'bad-format (parse-puzzle (substring classic 0 80)))
(test-equal "long line is bad-format"
  'bad-format (parse-puzzle (string-append classic "1")))
(test-equal "illegal character is bad-format"
  'bad-format (parse-puzzle (string-append "x" (substring classic 1 81))))
(test-equal "embedded space is bad-format"
  'bad-format (parse-puzzle (string-append (substring classic 0 40) " " (substring classic 41 81))))
(test-equal "char->digit" '(0 7 9 #f) (map char->digit (list #\0 #\7 #\9 #\a)))

;; 2.3 conflicts and candidates
(test-assert "classic has no conflicting givens"
  (not (conflicting-givens? (parse-puzzle classic))))
(test-assert "duplicate 5 in first row"
  (conflicting-givens?
   (parse-puzzle (string-append "53007000" "5" (substring classic 9 81)))))
(test-assert "duplicate in a column"
  (conflicting-givens?
   (parse-puzzle (string-append (substring classic 0 72) "5" (substring classic 73 81)))))
(test-assert "duplicate in a box only"
  (conflicting-givens?
   (parse-puzzle (string-append (substring classic 0 20) "5" (substring classic 21 81)))))

(define s (initial-state (parse-puzzle classic)))
(test-equal "candidates of r0c2" '(1 2 4) (candidates-of s 2))
(test-equal "candidates of r0c3" '(2 6) (candidates-of s 3))
(test-equal "given cell has no candidates" '() (candidates-of s 80))
(test-equal "given value kept" 9 (value-of s 80))
(test-equal "empty count" 51 (empty-cell-count s))

(define s2 (state-copy s))
(place! s2 3 6)
(test-equal "place sets value" 6 (value-of s2 3))
(test-assert "place removes digit from row peer" (not (memv 6 (candidates-of s2 5))))
(test-equal "copy is independent" 0 (value-of s 3))

;; grid->string
(test-equal "grid->string renders the classic puzzle"
  (string-append
   "5 3 . | . 7 . | . . .\n"
   "6 . . | 1 9 5 | . . .\n"
   ". 9 8 | . . . | . 6 .\n"
   "------+-------+------\n"
   "8 . . | . 6 . | . . 3\n"
   "4 . . | 8 . 3 | . . 1\n"
   "7 . . | . 2 . | . . 6\n"
   "------+-------+------\n"
   ". 6 . | . . . | 2 8 .\n"
   ". . . | 4 1 9 | . . 5\n"
   ". . . | . 8 . | . 7 9\n")
  (grid->string (parse-puzzle classic)))

(let ((fails (test-runner-fail-count (test-runner-current))))
  (test-end "grid")
  (exit (if (= fails 0) 0 1)))
