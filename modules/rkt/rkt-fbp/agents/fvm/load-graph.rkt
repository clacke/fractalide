#lang racket/base

(require racket/async-channel)
(require racket/function)
(require racket/future)
(require racket/list)
(require racket/match)

(require fractalide/modules/rkt/rkt-fbp/agent)
(require fractalide/modules/rkt/rkt-fbp/graph)

(define (graph-set-agent g a)
  (struct-copy graph g [agent a]))

(define (graph-insert-agent g a)
  (graph-set-agent g (cons a (graph-agent g))))

; (- (Listof agent) graph String graph)
(define (flat-graph actual-graph input output)
  (define ch (make-async-channel))

  (define (query-response port query)
    (define rch (make-async-channel))
    (async-channel-put ch (vector port query rch))
    (async-channel-get rch))

  (define port-manager (thread (lambda ()
    (let loop ()
      (define msg (async-channel-get ch))
      (unless (eq? msg 'stop)
        (match-define (vector port query rch) msg)
        (send (output port) query)
        (async-channel-put rch (recv (input port)))
        (loop))))))

  (define (get-graph agent)
    (query-response "ask-graph" agent))

  (define (ask-path node)
    (query-response "ask-path" node))

  (define (resolve-node node)
    (define maybe-subgraph (get-graph node))
    (if maybe-subgraph (resolve-subgraph maybe-subgraph) (resolve-agent node)))

  (define (lazy-resolve-node node)
    (future (lambda () (resolve-node node))))

  (define (resolve-agent agent)
    (vector '() (graph (list agent) '() '() '() '())))

  (define (resolve-subgraph subgraph)
    (vector (graph-agent subgraph) (graph-set-agent subgraph '())))

  (define (rec-flat-graph not-visited current-graph)
    (cond
      [(empty? not-visited) current-graph] ; done!
      [else
       (define nodes (map ask-path not-visited))
       (define todo (map resolve-node nodes))

       (define next-not-visited (append* (reverse (map (lambda (v) (vector-ref v 0)) todo))))
       (define graph-additions (map (lambda (v) (vector-ref v 1)) todo))

       (define next-graph (graph
         (append* (append (reverse (map graph-agent graph-additions))
                          (list (graph-agent current-graph))))
         (append* (append (reverse (map graph-edge graph-additions))
                          (list (graph-edge current-graph))))

         ; for virtual ports, order is important for recursive resolution
         ; existing ports need to come first

         (append* (graph-virtual-in current-graph)
                  (map graph-virtual-in graph-additions))
         (append* (graph-virtual-out current-graph)
                  (map graph-virtual-out graph-additions))

         (append* (append (reverse (map graph-mesg graph-additions))
                          (list (graph-mesg current-graph))))))

       (rec-flat-graph next-not-visited next-graph)]))

  (define flat (rec-flat-graph (graph-agent actual-graph) (struct-copy graph actual-graph [agent '()])))
  (async-channel-put ch 'stop)
  flat)

(define-agent
  #:input '("in" "ask-path" "ask-graph")
  #:output '("out" "ask-path" "ask-graph")
   (let* ([msg (recv (input "in"))])
     (define flat (flat-graph msg input output))
     (send (output "out") flat)))
