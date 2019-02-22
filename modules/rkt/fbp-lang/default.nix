{ pkgs ? (import ../../.. {}).pkgs
, buildThinRacketPackage ? pkgs.buildThinRacketPackage
}:

buildThinRacketPackage ./.
