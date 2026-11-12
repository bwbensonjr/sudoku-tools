;;; (p-diff techniques) -- human solving techniques.
;;;
;;; Each technique is a procedure (state) -> step or #f.  A step names the
;;; technique and lists placements and eliminations, each a (cell . digit)
;;; pair.  A technique never mutates the state; it only reports the first
;;; move it finds that would make progress (a placement, or at least one
;;; elimination of a candidate that is actually present).
(define-library (p-diff techniques)
  (import (scheme base) (p-diff grid))
  (export make-step step? step-technique step-placements step-eliminations
          technique-table technique-names
          naked-single hidden-single pointing box-line
          naked-pair hidden-pair naked-triple hidden-triple x-wing)
  (begin
    (define-record-type step
      (make-step technique placements eliminations)
      step?
      (technique step-technique)
      (placements step-placements)
      (eliminations step-eliminations))

    ;; ---- small list helpers -------------------------------------------

    (define (range a b)                 ; a .. b-1
      (if (>= a b) '() (cons a (range (+ a 1) b))))

    (define digits (range 1 10))

    (define (filter pred lst)
      (cond ((null? lst) '())
            ((pred (car lst)) (cons (car lst) (filter pred (cdr lst))))
            (else (filter pred (cdr lst)))))

    (define (all-same? f lst)
      (or (null? lst)
          (let ((v (f (car lst))))
            (let loop ((xs (cdr lst)))
              (or (null? xs) (and (= v (f (car xs))) (loop (cdr xs))))))))

    (define (union a b)                 ; sorted integer lists
      (cond ((null? a) b)
            ((null? b) a)
            ((< (car a) (car b)) (cons (car a) (union (cdr a) b)))
            ((> (car a) (car b)) (cons (car b) (union a (cdr b))))
            (else (cons (car a) (union (cdr a) (cdr b))))))

    (define (combinations lst k)
      (cond ((= k 0) '(()))
            ((null? lst) '())
            (else (append (map (lambda (rest) (cons (car lst) rest))
                               (combinations (cdr lst) (- k 1)))
                          (combinations (cdr lst) k)))))

    ;; Return the first non-#f result of (f x) over lst.
    (define (find-map f lst)
      (if (null? lst)
          #f
          (or (f (car lst)) (find-map f (cdr lst)))))

    (define all-cells (range 0 81))
    (define all-units (range 0 27))

    (define (unit-list u) (vector->list (unit-cells u)))

    ;; Cells of unit u that still have digit d as a candidate.
    (define (cells-with s u d)
      (filter (lambda (c) (memv d (candidates-of s c))) (unit-list u)))

    ;; Keep only eliminations whose digit is still a candidate.
    (define (live-eliminations s pairs)
      (filter (lambda (p) (memv (cdr p) (candidates-of s (car p)))) pairs))

    (define (elimination-step s name pairs)
      (let ((live (live-eliminations s pairs)))
        (if (null? live) #f (make-step name '() live))))

    ;; ---- singles --------------------------------------------------------

    (define (naked-single s)
      (find-map (lambda (c)
                  (let ((cs (candidates-of s c)))
                    (and (= 0 (value-of s c))
                         (= 1 (length cs))
                         (make-step 'naked-single (list (cons c (car cs))) '()))))
                all-cells))

    (define (hidden-single s)
      (find-map (lambda (u)
                  (find-map (lambda (d)
                              (let ((cs (cells-with s u d)))
                                (and (= 1 (length cs))
                                     (make-step 'hidden-single
                                                (list (cons (car cs) d)) '()))))
                            digits))
                all-units))

    ;; ---- intersections ----------------------------------------------

    ;; Digit d's candidates in box u all lie in one row or one column:
    ;; remove d from the rest of that line.
    (define (pointing s)
      (find-map
       (lambda (u)
         (find-map
          (lambda (d)
            (let ((cs (cells-with s u d)))
              (and (>= (length cs) 2)
                   (or (and (all-same? cell-row cs)
                            (elimination-step
                             s 'pointing
                             (map (lambda (c) (cons c d))
                                  (filter (lambda (c) (not (memv c cs)))
                                          (unit-list (cell-row (car cs)))))))
                       (and (all-same? cell-col cs)
                            (elimination-step
                             s 'pointing
                             (map (lambda (c) (cons c d))
                                  (filter (lambda (c) (not (memv c cs)))
                                          (unit-list (+ 9 (cell-col (car cs))))))))))))
          digits))
       (range 18 27)))

    ;; Digit d's candidates in row or column u all lie in one box: remove d
    ;; from the rest of that box.
    (define (box-line s)
      (find-map
       (lambda (u)
         (find-map
          (lambda (d)
            (let ((cs (cells-with s u d)))
              (and (>= (length cs) 2)
                   (all-same? cell-box cs)
                   (elimination-step
                    s 'box-line
                    (map (lambda (c) (cons c d))
                         (filter (lambda (c) (not (memv c cs)))
                                 (unit-list (+ 18 (cell-box (car cs))))))))))
          digits))
       (range 0 18)))

    ;; ---- subsets ----------------------------------------------------------

    ;; k cells in a unit whose candidates together are exactly k digits:
    ;; remove those digits from the unit's other cells.
    (define (naked-subset k name)
      (lambda (s)
        (find-map
         (lambda (u)
           (let ((pool (filter (lambda (c)
                                 (let ((n (length (candidates-of s c))))
                                   (and (>= n 2) (<= n k))))
                               (unit-list u))))
             (find-map
              (lambda (group)
                (let ((ds (let loop ((g group) (acc '()))
                            (if (null? g) acc
                                (loop (cdr g) (union acc (candidates-of s (car g))))))))
                  (and (= k (length ds))
                       (elimination-step
                        s name
                        (apply append
                               (map (lambda (c)
                                      (if (memv c group)
                                          '()
                                          (map (lambda (d) (cons c d)) ds)))
                                    (unit-list u)))))))
              (combinations pool k))))
         all-units)))

    ;; k digits in a unit confined to exactly k cells: remove every other
    ;; digit from those cells.
    (define (hidden-subset k name)
      (lambda (s)
        (find-map
         (lambda (u)
           (let ((pool (filter (lambda (d)
                                 (let ((n (length (cells-with s u d))))
                                   (and (>= n 2) (<= n k))))
                               digits)))
             (find-map
              (lambda (group)
                (let ((cs (let loop ((g group) (acc '()))
                            (if (null? g) acc
                                (loop (cdr g) (union acc (cells-with s u (car g))))))))
                  (and (= k (length cs))
                       (elimination-step
                        s name
                        (apply append
                               (map (lambda (c)
                                      (map (lambda (d) (cons c d))
                                           (filter (lambda (d) (not (memv d group)))
                                                   (candidates-of s c))))
                                    cs))))))
              (combinations pool k))))
         all-units)))

    (define naked-pair (naked-subset 2 'naked-pair))
    (define hidden-pair (hidden-subset 2 'hidden-pair))
    (define naked-triple (naked-subset 3 'naked-triple))
    (define hidden-triple (hidden-subset 3 'hidden-triple))

    ;; ---- fish -------------------------------------------------------------

    ;; Two base lines (rows, or columns) where digit d has exactly two
    ;; candidates, in the same two cover lines: remove d from those cover
    ;; lines everywhere outside the base lines.
    (define (x-wing-in s d base-units cover-of cover-unit)
      (let ((bases (filter (lambda (u) (= 2 (length (cells-with s u d))))
                           base-units)))
        (find-map
         (lambda (pair)
           (let ((a (cells-with s (car pair) d))
                 (b (cells-with s (cadr pair) d)))
             (and (= (cover-of (car a)) (cover-of (car b)))
                  (= (cover-of (cadr a)) (cover-of (cadr b)))
                  (let ((corners (append a b)))
                    (elimination-step
                     s 'x-wing
                     (map (lambda (c) (cons c d))
                          (filter (lambda (c) (not (memv c corners)))
                                  (append (unit-list (cover-unit (car a)))
                                          (unit-list (cover-unit (cadr a)))))))))))
         (combinations bases 2))))

    (define (x-wing s)
      (find-map
       (lambda (d)
         (or (x-wing-in s d (range 0 9) cell-col (lambda (c) (+ 9 (cell-col c))))
             (x-wing-in s d (range 9 18) cell-row (lambda (c) (cell-row c)))))
       digits))

    ;; ---- ordered table ------------------------------------------------

    ;; Simplest first.  The solver tries these in order and restarts from the
    ;; top after any progress.
    (define technique-table
      (list (cons 'naked-single naked-single)
            (cons 'hidden-single hidden-single)
            (cons 'pointing pointing)
            (cons 'box-line box-line)
            (cons 'naked-pair naked-pair)
            (cons 'hidden-pair hidden-pair)
            (cons 'naked-triple naked-triple)
            (cons 'hidden-triple hidden-triple)
            (cons 'x-wing x-wing)))

    (define technique-names (map car technique-table))))
