{ edge, edges }:

edge.capnp {
  src = ./.;
  edges =  with edges.capnp; [ ];
  schema = with edges.capnp; ''
    struct CoreLexical {
      union {
        start @0 :Text;
        end @1 :Text;
        notFound @2 :Text;
        token :union {
          bind @3 :Void;
          external @4 :Void;
          comp :group {
            name @5 :Text;
            sort @6 :Text;
          }
          port :group {
            name @7 :Text;
            selection @8 :Text;
          }
          imsg @9 :Text;
          break @10 :Void;
        }
      }
    }
  '';
}
