{
  pkgs ? import <nixpkgs> {}
, name ? "relay"
, src ? ../.
}:
let
in
pkgs.stdenv.mkDerivation {
  name = name;
  # TODO, src can be a tar file
  src = src;
  buildInputs = [ pkgs.nodejs-14_x pkgs.python38 ];
  HOME=".";
  buildPhase = ''
    make build-relay
  '';
  installPhase = ''
    mkdir $out
    cd packages/relay
    npx npm-pack-all
    mv *.tgz $out
    tar --strip-components=1 -xvf $out/*.tgz -C $out
  '';
}
