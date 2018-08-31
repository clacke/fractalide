#lang racket/base

(require racket/async-channel)
(require racket/future)
(require racket/list)
(require racket/match)

(require fractalide/modules/rkt/rkt-fbp/agent)
(require fractalide/modules/rkt/rkt-fbp/loader)
(require fractalide/modules/rkt/rkt-fbp/graph)

(define (graph-set-agent g a)
  (struct-copy graph g [agent a]))

(define (graph-insert-agent g a)
  (graph-set-agent g (cons a (graph-agent g))))

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
  (define (ask-path node)
    (send (output "ask-path") node)
    (recv (input "ask-path")))

  (define (rec-flat-graph not-visited actual-graph)
    (cond
      [(empty? not-visited) actual-graph] ; done!
      [else
       (define next-node (car not-visited))
       (define next-agent (ask-path next-node))
       (define maybe-subnet (load-graph (g-agent-type next-agent) (lambda () #f)))
       (cond
        [(not maybe-subnet)
         (rec-flat-graph (cdr not-visited) (graph-insert-agent actual-graph next-agent))]
        [else ; It's a sub-graph. Get the new graph, add the nodes in not-visited,
              ; save the virtual port and save the rest of the graph
         (define new-graph (get-graph next-agent))
         ; Add the agents in the not-visited list
         (define new-not-visited (append (graph-agent new-graph) (cdr not-visited)))
         ; add the virtual port
         ; Order is important, we need to save first virtual first, for reccursive array port
         (define new-virtual-in (append (graph-virtual-in actual-graph) (graph-virtual-in new-graph)))
         (define new-virtual-out (append (graph-virtual-out actual-graph) (graph-virtual-out new-graph)))
         ; add the mesgs
         (define new-mesg (append (graph-mesg new-graph) (graph-mesg actual-graph)))
         ; add the edges
         (define new-edge (append (graph-edge new-graph) (graph-edge actual-graph)))
         (rec-flat-graph new-not-visited (struct-copy graph actual-graph
           [mesg new-mesg] [edge new-edge] [virtual-in new-virtual-in] [virtual-out new-virtual-out]))])]))

  (define flat (rec-flat-graph (graph-agent actual-graph) (struct-copy graph actual-graph [agent '()])))
  (async-channel-put ch 'stop)
  flat)

(define-agent
  #:input '("in" "ask-path" "ask-graph")
  #:output '("out" "ask-path" "ask-graph")
   (let* ([msg (recv (input "in"))])
     (define flat (flat-graph msg input output))
     (send (output "out") flat)))
