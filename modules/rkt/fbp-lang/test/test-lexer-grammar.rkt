#lang racket

(module+ test
  (require
    rackunit
    "../lexer.rkt"
    "../grammar.rkt")

  (define (parse-string s)
    (parse (lex (open-input-string s))))

  (test-case "agent only"
    (parse-string "asdf(qwer);")
    (void)))
