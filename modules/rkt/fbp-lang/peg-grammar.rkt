#lang peg

graph <-- _ NL? internal-path* _ final-path NL? _;
mesg <-- STRING;
node <-- component-node / bare-node;
bare-node <-- IDENTIFIER;
component-node <-- IDENTIFIER component;
component <-- LEFTPAREN IDENTIFIER RIGHTPAREN;
plain-port <-- IDENTIFIER;
array-port <-- IDENTIFIER array-index;
array-index <-- LEFTBRACKET IDENTIFIER RIGHTBRACKET;
port <--  array-port / plain-port;
edge <-- port _ ARROW _ NL? port;
internal-path <-- ( path-steps / component-node _ ) ( ',' / NL );
final-path <-- ( path-steps / component-node _ ) ';';
path-steps <-- ( mesg / node _ port ) _ ARROW _ NL? port _ node _ ( edge _ node _ )*;
_ < [ \t]*;
NL <- ( [\n] _ )+;
STRING <- ['] [^'\n]* ['];
IDENTIFIER <- ( [0-9a-zA-Z/] / '-' )*;
LEFTPAREN < '(';
RIGHTPAREN < ')';
LEFTBRACKET < '[';
RIGHTBRACKET < ']';
ARROW < '->';
