#lang racket/base

(require racket/async-channel)
(require racket/future)
(require racket/list)
(require racket/match)

(require fractalide/modules/rkt/rkt-fbp/agent)
(require fractalide/modules/rkt/rkt-fbp/loader)
(require fractalide/modules/rkt/rkt-fbp/graph)

; (- (Listof agent) graph String graph)
(define (flat-graph actual-graph input output)
  (define ch (make-async-channel))
  (define (get-graph agent . _)
    (define rch (make-async-channel))
    (define (put msg) (async-channel-put ch (cons msg rch)))
    (define (get) (async-channel-get rch))

    (put agent)
    (get))
  (define graph-getter (thread (lambda ()
    (let loop ()
      (define msg (async-channel-get ch))
      (unless (eq? msg 'stop)
        (match-define (cons agent rch) msg)
        (send (output "ask-graph") agent)
        (async-channel-put rch (recv (input "ask-graph")))
        (loop))))))

  (define (rec-flat-graph not-visited actual-graph)
    (if (empty? not-visited)
        ; True -> End of the flat part
        actual-graph
        ; False -> Visit the next node
        (let* ([next (car not-visited)]
               [next (begin (send (output "ask-path") next) (recv (input "ask-path")))]
               [is-subnet? (load-graph (g-agent-type next) (lambda () #f))])
          (if is-subnet?
              ; It's a sub-graph. Get the new graph, add the nodes in not-visited, save the virtual port and save the rest of the graph
              (let* ([new-graph (get-graph next input output)]
                     ; Add the agents in the not-visited list
                     [new-not-visited (append (graph-agent new-graph) (cdr not-visited))]
                     ; add the virtual port
                     ; Order is important, we need to save first virtual first, for reccursive array port
                     [new-virtual-in (append (graph-virtual-in actual-graph) (graph-virtual-in new-graph))]
                     [new-virtual-out (append (graph-virtual-out actual-graph) (graph-virtual-out new-graph))]
                     ; add the mesgs
                     [new-mesg (append (graph-mesg new-graph) (graph-mesg actual-graph))]
                     ; add the edges
                     [new-edge (append (graph-edge new-graph) (graph-edge actual-graph))])
                (rec-flat-graph new-not-visited
                                (struct-copy graph actual-graph [mesg new-mesg]
                                             [edge new-edge]
                                             [virtual-in new-virtual-in]
                                             [virtual-out new-virtual-out])))
              ; It's a normal agent, do nothing and go for the next
              (rec-flat-graph (cdr not-visited) (struct-copy graph actual-graph [agent (cons next (graph-agent actual-graph))]))))))
  (define the-graph (rec-flat-graph (graph-agent actual-graph) (struct-copy graph actual-graph [agent '()])))
  (async-channel-put ch 'stop)
  the-graph)

(define-agent
  #:input '("in" "ask-path" "ask-graph")
  #:output '("out" "ask-path" "ask-graph")
   (let* ([msg (recv (input "in"))])
     (define flat (flat-graph msg input output))
     (send (output "out") flat)))
