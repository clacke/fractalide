#lang racket

(require br-parser-tools/lex)
(require brag/support)

(provide tokenize)

(define (tokenize ip)
  (define lexer (lexer-src-pos
    ["\n"
     (token 'LN lexeme)]
    [(repetition 1 +inf.0 blank)
     (token 'BLANK lexeme)]
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
     (token 'IDENTIFIER lexeme)]))

  (port-count-lines! ip)
  (define (next-token) (lexer ip))
  next-token)

