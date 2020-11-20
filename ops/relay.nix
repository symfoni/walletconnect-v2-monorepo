{
  pkgs ? import <nixpkgs> {}
, name ? "relay"
, src ? ../dist/relay.tar.gz
}:
let
  relayjson = builtins.fromJSON (builtins.readFile ../packages/relay/package.json);
  temp = relayjson.name + "-" + relayjson.version + ".tgz";
  tgzFile = builtins.replaceStrings ["@" "/"] ["" "-"] temp;
in
pkgs.stdenv.mkDerivation {
  name = name;
  src = ../.;
  buildInputs = [ pkgs.nodejs-14_x pkgs.python38 ];
  buildPhase = ''
    export HOME=$TMPDIR
    make build-relay
    cd packages/relay
    npx bundle-deps && npm pack
  '';
  installPhase = ''
    mkdir -pv $out
    echo Sup ${tgzFile}
    tar xvf --strip-components=1 ${tgzFile} -C $out
    ls $out
  '';
}
