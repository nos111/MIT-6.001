;;
;; meval.scm - 6.001 Spring 2005
;; implementation of meval 
;;


(define (m-eval exp env)
  (cond ((self-evaluating? exp) exp)
        ((variable? exp) (lookup-variable-value exp env))    
        ((quoted? exp) (text-of-quotation exp))
        ((assignment? exp) (eval-assignment exp env))
        ((definition? exp) (eval-definition exp env))
        ((unset!? exp) (eval-unset! exp env))
        ((if? exp) (eval-if exp env))
        ((or? exp) (eval-or exp env))
        ((and? exp) (eval-and exp env))
        ((lambda? exp)
         (make-procedure (lambda-parameters exp) (lambda-body exp) env))
        ((begin? exp) (eval-sequence (begin-actions exp) env))
        ((cond? exp) (m-eval (cond->if exp) env))
        ((case? exp) (m-eval (case->cond exp) env))
	((let? exp) (m-eval (let->application exp) env))
	((let*? exp) (eval-let* exp env))
	((do-while? exp) (eval-do-while exp env))
        ((application? exp)
         (m-apply (m-eval (operator exp) env)
                (list-of-values (operands exp) env)))
        (else (error "Unknown expression type -- EVAL" exp))))

(define (m-apply procedure arguments)
  (cond ((primitive-procedure? procedure)
         (apply-primitive-procedure procedure arguments))
        ((compound-procedure? procedure)
         (eval-sequence
          (procedure-body procedure)
          (extend-environment (procedure-parameters procedure)
                              arguments
                              (procedure-environment procedure))))
        (else (error "Unknown procedure type -- APPLY" procedure))))

(define (list-of-values exps env)
  (cond ((no-operands? exps) '())
        (else (cons (m-eval (first-operand exps) env)
                    (list-of-values (rest-operands exps) env)))))

(define (case->cond case-expr)
  (let ((val (extract-case-val case-expr))
        (exprs (extract-case-exprs case-expr)))
    `(cond ,@(case-exprs->cond-exprs exprs val))))

(define (eval-or expr env)
  (if (no-predicates? expr)
    #f
    (let ((predicate (m-eval (first-predicate expr) env)))
      (if predicate
        predicate
        (m-eval (pop-predicate expr) env)))))

(define (eval-and expr env)
  (cond ((no-predicates? expr) #t)
        ((one-predicate? expr) (m-eval (first-predicate expr) env))
        (else (let ((predicate (m-eval (first-predicate expr) env)))
                (if predicate
                  (m-eval (pop-predicate expr) env)
                  #f)))))

(define (eval-let* expr env)
  (if (null? (let*-bound-variables expr))
    (eval-sequence (let*-expr expr) env)
    (let ((let*-env (extend-environment '() '() env)))
      (eval-var-list (let*-bound-variables expr)
                     (let*-values expr)
                     let*-env)
      (eval-sequence (let*-expr expr) let*-env))))

(define (eval-var-list vars vals env)
  (if (null? vars)
    #t
    (begin 
      (define-variable! (car vars) (m-eval (car vals) env) env)
      (eval-var-list (cdr vars) (cdr vals) env))))
      
;; do-while evaluator from problem 6 using de-sugaring
(define (eval-do-while expr env)
  (m-eval (desugar-do-while expr) env))

(define (desugar-do-while expr)
  `(begin
     ,@(do-while-exps expr)
     (if ,(do-while-predicate expr)
      ,expr
      'done)))

;; do-while evaluator from problem 3
;(define (eval-do-while expr env)
;  (eval-sequence (do-while-exps expr) env)
;  (if (m-eval (do-while-predicate expr) env)
;    (m-eval expr env)
;    'done))

(define (eval-if exp env)
  (if (m-eval (if-predicate exp) env)
      (m-eval (if-consequent exp) env)
      (m-eval (if-alternative exp) env)))

(define (eval-sequence exps env)
  (cond ((last-exp? exps) (m-eval (first-exp exps) env))
        (else (m-eval (first-exp exps) env)
              (eval-sequence (rest-exps exps) env))))

(define (eval-assignment exp env)
  (set-variable-value! (assignment-variable exp)
                       (m-eval (assignment-value exp) env)
                       env))

(define (eval-unset! expr env)
  (unset-variable-value! (unset!-variable expr) env))

(define (eval-definition exp env)
  (define-variable! (definition-variable exp)
                    (m-eval (definition-value exp) env)
                    env))

(define (let->application expr)
  (let ((names (let-bound-variables expr))
        (values (let-values expr))
        (body (let-body expr)))
    (make-application (make-lambda names body)
		      values)))

(define (cond->if expr)
  (let ((clauses (cond-clauses expr)))
    (if (null? clauses)
	#f
	(if (eq? (car (first-cond-clause clauses)) 'else)
	    (make-begin (cdr (first-cond-clause clauses)))
	    (make-if (car (first-cond-clause clauses))
		     (make-begin (cdr (first-cond-clause clauses)))
		     (make-cond (rest-cond-clauses clauses)))))))

;;;;;;;;;;;;;;;;;; Code For Problem 9 ;;;;;;;;;;;;;;;;;;;;;;

      ; type: nil -> list<symbol>
(define (no-names)              ; builds an empty free list
  (list))

      ; type: symbol -> list<symbol>
(define (single-name var)       ; builds a free list of one variable
  (list var))

      ; type: symbol, list<symbol> -> list<symbol>
(define (add-name var namelist) ; adds a variable to the list
  (if (not (memq var namelist)) ; avoiding adding duplicates
      (cons var namelist)
      namelist))

      ; type: list<symbol>, list<symbol> -> list<symbol>
(define (merge-names f1 f2)     ; if variable is free in either list
  (fold-right add-name f1 f2))  ; it's free in the result

      ; type: list<expression> -> list<symbol>
(define (used-in-sequence exps) ; this is like free-in,
  (fold-right merge-names       ; but works on a sequence of expressions
	      (no-names) 
	      (map names-used-in exps)))

      ; type: list<symbol> -> symbol
(define (fresh-symbol free)         ; computes a new symbol not occurring in free
  (fold-right symbol-append 'unused free))


; This is the procedure you need to fill out.
; Depending on the predicates which you define, you may need to change some of the 
; clauses here.

; type: expression -> list<symbol>
(define (names-used-in exp)
  (cond ((self-evaluating? exp) (no-names))
        ((variable? exp) (list exp))
        ((quoted? exp) (no-names))
        ((assignment? exp) 
	 (merge-names (names-used-in (assignment-variable exp))
		      (names-used-in (assignment-value exp))))
	((unset!? exp) (list (unset!-variable exp))) 
        ((definition? exp)
	 (merge-names (names-used-in (definition-variable exp))
		      (names-used-in (definition-value exp))))
        ((if? exp)
	 (merge-names (names-used-in (if-predicate exp))
  	   (merge-names (names-used-in (if-consequent exp))
			(names-used-in (if-alternative exp)))))
        ((lambda? exp) 
   (merge-names (names-used-in (lambda-parameters exp))
                (names-used-in (lambda-body exp))))
        ((begin? exp) (used-in-sequence (cdr exp)))
        ((cond? exp) (names-used-in (cond->if exp)))
	((let? exp) (names-used-in (let->application exp)))
  ((let*? exp) 
	 (merge-names (names-used-in (let*-bound-variables exp))
  	   (merge-names (names-used-in (let*-values exp))
			(names-used-in (let*-expr exp)))))
	((and? exp) (names-used-in (and-body exp)))
	((or? exp) (names-used-in (or-body exp)))
	((do-while? exp)
   (merge-names (names-used-in (do-while-predicate exp))
                (names-used-in (do-while-exps exp))))
	((case? exp) (names-used-in (case->cond exp)))
        ((application? exp)
	 (merge-names (names-used-in (operator exp))
		      (used-in-sequence (operands exp))))
        (else (error "Unknown expression type -- NAMES-USED-IN" exp))))
