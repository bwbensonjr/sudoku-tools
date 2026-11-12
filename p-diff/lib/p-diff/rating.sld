;;; (p-diff rating) -- difficulty levels and report lines.
(define-library (p-diff rating)
  (import (scheme base) (p-diff techniques) (p-diff solver))
  (export level-table technique-level hardest-technique result-level
          report-line invalid-line)
  (begin
    ;; Technique name -> level.  Must name the same techniques as
    ;; technique-table, which test/rating-test.scm checks.
    (define level-table
      '((naked-single . "Easy")
        (hidden-single . "Easy")
        (pointing . "Medium")
        (box-line . "Medium")
        (naked-pair . "Medium")
        (hidden-pair . "Medium")
        (naked-triple . "Hard")
        (hidden-triple . "Hard")
        (x-wing . "Expert")))

    (define (technique-level name) (cdr (assq name level-table)))

    ;; counts are in technique order, simplest first, so the hardest
    ;; technique applied is the last one listed.  #f when none was applied.
    (define (hardest-technique counts)
      (if (null? counts)
          #f
          (car (list-ref counts (- (length counts) 1)))))

    ;; "Easy" through "Expert" for a solved result, "Unsolved" otherwise.
    ;; A solved puzzle with no technique applied had no empty cells.
    (define (result-level r)
      (if (eq? 'solved (result-status r))
          (let ((h (hardest-technique (result-counts r))))
            (if h (technique-level h) "Easy"))
          "Unsolved"))

    (define (join strs sep)
      (if (null? strs)
          ""
          (let loop ((acc (car strs)) (rest (cdr strs)))
            (if (null? rest)
                acc
                (loop (string-append acc sep (car rest)) (cdr rest))))))

    (define tab (string #\tab))

    (define (count-field r)
      (join (append
             (map (lambda (p)
                    (string-append (symbol->string (car p)) "="
                                   (number->string (cdr p))))
                  (result-counts r))
             (if (eq? 'unsolved (result-status r))
                 (list (string-append "remaining="
                                      (number->string (result-remaining r))))
                 '()))
            " "))

    ;; Report line for a solved or unsolved result (no trailing newline).
    (define (report-line line-number r)
      (let ((h (hardest-technique (result-counts r))))
        (join (list (number->string line-number)
                    (result-level r)
                    (if h (symbol->string h) "-")
                    (count-field r))
              tab)))

    ;; Report line for an invalid puzzle; reason is a symbol.
    (define (invalid-line line-number reason)
      (join (list (number->string line-number) "Invalid" "-"
                  (symbol->string reason))
            tab))))
