;;; (p-diff solver) -- apply techniques simplest first until solved or stuck.
(define-library (p-diff solver)
  (import (scheme base) (p-diff grid) (p-diff techniques))
  (export solve apply-step! contradiction?
          result? result-status result-counts result-remaining result-state
          solved-grid-valid?)
  (begin
    ;; status is one of solved, unsolved, no-solution.  counts is a list of
    ;; (technique . times-applied) in technique order, omitting zeros.
    (define-record-type solve-result
      (make-result status counts remaining state)
      result?
      (status result-status)
      (counts result-counts)
      (remaining result-remaining)
      (state result-state))

    ;; Placements also remove the digit from every peer (design D4).
    (define (apply-step! s st)
      (for-each (lambda (p) (place! s (car p) (cdr p))) (step-placements st))
      (for-each (lambda (p) (remove-candidate! s (car p) (cdr p)))
                (step-eliminations st)))

    (define (range a b) (if (>= a b) '() (cons a (range (+ a 1) b))))

    (define (any? pred lst)
      (and (pair? lst) (or (pred (car lst)) (any? pred (cdr lst)))))

    ;; True when an empty cell has no candidates, or some unit has a digit
    ;; that is neither placed nor a candidate anywhere in the unit.
    (define (contradiction? s)
      (or (any? (lambda (c) (and (= 0 (value-of s c)) (null? (candidates-of s c))))
                (range 0 81))
          (any? (lambda (u)
                  (let ((cells (vector->list (unit-cells u))))
                    (any? (lambda (d)
                            (not (any? (lambda (c) (or (= d (value-of s c))
                                                       (memv d (candidates-of s c))))
                                       cells)))
                          (range 1 10))))
                (range 0 27))))

    (define (find-step s)
      (let loop ((table technique-table) (i 0))
        (if (null? table)
            #f
            (let ((st ((cdar table) s)))
              (if st (cons i st) (loop (cdr table) (+ i 1)))))))

    (define (count-list counts)
      (let loop ((names technique-names) (i 0) (acc '()))
        (cond ((null? names) (reverse acc))
              ((> (vector-ref counts i) 0)
               (loop (cdr names) (+ i 1)
                     (cons (cons (car names) (vector-ref counts i)) acc)))
              (else (loop (cdr names) (+ i 1) acc)))))

    ;; Solve the puzzle given as an 81-element values vector whose givens do
    ;; not conflict.  Never guesses: stops when no technique applies.
    (define (solve values)
      (let ((s (initial-state values))
            (counts (make-vector (length technique-names) 0)))
        (define (finish status)
          (make-result status (count-list counts) (empty-cell-count s) s))
        (let loop ()
          (cond ((contradiction? s) (finish 'no-solution))
                ((= 0 (empty-cell-count s)) (finish 'solved))
                (else
                 (let ((found (find-step s)))
                   (if (not found)
                       (finish 'unsolved)
                       (begin
                         (vector-set! counts (car found)
                                      (+ 1 (vector-ref counts (car found))))
                         (apply-step! s (cdr found))
                         (loop)))))))))

    ;; True when every unit of the final state holds 1-9 exactly once and
    ;; every given in `givens` is unchanged.
    (define (solved-grid-valid? s givens)
      (and (not (any? (lambda (c)
                        (let ((g (vector-ref givens c)))
                          (and (> g 0) (not (= g (value-of s c))))))
                      (range 0 81)))
           (not (any? (lambda (u)
                        (let ((ds (map (lambda (c) (value-of s c))
                                       (vector->list (unit-cells u)))))
                          (any? (lambda (d) (not (memv d ds))) (range 1 10))))
                      (range 0 27)))))))
