{
  pkgs ? import <nixpkgs> {}
, name ? "relay"
, src ? ../dist/relay.tar.gz
}:
let
in
pkgs.stdenv.mkDerivation {
  name = name;
  src = src;
  buildInputs = [ pkgs.nodejs-14_x pkgs.python38 ];
  buildPhase = ''
    export HOME=$TMPDIR
    make build-relay
    cd packages/relay && npx bundle-deps
    tgzFile=$(npm pack | tail -1)
  '';
  installPhase = ''
    mkdir -pv $out
    tar xf  $tgzFile  --strip-components=1 -C $out
  '';
}
