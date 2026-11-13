;;; (p-diff grid) -- cells, units, peers, solve state, and puzzle parsing.
;;;
;;; Cells are numbered 0-80 in row-major order.  The 27 units are numbered
;;; 0-8 for rows, 9-17 for columns, and 18-26 for boxes; each unit is a
;;; vector of its nine cell indices in ascending order.
;;;
;;; A solve state holds two 81-element vectors: `values` (0 for an empty
;;; cell, otherwise the digit) and `candidates` (a sorted list of digits for
;;; an empty cell, the empty list for a filled one).
(define-library (p-diff grid)
  (import (scheme base) (scheme char))
  (export cell-row cell-col cell-box cell-index
          units unit-cells unit-kind cell-units cell-peers
          make-state state? state-values state-candidates
          state-copy candidates-of value-of
          remove-candidate! place! empty-cell-count
          char->digit trim-string
          parse-puzzle conflicting-givens? initial-state
          state-from-strings grid->string print-grid)
  (begin
    (define (cell-row c) (quotient c 9))
    (define (cell-col c) (remainder c 9))
    (define (cell-box c)
      (+ (* 3 (quotient (cell-row c) 3)) (quotient (cell-col c) 3)))
    (define (cell-index r c) (+ (* 9 r) c))

    (define (iota-list n)
      (let loop ((i (- n 1)) (acc '()))
        (if (< i 0) acc (loop (- i 1) (cons i acc)))))

    (define (cells-where pred)
      (let loop ((c 80) (acc '()))
        (cond ((< c 0) (list->vector acc))
              ((pred c) (loop (- c 1) (cons c acc)))
              (else (loop (- c 1) acc)))))

    (define units
      (list->vector
       (append
        (map (lambda (r) (cells-where (lambda (c) (= (cell-row c) r)))) (iota-list 9))
        (map (lambda (k) (cells-where (lambda (c) (= (cell-col c) k)))) (iota-list 9))
        (map (lambda (b) (cells-where (lambda (c) (= (cell-box c) b)))) (iota-list 9)))))

    (define (unit-cells u) (vector-ref units u))

    ;; Returns row, col, or box.
    (define (unit-kind u)
      (cond ((< u 9) 'row) ((< u 18) 'col) (else 'box)))

    ;; For each cell, the list (row-unit col-unit box-unit).
    (define cell-units
      (list->vector
       (map (lambda (c)
              (list (cell-row c) (+ 9 (cell-col c)) (+ 18 (cell-box c))))
            (iota-list 81))))

    ;; For each cell, the sorted list of the 20 other cells sharing a unit.
    (define cell-peers
      (list->vector
       (map (lambda (c)
              (let loop ((p 80) (acc '()))
                (cond ((< p 0) acc)
                      ((and (not (= p c))
                            (or (= (cell-row p) (cell-row c))
                                (= (cell-col p) (cell-col c))
                                (= (cell-box p) (cell-box c))))
                       (loop (- p 1) (cons p acc)))
                      (else (loop (- p 1) acc)))))
            (iota-list 81))))

    (define-record-type solve-state
      (make-state values candidates)
      state?
      (values state-values)
      (candidates state-candidates))

    (define (state-copy s)
      (make-state (vector-copy (state-values s))
                  (vector-copy (state-candidates s))))

    (define (candidates-of s c) (vector-ref (state-candidates s) c))
    (define (value-of s c) (vector-ref (state-values s) c))

    (define (remove-digit d lst)
      (cond ((null? lst) '())
            ((= (car lst) d) (cdr lst))
            (else (cons (car lst) (remove-digit d (cdr lst))))))

    ;; Remove digit d from cell c's candidates.  Returns #t if it was there.
    (define (remove-candidate! s c d)
      (let ((cs (candidates-of s c)))
        (if (memv d cs)
            (begin (vector-set! (state-candidates s) c (remove-digit d cs)) #t)
            #f)))

    ;; Place digit d in cell c and remove d from every peer's candidates.
    (define (place! s c d)
      (vector-set! (state-values s) c d)
      (vector-set! (state-candidates s) c '())
      (for-each (lambda (p) (remove-candidate! s p d))
                (vector-ref cell-peers c)))

    (define (empty-cell-count s)
      (let loop ((c 0) (n 0))
        (if (= c 81)
            n
            (loop (+ c 1) (if (= 0 (value-of s c)) (+ n 1) n)))))

    ;; Emit 0.6.0 has no digit-value in (scheme base).  Returns 0-9 or #f.
    (define (char->digit ch)
      (let ((n (- (char->integer ch) (char->integer #\0))))
        (if (and (>= n 0) (<= n 9)) n #f)))

    (define (trim-string s)
      (let* ((n (string-length s))
             (start (let loop ((i 0))
                      (if (and (< i n) (char-whitespace? (string-ref s i)))
                          (loop (+ i 1))
                          i)))
             (end (let loop ((i n))
                    (if (and (> i start) (char-whitespace? (string-ref s (- i 1))))
                        (loop (- i 1))
                        i))))
        (substring s start end)))

    ;; Parse a puzzle line.  Returns a vector of 81 values (0 for empty) or
    ;; the symbol bad-format.
    (define (parse-puzzle line)
      (let ((s (trim-string line)))
        (if (not (= (string-length s) 81))
            'bad-format
            (let ((v (make-vector 81 0)))
              (let loop ((i 0))
                (if (= i 81)
                    v
                    (let* ((ch (string-ref s i))
                           (d (if (char=? ch #\.) 0 (char->digit ch))))
                      (if d
                          (begin (vector-set! v i d) (loop (+ i 1)))
                          'bad-format))))))))

    ;; True when some unit has the same given digit twice.
    (define (conflicting-givens? values)
      (let unit-loop ((u 0))
        (if (= u 27)
            #f
            (let ((seen (make-vector 10 #f))
                  (cells (unit-cells u)))
              (let cell-loop ((i 0))
                (if (= i 9)
                    (unit-loop (+ u 1))
                    (let ((d (vector-ref values (vector-ref cells i))))
                      (cond ((= d 0) (cell-loop (+ i 1)))
                            ((vector-ref seen d) #t)
                            (else (vector-set! seen d #t)
                                  (cell-loop (+ i 1)))))))))))

    ;; Build a state from parsed values: every empty cell gets the digits
    ;; not already given among its peers.
    (define (initial-state values)
      (let ((s (make-state (make-vector 81 0)
                           (make-vector 81 '(1 2 3 4 5 6 7 8 9)))))
        (let loop ((c 0))
          (when (< c 81)
            (let ((d (vector-ref values c)))
              (unless (= d 0) (place! s c d)))
            (loop (+ c 1))))
        s))

    ;; Build a state directly from values and explicit candidates, for tests
    ;; that need a hand-made candidate pattern.  `values` is an 81-character
    ;; puzzle string; `cands` is an association list of (cell . digit-list)
    ;; overriding the computed candidates of those cells.
    (define (state-from-strings puzzle cands)
      (let ((s (initial-state (parse-puzzle puzzle))))
        (for-each (lambda (entry)
                    (vector-set! (state-candidates s) (car entry) (cdr entry)))
                  cands)
        s))

    ;; Render a vector of 81 values (0 for empty) as a 9x9 text grid, with
    ;; empty cells shown as `.` and lines between the 3x3 boxes:
    ;;
    ;;   5 3 . | . 7 . | . . .
    ;;   6 . . | 1 9 5 | . . .
    ;;   . 9 8 | . . . | . 6 .
    ;;   ------+-------+------
    ;;   ...
    (define (grid->string values)
      (let ((out (open-output-string)))
        (let loop ((c 0))
          (when (< c 81)
            (let ((r (cell-row c))
                  (col (cell-col c))
                  (d (vector-ref values c)))
              (when (and (= col 0) (> r 0) (= 0 (remainder r 3)))
                (write-string "------+-------+------\n" out))
              (cond ((= col 0))
                    ((= 0 (remainder col 3)) (write-string " | " out))
                    (else (write-char #\space out)))
              (if (= d 0)
                  (write-char #\. out)
                  (write-string (number->string d) out))
              (when (= col 8) (newline out)))
            (loop (+ c 1))))
        (get-output-string out)))

    ;; Print a vector of 81 values as a text grid to `port` (default: the
    ;; current output port).
    (define (print-grid values . port)
      (write-string (grid->string values)
                    (if (null? port) (current-output-port) (car port))))))
