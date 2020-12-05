{ pkgs ? <nixpkgs>}:
let
  nodeDependencies = (pkgs.callPackage ../servers/relay/default.nix {}).nodeDependencies;
in
pkgs.stdenv.mkDerivation {
  name = "relay";
  src = ../servers/relay/node-env.nix;
  buildInputs = [ pkgs.nodejs-14_x pkgs.python38 ];
  buildPhase = ''
    ln -s ${nodeDependencies}/lib/node_modules ./node_modules
    export PATH="${nodeDependencies}/bin:$PATH"

    # Build the distribution bundle in "dist"
    npm run build
    cp -r dist $out/
  '';
}
