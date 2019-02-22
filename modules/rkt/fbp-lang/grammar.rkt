#lang brag

mesg: STRING
node: bare-node
| component-node
bare-node: IDENTIFIER
component-node: IDENTIFIER "(" IDENTIFIER ")"
port: plain-port
| array-port
plain-port: IDENTIFIER
array-port: IDENTIFIER "[" IDENTIFIER "]"
edge: port "->" NL* port
internal-path: component-node ( "," | NL )
| path-steps ( "," | NL )
final-path: component-node ( ";" | END )
| path-steps ( ";" | END)
path-steps: ( mesg | node port ) "->" NL* port node ( edge node )*
graph: internal-path* final-path
