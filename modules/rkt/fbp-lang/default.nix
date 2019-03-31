{ pkgs ? (import ../../.. {}).pkgs
, buildRacket ? racket2nix.buildRacket
, buildRacketPackage ? racket2nix.buildRacketPackage
, racket2nix ? pkgs.racket2nix
, coreutils ? pkgs.coreutils
, findutils ? pkgs.findutils
, time ? pkgs.time
}:

let drv = buildRacketPackage (builtins.path {
  name = "fbp-lang";
  path = ./.;
  filter = (path: type:
    type != "symlink"
  );
}); in

drv // {
  test = drv.racket-packages.compiler-lib.overrideRacketDerivation (oldAttrs: {
    pname = "${drv.pname}-test";
    buildInputs = drv.racket-packages.compiler-lib.buildInputs or [] ++ [ coreutils findutils time ];
    racketBuildInputs = oldAttrs.racketBuildInputs ++ [ drv ] ++
      (builtins.filter (buildInput: buildInput.pname or "" != "compiler-lib") drv.racketBuildInputs);
    phases = "unpackPhase patchPhase installPhase fixupPhase installCheckPhase";
    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      xargs -I {} -0 -n 1 -P ''${NIX_BUILD_CORES:-1} bash -c '
        set -eu
        testpath=''${1#*/share/racket/pkgs/}
        logdir="$out/log/test/''${testpath/*}"
        mkdir -p "$logdir"
        timeout 60 time -f "%e s" racket -l- raco test "$1" |&
          grep -v -e "warning: tool .* registered twice" -e "@[(]test-responsible" |
          tee "$logdir/''${1##*/}"
      ' {} {} < <(find ${drv.env}/share/racket/pkgs/${drv.pname} -name '*.rkt' -print0)
      runHook postInstallCheck
    '';
  });
}
