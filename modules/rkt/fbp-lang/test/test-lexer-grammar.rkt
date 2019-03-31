#lang racket

(module+ test
  (require
    rackunit
    "../grammar.rkt"
    "../lexer.rkt"
)

  (define (parse-string s)
    (parse (lex (open-input-string s))))

  (test-case "agent only"
    (parse-string "asdf(qwer);")
    (void))

  (test-case "message only"
    (check-exn
      exn:fail?
      (lambda ()
        (parse-string "'asdf';"))))

  (test-case "simple chain"
    (parse-string "asdf out -> in qwer;")
    (void))

  (test-case "component chain"
    (parse-string "asdf(foo) out -> in qwer(bar);")
    (void))

  (test-case "mixed chain"
    (parse-string "asdf(foo) out -> in zxvc out -> in qwer(bar);")
    (void))

  (test-case "diamond chain"
    (parse-string "foo l -> in left out -> l bar, foo r -> in right out -> r bar;")
    (void))

  (test-case "array ports"
    (parse-string "foo out[l] -> in left out -> in[l] bar, foo out[r] -> in right out -> in[r] bar;")
    (void))
)
