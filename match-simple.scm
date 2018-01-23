;; A temporary test file, based on code from:
;; http://synthcode.com/scheme/match-simple.scm
(import (scheme base) (scheme write))

(define-syntax match
  (syntax-rules ()
    ((match expr (pat . body) ...)
     (match-gen-labels expr start () (pat . body) ...))))

(define-syntax match-gen-labels
  (syntax-rules (=>)
    ((_ expr label ((k1 fk1 pat1 . body1) (k fk pat . body) ...))
     (let ((tmp expr))
       (letrec ((k (lambda () (match-one tmp pat (begin . body) (fk)))) ...
                (label (lambda () (error "no matches" tmp))))
         (match-one tmp pat1 (begin . body1) (fk1)))))
    ((_ expr label (labels ...) (pat (=> fk) . body) . rest)
     (match-gen-labels expr fk (labels ... (label fk pat . body)) . rest))
    ((_ expr label (labels ...) (pat . body) . rest)
     (match-gen-labels expr fail (labels ... (label fail pat . body)) . rest))
    ))

(define-syntax match-one
  (syntax-rules (_ ___ quote ? and or not)
    ((match-one var () sk fk)
     (if (null? var) sk fk))
    ((match-one var (quote a) sk fk)
     (if (equal? var 'a) sk fk))
    ((match-one var (and) sk fk) sk)
    ((match-one var (and a b ...) sk fk)
     (match-one var a (match-one var (and b ...) sk fk) fk))
    ((match-one var (or) sk fk) fk)
    ((match-one var (or a ...) sk fk)
     (let ((sk2 (lambda () sk)))
       (match-one var (not (and (not a) ...)) (sk2) fk)))
    ((match-one var (not a) sk fk)
     (match-one var a fk sk))
    ((match-one var (? pred a ...) sk fk)
     (if (pred var) (match-one var (and a ...) sk fk) fk))
    ((match-one var (a ___) sk fk)
     (match-extract-variables a (match-gen-ellipses var a sk fk) ()))
    ((match-one var (a) sk fk)
     (if (and (pair? var) (null? (cdr var)))
       (let ((tmp (car var)))
         (match-one tmp a sk fk))
       fk))
    ((match-one var (a . b) sk fk)
     (if (pair? var)
       (let ((tmp1 (car var)))
         (match-one tmp1 a (let ((tmp2 (cdr var))) (match-one tmp2 b sk fk)) fk))
       fk))
    ((match-one var #(a ...) sk fk)
     (if (vector? var)
       (let ((ls (vector->list var)))
         (match-one ls (a ...) sk fk))
       fk))
    ((match-one var _ sk fk) sk)
    ((match-one var x sk fk)
     (let-syntax ((sym?
                   (syntax-rules ()
                     ((sym? x) (let ((x var)) sk))
                     ((sym? y) (if (equal? var x) sk fk)))))
       (sym? abracadabra)))  ; thanks Oleg
    ))

(define-syntax match-gen-ellipses
  (syntax-rules ()
    ((_ var a sk fk ((v v-ls) ...))
     (let loop ((ls var) (v-ls '()) ...)
       (cond ((null? ls)
              (let ((v (reverse v-ls)) ...) sk))
             ((pair? ls)
              (let ((x (car ls)))
                (match-one x a (loop (cdr ls) (cons v v-ls) ...) fk)))
             (else
              fk))))
    ))

(define-syntax match-extract-variables
  (syntax-rules (_ ___ quote ? and or not)
    ((_ (a . b) k v)
     (match-extract-variables a (match-extract-variables-step b k v) ()))
    ((_ #(a ...) k v)
     (match-extract-variables (a ...) k v))
    ((_ a (k ...) (v ...))
     (let-syntax ((sym?
                   (syntax-rules ()
                     ((sym? a) (k ... (v ... (a a-ls))))
                     ((sym? b) (k ... (v ...))))))
       (sym? abracadabra)))
    ))

(define-syntax match-extract-variables-step
  (syntax-rules ()
    ((_ a k (v ...) (v2 ...))
     (match-extract-variables a k (v ... v2 ...)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; gimme some sugar baby

(define-syntax match-lambda
  (syntax-rules ()
    ((_ clause ...) (lambda (expr) (match expr clause ...)))))

;(define-syntax match-lambda*
;  (syntax-rules ()
;    ((_ clause ...) (lambda expr (match expr clause ...)))))
;
;(define-syntax match-let
;  (syntax-rules ()
;    ((_ ((pat expr)) . body)
;     (match expr (pat . body)))
;    ((_ ((pat expr) ...) . body)
;     (match (list expr ...) ((pat ...) . body)))
;    ((_ loop . rest)
;     (match-named-let loop () . rest))
;    ))
;
;(define-syntax match-named-let
;  (syntax-rules ()
;    ((_ loop ((pat expr var) ...) () . body)
;     (let loop ((var expr) ...)
;       (match-let ((pat var) ...)
;         . body)))
;    ((_ loop (v ...) ((pat expr) . rest) . body)
;     (match-named-let loop (v ... (pat expr tmp)) rest . body))
;    ))
;
;(define-syntax match-letrec
;  (syntax-rules ()
;    ((_ vars . body) (match-letrec-helper () vars . body))))
;
;(define-syntax match-letrec-helper
;  (syntax-rules ()
;    ((_ ((pat expr var) ...) () . body)
;     (letrec ((var expr) ...)
;       (match-let ((pat var) ...)
;         . body)))
;    ((_ (v ...) ((pat expr) . rest) . body)
;     (match-letrec-helper (v ... (pat expr tmp)) rest . body))
;    ))
;
;(define-syntax match-let*
;  (syntax-rules ()
;    ((_ () . body)
;     (begin . body))
;    ((_ ((pat expr) . rest) . body)
;     (match expr (pat (match-let* rest . body))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; match-simple ends, this is the unit test section:

;(define tst
;  (match-lambda
;     ((a b) (vector 'fromlist a b))
;     ((? string? x) x)
;     ((X #f))))
;
;(display (match (list 1 2 3) ((a b c) b)))
;(display (tst '(1 2)))
;(display (tst "gehtdurch"))
;(display (tst 42))

;(display (match-one '(a . b) (? pair? x) 1 0))
(display (match 
           "test"
           ;'(c . d) ;;"test" 
           ;((? pair? x) x)
           ((? string? x) x)
           (_ 'no-match)
          ))

 ;; Expanded version of above, what is going on?
 (display
   ((lambda (tmp$1539$1543)
      ((lambda (fail$1534$1545 fail$1537$1544)
         (set! fail$1534$1545 (lambda () 'no-match))
         (set! fail$1537$1544
           (lambda () (error "no matches" tmp$1539$1543)))
         (if (string? tmp$1539$1543)
           (if (pair? tmp$1539$1543)
             ((lambda (tmp1$1558$1559)
                ((lambda (abracadabra$1561$1612)
                   ((lambda (tmp2$1555$1608$1613)
                      (if (if (pair? tmp2$1555$1608$1613)
                            (null? (cdr tmp2$1555$1608$1613))
                            #f)
                        ((lambda (tmp$1617$1621)
                           ((lambda (abracadabra$1623$1670)
                              abracadabra$1623$1670)
                            tmp$1617$1621))
                         (car tmp2$1555$1608$1613))
                        (fail$1534$1545)))
                    (cdr tmp$1539$1543)))
                 tmp1$1558$1559))
              (car tmp$1539$1543))
             (fail$1534$1545))
           (fail$1534$1545)))
       #f
       #f))
    "test"))