;;; p-diff -- rate Sudoku puzzle difficulty by solving with human techniques.
;;;
;;; usage: p-diff [FILE ...]
;;; Reads one 81-character puzzle per line from each FILE, or from standard
;;; input when no FILE is given or FILE is "-", and prints one tab-separated
;;; report line per puzzle.  See README.md for the formats.
(import (scheme process-context) (scheme file)
        (p-diff grid) (p-diff solver) (p-diff rating))

(define usage-text
  "usage: p-diff [FILE ...]

Rate the difficulty of Sudoku puzzles by solving them with human techniques.

Each input line is one puzzle: 81 characters, digits 1-9 for givens and
0 or . for empty cells.  Blank lines and lines starting with # are skipped.
Puzzles are read from each FILE in order, or from standard input when no
FILE is given or FILE is -.

Output is one line per puzzle, tab-separated:
  LINE  LEVEL  HARDEST-TECHNIQUE  TECHNIQUE=COUNT ...
LEVEL is Easy, Medium, Hard, Expert, Unsolved, or Invalid.

Exit status: 0 all puzzles valid, 1 some puzzle invalid, 2 usage or file error.

options:
  --help    print this message and exit
")

(define (usage-error)
  (display usage-text (current-error-port))
  (exit 2))

(define (option? arg)
  (and (> (string-length arg) 1) (char=? #\- (string-ref arg 0))))

(define (skip-line? trimmed)
  (or (= 0 (string-length trimmed))
      (char=? #\# (string-ref trimmed 0))))

;; Rate one line.  Returns #t when the line was invalid.
(define (rate-line! line-number line)
  (let ((values (parse-puzzle line)))
    (define (invalid! reason)
      (display (invalid-line line-number reason))
      (newline)
      #t)
    (cond ((eq? values 'bad-format) (invalid! 'bad-format))
          ((conflicting-givens? values) (invalid! 'conflicting-givens))
          (else
           (let ((r (solve values)))
             (if (eq? 'no-solution (result-status r))
                 (invalid! 'no-solution)
                 (begin (display (report-line line-number r))
                        (newline)
                        #f)))))))

;; Rate every line from port.  Line numbers start at 1 for each input and
;; count skipped lines.  Returns #t if any line was invalid.
(define (rate-port port)
  ;; Emit 0.6.0: read-line needs an explicit port argument.
  (let loop ((n 1) (any-invalid #f))
    (let ((line (read-line port)))
      (if (eof-object? line)
          any-invalid
          (loop (+ n 1)
                (if (skip-line? (trim-string line))
                    any-invalid
                    (or (rate-line! n line) any-invalid)))))))

(define (main args)
  (when (member "--help" args)
    (display usage-text)
    (exit 0))
  (for-each (lambda (a) (when (option? a) (usage-error))) args)
  (let ((inputs (if (null? args) '("-") args)))
    (for-each (lambda (f)
                (unless (or (string=? f "-") (file-exists? f))
                  (display (string-append "p-diff: cannot read file: " f)
                           (current-error-port))
                  (newline (current-error-port))
                  (exit 2)))
              inputs)
    (let loop ((fs inputs) (any-invalid #f))
      (if (null? fs)
          (exit (if any-invalid 1 0))
          (let ((invalid
                 (if (string=? (car fs) "-")
                     (rate-port (current-input-port))
                     (call-with-input-file (car fs) rate-port))))
            (loop (cdr fs) (or invalid any-invalid)))))))

(main (cdr (command-line)))
