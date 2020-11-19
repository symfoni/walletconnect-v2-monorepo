{
  pkgs ? import <nixpkgs> {}
, name ? "relay"
, src ? ../.
}:
let
in
pkgs.stdenv.mkDerivation {
  name = name;
  src = src;
  buildInputs = [ pkgs.nodejs-14_x ];
  HOME=".";
  buildPhase = ''
    make build-lerna
  '';
  installPhase = ''
   mkdir $out
   cp -r packages/relay/dist $out/
  '';
}
