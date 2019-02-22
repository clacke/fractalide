#lang racket

(require br-parser-tools/lex)
(require brag/support)

(provide tokenize)

(define (tokenize ip)
  (define end? #f)
  (define lexer (lexer-src-pos
    ["\n"
     (token 'NL lexeme)]
    [(repetition 1 +inf.0 blank)
     (token 'BLANK #:skip? #t lexeme)]
    [";"
     (token ";" lexeme)]
    [","
     (token "," lexeme)]
    [":"
     (token ":" lexeme)]
    ["->"
     (token "->" lexeme)]
    ["("
     (token "(" lexeme)]
    [")"
     (token ")" lexeme)]
    [(concatenation "'" (repetition 1 +inf.0 (char-complement (union "'" "\n"))) "'")
     (token 'STRING lexeme)]
    [(repetition 1 +inf.0 (union numeric alphabetic "-" "/"))
     (token 'IDENTIFIER lexeme)]
    [(eof)
     (cond
       [end? 'EOF]
       [else
        (set! end? #t)
        'END])]))

  (port-count-lines! ip)
  (define (next-token) (define x (lexer ip)) (eprintf "token ~a~n" x) x)
  next-token)

