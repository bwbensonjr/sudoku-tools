;;; Tests for (p-diff techniques).  Run from p-diff/: emit run test/techniques-test.scm
;;;
;;; Each state starts from an empty grid (every cell has candidates 1-9) and
;;; then has candidates removed or set by hand to create one pattern.
(import (scheme process-context) (srfi 64) (p-diff grid) (p-diff techniques))

(define empty-puzzle (make-string 81 #\.))

(define (blank) (initial-state (parse-puzzle empty-puzzle)))

(define (range a b) (if (>= a b) '() (cons a (range (+ a 1) b))))

;; Remove digit d from each of the listed cells.
(define (strip! s cells d)
  (for-each (lambda (c) (remove-candidate! s c d)) cells))

(define (set-cands! s c ds)
  (vector-set! (state-candidates s) c ds))

(define (row-cells r) (range (* 9 r) (+ (* 9 r) 9)))
(define (col-cells k) (map (lambda (r) (+ (* 9 r) k)) (range 0 9)))

;; The cells of lst not in keep.
(define (filter-out keep lst)
  (cond ((null? lst) '())
        ((memv (car lst) keep) (filter-out keep (cdr lst)))
        (else (cons (car lst) (filter-out keep (cdr lst))))))

(define (sorted-pairs pairs)
  ;; Sort (cell . digit) pairs by cell then digit, for order-free comparison.
  (define (less? a b)
    (or (< (car a) (car b)) (and (= (car a) (car b)) (< (cdr a) (cdr b)))))
  (define (insert p lst)
    (cond ((null? lst) (list p))
          ((less? p (car lst)) (cons p lst))
          (else (cons (car lst) (insert p (cdr lst))))))
  (let loop ((ps pairs) (acc '()))
    (if (null? ps) acc (loop (cdr ps) (insert (car ps) acc)))))

(define (elims-of step) (sorted-pairs (step-eliminations step)))

(define (pairs-for cells ds)
  (sorted-pairs (apply append (map (lambda (c) (map (lambda (d) (cons c d)) ds)) cells))))

(test-begin "techniques")

;; 3.1 table
(test-equal "technique order"
  '(naked-single hidden-single pointing box-line naked-pair hidden-pair
    naked-triple hidden-triple x-wing)
  technique-names)

;; 3.2 singles
(let ((s (blank)))
  (set-cands! s 10 '(4))
  (let ((st (naked-single s)))
    (test-equal "naked single technique" 'naked-single (step-technique st))
    (test-equal "naked single placement" '((10 . 4)) (step-placements st))))
(test-assert "no naked single on blank grid" (not (naked-single (blank))))

(let ((s (blank)))
  (strip! s (list 0 1 2 3 4 6 7 8) 7)
  (let ((st (hidden-single s)))
    (test-equal "hidden single technique" 'hidden-single (step-technique st))
    (test-equal "hidden single placement" '((5 . 7)) (step-placements st))))
(test-assert "no hidden single on blank grid" (not (hidden-single (blank))))

;; 3.3 intersections
(let ((s (blank)))
  (strip! s (list 2 9 10 11 18 19 20) 3)  ; 3 in box 0 only at cells 0, 1
  (test-equal "pointing pair along row"
    (pairs-for (range 3 9) '(3)) (elims-of (pointing s))))
(let ((s (blank)))
  (strip! s (list 9 10 11 18 19 20) 3)    ; 3 in box 0 only at cells 0, 1, 2
  (test-equal "pointing triple along row"
    (pairs-for (range 3 9) '(3)) (elims-of (pointing s))))
(let ((s (blank)))
  (strip! s (list 1 2 10 11 19 20 18) 3)  ; 3 in box 0 only at cells 0, 9
  (test-equal "pointing pair along column"
    (pairs-for '(27 36 45 54 63 72) '(3)) (elims-of (pointing s))))
(let ((s (blank)))
  (strip! s (list 2 9 10 11 18 19 20) 3)
  (strip! s (range 3 9) 3)                ; already exploited
  (test-assert "pointing with nothing left to remove" (not (pointing s))))
(test-assert "no pointing on blank grid" (not (pointing (blank))))

(let ((s (blank)))
  (strip! s (range 3 9) 5)                ; 5 in row 0 only in box 0
  (test-equal "box-line from row"
    (pairs-for '(9 10 11 18 19 20) '(5)) (elims-of (box-line s))))
(let ((s (blank)))
  (strip! s '(27 36 45 54 63 72) 5)       ; 5 in column 0 only in box 0
  (test-equal "box-line from column"
    (pairs-for '(1 2 10 11 19 20) '(5)) (elims-of (box-line s))))
(test-assert "no box-line on blank grid" (not (box-line (blank))))

;; 3.4 subsets
(let ((s (blank)))
  (set-cands! s 0 '(1 2))
  (set-cands! s 1 '(1 2))
  (let ((st (naked-pair s)))
    (test-equal "naked pair technique" 'naked-pair (step-technique st))
    (test-equal "naked pair eliminations"
      (pairs-for (range 2 9) '(1 2)) (elims-of st))))
(let ((s (blank)))
  (set-cands! s 0 '(1 2))
  (set-cands! s 1 '(1 3))
  (test-assert "no naked pair when candidates differ" (not (naked-pair s))))
(let ((s (blank)))
  (set-cands! s 0 '(1 2))
  (set-cands! s 1 '(1 2))
  (strip! s (append (range 2 9) '(9 10 11 18 19 20)) 1)
  (strip! s (append (range 2 9) '(9 10 11 18 19 20)) 2)
  (test-assert "naked pair with nothing left to remove" (not (naked-pair s))))

(let ((s (blank)))
  (strip! s (range 2 9) 4)
  (strip! s (range 2 9) 6)
  (let ((st (hidden-pair s)))
    (test-equal "hidden pair technique" 'hidden-pair (step-technique st))
    (test-equal "hidden pair eliminations"
      (pairs-for '(0 1) '(1 2 3 5 7 8 9)) (elims-of st))))
(test-assert "no hidden pair on blank grid" (not (hidden-pair (blank))))

(let ((s (blank)))
  (set-cands! s 0 '(1 2))
  (set-cands! s 1 '(2 3))
  (set-cands! s 2 '(1 3))                 ; each cell holds two of {1,2,3}
  (let ((st (naked-triple s)))
    (test-equal "naked triple technique" 'naked-triple (step-technique st))
    (test-equal "naked triple eliminations"
      (pairs-for (range 3 9) '(1 2 3)) (elims-of st))))
(let ((s (blank)))
  (set-cands! s 0 '(1 2))
  (set-cands! s 1 '(2 3))
  (set-cands! s 2 '(3 4))
  (test-assert "no naked triple over four digits" (not (naked-triple s))))

(let ((s (blank)))
  (for-each (lambda (d) (strip! s (range 3 9) d)) '(4 6 8))
  (strip! s '(2) 8)                       ; cell 2 holds only 4 and 6 of the three
  (let ((st (hidden-triple s)))
    (test-equal "hidden triple technique" 'hidden-triple (step-technique st))
    (test-equal "hidden triple eliminations"
      (pairs-for '(0 1 2) '(1 2 3 5 7 9)) (elims-of st))))
(test-assert "no hidden triple on blank grid" (not (hidden-triple (blank))))

;; 3.5 x-wing
(let ((s (blank)))
  (strip! s (filter-out '(1 7) (row-cells 0)) 7)
  (strip! s (filter-out '(37 43) (row-cells 4)) 7)
  (let ((st (x-wing s)))
    (test-equal "x-wing technique" 'x-wing (step-technique st))
    (test-equal "x-wing on rows"
      (pairs-for (filter-out '(1 37 7 43) (append (col-cells 1) (col-cells 7))) '(7))
      (elims-of st))))
(let ((s (blank)))
  (strip! s (filter-out '(18 54) (col-cells 0)) 2)
  (strip! s (filter-out '(23 59) (col-cells 5)) 2)
  (test-equal "x-wing on columns"
    (pairs-for (filter-out '(18 23 54 59) (append (row-cells 2) (row-cells 6))) '(2))
    (elims-of (x-wing s))))
(let ((s (blank)))
  (strip! s (filter-out '(1 7) (row-cells 0)) 7)
  (strip! s (filter-out '(37 42) (row-cells 4)) 7)
  (test-assert "no x-wing when columns differ" (not (x-wing s))))
(test-assert "no x-wing on blank grid" (not (x-wing (blank))))

(let ((fails (test-runner-fail-count (test-runner-current))))
  (test-end "techniques")
  (exit (if (= fails 0) 0 1)))
