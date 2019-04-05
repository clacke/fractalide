{ pkgs ? (import ../../.. {}).pkgs
, buildThinRacketPackage ? racket2nix.buildThinRacketPackage
, racket2nix ? pkgs.racket2nix
, coreutils ? pkgs.coreutils
, findutils ? pkgs.findutils
, time ? pkgs.time
}:

let drv = (buildThinRacketPackage (builtins.path {
  name = "fbp-lang";
  path = ./.;
  filter = (path: type:
    type != "symlink"
  );
})
).overrideRacketDerivation (oldAttrs: { doInstallCheck = true; });

in drv
