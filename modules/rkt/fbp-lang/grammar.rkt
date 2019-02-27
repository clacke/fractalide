#lang brag

graph: NL* internal-path* final-path NL*
mesg: STRING
bare-node: IDENTIFIER
component-node: IDENTIFIER "(" IDENTIFIER ")"
node: bare-node
| component-node
plain-port: IDENTIFIER
array-port: IDENTIFIER "[" IDENTIFIER "]"
port: plain-port
| array-port
edge: port ARROW NL* port
internal-path: component-node ( "," | NL )
| path-steps ( "," | NL )
final-path: component-node ";"
| path-steps ";"
path-steps: ( mesg | node port ) ARROW NL* port node ( edge node )*
