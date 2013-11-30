;; project 2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; problem 1: extract entry function
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (extract-entry play game)
  (if (equal? (caar game) play)
    (car game)
    (extract-entry play (cdr game))))

; test problem 1:
(define a-play (make-play "c" "d"))
(extract-entry a-play *game-association-list*)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; problem 2: performance of different strategies
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; patsy vs. eye-for-eye
(play-loop PATSY EYE-FOR-EYE)
; score:    3        3

; patsy vs. nasty
(play-loop PATSY NASTY)
; score:    0      5

; nasty vs. eye-for-eye
(play-loop NASTY EYE-FOR-EYE)
; score:   1.04    .99 

; nasty vs. eye-for-eye
(play-loop NASTY EYE-FOR-EYE)
; score:   1.04    .99 

; egalitarian vs. eye-for-eye
(play-loop EGALITARIAN EYE-FOR-EYE)
; score:      3             3

; egalitarian vs. nasty
(play-loop EGALITARIAN NASTY)
; score:       .99      1.04

; eye-for-eye vs. patsy
(play-loop EYE-FOR-EYE PATSY)
; score:      3          3

; eye-for-eye vs. spastic
(play-loop EYE-FOR-EYE SPASTIC)
; score:      2.23       2.28

; results: different strategies result in significantly
; different scores. the nasty strategy tends to result
; in relatively low scores for both players, except against
; the naive patsy strategy.  the eye-for-eye strategy does
; perform quite well, seemingly because it allows cooperation
; when the other strategy permits but does not allow defection
; to go unpunished.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; problem 3: performance of egalitarian strategy
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; the egalitarian strategy is slower to compute compared to the
; others because it is O(number of games) while the others are
; O(1).  the revised definition of egalitarian in the project 
; handout is the same order of growth as the original definition
; since it must iterate through the entire history of games to
; compute the correct play.  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; problem 4: eye-for-two-eyes strategy
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (EYE-FOR-TWO-EYES my-history other-history)
  (cond ((empty-history? my-history) "c")
        ((empty-history? (rest-of-plays my-history)) "c")
        ((and (equal? (most-recent-play other-history) "d")
              (equal? (most-recent-play (rest-of-plays my-history)) "d")) "d")
        (else "c")))

(test-equal (EYE-FOR-TWO-EYES '() '()) "c")
(test-equal (EYE-FOR-TWO-EYES '("c") '("c")) "c")
(test-equal (EYE-FOR-TWO-EYES '("c") '("c")) "c")
(test-equal (EYE-FOR-TWO-EYES '("d" "d") '("d" "d")) "d")
(test-equal (EYE-FOR-TWO-EYES '("d" "d") '("c" "d")) "c")
(test-equal (EYE-FOR-TWO-EYES '("d" "d") '("c" "c")) "c")

