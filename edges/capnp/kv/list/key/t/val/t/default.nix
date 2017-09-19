{ edge, edges }:

edge.capnp {
  src = ./.;
  edges =  with edges.capnp; [ KvKeyTValT ];
  schema = with edges.capnp; ''
    struct KvListKeyTValT {
      list @0 : List(KvKeyTValT);
    }
  '';
}
