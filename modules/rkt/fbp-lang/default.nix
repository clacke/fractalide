{ pkgs ? (import ../../.. {}).pkgs
, buildRacketPackage ? racket2nix.buildRacketPackage
, racket2nix ? pkgs.racket2nix
}:

buildRacketPackage (builtins.path {
  name = "fbp-lang";
  path = ./.;
  filter = (path: type:
    type != "symlink"
  );
})
