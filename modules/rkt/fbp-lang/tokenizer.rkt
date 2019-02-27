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
     (token 'ARROW lexeme)]
    ["("
     (token "(" lexeme)]
    [")"
     (token ")" lexeme)]
    [(concatenation "'" (repetition 1 +inf.0 (char-complement (union "'" "\n"))) "'")
     (token 'STRING lexeme)]
    [(repetition 1 +inf.0 (union numeric alphabetic "-" "/"))
     (token 'IDENTIFIER lexeme)]))

  (port-count-lines! ip)
  (define (next-token) (lexer ip))
  next-token)

