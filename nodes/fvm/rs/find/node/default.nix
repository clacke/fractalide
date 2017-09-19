{ support, edges, mods, pkgs }:

support.node.rs.agent {
  src = ./.;
  edges = with edges.capnp; [ FsPath FsPathOption ];
  mods = with mods.rs; [ rustfbp capnp ];
  osdeps = with pkgs; [ nix ];
}
