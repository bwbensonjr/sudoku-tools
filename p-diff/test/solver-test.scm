;;; Tests for (p-diff solver).  Run from p-diff/: emit run test/solver-test.scm
;;;
;;; Each puzzle below has a unique solution, checked with an independent
;;; brute-force search; the solution strings come from that search.
(import (scheme process-context) (srfi 64)
        (p-diff grid) (p-diff techniques) (p-diff solver))

(define (solve-line line) (solve (parse-puzzle line)))

(define (technique-set r) (map car (result-counts r)))

;; (puzzle . solution) pairs for puzzles the solver completes.
(define solvable
  '(("530070000600195000098000060800060003400803001700020006060000280000419005000080079"
     . "534678912672195348198342567859761423426853791713924856961537284287419635345286179")
    ("003020600900305001001806400008102900700000008006708200002609500800203009005010300"
     . "483921657967345821251876493548132976729564138136798245372689514814253769695417382")
    ("4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......"
     . "417369825632158947958724316825437169791586432346912758289643571573291684164875293")
    ("400000938032094100095300240370609004529001673604703090957008300003900400240030709"
     . "461572938732894156895316247378629514529481673614753892957248361183967425246135789")
    ("000000000231090000065003100008924000100050006000136700009300570000010843000000000"
     . "894571632231698457765243198678924315143857926952136784489362571526719843317485269")
    ("8....3.....36......7..9.2...5...7...3...457.....1...3...1....68..85...1..9....4.."
     . "812753649943682175675491283154237896369845721287169534521974368438526917796318452")
    ("100000569492056108056109240009640801064010000218035604040500016905061402621000005"
     . "187423569492756138356189247539647821764218953218935674843592716975361482621874395")
    ("000000094760910050390002081070050010000709000080030060240100070010090045900000100"
     . "125683794768914352394572681472856913631749528589231467243165879816397245957428136")))

;; Inkala's puzzle: unique, but needs techniques beyond X-Wing.
(define inkala
  "8..........36......7..9.2...5...7.......457.....1...3...1....68..85...1..9....4..")
(define inkala-solution
  "812753649943682175675491283154237896369845721287169534521974368438526917796318452")

(define (agrees-with-solution? s solution)
  ;; Every placed digit matches the solution.
  (let loop ((c 0))
    (or (= c 81)
        (let ((v (value-of s c)))
          (and (or (= v 0) (= v (char->digit (string-ref solution c))))
               (loop (+ c 1)))))))

(test-begin "solver")

;; 4.1 simplest-first loop
(let ((r (solve-line (car (car solvable)))))
  (test-equal "classic puzzle solves" 'solved (result-status r))
  (test-equal "classic puzzle needs only singles" '(naked-single) (technique-set r))
  (test-equal "classic puzzle naked-single count" 51 (cdr (assq 'naked-single (result-counts r)))))
(test-equal "counts are in technique order"
  '(naked-single hidden-single pointing hidden-pair naked-triple)
  (technique-set (solve-line "000000000231090000065003100008924000100050006000136700009300570000010843000000000")))
(let ((s (initial-state (parse-puzzle (make-string 81 #\.)))))
  (apply-step! s (make-step 'naked-single '((0 . 5)) '()))
  (test-equal "apply-step places digit" 5 (value-of s 0))
  (test-assert "apply-step propagates to column peer" (not (memv 5 (candidates-of s 72))))
  (test-assert "apply-step propagates to row peer" (not (memv 5 (candidates-of s 8))))
  (apply-step! s (make-step 'pointing '() '((40 . 3))))
  (test-assert "apply-step removes candidate" (not (memv 3 (candidates-of s 40)))))

;; 4.2 contradictions
(define no-solution
  (string-append "123456780" "000000009" (make-string 63 #\0)))
(test-assert "no-solution givens do not conflict directly"
  (not (conflicting-givens? (parse-puzzle no-solution))))
(test-equal "cell with no candidates is no-solution"
  'no-solution (result-status (solve-line no-solution)))
(let ((s (initial-state (parse-puzzle (make-string 81 #\.)))))
  (for-each (lambda (c) (remove-candidate! s c 4)) '(0 1 2 3 4 5 6 7 8))
  (test-assert "digit with no place in a row is a contradiction" (contradiction? s)))
(test-assert "fresh puzzle is not a contradiction"
  (not (contradiction? (initial-state (parse-puzzle (car (car solvable)))))))

;; 4.3 unsolved results
(let ((r (solve-line inkala)))
  (test-equal "Inkala puzzle is unsolved" 'unsolved (result-status r))
  (test-equal "Inkala puzzle remaining cells" 60 (result-remaining r))
  (test-equal "Inkala puzzle applies no technique" '() (result-counts r))
  (test-assert "Inkala placements agree with solution"
    (agrees-with-solution? (result-state r) inkala-solution)))
(let ((r (solve-line "017903600000080000900000507072010430000402070064370250701000065000030000005601720")))
  (test-equal "partially solved puzzle is unsolved" 'unsolved (result-status r))
  (test-equal "partially solved remaining" 45 (result-remaining r))
  (test-assert "partial placements agree with solution"
    (agrees-with-solution?
     (result-state r)
     "417953682256187943983246517872519436539462871164378259791824365628735194345691728")))
(let ((r (solve-line (make-string 81 #\.))))
  (test-equal "empty grid has many solutions and stays unsolved" 'unsolved (result-status r))
  (test-equal "empty grid places nothing" 81 (result-remaining r)))

;; 4.4 soundness on every solvable fixture
(for-each
 (lambda (entry)
   (let* ((givens (parse-puzzle (car entry)))
          (r (solve givens)))
     (test-equal (string-append "solves " (car entry)) 'solved (result-status r))
     (test-assert (string-append "valid grid " (car entry))
       (solved-grid-valid? (result-state r) givens))
     (test-assert (string-append "matches solution " (car entry))
       (agrees-with-solution? (result-state r) (cdr entry)))))
 solvable)
(let* ((givens (parse-puzzle (car (car solvable))))
       (r (solve givens))
       (s (state-copy (result-state r))))
  (vector-set! (state-values s) 0 (if (= 5 (value-of s 0)) 6 5))
  (test-assert "validity check catches a changed cell" (not (solved-grid-valid? s givens))))

(let ((fails (test-runner-fail-count (test-runner-current))))
  (test-end "solver")
  (exit (if (= fails 0) 0 1)))
